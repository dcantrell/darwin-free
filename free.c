/*
 * free.c
 * Memory usage utility for Darwin & MacOS X (similar to 'free' under Linux)
 *
 * by:  David Cantrell <david.l.cantrell@gmail.com>
 * Copyright (C) 2002, David Cantrell, Atlanta, GA, USA.
 * Copyright (C) 2008, David Cantrell, Honolulu, HI, USA.
 * All rights reserved.
 *
 * Licensed under the GNU Lesser General Public License version 2.1 or later.
 * See COPYING.LIB for licensing details.
 */

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <libgen.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/kern_return.h>
#include <mach/host_info.h>
#include <mach/host_priv.h>

extern char *optarg;
extern int optind;

enum { DEFAULT, BYTES, KILOBYTES, MEGABYTES };
enum { OFF, ON };

typedef struct mem {
    uint64_t total;
    uint64_t used;
    uint64_t free;
    uint64_t active;
    uint64_t inactive;
    uint64_t wired;
} mem_t;

typedef struct vm {
    mem_t memory;
} vm_t;

void usage(char *pn) {
    printf( "Usage: %s [-b|-k|-m] [-s delay] [-V] [-h|-?]\n", basename(pn));
    return;
}

void checkunits(int u, char *pn) {
    if(u != DEFAULT) {
        fprintf(stderr, "You may only choose one of the following unit options:  -b, -k, or -m\n");
        fflush(stderr);
        usage(pn);
        exit(EXIT_FAILURE);
    }
}

int main(int argc, char **argv) {
    int units, poll, memsize, vmsize;
    char c;
    kern_return_t ke = KERN_SUCCESS;
    mach_port_t host, task;
    vm_size_t hps;
    vm_statistics_data_t hs;
    struct host_basic_info hbi;
    vm_t ms;

    /* set default options */
    units = DEFAULT;
    poll = 0;
 
    /* parse our command line options */
    while ((c = getopt(argc, argv, "bkms:Vh?")) != -1) {
        switch (c) {
            case 'b':
                checkunits(units, argv[0]);
                units = BYTES;
                break;
            case 'k':
                checkunits(units, argv[0]);
                units = KILOBYTES;
                break;
            case 'm':
                checkunits(units, argv[0]);
                units = MEGABYTES;
                break;
            case 's':
                poll = atoi(optarg);
                break;
            case 'V':
                printf("free version %s\n", _FREE_VERSION);
                return EXIT_SUCCESS;
                break;
            case 'h':
            case '?':
            default:
                usage(argv[0]);
                return EXIT_FAILURE;
        }
    }

    argc -= optind;
    argv += optind;

    /* use kilobytes if the user didn't specify a unit */
    if (units == DEFAULT) {
        units = KILOBYTES;
    }

    host = mach_host_self();
    task = mach_task_self();

    /* set some preferred sizes */
    memsize = sizeof(hbi) / sizeof(integer_t);
    vmsize = sizeof(hs) / sizeof(integer_t);

    /* get basic system information */
    ke = host_info(host, HOST_BASIC_INFO, (host_info_t) &hbi, &memsize);
    if (ke != KERN_SUCCESS) {
        mach_error("host_info", ke);
        return EXIT_FAILURE;
    }

    /* loop over this in case we are polling */
    while (1) {
        /* get the virtual memory page size for this machine */
        if ((ke = host_page_size(host, &hps)) != KERN_SUCCESS) {
            mach_error("host_page_size", ke);
            return EXIT_FAILURE;
        }

        /* gather virtual memory statistics */
        ke = host_statistics(host, HOST_VM_INFO, (host_info_t) &hs, &vmsize);
        if (ke != KERN_SUCCESS) {
            mach_error("host_statistics", ke);
            return EXIT_FAILURE;
        }

        /* we have collected data, put it into our structure */
        ms.memory.total = hbi.max_mem;
        ms.memory.used = (hs.active_count + hs.inactive_count + hs.wire_count) *
                         hps;
        ms.memory.free = hs.free_count * hps;
        ms.memory.active = hs.active_count * hps;
        ms.memory.inactive = hs.inactive_count * hps;
        ms.memory.wired = hs.wire_count * hps;

        /* convert to appropriate units (kilobytes are the default) */
        if (units == KILOBYTES) {
            ms.memory.total /= 1024;
            ms.memory.used /= 1024;
            ms.memory.free /= 1024;
            ms.memory.active /= 1024;
            ms.memory.inactive /= 1024;
            ms.memory.wired /= 1024;
        } else if (units == MEGABYTES) {
            ms.memory.total /= 1048576;
            ms.memory.used /= 1048576;
            ms.memory.free /= 1048576;
            ms.memory.active /= 1048576;
            ms.memory.inactive /= 1048576;
            ms.memory.wired /= 1048576;
        }

        /* display the memory usage statistics */
        printf("%18s %10s %10s %10s %10s %10s\n",
               "total", "used", "free", "active", "inactive", "wired");
        printf("Mem: %13llu %10llu %10llu %10llu %10llu %10llu\n",
               ms.memory.total, ms.memory.used, ms.memory.free,
               ms.memory.active, ms.memory.inactive, ms.memory.wired);

        /* does the loop continue? */
        if (poll != 0) {
            sleep(poll);
            printf("\n");
        } else {
            break;
        }
    }

    return EXIT_SUCCESS;
}
