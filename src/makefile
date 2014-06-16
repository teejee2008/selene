prefix = /usr
bindir = $(prefix)/bin
sharedir = $(prefix)/share
localedir = $(sharedir)/locale
launcherdir = $(sharedir)/applications
mandir = $(sharedir)/man
man1dir = $(mandir)/man1
CFLAGS = --std=c99

all:
	valac -X -D'GETTEXT_PACKAGE="selene"' --Xcc="-lm" "Main.vala" "Utility.vala" "MainWindow.vala" "PrefWindow.vala" "ConfigWindow.vala" "EncodersWindow.vala" "FileInfoWindow.vala" "AboutWindow.vala" "DonationWindow.vala" -o selene --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg gee-1.0 --pkg libsoup-2.4 --pkg json-glib-1.0 

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
	mkdir -p $(DESTDIR)$(sharedir)/selene
	mkdir -p $(DESTDIR)$(sharedir)/pixmaps
	
	#binary
	install -m 0755 selene $(DESTDIR)$(bindir)
	
	#shared files
	cp -dpr --no-preserve=ownership -t $(DESTDIR)$(sharedir)/selene ./share/selene/*
	chmod --recursive 0755 $(DESTDIR)$(sharedir)/selene/*
	
	#launcher
	install -m 0755 Selene.desktop $(DESTDIR)$(launcherdir)
	
	#app icon
	install -m 0755 ./share/pixmaps/selene.png $(DESTDIR)$(sharedir)/pixmaps
	
	#translations
	#mkdir -p "$(DESTDIR)$(localedir)/cs_CZ/LC_MESSAGES"
	#msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/cs_CZ/LC_MESSAGES/selene.mo" ../po/selene-cs.po
	
uninstall:
	#binary
	rm -f $(DESTDIR)$(bindir)/selene
	#rm -f $(DESTDIR)$(bindir)/selene-admin
	
	#shared files
	rm -rf $(DESTDIR)$(sharedir)/selene
	
	#launcher
	rm -f $(DESTDIR)$(launcherdir)/Selene.desktop
	
	#app icon
	rm -f $(DESTDIR)$(sharedir)/pixmaps/selene.png
	
    #translations
	#rm -f "$(DESTDIR)$(localedir)/*/LC_MESSAGES/selene.mo"
