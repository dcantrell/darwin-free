#
# free Makefile
# Memory usage utility for Darwin & MacOS X
# by:  David L. Cantrell Jr. <david.l.cantrell@gmail.com>
# See free.c for license and copyright information.
#

PKG         = darwin-free
VER         = 0.5.1

CWD         = $(shell pwd)
PREFIX      ?= /usr/local

CC          = gcc
CFLAGS      = -O2 -Wall -std=c99 -D_FREE_VERSION=\"$(VER)\"
CDEBUGFLAGS = -g

SRCS        = free.c
OBJS        = free.o

# Packaging commands
PACKAGEMAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
HDIUTIL=/usr/bin/hdiutil

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
	-rm -rf $(OBJS) free core free-$(VER).tar.gz
	sudo rm -rf $(PKG) $(PKG)-$(VER).pkg $(PKG).dmg $(PKG)-$(VER)

pkg:
	$(MAKE) install PREFIX=$(CWD)/$(PKG)$(PREFIX)
	find $(CWD)/$(PKG) -type d | xargs sudo chmod 0755
	sudo chmod 2755 $(CWD)/$(PKG)/usr
	sudo chown -R root $(CWD)/$(PKG)
	sudo chgrp -R wheel $(CWD)/$(PKG)
	sudo $(PACKAGEMAKER) \
		--root $(CWD)/$(PKG)$(PREFIX)/ \
		--resources $(CWD)/Resources/ \
		--out $(PKG)-$(VER).pkg \
		--id org.burdell.pkg.$(PKG)-$(VER) \
		--title $(PKG) --domain system --version
	find $(CWD)/$(PKG)-$(VER).pkg -name ".git" | xargs sudo rm -rf
	mkdir $(PKG)-$(VER)
	sudo mv *.pkg $(PKG)-$(VER)
	sudo $(HDIUTIL) create \
		-verbose \
		-srcfolder $(CWD)/$(PKG)-$(VER) \
		-nospotlight \
		-format UDBZ \
		$(PKG).dmg

tag:
	git tag -s -m "v$(VER)" v$(VER)

release: tag
	rm -rf free-$(VER)
	mkdir -p free-$(VER)
	cp -p Makefile README COPYING.LIB free.1 free.c free.h free-$(VER)
	tar -cvf - free-$(VER) | gzip -9c > free-$(VER).tar.gz
	rm -rf free-$(VER)
