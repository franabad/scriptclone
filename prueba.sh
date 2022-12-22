#!/bin/bash

#touch try.txt
#cd ~/Descargas

#disco_script=$(lsblk -e 7 -o name,label | awk '{print $1"\t""\t"$2}' | grep "script")

#disco=${disco_script:2:3}

#sudo umount "/dev/$disco"?*

#sleep 0.5
#setsid gparted &>/dev/null

#sleep 0.5
#nautilus -q

#sleep 1
#gnome-terminal -- bash -c ". test.sh; exec bash"

#exit

#disco_secundario=$(lsblk -e 7 | tail -n 1 | awk '{print $1}')
#disco_secundario2=


#if [[ $disco_secundario == "nvme1n1" ]] || [[ $disco_secundario == "sdb" ]]; then
#  echo "Funciona"
#else 
#  echo "No funciona"
#fi

#read -p "Indique si quiere que la etiqueta sea 1. Datos, 2. Data: " etiqueta
#etiqueta=${etiqueta:-1}

#until [[ $etiqueta == "1" ]] || [[ $etiqueta == "2" ]]
#do
#  read -p "[-]¡ERROR! Indique si quiere que la etiqueta sea 1. Datos, 2. Data: " etiqueta
#  etiqueta=${etiqueta:-1}
#done

#case $etiqueta in
#  1)
#    echo "Datos"
#  ;;
#  2)  
#    echo "Data"
#esac

#(
#echo mktable gpt
#echo quit
#) | sudo parted /dev/sdb > /dev/null

#fichero=~/Escritorio/error.txt

#if [ -s $fichero ]; then

#  read -p "Indica blabla..." indicar 2>&1
#  echo "Ha habido algún error"
#	tput setaf 1;cat error.txt;tput setaf default
#else 
#  echo "No ha habido ningún error"
#fi

#hola=true
#adios=3

#if [ $hola = true ] && [[ $adios == 3 ]]; then
#  echo "Funciona"
#else
#  echo "No funciona"
#fi

# function countdown() {
# 	hour=0
# 	min=0
# 	sec=20
# 	tput civis
# 	while [ $hour -ge 0 ]; do
# 		while [ $min -ge 0 ]; do
# 			while [ $sec -ge 0 ]; do
# 				echo -ne "Quedan $(printf "%02d" $hour):$(printf "%02d" $min):$(printf "%02d" $sec) segundo(s) restantes...\033[0K\r"
# 				let "sec=sec-1"
# 				#sleep 1
# 				read -t 1 -n 1 -s keypress && break
# 			done
# 				sec=59
# 				let "min=min-1"
# 		done
# 	min=59
# 	let "hour=hour-1" 
# 	done
# }
# countdown

# grep -v "Puede que tenga que actualizar /etc/fstab." try.txt > tmp && mv tmp try2.txt

# sed -i '/^$/d' try2.txt

# log=~/Escritorio/try2.txt

# if [[ -s $log ]]; then
#   tput setaf 1;cat $log;tput init
# 	echo "Ha habido algún error al clonar"
# else
# 	sec=10
# 	while [ $sec -ge 0 ]; do 
# 		echo -ne "[!]----Se reiniciará en $(printf $sec) segundo(s)... Pulse ENTER para continuar. Use ESC p\033[0K\r"
# 		let "sec=sec-1"
# 		sleep 15
# 	done
# 	lsblk -e 7
# fi

# function listar_particiones() {
# 	echo "Lista de discos y particiones:"
# 	comando_filas=$(lsblk -e 7 | wc -l)
# 	comando=$(lsblk -e 7 -o name,label | awk '{print $1"\t""\t"$2}')
# 	j=2
	
# 	#lsblk -e 7 -o name,label,partlabel | head -n 1 | sed 's/NAME/Dispositivo/' | sed 's/LABEL/Label/' | sed 's/PARTLABEL/Fecha/'

# 	printf "%-16s%-16s%-16s\n" Dispositivo Label Fecha

# 	for ((i=1;i<=$comando_filas-1;i++))
# 	do
#         	echo $i-$(lsblk -e 7 -o name,label,partlabel | head -n $j | tail -n +$j | sed 's/PARTLABEL/Fecha/')
#         	((j=j+1))
# 	done | column -t
# }

