
avconv -i "${inFile}" -f asf -acodec wmav2 -ac 2 -vn -sn -y "${outDir}/${title}.wma"
