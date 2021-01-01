CC = gcc
FLAGS = -Wall `pkg-config --libs --cflags gtk+-2.0`
PROG = firewallstatus
PREFIX=$(DESTDIR)/usr

$(PROG) : $(PROG).c
	$(CC) -o $@ $^ $(FLAGS)
	xgettext --keyword="_" $(PROG).c -o po/$(PROG).pot
	
clean :
	rm -f $(PROG) po/*
	
install :
	install -d -m 0755 $(PREFIX)/bin
	install -s -m 0755 $(PROG) $(PREFIX)/bin
	
uninstall :
	rm -f $(PREFIX)/bin/$(PROG)
	
install_all :
	install -d -m 0755 $(PREFIX)/bin
	install -s -m 0755 $(PROG) $(PREFIX)/bin
	install -d -m 0755 $(PREFIX)/share/pixmaps/puppy
	for image in icons/*; do \
	install -m 0644 $$image $(PREFIX)/share/pixmaps/puppy; \
	done
	
uninstall_all :
	rm -f $(PREFIX)/bin/$(PROG)
	for image in icons/*; do \
	rm -f $(PREFIX)/share/pixmaps/puppy/$$image ; \
	done
	
install_min :
	install -d -m 0755 $(PREFIX)/bin
	install -s -m 0755 $(PROG) $(PREFIX)/bin
	install -d -m 0755 $(PREFIX)/share/pixmaps/puppy
