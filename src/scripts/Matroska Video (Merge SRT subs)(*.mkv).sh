
if [ "${ext}" == ".flv" ]; then

	avconv -i "${inFile}" -f matroska -acodec copy -vn -sn -y "${tempDir}/audio.mka"
	avconv -i "${inFile}" -f matroska -vcodec copy -an -sn -y "${tempDir}/video.mkv"

	if [ "${subExt}" == ".srt" ] || [ "${subExt}" == ".sub" ] || [ "${subExt}" == ".ssa" ]; then
		mkvmerge --output "${outDir}/${title}.mkv" --compression -1:none "${tempDir}/video.mkv" --compression -1:none "${tempDir}/audio.mka" --compression -1:none "${subFile}"
	else
		mkvmerge --output "${outDir}/${title}.mkv" --compression -1:none "${tempDir}/video.mkv" --compression -1:none "${tempDir}/audio.mka"
	fi

else

	if [ "${subExt}" == ".srt" ] || [ "${subExt}" == ".sub" ] || [ "${subExt}" == ".ssa" ]; then
		mkvmerge --output "${outDir}/${title}.mkv" --no-subtitles --compression -1:none "${inFile}" --compression -1:none "${subFile}"
	else
		mkvmerge --output "${outDir}/${title}.mkv" --compression -1:none "${inFile}"
	fi

fi
