#!/bin/bash

sudo cp clone.sh ~/Desktop
cd ~/Desktop
sudo chmod 777 clone.sh

disco_script=$(lsblk -e 7 -o name,label | awk '{print $1"\t""\t"$2}' | grep "script")

disco=${disco_script:2:3}

#sudo umount "/dev/$disco"?*

sudo eject "/dev/$disco"

sleep 2
setsid gparted &>/dev/null

sleep 1
nautilus -q

sleep 2
gnome-terminal -- bash -c ". clone.sh > >(tee output.txt) 2> error.txt; exec bash" 
#echo -ne "\ec"

#tput setaf 1;echo "Inserte clonadora...";tput init

#sleep 0.5
exit

