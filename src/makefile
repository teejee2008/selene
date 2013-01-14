prefix = /usr
bindir = $(prefix)/bin
sharedir = $(prefix)/share
launcherdir = $(sharedir)/applications
mandir = $(sharedir)/man
man1dir = $(mandir)/man1
CFLAGS = --std=c99

all:
	valac "Main.vala" "Utility.vala" "MainWindow.vala" "PrefWindow.vala" "FileInfoWindow.vala" -o selene --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0

clean:
	rm -rf *.o selene

install:
	mkdir -p $(DESTDIR)
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sharedir)
	mkdir -p $(DESTDIR)$(mandir)
	mkdir -p $(DESTDIR)$(man1dir)
	mkdir -p $(DESTDIR)$(launcherdir)
	mkdir -p $(DESTDIR)$(sharedir)/glib-2.0/schemas/
	mkdir -p $(DESTDIR)$(sharedir)/selene/scripts
	
	install -m 0755 selene $(DESTDIR)$(bindir)
	install -m 0755 selene-scripts/* $(DESTDIR)$(sharedir)/selene/scripts
	install -m 0644 apps.selene.gschema.xml $(DESTDIR)$(sharedir)/glib-2.0/schemas
	install -m 0755 Selene.desktop $(DESTDIR)$(launcherdir)
	sudo glib-compile-schemas $(DESTDIR)$(sharedir)/glib-2.0/schemas/
	
uninstall:
	sudo rm -f /usr/bin/selene
	sudo rm -f /usr/bin/selene-admin
	sudo rm -rf /usr/share/selene-scripts
	sudo rm -f /usr/share/glib-2.0/schemas/apps.selene.gschema.xml
	sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
