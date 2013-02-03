
tempAudio="${tempDir}/${title}.mp3"
tempVideo="${tempDir}/${title}.mkv"

if [ "${hasAudio}" == "1" ]; then
	avconv -i "${inFile}" -f wav -acodec pcm_s16le -ac 2 -vn -y - | lame --nohist --brief -V 4 -q 5 --replaygain-fast - "${tempAudio}"
fi

x264 --vf crop:0,0,0,0 -o "${tempVideo}" "${inFile}"

if [ "${hasAudio}" == "1" ]; then

	if [ "${subExt}" == ".srt" ] || [ "${subExt}" == ".sub" ] || [ "${subExt}" == ".ssa" ]; then
		mkvmerge --output "${outDir}/${title}.mkv" --compression -1:none "${tempAudio}" --compression -1:none "${tempVideo}" --compression -1:none "${subFile}"
	else
		mkvmerge --output "${outDir}/${title}.mkv" --compression -1:none "${tempAudio}" --compression -1:none "${tempVideo}"
	fi

else

	mv -T "${tempVideo}" "${outDir}/${title}.mkv"

fi


