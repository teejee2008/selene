cd /tmp
wget http://ftp6.nero.com/tools/NeroAACCodec-1.5.1.zip
unzip -j NeroAACCodec-1.5.1.zip linux/neroAacEnc
sudo install -m 0755 neroAacEnc /usr/bin

sudo apt-get install gpac
