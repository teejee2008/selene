
sudo rm -r /usr/share/selene/scripts/*
sudo rm -r /usr/share/selene/presets/*
sudo cp -dpr --no-preserve=ownership -t /usr/share/selene/scripts scripts/*
sudo cp -dpr --no-preserve=ownership -t /usr/share/selene/presets presets/*
sudo chmod --recursive 0755 /usr/share/selene/*

echo "Finished"
read dummy
