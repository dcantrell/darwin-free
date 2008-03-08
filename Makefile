#
# free Makefile
# Memory usage utility for Darwin & MacOS X
# by:  David L. Cantrell Jr. <david.l.cantrell@gmail.com>
# See free.c for license and copyright information.
#

VER         = 0.4.1

PREFIX      ?= /usr/local

CC          = gcc
CFLAGS      = -O2 -Wall -std=c99 -arch ppc -arch i386 -D_FREE_VERSION=\"$(VER)\"
CDEBUGFLAGS = -g

SRCS        = free.c
OBJS        = free.o

# source repository information
SVNURL = https://darwin-free.googlecode.com/svn

free: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o free

.c.o:
	$(CC) $(CFLAGS) -o $@ $< -c

install: free
	mkdir -p $(PREFIX)/bin
	mkdir -p $(PREFIX)/share/man/man1
	install -p -s -m 0755 free $(PREFIX)/bin
	install -p -m 0644 free.1 $(PREFIX)/share/man/man1

uninstall:
	rm -rf $(PREFIX)/bin/free
	rm -rf $(PREFIX)/share/man/man1/free.1

clean:
	-rm -rf $(OBJS) free core darwin-free free-$(VER).tar.gz

pkg:
	$(MAKE) install PREFIX=`pwd`/darwin-free$(PREFIX)
	/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -r `pwd`/darwin-free -i darwin-free -n $(VER) -t free -h system -v

tag:
	svn cp $(SVNURL)/trunk $(SVNURL)/tags/v$(VER)

release: tag
	rm -rf free-$(VER)
	mkdir -p free-$(VER)
	cp -p Makefile README COPYING.LIB free.1 free.c free-$(VER)
	tar -cvf - free-$(VER) | gzip -9c > free-$(VER).tar.gz
	rm -rf free-$(VER)
