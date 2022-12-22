#!/bin/bash

sudo apt install scrub -y

ubicado=$(sudo fdisk -l /dev/sdb |  tail -3 | head -1 | awk '{print $1}')
tres_letras=$(echo ${ubicado:8:2})
echo $tres_letras

> saber.txt
> ordenado.txt

for (( c=1; c<=$tres_letras; c++ ))
do

# hola+=$(sudo fdisk -l  /dev/sdb | awk '/sdb'$c'/ { print $2} ')
 #hola+=$(echo -e '   ')
  sudo fdisk -l  /dev/sdb | grep 'sdb'$c' ' | awk ' { print $2} ' >> saber.txt
done


intentar=$(sort -n saber.txt)

echo $intentar |  awk '{gsub(" ","\n"); print }' > saber.txt
contador_lineas=$(wc -l saber.txt | awk ' { print $1 } ')


for (( c=1; c<=$contador_lineas; c++ ))
do
  sector_ord=$(awk 'NR=='$c saber.txt)
  disco_ord=$( sudo fdisk -l  /dev/sdb | grep $sector_ord' ' | awk ' { gsub("/"," ") ; print $2 } ' )
  sudo fdisk -l  /dev/sdb | grep $sector_ord | awk ' { gsub("/"," ") ; print $2 } ' >> ordenado.txt | head -1
#sudo fdisk -l  /dev/sdb | grep $sector_ord' ' | awk ' { print } '

  lsblk | grep $disco_ord' ' | awk '{gsub("/"," ") ; print $1 " ->  " $9}' >> ordenado_disco.txt

done


