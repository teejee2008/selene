
avconv -i "${inFile}" -f wav -acodec pcm_s16le -ac 2 -vn -y - | lame --nohist --brief -V 4 -q 5 --replaygain-fast - "${outDir}/${title}.mp3"
