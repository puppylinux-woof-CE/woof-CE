CC=gcc
PREFIX=$(DESTDIR)/usr
GTKFLAGS=gtk+-2.0
CFLAGS=-Wall -pedantic -std=gnu99 -g -I/usr/include `pkg-config --cflags $(GTKFLAGS)`
LDFLAGS=-Wall -s -Os `pkg-config --libs $(GTKFLAGS)` -liw -lm
SYMLINK=netmon_wpoll

all : netmon_wce

netmon_wce : netmon_wce.o
	$(CC) -o $@ $^ $(LDFLAGS)
	-ln -sf $@ $(SYMLINK)
	xgettext --keyword="_" netmon_wce.c -o po/netmon_wce.pot
	for i in po/*.po ; do \
		msgfmt $$i -o $${i%po}gmo ; \
	done

netmon_wce.o : netmon_wce.c
	$(CC) -o $@ $(CFLAGS) -c $^

install :
	install -d -m 0755 $(PREFIX)/bin
	install -m 0755 netmon_wce $(PREFIX)/bin
	-cp -af $(SYMLINK) $(PREFIX)/bin
	for j in po/*gmo ; do \
		k=$${j#*/} ; \
		install -d -m 0755 $(PREFIX)/share/locale/$${k%.gmo}/LC_MESSAGES ; \
		install -m 0644 $$j $(PREFIX)/share/locale/$${k%.gmo}/LC_MESSAGES/netmon_wce.mo ; \
	done
	install -d -m 0755 $(PREFIX)/share/pixmaps/netmon_wce
	for i in Icons/* ; do \
		install -m 0644 $$i $(PREFIX)/share/pixmaps/netmon_wce/ ; \
	done
	@echo install complete

uninstall :
	rm -f $(PREFIX)/bin/netmon_w*
	for j in po/*gmo ; do \
		k=$${j#*/} ; \
		rm -f $(PREFIX)/share/locale/$${k%.gmo}/LC_MESSAGES/netmon_wce.mo ; \
	done
	@echo uninstall complete

clean :
	-rm -f *.o netmon_wce netmon_wpoll po/*.gmo
