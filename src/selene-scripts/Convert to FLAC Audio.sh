
avconv -i "${inFile}" -f flac -acodec flac -vn -sn -y "${outDir}/${title}.flac"
