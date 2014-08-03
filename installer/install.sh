#!/bin/bash

app_name='selene'
app_fullname='Selene'

generic_depends=(mediainfo libav-tools vorbis-tools x264 lame mkvtoolnix realpath rsync libgee json-glib)
debian_depends=(realpath mediainfo libav-tools vorbis-tools x264 lame mkvtoolnix rsync libgee2 libjson-glib-1.0-0)
redhat_depends=(rsync libgee json-glib mediainfo vorbis-tools mkvtoolnix)
arch_depends=(rsync libgee json-glib mediainfo x264 ffmpeg vorbis-tools lame mkvtoolnix boost icu extra/libstdc++5)

generic_recommends=(opus-tools vpx-tools ffmpeg2theora gpac sox)
debian_recommends=(opus-tools vpx-tools ffmpeg2theora gpac sox)
redhat_recommends=(opus-tools libvpx-utils theora-tools sox)
arch_recommends=(ffmpeg2theora community/opus-tools extra/libvpx gpac sox)

Reset='\e[0m'
Red='\e[1;31m'
Green='\e[1;32m'
Yellow='\e[1;33m'

CHECK_COLOR_SUPPORT() {
	colors=`tput colors`
	if [ $colors -gt 1 ]; then
		COLORS_SUPPORTED=0
	else
		COLORS_SUPPORTED=1
	fi
}

MSG_INFO() {
	if [ $COLORS_SUPPORTED -eq 0 ]; then
        echo -e "[${Yellow}*${Reset}] ${Green}$1${Reset}"
    else
        echo -e "[*] $1"
    fi
}

MSG_WARNING() {
	if [ $COLORS_SUPPORTED -eq 0 ]; then
        echo -e "[${Red}!${Reset}] ${Yellow}$1${Reset}"
    else
        echo -e "[!] $1"
    fi
}

MSG_ERROR() {
    if [ $COLORS_SUPPORTED -eq 0 ]; then
        echo -e "[${Red}X${Reset}] ${Yellow}$1${Reset}"
    else
        echo -e "[X] $1"
    fi
}

CD_PUSH() {
	cd_backup=`pwd`
}

CD_POP() {
	if [ ! -z "${cd_backup}" ]; then
		cd "${cd_backup}"
	fi
}

BACKUP_IFS(){
	IFS_backup="${IFS}"
}

SET_IFS_NEWLINE(){
	IFS=$'\n'
}

RESET_IFS() {
	if [ ! -z "${IFS_backup}" ]; then
		IFS="${IFS_backup}"
	fi
}

EXIT(){
	RESET_IFS
	CD_POP
	exit $1
}

WAIT_FOR_INPUT() {
	echo ""
	echo "Press any key to exit..."
	read dummy
}

GET_SCRIPT_PATH(){
	SCRIPTPATH="$(cd "$(dirname "$0")" && pwd)"
	SCRIPTNAME=`basename $0`
}

RUN_AS_ADMIN() {
	if [ ! `id -u` -eq 0 ]; then
		GET_SCRIPT_PATH
		if command -v sudo >/dev/null 2>&1; then
			sudo "${SCRIPTPATH}/${SCRIPTNAME}"
			EXIT $?
		elif command -v su >/dev/null 2>&1; then
			su -c "${SCRIPTPATH}/${SCRIPTNAME}"
			EXIT $?
		else
			echo ""
			MSG_ERROR "** Installer must be run as Admin (using 'sudo' or 'su') **"
			echo ""
			EXIT 1
		fi
	fi
}

CD_PUSH
CHECK_COLOR_SUPPORT
RUN_AS_ADMIN
BACKUP_IFS

SET_IFS_NEWLINE

MSG_INFO "Expanding directories..."
for f in `find ./ -type d -exec echo "{}" \;`; do
    directory=`echo "$f" | sed -r 's/^.{2}//'`
    mkdir -p -m 755 "/$directory"
    echo "/$directory"
done
echo ""

MSG_INFO "Installing files..."
for f in `find ./ -type f \( ! -iname "install.sh" \) -exec echo "{}" \;`; do
    file=`echo "$f" | sed -r 's/^.{2}//'`
    install -m 0755 "./$file" "/$file"
    echo "/$file"
done
echo ""

RESET_IFS

if [ -f /etc/debian_version ]; then
	if command -v apt-get >/dev/null 2>&1; then
		MSG_INFO "Installing Debian packages..."
		echo ""
		for i in "${debian_depends[@]}"; do
		  MSG_INFO "Installing: $i"
		  apt-get -y install $i
		  echo ""
		done
	fi
elif [ -f /etc/redhat-release ]; then
	if command -v yum >/dev/null 2>&1; then
		MSG_INFO "Installing RedHat packages..."
		echo ""
		for i in "${redhat_depends[@]}"; do
		  MSG_INFO "Installing: $i"
		  yum -y install $i
		  echo ""
		done
	fi
elif [ -f /etc/arch-release ] || [ -f /etc/manjaro-release ]; then
	if command -v pacman >/dev/null 2>&1; then
		MSG_INFO "Installing ArchLinux packages..."
		echo ""
		for i in "${arch_depends[@]}"; do
		  MSG_INFO "Installing: $i"
		  pacman -S --noconfirm $i
		  echo ""
		done
	fi
fi
echo ""

MSG_INFO "Install completed."
echo ""
MSG_INFO "Start ${app_fullname} using the shortcut in the Applications Menu"
MSG_INFO "or by running the command: ${app_name}"	
MSG_INFO "If it fails to start, check and install following packages:"
MSG_WARNING "Required: ${generic_depends[@]}"
MSG_WARNING "Optional: ${generic_recommends[@]}"
WAIT_FOR_INPUT
EXIT 0
