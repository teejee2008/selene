
tempAudio="${tempDir}/${title}.mp3"
tempVideo="${tempDir}/${title}.mkv"

if [ "${hasAudio}" == "1" ]; then
	avconv -i "${inFile}" -f mp3 -acodec libmp3lame -q 4 -vn -sn -y "${tempAudio}"
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


