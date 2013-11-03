#!/bin/bash

backup=`pwd`
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd "$DIR"

echo "Installing files..."

sudo cp -dpr --no-preserve=ownership -t / ./*

if [ $? -eq 0 ]; then
	echo "Installed successfully."
	echo ""
	echo "Start Selene using the shortcut in the application menu"
	echo "or by typing 'selene' in a terminal window"	
	echo ""
	echo "Following packages are required for this application to function correctly:"
	echo "- (Required) libgtk-3, libgee2, libsoup, libjson-glib, realpath, rsync, mediainfo, libav-tools"
	echo "- (Optional) vorbis-tools, opus-tools, vpx-tools, x264, lame, mkvtoolnix, ffmpeg2theora, gpac, rsync"
	echo "Please ensure that the required packages are installed and up-to-date"
else
	echo "Installation failed!"
	exit 1
fi

cd "$backup"
