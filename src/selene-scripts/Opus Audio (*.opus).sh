
avconv -i "${inFile}" -f wav -acodec pcm_s16le -vn -y - | opusenc - "${outDir}/${title}.opus"
