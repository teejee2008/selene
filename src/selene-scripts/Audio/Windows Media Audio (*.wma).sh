
avconv -i "${inFile}" -f asf -acodec wmav2 -vn -sn -y "${outDir}/${title}.wma"
