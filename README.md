# Selene Media Encoder

https://github.com/teejee2008/selene-media-converter

Selene is an audio/video converter for audio and video files. It supports almost every file format that you are likely to come across and can encode them to popular output formats like MKV, MP4, etc. It aims to provide a simple GUI for converting files to popular formats along with powerful command-line options for automated/unattended encoding.  

## Features

*   Supports almost all input file formats that you are likely to come across (powered by ffmpeg)

*   Encode videos to common file formats like MKV, MP4, OGV, and WEBM

*   Encode music to common audio formats like MP3, MP4, AAC, OGG, OPUS, FLAC, and WAV

*   Supports encoding to latest formats like H265/HEVC, WEBM and OPUS

*   Option to pause and resume encoding

*   Option to run in background and shutdown PC after encoding

*   Commandline interface for unattended/automated encoding

*   Bash scripts can be written to control the encoding process


## Screenshots

_Main Window - Tiled View_

[![](https://4.bp.blogspot.com/-vjjv0DsK5Vo/WP4VBNcB7mI/AAAAAAAAGSc/jsQFVCkojEYaLcNppYftOqXmJGHR08iXwCLcB/s560/selene_main_tiled.png)](https://4.bp.blogspot.com/-vjjv0DsK5Vo/WP4VBNcB7mI/AAAAAAAAGSc/jsQFVCkojEYaLcNppYftOqXmJGHR08iXwCLcB/s1600/selene_main_tiled.png)

_Main Window - List View_

[![](https://1.bp.blogspot.com/-dcUuBDzNRyo/WP4WAGauF3I/AAAAAAAAGSk/Nti94GOWYf4BtV8E8iAeMOgCsmGuCt5-ACLcB/s560/selene_main_listview.png)](https://1.bp.blogspot.com/-dcUuBDzNRyo/WP4WAGauF3I/AAAAAAAAGSk/Nti94GOWYf4BtV8E8iAeMOgCsmGuCt5-ACLcB/s1600/selene_main_listview.png)

_Presets_

[![](https://2.bp.blogspot.com/-zlmeTJojdn8/WP4XbA_8AZI/AAAAAAAAGS0/EFyOmG0L8MYUFPGbr38fTe3m9lNvEAzMACLcB/s640/selene_presets.png)](https://2.bp.blogspot.com/-zlmeTJojdn8/WP4XbA_8AZI/AAAAAAAAGS0/EFyOmG0L8MYUFPGbr38fTe3m9lNvEAzMACLcB/s1600/selene_presets.png)

_Encoding Settings_

![](https://1.bp.blogspot.com/-KLyatjZpekk/WP4dFNHRJTI/AAAAAAAAGTk/vSflwonmDK4vcXyUdqz2hCGglLVZBBivACLcB/s1600/selene_encoder_settings.gif)  

_Progress Window_

[![](https://3.bp.blogspot.com/-T-yYwuK6-cA/WP4fNHC0i5I/AAAAAAAAGTw/utRoTIF6eUUl7rurU6NCSoPdkOpXEiGBgCLcB/s1600/selene_progress.png)](https://3.bp.blogspot.com/-T-yYwuK6-cA/WP4fNHC0i5I/AAAAAAAAGTw/utRoTIF6eUUl7rurU6NCSoPdkOpXEiGBgCLcB/s1600/selene_progress.png)  

## Installation

**Ubuntu-based Distributions (Ubuntu, Linux Mint, etc)**

Packages are available in the Launchpad PPA for supported Ubuntu releases.
Run the following commands in a terminal window:  

```sh
sudo apt-add-repository -y ppa:teejee2008/ppa
sudo apt-get update
sudo apt-get install selene
```

Installers are available on the [Releases](https://github.com/teejee2008/selene/releases) page for older Ubuntu releases which have reached end-of-life.

**Other Linux Distributions**

Installers are available on the [Releases](https://github.com/teejee2008/selene/releases) page.  
Run the following commands in a terminal window: 
```sh
# 64-bit
sudo chmod a+x ./selene-*-amd64.run
sudo ./selene-*-amd64.run
# 32-bit
sudo chmod a+x ./selene-*-i386.run
sudo ./selene-*-i386.run
```
You may also need to install the packages for following dependencies:  
```sh
Required: libgtk-3 libgee2 libjson-glib rsync libav-tools mediainfo
Optional: vorbis-tools, opus-tools, vpx-tools, x264, lame, mkvtoolnix, ffmpeg2theora, gpac, sox 
```

## Frequently Asked Questions

### AAC Encoding

The _Fraunhoffer FDK_ codec is used by default for AAC encoding. It produces better quality audio compared to Nero AAC which was previously the best, but is no longer developed.

_NeroAAC_ encoder can be downloaded and installed if required. 

Run following commands in a terminal window to download the last available version:
```sh
cd /tmp
wget http://ftp6.nero.com/tools/NeroAACCodec-1.5.1.zip
unzip -j NeroAACCodec-1.5.1.zip linux/neroAacEnc
sudo install -m 0755 neroAacEnc /usr/bin
sudo apt-get install gpac
```

### Command-line options

Selene can also be used from the command line and provides a rich set of options. Run Selene with the '--help' argument to see the full list of options.  

[![](http://1.bp.blogspot.com/-SR1Wk_3NGik/UfzUgy8NqTI/AAAAAAAABAk/XUxlyNdCPCU/s600/console_2.2.png)](http://1.bp.blogspot.com/-SR1Wk_3NGik/UfzUgy8NqTI/AAAAAAAABAk/XUxlyNdCPCU/s1600/console_2.2.png)  

### Using bash scripts for encoding

Bash scripts can be written for controlling the encoding process.  For example:
```sh
x264 -o "${outDir}/${title}.mkv" "${inFile}"
```
This script converts any given input file to an MKV file using the x264 encoder.  
\${inFile}, \${outDir}, \${title} are variables which refer to the input file. These variables will be inserted into the script before execution. It is mandatory to use these variables instead of hard-coding the input file names. This is the only restriction.  

The script can use _any_ command line utility (like ffmpeg, x264, etc) for converting the files. The progress percentage will be calculated automatically from the console output.  

If the encoding tool is a common tool (like ffmpeg or x264), selene will provide some additional features:  

*   The console output displayed in the statusbar will be pretty-formatted
*   The input files can be auto-cropped by replacing the cropping parameters specified in the script.  

### Auto-cropping videos

For auto-cropping the input files, select one or more files from the input list, right-click, and select the AutoCrop option. This will automatically detect the black borders in the video and set the cropping parameters for the file.

After using the 'AutoCrop' option, the output can be previewed by right-clicking the file and selecting the 'Preview Output' option. The values can be edited directly from the input file list. Clear the values to disable the cropping option.  

## License

Selene Copyright © 2012-2017 by Tony George [<teejeetech@gmail.com>](teejeetech@gmail.com)

Selene is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This application is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this application. If not, you can download a copy from [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).


## Contribute

You can contribute to this project in various ways:

* Submitting ideas, and reporting issues in the [tracker](https://github.com/teejee2008/selene-media-converter/issues)
* Translating this application to other languages
* Contributing code changes by fixing issues and submitting a pull request
* Making a donation via PayPal or bitcoin, or signing-up as a patron on Patreon

## Donate

**PayPal** ~ If you find this application useful and wish to say thanks, you can buy me a coffee by making a one-time donation with Paypal. 

[![](https://upload.wikimedia.org/wikipedia/commons/b/b5/PayPal.svg)](https://www.paypal.com/cgi-bin/webscr?business=teejeetech@gmail.com&cmd=_xclick&currency_code=USD&amount=10&item_name=Selene%20Donation)  

**Patreon** ~ You can also sign up as a sponsor on Patreon.com. As a patron you will get access to beta releases of new applications that I'm working on. You will also get news and updates about new features that are not published elsewhere.

[![](https://2.bp.blogspot.com/-DNeWEUF2INM/WINUBAXAKUI/AAAAAAAAFmw/fTckfRrryy88pLyQGk5lJV0F0ESXeKrXwCLcB/s200/patreon.png)](https://www.patreon.com/bePatron?u=3059450)

**Bitcoin** ~ You can send bitcoins at this address or by scanning the QR code below:

```1FahtkNtVBZdLNbUnC1KR7yDvvNFRuiShN```

![](https://1.bp.blogspot.com/-QQOLD2mJZ7c/WP4pRCYLqUI/AAAAAAAAGUA/tE2DOuOvfzY7MhZnJlcmdpYUeT5jPC5kQCLcB/s1600/selene.png)