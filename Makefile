#
# free Makefile
# Memory usage utility for Darwin & MacOS X
# by:  David L. Cantrell Jr. <david.l.cantrell@gmail.com>
# See free.c for license and copyright information.
#

VER         = 0.4.0

PREFIX      = /usr/local

CC          = gcc
CFLAGS      = -O2 -Wall -std=c99 -arch ppc -arch i386 -D_FREE_VERSION=\"$(VER)\"
CDEBUGFLAGS	= -g

SRCS        = free.c
OBJS        = free.o

free: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o free

.c.o:
	$(CC) $(CFLAGS) -o $@ $< -c

install:
	install -c -p -d -m 0755 -o root -g wheel free $(PREFIX)/bin
	install -c -p -d -m 0644 -o root -g wheel free.1 $(PREFIX)/share/man/man1

uninstall:
	rm -rf $(PREFIX)/bin/free
	rm -rf $(PREFIX)/share/man/man1/free.1

clean:
	-rm -rf $(OBJS) free core

release:
	rm -rf free-$(VER)
	mkdir -p free-$(VER)
	cp -p Makefile README COPYING.LIB free.1 free.c free-$(VER)
	tar -cvf - free-$(VER) | gzip -9c > free-$(VER).tar.gz
	rm -rf free-$(VER)
