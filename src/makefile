prefix=/usr
bindir=$(prefix)/bin
sharedir=$(prefix)/share
localedir=$(sharedir)/locale
launcherdir=$(sharedir)/applications
mandir=$(sharedir)/man
man1dir=$(mandir)/man1
CFLAGS=--std=c99
app_name=selene
app_fullname=Selene

gtk3_version=$(shell { (pkg-config --modversion gtk+-3.0 | cut -d. -f2); } )

ifeq ($(shell { test ${gtk3_version} -gt 17 ; echo $$? ; } ), 0)
gtk3_symbols=$(shell { echo '-D GTK3_18'; } )
else
gtk3_symbols=$(shell { echo ''; } )
endif

define_symbols=$(shell { echo "${gtk3_symbols}"; } )

all:
	#build binaries
	valac -X -D'GETTEXT_PACKAGE="${app_name}"' --Xcc="-lm" -X -Wl,-rpath,/usr/share/${app_name}/libs ${define_symbols} "Main.vala" "Utility.vala" "MainWindow.vala" "AppConfigWindow.vala" "EncoderConfigWindow.vala" "EncoderStatusWindow.vala" "FileInfoWindow.vala" "AboutWindow.vala" "DonationWindow.vala" "CustomMessageDialog.vala" "SimpleProgressWindow.vala" "ColumnSelectionDialog.vala" "BatchEditWindow.vala" "MediaFile.vala" "MediaPlayer.vala" "ScriptFile.vala" "MediaPlayerWindow.vala" "XidHelper.vala" "TreeViewColumnManager.vala" "ColumnSelectionBox.vala" -o ${app_name} --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg gee-0.8 --pkg json-glib-1.0 --pkg gdk-x11-3.0
	#--pkg gdk-x11-3.0

	#valac -X -D'GETTEXT_PACKAGE=ffmpeg-builder' --Xcc="-lm" -X -Wl,-rpath,/usr/share/${app_name}/libs "Main.vala" "Utility.vala" "FFmpegBuilder.vala" "CustomMessageDialog.vala" -o ${app_name} --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg gee-0.8 --pkg json-glib-1.0 --pkg libvte

	#update translation template
	xgettext --language=C --keyword=_ --copyright-holder='Tony George (teejee2008@gmail.com)' --package-name='${app_name}' --package-version='2.2' --msgid-bugs-address='teejee2008@gmail.com' --escape --sort-output -o ../${app_name}.pot *.vala

clean:
	rm -rf *.o ${app_name}

install:
	mkdir -p "$(DESTDIR)$(bindir)"
	mkdir -p "$(DESTDIR)$(sharedir)"
	mkdir -p "$(DESTDIR)$(mandir)"
	mkdir -p "$(DESTDIR)$(man1dir)"
	mkdir -p "$(DESTDIR)$(launcherdir)"
	mkdir -p "$(DESTDIR)$(sharedir)/glib-2.0/schemas/"
	mkdir -p "$(DESTDIR)$(sharedir)/${app_name}"
	mkdir -p "$(DESTDIR)$(sharedir)/pixmaps"

	#binary
	install -m 0755 ${app_name} "$(DESTDIR)$(bindir)"
	install -m 0755 ${app_name}-uninstall "$(DESTDIR)$(bindir)"

	#shared files
	cp -dpr --no-preserve=ownership -t "$(DESTDIR)$(sharedir)/${app_name}" ./share/${app_name}/*
	chmod --recursive 0755 $(DESTDIR)$(sharedir)/${app_name}/*

	#launcher
	install -m 0755 ${app_name}.desktop "$(DESTDIR)$(launcherdir)"

	#app icon
	install -m 0755 ./share/pixmaps/${app_name}.png "$(DESTDIR)$(sharedir)/pixmaps"

	#translations
	mkdir -p "$(DESTDIR)$(localedir)/ms/LC_MESSAGES"
	msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/ms/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-ms.po
	mkdir -p "$(DESTDIR)$(localedir)/ko/LC_MESSAGES"
	msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/ko/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-ko.po
	mkdir -p "$(DESTDIR)$(localedir)/es/LC_MESSAGES"
	msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/es/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-es.po
	mkdir -p "$(DESTDIR)$(localedir)/cs/LC_MESSAGES"
	msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/cs/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-cs.po
	mkdir -p "$(DESTDIR)$(localedir)/nl/LC_MESSAGES"
	msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/nl/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-nl.po
	mkdir -p "$(DESTDIR)$(localedir)/fr/LC_MESSAGES"
	msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/fr/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-fr.po
	mkdir -p "$(DESTDIR)$(localedir)/sv/LC_MESSAGES"
	msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/sv/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-sv.po
	mkdir -p "$(DESTDIR)$(localedir)/pt_BR/LC_MESSAGES"
	msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/pt_BR/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-pt_BR.po
	
uninstall:
	#binary
	rm -f "$(DESTDIR)$(bindir)/${app_name}"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-uninstall"

	#shared files
	rm -rf "$(DESTDIR)$(sharedir)/${app_name}"

	#launcher
	rm -f "$(DESTDIR)$(launcherdir)/${app_name}.desktop"

	#app icon
	rm -f "$(DESTDIR)$(sharedir)/pixmaps/${app_name}.png"

    #translations
	rm -f $(DESTDIR)$(localedir)/*/LC_MESSAGES/${app_name}.mo
