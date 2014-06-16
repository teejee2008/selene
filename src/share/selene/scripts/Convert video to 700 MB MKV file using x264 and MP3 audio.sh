
tempAudio="${tempDir}/${title}.mp3"
tempVideo="${tempDir}/${title}.mkv"
targetMB=700

#convert audio

avconv -i "${inFile}" -f wav -acodec pcm_s16le -ac 2 -vn -y - | lame --nohist --brief -V 4 -q 5 --replaygain-fast - "${tempAudio}"

#calculate video bitrate

echo "==========================================================">&2
audioSize=$(stat -c%s "${tempAudio}")
echo "[selene] Audio file size = ${audioSize} bytes">&2

videoSize=$((${targetMB}*1024*1024 - ${audioSize}))
echo "[selene] Target video file size = ${videoSize} bytes">&2

videoRate=$(( ($videoSize*8)/($duration*1024) ))
echo "[selene] Target video bitrate = $videoRate kbps">&2
echo "==========================================================">&2

#convert video

x264 --pass 1 --bitrate ${videoRate} --vf crop:0,0,0,0 -o /dev/null "${inFile}"
x264 --pass 2 --bitrate ${videoRate} --vf crop:0,0,0,0 -o "${tempVideo}" "${inFile}"

#merge subtiltles

if [ "${subExt}" == ".srt" ] || [ "${subExt}" == ".sub" ] || [ "${subExt}" == ".ssa" ]; then
	mkvmerge --output "${outDir}/${title}.mkv" --compression -1:none "${tempAudio}" --compression -1:none "${tempVideo}" --compression -1:none "${subFile}"
else
	mkvmerge --output "${outDir}/${title}.mkv" --compression -1:none "${tempAudio}" --compression -1:none "${tempVideo}"
fi