while true
do

  echo "clonar"

  #lsblk | grep sd | awk '{gsub("/"," ") ; print $1 " ->  " $9}'
  cat ordenado_disco.txt
  echo ""
  echo "--------------------------------------------------"
  read -p "QUE PARTICION QUIERES CLONAR? (Ejemplo: 'sdb3'): " ubicacion

  echo "$ubicacion"
  #numero=$(echo ${ubicacion:3:2})
  dos_letras=$(echo ${ubicacion:0:2})
  tres_letras=$(echo ${ubicacion:0:3})
  particion_comp=$(lsblk | grep $ubicacion)


  #echo $numero
  echo "$ubicacion"
  echo "$dos_letras"
  echo "$particion_comp"


  numero=$(cat ordenado.txt | grep -n $ubicacion | awk '{gsub(":"," "); print $1 }' | head -1)



  let i=$numero-1
  arranque=$(awk 'NR=='$i ordenado.txt)
  echo $numero
   echo $arranque


  let num_recuperacion=$numero-2
  recuperacion=$(echo $tres_letras$num_recuperacion)

  if [[ "$dos_letras" == "sd" ]] && [[ "$particion_comp" != "" ]]; then

    read -p 'Seguro que quieres clonar la partincion '$ubicacion' en nvme0n1?(y/N)' clonar_sys
    if [[ "${clonar_sys,,}" == "y" ]]; then
    read -p 'Elige que SISTEMA OPERATIVO quieres: 1.Ubuntu u otros 2.Windows 3.Debian' eleccion_so


     if [[ $eleccion_so == '1' ]]; then
      echo '-------------------------------------------'
      echo 'CLONANDO LA PARTICION ' $ubicacion ' --> nvme0n1'

      echo 'sudo parted -s /dev/nvme0n1 mklabel gpt'
      sudo parted -s /dev/nvme0n1 mklabel gpt
      read
      sudo scrub /dev/nvme0n1  &
      sleep 40
      sudo pkill -e scrub
      read
      echo 'sudo parted -s /dev/nvme0n1 mklabel gpt'
      sudo parted -s /dev/nvme0n1 mklabel gpt
      read
      echo 'sudo parted -s /dev/nvme0n1 mkpart primary 1 538'
      sudo parted -s /dev/nvme0n1 mkpart primary 1 538
      read
      echo 'sudo mkfs.fat -F 32 /dev/nvme0n1p1'
      sudo mkfs.fat -F 32 /dev/nvme0n1p1
      read
      echo $arranque
      echo 'sudo dd if=/dev/'$arranque' of=/dev/nvme0n1p1'
      sudo dd if=/dev/$arranque of=/dev/nvme0n1p1

      echo 'sudo parted -s /dev/nvme0n1 set 1 boot on'
      sudo parted -s /dev/nvme0n1 set 1 boot on

      echo ''
      echo '------------ARRANQUE INSTALADO-------------'
      echo ''

      echo 'sudo parted -s /dev/nvme0n1 mkpart primary 538 100%'
      sudo parted -s /dev/nvme0n1 mkpart primary 538 100%
      read
      echo 'sudo mkfs.ext4 /dev/nvme0n1p2 '
      sudo mkfs.ext4 /dev/nvme0n1p2
      read
      echo $ubicacion
      echo 'sudo dd if=/dev/'$ubicacion' of=/dev/nvme0n1p2'
      sudo dd if=/dev/$ubicacion of=/dev/nvme0n1p2

      disco2=$(sudo fdisk -l | awk '/nvme0n1p2/ { gsub("G",""); print $5 }')
      disco2=$(echo "$disco2" | awk '{ gsub(",","."); print}')
      disco1=$(awk "BEGIN {print  ($disco2*1024) - 500}")
      echo $disco1

      echo 'sudo e2fsck -f -y -v -C 0 /dev/nvme0n1p2'
      sudo e2fsck -f -y -v -C 0 '/dev/nvme0n1p2'

      echo 'sudo resize2fs -p /dev/nvme0n1p2 ' ${disco1}'M'
      sudo resize2fs -p '/dev/nvme0n1p2' ${disco1}M

     elif [[ $eleccion_so = '2' ]]; then
      echo '-------------------------------------------'
      echo 'CLONANDO LA PARTICION ' $ubicacion ' --> nvme0n1'
      let i=$numero-2
      recuperacion=$(awk 'NR=='$i ordenado.txt)

      echo 'sudo parted -s /dev/nvme0n1 mklabel gpt'
      sudo parted -s /dev/nvme0n1 mklabel gpt
      read
      sudo scrub /dev/nvme0n1  &
      sleep 50
      sudo pkill -e scrub
      read
      echo 'sudo parted -s /dev/nvme0n1 mklabel gpt'
      sudo parted -s /dev/nvme0n1 mklabel gpt
      read
      echo 'sudo parted -s /dev/nvme0n1 mkpart primary 1 538'
      sudo parted -s /dev/nvme0n1 mkpart primary 1 538
      read

      sudo ntfsresize -i -f -v '/dev/'$recuperacion
      sudo ntfsclone -f --overwrite '/dev/nvme0n1p1' '/dev/'$recuperacion
      
      echo 'sudo parted -s /dev/nvme0n1 set 1 boot on'
      sudo parted -s /dev/nvme0n1 set 1 diag on
      sudo parted -s /dev/nvme0n1 set 1 hidden on

      echo ''
      echo '------------RECUPERACION INSTALADA-------------'
      echo ''
      echo 'sudo parted -s /dev/nvme0n1 mkpart primary 538 648'
      sudo parted -s /dev/nvme0n1 mkpart primary 538 643
      read
      echo 'sudo mkfs.fat -F 32 /dev/nvme0n1p1'
      sudo mkfs.fat -F 32 /dev/nvme0n1p2 
      read
      echo $arranque
      echo 'sudo dd if=/dev/'$arranque' of=/dev/nvme0n1p1'
      sudo dd if=/dev/$arranque of=/dev/nvme0n1p2

      echo 'sudo parted -s /dev/nvme0n1 set 1 boot on'
      sudo parted -s /dev/nvme0n1 set 2 boot on

      echo ''
      echo '------------ARRANQUE INSTALADO-------------'

      echo 'sudo parted -s /dev/nvme0n1 mkpart primary 538 100%'
      sudo parted -s /dev/nvme0n1 mkpart primary 643 100%
      read
      echo $ubicacion
      echo "ntfsresize -i -f -v '/dev/'$ubicacion"
      sudo ntfsresize -i -f -v '/dev/'$ubicacion

      echo "ntfsclone -f --overwrite '/dev/nvme0n1p3' '/dev/'$ubicacion"
      sudo ntfsclone -f --overwrite '/dev/nvme0n1p3' '/dev/'$ubicacion 

      sudo ntfsresize -i -f -v '/dev/nvme0n1p3'
      sudo ntfsresize --force --force '/dev/nvme0n1p3'

      sudo parted -s /dev/nvme0n1 set 3 msftdata on

    elif [[ $eleccion_so = '3' ]]; then
      echo '-------------------------------------------'
      echo 'CLONANDO LA PARTICION ' $ubicacion ' --> nvme0n1'
      echo $numero
      let i=$numero+1
      echo $i
      swap_debian=$(awk 'NR=='$i ordenado.txt)
      echo $swap_debian

      echo 'sudo parted -s /dev/nvme0n1 mklabel gpt'
      sudo parted -s /dev/nvme0n1 mklabel gpt
      read
      sudo scrub /dev/nvme0n1  &
      sleep 60
      sudo pkill -e scrub
      read
      echo 'sudo parted -s /dev/nvme0n1 mklabel gpt'
      sudo parted -s /dev/nvme0n1 mklabel gpt
      read
      echo 'sudo parted -s /dev/nvme0n1 mkpart primary 1 538'
      sudo parted -s /dev/nvme0n1 mkpart primary 1 538
      read
      echo 'sudo mkfs.fat -F 32 /dev/nvme0n1p1'
      sudo mkfs.fat -F 32 /dev/nvme0n1p1

      read
      echo $arranque
      echo 'sudo dd if=/dev/'$arranque' of=/dev/nvme0n1p1'
      sudo dd if=/dev/$arranque of=/dev/nvme0n1p1

      echo 'sudo parted -s /dev/nvme0n1 set 1 boot on'
      sudo parted -s /dev/nvme0n1 set 1 boot on

      echo ''
      echo '------------ARRANQUE INSTALADO-------------'
      echo ''
     read
      inf_disc=$(sudo fdisk -l | grep "nvme0n1:" | awk ' { gsub("G",""); print $3 }')
      inf_disc_2=$(awk "BEGIN {print  ($inf_disc*1024) - 9040}")

      echo 'sudo parted -s /dev/nvme0n1 mkpart primary 538 100%'
      sudo parted -s /dev/nvme0n1 mkpart primary 538 ${inf_disc_2}MiB
      read
      echo 'sudo mkfs.ext4 /dev/nvme0n1p2 '
      sudo mkfs.ext4 /dev/nvme0n1p2
      read
      echo $ubicacion
      echo 'sudo dd if=/dev/'$ubicacion' of=/dev/nvme0n1p2'
      sudo dd if=/dev/$ubicacion of=/dev/nvme0n1p2

      disco2=$(sudo fdisk -l | awk '/nvme0n1p2/ { gsub("G",""); print $5 }')
      disco2=$(echo "$disco2" | awk '{ gsub(",","."); print}')
      disco1=$(awk "BEGIN {print  ($disco2*1024) - 500}")
      echo $disco1

      echo 'sudo e2fsck -f -y -v -C 0 /dev/nvme0n1p2'
      sudo e2fsck -f -y -v -C 0 '/dev/nvme0n1p2'

      echo 'sudo resize2fs -p /dev/nvme0n1p2 ' ${disco1}'M'
      sudo resize2fs -p '/dev/nvme0n1p2' ${disco1}M
      
      echo ''
      echo '------------SISTEMA INSTALADO-------------'
      echo ''
      read
      echo 'sudo parted -s /dev/nvme0n1 mkpart primary 1 538'
      inf_disc=$(sudo fdisk -l | grep "nvme0n1:" | awk ' { gsub("G",""); print $3 }')
      inf_disc_2=$(awk "BEGIN {print  ($inf_disc*1024) - 9040}")
      sudo parted -s /dev/nvme0n1 mkpart primary ${inf_disc_2}MiB 100%


      uuid_swap=$(sudo blkid | grep $swap_debian":" | awk '{gsub("\""," ") ; print $3}')
      echo $uuid_swap
      sudo mkswap -L '' -U $uuid_swap /dev/nvme0n1p3
      read

      echo 'sudo parted -s /dev/nvme0n1 set 1 boot on'
      sudo parted -s /dev/nvme0n1 set 3 swap on

      echo ''
      echo '------------SWAP INSTALADA-------------'
      echo ''
      read

     else
      echo 'Elige entre las opciones: "1", "2", o "3"'
     fi
    else
      echo '-------------------------------------------'
      echo 'ABORTANDO EL PROCESO DE CLONADO'
    fi

  else
    echo "mal"
    read
  fi
done


