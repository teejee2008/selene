prefix = /usr
bindir = $(prefix)/bin
sharedir = $(prefix)/share
localedir = $(sharedir)/locale
launcherdir = $(sharedir)/applications
mandir = $(sharedir)/man
man1dir = $(mandir)/man1
CFLAGS = --std=c99

all:
	valac -X -D'GETTEXT_PACKAGE="selene"' --Xcc="-lm" "Main.vala" "Utility.vala" "MainWindow.vala" "PrefWindow.vala" "ConfigWindow.vala" "FileInfoWindow.vala" -o selene --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg gee-1.0 --pkg libsoup-2.4 --pkg json-glib-1.0 

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
	mkdir -p $(DESTDIR)$(sharedir)/selene/presets
	mkdir -p $(DESTDIR)$(sharedir)/selene/images

	install -m 0755 selene $(DESTDIR)$(bindir)
	cp -dpr --no-preserve=ownership -t $(DESTDIR)$(sharedir)/selene/scripts scripts/*
	cp -dpr --no-preserve=ownership -t $(DESTDIR)$(sharedir)/selene/presets presets/*
	cp -dpr --no-preserve=ownership -t $(DESTDIR)$(sharedir)/selene/images  images/*
	chmod --recursive 0755 $(DESTDIR)$(sharedir)/selene/*
	
	install -m 0755 Selene.desktop $(DESTDIR)$(launcherdir)
	install -m 0644 apps.selene.gschema.xml $(DESTDIR)$(sharedir)/glib-2.0/schemas
	glib-compile-schemas $(DESTDIR)$(sharedir)/glib-2.0/schemas/

uninstall:
	rm -f $(DESTDIR)$(bindir)/selene
	rm -f $(DESTDIR)$(bindir)/selene-admin
	rm -rf $(DESTDIR)$(sharedir)/selene/scripts
	rm -rf $(DESTDIR)$(sharedir)/selene/presets
	rm -rf $(DESTDIR)$(sharedir)/selene/images
	rm -rf $(DESTDIR)$(sharedir)/selene
	rm -f $(DESTDIR)$(launcherdir)/Selene.desktop
	rm -f $(DESTDIR)$(sharedir)/glib-2.0/schemas/apps.selene.gschema.xml
	glib-compile-schemas $(DESTDIR)$(sharedir)/glib-2.0/schemas/
	