# listar_particiones

out=~/Escritorio/output.txt
err=~/Escritorio/error.txt
err_command=~/Escritorio/comando.txt

# { exec 2>&1 1>&3 | tee error.txt; } > output.txt 3>&1

# echo -ne "Haciendo ping...\033[0K\r"| tee -a /dev/tty
# #ping -c 3 google.es 
# #sleep 0.5
# if ! ping -c 3 google.es; then
#   echo -ne "Error al hacer ping \u2717\033[0K\r\n"| tee -a /dev/tty
# else
#   echo -ne "Ping realizado con éxito\u2714\033[0K\r\n" | tee -a /dev/tty
# fi

# (
#   echo select /dev/sdb
#   echo set 4 boot ON
#   echo set 4 esp ON
#   echo name 4 
#   echo ' '
#   echo name 5 
#   echo ' '
# ) | sudo parted /dev/sdb 2> $err_command &2> $err
# read
# grep -v "Información: Puede que sea necesario actualizar /etc/fstab." $err_command > tmp && rm $err_command && mv tmp comando.txt
# #grep -v "La etiqueta de disco actual en" $err > tmp && rm $err && mv tmp error.txt
# sed -i '/^$/d' $err

# if [[ -s ${err_command} ]];then
#   echo "Error al setear flags y/o nombre" | tee -a /dev/tty
# else
#   echo "Flags y nombres creados correctamente" | tee -a /dev/tty
# fi
# read
# (
#   echo select /dev/sdb
#   echo set 9 boot ON
#   echo set 9 esp ON
#   echo name 4 
#   echo ' '
#   echo name 5 
#   echo ' '
# ) | sudo parted /dev/sdb > $err_command

# if [[ -s ${err_command} ]];then
#   echo "Error al setear flags y/o nombre" | tee -a /dev/tty
# else
#   echo "Flags y nombres creados correctamente" | tee -a /dev/tty
# fi

#set +x

# echo -ne "Creando archivo...\033[0K\r"
# touch try.txt 2>>
# sleep 2
# if [[ -s ${error} ]] ;then
# 	echo -ne "Error al crear el archivo \u2717\033[0K\r\n"
# else
# 	echo -ne "Archivo creado \u2714\033[0K\r\n"
# fi

# echo -ne "Hola\033[0K\r"
# sleep 0.5
# echo -ne "Adios\033[0K\r"
# sleep 0.5
# echo -e "T\033[0K\r"

# rm output.txt
# rm error.txt

#exec 2> >(tee output.txt)
#exec 2> >(tee error.txt)
#exec 1> >(tee output.txt)

# echo "stdout"
# echo "stderr" >&2

# echo -ne "Haciendo ping...\n" | tee -a /dev/tty
# ping -c 5 dknsosvnio.es 
# echo -e "Error" | tee -a /dev/tty

# function cargando() {
#   echo -ne "Cargando clonadora\033[0K\r" 2>&1
#   sleep 0.3
#   echo -ne "Cargando clonadora.\033[0K\r" 2>&1
#   sleep 0.3
#   echo -ne "Cargando clonadora..\033[0K\r" 2>&1
#   sleep 0.3
#   echo -ne "Cargando clonadora...\033[0K\r" 2>&1
#   sleep 0.3
# }

# lista=$(lsblk | wc -l)
# no_usb=$(($lista-3)) 
# clone=false
# until [[ $clone = true ]];do
#   echo "No hemos quitado USB"
#   tput civis
#   lista=$(lsblk | wc -l)
#   cargando
#   while [[ $lista == $no_usb ]];do #Cuando quitas USB
#     echo "USB fuera"
#     lista_clone=$(lsblk | wc -l)
#     cargando
#     if [[ $lista_clone -gt $no_usb ]];then
#       echo "Clonadora conectada"
#       break
#     fi
#   clone=true
#   done
# done

# tput cnorm

