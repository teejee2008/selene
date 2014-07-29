cd /tmp
wget http://ftp6.nero.com/tools/NeroAACCodec-1.5.1.zip
unzip -j NeroAACCodec-1.5.1.zip linux/neroAacEnc linux/neroAacDec linux/neroAacTag
sudo install -m 0755 neroAacDec /usr/bin
sudo install -m 0755 neroAacEnc /usr/bin
sudo install -m 0755 neroAacTag /usr/bin
rm -f NeroAACCodec-1.5.1.zip neroAacDec neroAacEnc neroAacTag

sudo apt-get -y install gpac
