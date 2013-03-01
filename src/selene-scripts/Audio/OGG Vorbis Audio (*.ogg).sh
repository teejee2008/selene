
avconv -i "${inFile}" -f mp3 -acodec libvorbis -q 3 -vn -sn -y "${outDir}/${title}.ogg"