# until false;do
#   tput civis
#   echo -ne "Cargando clonadora\033[0K\r" 2>&1
#   sleep 0.3
#   echo -ne "Cargando clonadora.\033[0K\r" 2>&1
#   sleep 0.3 
#   echo -ne "Cargando clonadora..\033[0K\r" 2>&1
#   sleep 0.3
#   echo -ne "Cargando clonadora...\033[0K\r" 2>&1
#   read -t 0.3 -n 1 -s keypress && break 
#   no_clone=$(lsblk -e 7 | wc -l)
#   clone=$(lsblk -e 7 | wc -l)
#   if [[ $no_clone == $no_clone-2 ]];then
#     if [[ "$clone" -gt "$no_clone" ]]; then
#       break
#     fi
#   else 
#     echo "Aún no"
#   fi
# done

# #set +x
# echo -e "Puesta\033[0K\r" 2>&1
# tput cnorm


# disco_lleno=$(lsblk -e 7 | awk '{print $1}' | grep "sdc1")

# # if [[ -n $disco_lleno ]]; then
# #   echo "Está el disco lleno"
# # else 
# #   echo "Está vacio"
# # fi

# until [ "$disco_lleno; echo $?" = "0" ]
# do 
#   echo -ne "Disco vacío...\033[0K\r"
# done

# echo "Hay una partición"

# read -r -s -t 1 -N 1 -p "Indique si es un dualboot(y/n): " dualboot;echo
# dualboot=${dualboot:-n}

# case $dualboot in 
# 	'n')
# 		echo "No hay dual"
# 	;;
# 	$'\n')
# 		echo "Si hay dual"
# esac

# size_disk_bytes=$(lsblk -b -e 7 -o name,size | awk '{ print $1 $2 }' | grep "sdc" | sed -e 's/sdc//g')

# echo $size_disk_bytes

# size_disk_sec=$((size_disk_bytes/512))
# echo $size_disk_sec

# function check_clone2() {
# 	clonadora=$(lsblk -e 7 -o name,label | sed -n '/sd.*5/p')
# 	until [[ -n $clonadora ]];do
# 		tput civis
# 		echo -ne "Cargando clonadora\033[0K\r"
# 		sleep 0.3
# 		echo -ne "Cargando clonadora.\033[0K\r"
# 		sleep 0.3
# 		echo -ne "Cargando clonadora..\033[0K\r"
# 		sleep 0.3
# 		echo -ne "Cargando clonadora...\033[0K\r"
# 		sleep 0.3
# 		#echo -ne "Quedan $(printf "%02d" $hour):$(printf "%02d" $min):$(printf "%02d" $sec) segundo(s) restantes...\033[0K\r"
# 		#let "sec=sec-1"
# 		#sleep 1
# 		#read -t 0.1 -n 1 -s keypress && break 
# 		clonadora=$(lsblk -e 7 -o name,label | sed -n '/sd.*5/p')
# 	done
# 	tput cnorm
# }


# hora=$(date -d '+1 hour' | awk '{print $5}')

# timedatectl set-ntp 0
# sudo date +%T -s "$hora"

# sleep 3
# timedatectl set-ntp 1

# sec=10
# enter=$(echo "")
# while [ $sec -ge 0 ]; do 
#   tput civis
#   echo -ne "[!]----Se reiniciará en $(printf $sec) segundo(s)...\033[0K\r"
#   let "sec=sec-1"
#   #sleep 1
#   read -r -t 1 -n 1 -s keypress
#   enter=$(echo $?) 
#   if [ "$enter" -eq 0 ] && [ "$keypress" = "" ]; then
#     echo -ne "\033[0K\r" && lsblk && break #lsblk = reboot
#   elif [ "$keypress" = $'\e' ]; then
#     echo -e "Reinicio cancelado!\033[0K\r"
#     break
#   elif [ "$enter" -eq 142 ]; then
#     continue
#   else 
#     sec=10   
#   fi
# done

# tput cnorm

  # case $keypress in
  #   $'\e')
  #     break
  #   ;;
  #   $'\n')
  #     echo -ne "\033[0K\r" && lsblk && break
  #   ;;
  # esac

  # if [ "$keypress" = "" ]; then
  #   echo -ne "\033[0K\r" && lsblk && break 
  # elif [ "$keypress" = $'\e' ]; then
  #   break
  # else 
  #   continue   
  # fi

ping=$(ping -c 1 grompofofm.es)

if ! $ping; then
  echo "Correcto"
else
  echo "No correcto"
fi