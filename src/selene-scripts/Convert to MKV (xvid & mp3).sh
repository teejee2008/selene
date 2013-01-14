
avconv -i "${inFile}" -f matroska -acodec libmp3lame -vcodec libxvid -vf crop=iw:ih:0:0 -q 4 -qscale 4 -sn -y "${outDir}/${title}.mkv"

