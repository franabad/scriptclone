#!/bin/bash

# output="output.txt"
# error="error.txt"
# exec 3>&1
#  exec 1>>$output
#  exec 2>>$error

# #Comprobar si el disco nvme0n1 está usado
# disco_lleno=$(lsblk -e 7 | awk '{print $1}' | grep "sdc1")
# error=~/Desktop/error.txt

# if [[ -n $disco_lleno ]]; then
# 	echo -ne "Creando nueva tabla GPT...\n" 
# 	sleep 2
# 	sudo wipefs -a /dev/sdc 
# 	if [[ -s ${error} ]]; then
# 		echo -e "Error al crear la tabla GPT\u2717\033[0K\r\n"
# 	else
# 		echo -e "Tabla GPT creada correctamente\033[0K\r\n"
# 	fi
# fi

# sudo gparted &
# sleep 3
# echo -ne "\ec"

function cargando() {
  echo -ne "Cargando clonadora\033[0K\r" 2>&1
  sleep 0.3
  echo -ne "Cargando clonadora.\033[0K\r" 2>&1
  sleep 0.3
  echo -ne "Cargando clonadora..\033[0K\r" 2>&1
  sleep 0.3
  echo -ne "Cargando clonadora...\033[0K\r" 2>&1
  sleep 0.3
}

function delete_errores() {
	grep -v "Puede que tenga que actualizar /etc/fstab." $error > tmp && rm $error && mv tmp error.txt
	grep -v "La etiqueta de disco actual en" $error > tmp && rm $error && mv tmp error.txt
	sed -i '/^$/d' $error
}

function check_clone() {
	lista=$(lsblk | wc -l)
	no_usb=$(($lista-3)) 
	clone=false
	until [[ $clone = true ]];do
		tput civis
		lista=$(lsblk | wc -l)
		cargando
		while [[ $lista == $no_usb ]];do #Cuando quitas USB
			lista_clone=$(lsblk | wc -l)
			cargando
			if [[ $lista_clone -gt $no_usb ]];then
				break
			fi
		clone=true
		done
	done

	tput cnorm
}

function listar_particiones() {
	echo "Lista de discos y particiones:"
	comando_filas=$(lsblk -e 7 | wc -l)
	comando=$(lsblk -e 7 -o name,label | awk '{print $1"\t""\t"$2}')
	j=2
	
	#lsblk -e 7 -o name,label,partlabel | awk '{print $1 "\t" $2 "\t" $3}' | head -n 1 | sed 's/NAME/Dispositivo/' | sed 's/LABEL/Label/'| sed 's/PARTLABEL/Fecha/'

  printf "%-15s%-15s%-15s\n" Dispositivo Label Fecha    

	for ((i=1;i<=$comando_filas-1;i++))
	do
        	echo $i-$(lsblk -e 7 -o NAME,LABEL,PARTLABEL | head -n $j | tail -n +$j | sed 's/PARTLABEL/Fecha/')
        	((j=j+1))
	done | column -t
}

function seleccionar_particion() {
	case $so in 
		1|'')
			read -p "Elija la partición de sistema que desee clonar. Se clonará automáticamente el boot asociado: " numero  
		;;
		2)
			read -p "Elija la partición de sistema que desee clonar. Se clonará automáticamente la recuperación y el boot asociados: " numero 
		;;
		3)
			read -p "Elija la partición de sistema que desee clonar. Se clonará automáticamente el swap y el boot asociados: " numero 
	esac
	comando_filas=$(lsblk -e 7 | wc -l)
	for ((i=1;i<=$comando_filas-1;i++))
		do
			if [[ $numero == $i ]]; then
				b=$i
				r=$((numero-1))
				s=$((i+1))
				sw=$((i+2))
				part_swap=$(lsblk -e 7 -o name | awk '{ print $1 }' | head -n $sw | tail -n +$sw | sed -r 's/^.{2}//')
				part_recu=$(lsblk -e 7 -o name | awk '{ print $1 }' | head -n $r | tail -n +$r | sed -r 's/^.{2}//')
				part_boot=$(lsblk -e 7 -o name | awk '{ print $1 }' | head -n $b | tail -n +$b | sed -r 's/^.{2}//')
				part_sys=$(lsblk -e 7 -o name | awk '{ print $1 }' | head -n $s | tail -n +$s | sed -r 's/^.{2}//')
				size_swap=$(lsblk -b -e 7 -o name,size | awk '{ print $2 }'| head -n $sw | tail -n +$sw)
				size_swap=$((size_swap/512))
				size_recu=$(lsblk -b -e 7 -o name,size | awk '{ print $2 }'| head -n $r | tail -n +$r)
				size_recu=$((size_recu/512))
				size_boot=$(lsblk -b -e 7 -o name,size | awk '{ print $2 }'| head -n $b | tail -n +$b)
				size_boot=$((size_boot/512))
				size_sys=$(lsblk -b -e 7 -o name,size | awk '{ print $2 }'| head -n $s | tail -n +$s)
				size_sys=$((size_sys/512))
				if [[ $nvme = true ]]; then
					size_disk_bytes=$(lsblk -b -e 7 -o name,size | awk '{ print $1 $2 }' | grep "nvme0n1" | sed -e 's/nvme0n1//g')
				elif [[ $nvme = false ]]; then	
					size_disk_bytes=$(lsblk -b -e 7 -o name,size | awk '{ print $1 $2 }' | grep "sdc" | sed -e 's/sdc//g')
				fi
				size_disk_sec=$((size_disk_bytes/512))
		#porcentaje_swap=`echo 901120/${size_disk_mib} | bc -l`
			else
				continue
			fi
	done
}

function crear_recu() {
		if [ $nvme = true ]; then # En NVMe
			end_recu=$((size_recu+2047))
			(
			echo select /dev/nvme0n1
			echo mktable gpt
			echo mkpart recu 2048s "$end_recu"s
			echo quit
			) | sudo parted /dev/nvme0n1
			sudo mkfs.ntfs -v "/dev/nvme0n1p1" 
		else # En sdc
			end_recu=$((size_recu+2047))
			(
			echo select /dev/sdc
			echo mktable gpt
			echo mkpart recu 2048s "$end_recu"s
			echo quit
			) | sudo parted /dev/sdc
			sudo mkfs.ntfs -v "/dev/sdc1" 
		fi 
}

function crear_boot_linux() {
	if [ $nvme = true ]; then # En NVMe
			end_boot=$((size_boot+2047))
			(
			echo select /dev/nvme0n1
			echo mktable gpt
			#echo yes
			echo mkpart boot 2048s "$end_boot"s
			echo quit
			) | sudo parted /dev/nvme0n1
			sudo mkfs -t vfat -F 32 /dev/nvme0n1p1 
	else # En sdc
		end_boot=$((size_boot+2047))
		(
		echo select /dev/sdc
		echo mktable gpt
		echo mkpart boot 2048s "$end_boot"s
		echo quit
		) | sudo parted /dev/sdc
		sudo mkfs -t vfat -F 32 /dev/sdc1 
	fi	
}

function crear_boot_linux_sec() {
	if [ $nvme = true ]; then
		end_boot=$((size_boot+0))
		start_boot=$((end_sys+1))
		(
		echo select /dev/nvme0n1
		#echo yes
		echo mkpart boot "$start_boot"s "$end_boot"s
		echo quit
		) | sudo parted /dev/nvme0n1
		sudo mkfs -t vfat -F 32 /dev/nvme0n1p4 
	else # En sdc
		end_boot=$((size_boot+0))
		start_boot=$((end_sys+1))
		(
		echo select /dev/sdc
		echo mkpart boot "$start_boot"s "$end_boot"s
		echo quit
		) | sudo parted /dev/sdc
		sudo mkfs -t vfat -F 32 /dev/sdc4 
	fi	
}

function crear_boot_win() {
	if [ $nvme = true ]; then # En NVMe
		start_boot=$((end_recu+1))
		end_boot=$((size_boot+end_recu))
		(
		echo select /dev/nvme0n1
		echo mkpart boot "$start_boot"s "$end_boot"s
		echo quit
		) | sudo parted /dev/nvme0n1
		sudo mkfs -t vfat -F 32 /dev/nvme0n1p2 
	else # En sdc
		start_boot=$((end_recu+1))
		end_boot=$((size_boot+end_recu))
		(
		echo select /dev/sdc
		echo mkpart boot "$start_boot"s "$end_boot"s
		echo quit
		) | sudo parted /dev/sdc
		sudo mkfs -t vfat -F 32 /dev/sdc2 
	fi
}

function crear_boot_debian() {
	if [ $nvme = true ]; then # En NVMe
		end_boot=$((size_boot+2047))
		(
		echo select /dev/nvme0n1
		echo mkpart boot 2048s "$end_boot"s
		echo quit
		) | sudo parted /dev/nvme0n1
		sudo mkfs -t vfat -F 32 /dev/nvme0n1p2 
	else # En sdc
		end_boot=$((size_boot+2047))
		(
		echo select /dev/sdc
		echo mkpart boot 2048s "$end_boot"s
		echo quit
		) | sudo parted /dev/sdc
		sudo mkfs -t vfat -F 32 /dev/sdc2 
	fi
}

function crear_sys() {
	if [ $nvme = true ]; then # En NVMe
		if [[ $dualboot == "n" ]];then # No es dualboot
			start_sys=$((end_boot+1))
			(
			echo select /dev/nvme0n1
			echo mkpart sys "$start_sys"s 100%
			#echo yes
			echo quit
			) | sudo parted /dev/nvme0n1
		else # Es dualboot
			start_sys=$((end_boot+1))
			sum_ant=$((size_recu+size_boot))
			end_sys=$((size_disk_sec-2048-sum_ant-344))
			end_sys=$((end_sys/2))
			(
			echo select /dev/nvme0n1
			echo mkpart sys "$start_sys"s "$end_sys"s
			#echo yes
			echo quit
			) | sudo parted /dev/nvme0n1	
		fi		
		case $so in 
			1|'') #linux
				sudo mkfs.ext4 -F "/dev/nvme0n1p1" 
			;;
			2) #Win
				sudo mkfs.ntfs -vf "/dev/nvme0n1p2" 
			;;
		esac
	else # En sdc
		if [[ $dualboot == "n" ]];then # No es dualboot
			start_sys=$((end_boot+1))
			(
			echo select /dev/sdc
			echo mkpart sys "$start_sys"s 100%
			echo quit
			) | sudo parted /dev/sdc
		else # Es dualboot
			start_sys=$((end_boot+1))
			sum_ant=$((size_recu+size_boot))
			echo $size_disk_sec
			end_sys=$((size_disk_sec-2048-sum_ant-344))
			end_sys=$((end_sys/2))
			(
			echo select /dev/sdc
			echo mkpart sys "$start_sys"s "$end_sys"s
			echo quit
			) | sudo parted /dev/sdc
		fi			
		case $so in 
			1|'') #linux
				sudo mkfs.ext4 -F "/dev/sdc2" 
			;;
			2) #Win
				sudo mkfs.ntfs -vf "/dev/sdc3" 
			;;
		esac
	fi
}

function crear_sys_sec () {
	if [ $nvme = true ]; then # En NVMe
		start_sys=$((end_boot+1))
		(
		echo select /dev/nvme0n1
		echo mkpart sys "$start_sys"s 100%
		#echo yes
		echo quit
		) | sudo parted /dev/nvme0n1		
		case $so in 
			1|'') #linux
				sudo mkfs.ext4 -F "/dev/nvme0n1p5" 
			;;
			2) #Debian
				sudo mkfs.ntfs -vf "/dev/nvme0n1p6" 
			;;
		esac
	else # En sdc
		start_sys=$((end_boot+1))
		(
		echo select /dev/sdc
		echo mkpart sys "$start_sys"s 100%
		echo quit
		) | sudo parted /dev/sdc
		case $so in 
			1|'') #linux
				sudo mkfs.ext4 -F "/dev/sdc5" 
			;;
			2) #Win
				sudo mkfs.ntfs -vf "/dev/sdc6" 
			;;
		esac
	fi
}

function crear_sys_debian() {
	if [ $nvme = true ]; then # En NVMe
		start_sys=$((end_boot+1))
		end_sys=$((start_swap-1))
		(
		echo select /dev/nvme0n1
		echo mkpart sys "$start_sys"s "$end_sys"s
		echo quit
		) | sudo parted /dev/nvme0n1
		sudo mkfs.ext4 -F "/dev/nvme0n1p3" 
	else #En sdc
		start_sys=$((end_boot+1))
		end_sys=$((start_swap-1))
		(
		echo select /dev/sdc
		echo mkpart sys "$start_sys"s "$end_sys"s
		echo quit
		) | sudo parted /dev/sdc
		sudo mkfs.ext4 -F "/dev/sdc3" 
	fi
}

function crear_swap() {
	if [ $nvme = true ]; then # En NVMe
		start_swap=$((size_disk_sec-size_swap))
		start_swap=$((start_swap-688))
		(
		echo select /dev/nvme0n1
		echo mktable gpt
		echo mkpart swap "$start_swap"s 100%
		echo quit
		) | sudo parted /dev/nvme0n1
		#sudo mkswap -L "swap" "/dev/nvme0n1p1"
	else # En sdc
		start_swap=$((size_disk_sec-size_swap))
		start_swap=$((start_swap-688))
		(
		echo select /dev/sdc
		echo mktable gpt
		echo mkpart swap "$start_swap"s 100%
		echo quit
		) | sudo parted /dev/sdc
		#sudo mkswap -L "swap" "/dev/sdc1"
	fi
}

function copiar_linux() {
	echo "--------------COPIANDO BOOT-------------------"
	#Comprobar errores de part boot
	sudo fsck.fat -a -w -v "/dev/$part_boot" 

	#Crear partición y copiar boot
	if [ $nvme = true ]; then
		if [[ $dualboot != 'n' ]];then #Es dualboot
			crear_boot_linux_sec
			sudo dd if=/dev/$part_boot of=/dev/nvme0n1p4 status=progress 
			
			echo "-------------COPIANDO SYS---------------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 

			#Crear partición y copiar sys
			crear_sys_sec
			sudo e2image -ra -p "/dev/$part_sys" "/dev/nvme0n1p5"
			sudo e2fsck -f -y -v -C 0 "/dev/nvme0n1p5"
			sudo resize2fs -p "/dev/nvme0n1p5"
			sudo e2label "/dev/nvme0n1p5" ''
			echo "----------SETEANDO FLAGS Y NOMBRES---------------"
			(
				echo select /dev/nvme0n1
				echo set 4 boot ON
				echo set 4 esp ON
				echo name 4 
				echo ' '
				echo name 5 
				echo ' '
			) | sudo parted /dev/nvme0n1
		fi				

			#-----No es dualboot-------
			crear_boot_linux

			crear_sys
 			sudo e2image -ra -p "/dev/$part_sys" "/dev/nvme0n1p2" 

			#Comprobar errores de nvme0n1p2
			sudo e2fsck -f -y -v -C 0 "/dev/nvme0n1p2" 

			#Llenamos la partición
			sudo resize2fs -p "/dev/nvme0n1p2" 

			#Cambiar label
			sudo e2label "/dev/nvme0n1p2" ''

			echo "----------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			echo select /dev/nvme0n1
			echo set 1 boot ON
			echo set 1 esp ON
			echo name 1 
			echo ' '
			echo name 2 
			echo ' '
			) | sudo parted /dev/nvme0n1
	else # En sdc
		if [[ $dualboot != 'n' ]];then #Es dualboot
			crear_boot_linux_sec
			sudo dd if=/dev/$part_boot of=/dev/sdc4 status=progress 

			echo "------------COPIANDO SISTEMA--------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 

			#Crear partición y copiar sys
			crear_sys_sec
			
			sudo e2image -ra -p "/dev/$part_sys" "/dev/sdc5" 

			#Comprobar errores de sdc2
			sudo e2fsck -f -y -v -C 0 "/dev/sdc5" 

			#Llenamos la partición
			sudo resize2fs -p "/dev/sdc5" 

			#Cambiar label
			sudo e2label "/dev/sdc5" '' 

			echo "----------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			echo select /dev/sdc
			echo set 4 boot ON
			echo set 4 esp ON
			echo name 4 
			echo ' '
			echo name 5 
			echo ' '
			) | sudo parted /dev/sdc
		else # No es dualboot
			crear_boot_linux
			sudo dd if=/dev/$part_boot of=/dev/sdc1 status=progress 

			echo "------------COPIANDO SISTEMA--------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 

			#Crear partición y copiar sys
			crear_sys
			
			sudo e2image -ra -p "/dev/$part_sys" "/dev/sdc2" 

			#Comprobar errores de sdc2
			sudo e2fsck -f -y -v -C 0 "/dev/sdc2" 

			#Llenamos la partición
			sudo resize2fs -p "/dev/sdc2" 

			#Cambiar label
			sudo e2label "/dev/sdc2" '' 

			echo "----------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			echo select /dev/sdc
			echo set 1 boot ON
			echo set 1 esp ON
			echo name 1 
			echo ' '
			echo name 2 
			echo ' '
			) | sudo parted /dev/sdc
		fi
	fi
}

function copiar_win() {
	if [ $nvme = true ]; then
			echo "-------------COPIANDO RECUPERACIÓN-------------------"
			#Comprobar errores del origen
			sudo ntfsresize -i -f -v "/dev/$part_recu" 

			#Crear partición y copiar recu
			crear_recu
			sudo ntfsclone -f --overwrite "/dev/nvme0n1p1" "/dev/$part_recu" 

			#Comprobación errores del destino
			#ntfsresize -i -f -u "/dev/nvme0n1p1"
			
			echo "-------------COPIANDO BOOT---------------------------"
			#Comprobar errores de part boot
			sudo fsck.fat -a -w -v "/dev/$part_boot" 

			#Crear partición y copiar boot
			crear_boot_win
			sudo dd if=/dev/$part_boot of=/dev/nvme0n1p2 status=progress 

			#echo "---------Cambiar label-------------"
			#sudo fatlabel "/dev/nvme0n1p2" ' ' 

			#Comprobar errores del destino
			#sudo fsck.fat -a -w -v "/dev/nvme0n1p2"

			echo "-------------COPIANDO SISTEMA------------------------"
			#Comprobar errores de par sys
			sudo ntfsresize -i -f -v "/dev/nvme0n1p3" 
			
			#Crear partición y copiar sys
			crear_sys

			sudo ntfsclone -f --overwrite "/dev/nvme0n1p3" "/dev/$part_sys" 

			#Comprobar errores de destino sys
			sudo ntfsresize -i -f -v "/dev/nvme0n1p3" 

			#Ejecutamos simulación para aumentar tamaño sys files
			sudo ntfsresize --force --force --no-action "/dev/nvme0n1p3" 

			#Comprobamos simulación
			if [ $? -eq 0 ]; then
				sudo ntfsresize --force --force "/dev/nvme0n1p3" 
			else
				echo "------------------Falló el resize, exit status: $?----------------------"
			fi

			#Cambiar label
			sudo ntfslabel -fv "/dev/nvme0n1p3" ' ' 

			#Comprobar errores?
			#ntfsresize -i -f -v "/dev/nvme0n1p3"

			echo "------------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			#echo select /dev/nvme0n1
			echo set 1 diag ON
			echo set 1 hidden ON
			echo set 2 boot ON
			echo set 2 esp ON
			echo set 3 msftdata ON
			echo name 1 
			echo ' '
			echo name 2 
			echo ' '
			echo name 3
			echo ' '
			) | sudo parted /dev/nvme0n1
		else
			echo "-------------RECUPERACIÓN-------------------"
			echo \
			
			#echo "--------------Comprobar errores del origen----------"
			sudo ntfsresize -i -f -v "/dev/$part_recu" 

			#echo "-----------Crear partición y copiar recu------------"
			crear_recu
			sudo ntfsclone -f --overwrite "/dev/sdc1" "/dev/$part_recu" 

			#echo "------------------Comprobación errores del destino---------"
			#ntfsresize -i -f -u "/dev/sdc1"
			
			echo "-------------BOOT---------------------------"
			echo \
			
			#echo "-----------Comprobar errores de part boot------------"
			sudo fsck.fat -a -w -v "/dev/$part_boot" 

			#echo "--------------Crear partición y copiar boot-----------"
			crear_boot_win
			sudo dd if=/dev/$part_boot of=/dev/sdc2 status=progress 

			#echo "---------Cambiar label-------------"
			sudo fatlabel "/dev/sdc2" ' ' 

			#Comprobar errores del destino
			#sudo fsck.fat -a -w -v "/dev/sdc2" 

			echo "-------------SISTEMA------------------------"
			echo \
			
			#echo "------------Comprobar errores de par sys-----------"
			sudo ntfsresize -i -f -v "/dev/$part_sys" 
			
			#echo "-------------Crear partición y copiar sys---------"
			crear_sys
			sudo ntfsclone -f --overwrite "/dev/sdc3" "/dev/$part_sys" 

			#echo "-------Comprobar errores de destino sys------"
			sudo ntfsresize -i -f -v "/dev/sdc3" 

			#echo "------Simulación para aumentar tamaño sys files"
			sudo ntfsresize --force --force --no-action "/dev/sdc3" 

			#Comprobamos simulación
			if [ $? -eq 0 ]; then
				sudo ntfsresize --force --force "/dev/sdc3" 
			else
				echo "--------------Falló el resize, exit status: $? -----------------------"
			fi

			#echo "---------Cambiar label-------------"
			sudo ntfslabel -fv "/dev/sdc3" ' ' 

			#Comprobar errores?
			#ntfsresize -i -f -v "/dev/nvme0n1p3"

			echo "------------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			echo select /dev/sdc
			echo set 1 diag ON
			echo set 1 hidden ON
			echo set 2 boot ON
			echo set 2 esp ON
			echo set 3 msftdata ON			
			echo name 1 
			echo ' '
			echo name 2 
			echo ' '
			echo name 3
			echo ' '
			) | sudo parted /dev/sdc
	fi
}

function copiar_debian() {
	if [ $nvme = true ]; then
			echo "--------------SWAP-------------------"
			#Crear partición
			crear_swap

			#Recrear sistema de archivos
			uuid=$(blkid | grep $part_swap | awk '{ print $3 }' | sed -e 's/UUID="//g' | sed -e 's/"//g')
			sudo mkswap -L 'linux_swap' -U $uuid '/dev/nvme0n1p1'
			
			echo "--------------BOOT-------------------"
			#Comprobar errores de part boot
			sudo fsck.fat -a -w -v "/dev/$part_boot" 

			#Crear partición y copiar boot
			crear_boot_debian
			sudo dd if=/dev/$part_boot of=/dev/nvme0n1p2 status=progress 

			#Cambiar label
			sudo fatlabel "/dev/nvme0n1p2" ' '

			echo "-------------SYS---------------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 

			#Crear partición y copiar sys
			crear_sys_debian
			sudo e2image -ra -p "/dev/$part_sys" "/dev/nvme0n1p3"

			#Comprobar errores de sdc3
			sudo e2fsck -f -y -v -C 0 "/dev/nvme0n1p3" 
 
			#Llenamos la partición
			sudo resize2fs -p "/dev/nvme0n1p3"

			#Cambiar label
			sudo e2label "/dev/nvme0n1p3" ''

			echo "------------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			#echo select /dev/nvme0n1
			echo set 2 boot ON
			echo set 2 esp ON
			echo set 1 swap ON
			echo name 1 
			echo ' '
			echo name 2
			echo ' ' 
			echo name 3
			echo ' '
			) | sudo parted /dev/nvme0n1
    else
			echo "--------------SWAP-------------------"
			#Crear partición
			crear_swap

			#Recrear sistema de archivos
			uuid=$(blkid | grep $part_swap | awk '{ print $3 }' | sed -e 's/UUID="//g' | sed -e 's/"//g')
			sudo mkswap -L 'linux_swap' -U $uuid '/dev/sdc1'

			echo "--------------BOOT-------------------"
			#Comprobar errores de part boot
			sudo fsck.fat -a -w -v "/dev/$part_boot" 

			#Crear partición y copiar boot
			crear_boot_debian
			sudo dd if=/dev/$part_boot of=/dev/sdc2 bs=64K status=progress 

			#Cambiar label
			#sudo fatlabel "/dev/sdc2" ''

			echo "-------------SYS---------------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 

			#Crear partición y copiar sys
			crear_sys_debian
			sudo e2image -ra -p "/dev/$part_sys" "/dev/sdc3"

			#Comprobar errores de sdc3

			#Llenamos la partición
			sudo resize2fs -p "/dev/sdc3"

			#Cambiar label
			sudo e2label "/dev/sdc3" ''

			echo "------------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			echo select /dev/sdc
			echo set 1 swap ON
			echo set 2 boot ON
			echo set 2 esp ON
			echo name 1 
			echo ' '
			echo name 2
			echo ' ' 
			echo name 3
			echo ' '
			) | sudo parted /dev/sdc
	fi
}

check_clone

read -r -s -t 3 -N 1 -p "Indique si es un dualboot(y/n): " dualboot ;echo 
dualboot=${dualboot:-n}

case $dualboot in 
	'n')
		read -p "Indica si el sistema es 1. Linux, 2. Windows o 3. Debian: " so 
	;;
	$'\n')
		read -p "Indica si el primer sistema del dualboot es 1. Linux, 2. Windows o 3. Debian: " so 
esac

until [[ $so == 1 ]] || [[ $so == 2 ]] || [[ $so == 3 ]]
do
	read -p "[-]¡ERROR! Debe especificar 1. Linux, 2. Windows o 3. Debian: " so 
done

comprobar_nvme=$(lsblk -e 7 -o name,label | awk '{print $1"\t""\t"$2}' | grep "nvme0n1")

listar_particiones

seleccionar_particion

if [[ -n $comprobar_nvme ]]; then
	echo "----Se copiará en un disco NVMe----" 
	nvme=true
else
	echo "----Se copiará en un disco SSD----" 
	nvme=false
fi

echo "Compruebe que las particiones son correctas: " 
case $so in
	1|'')
		echo "Boot: " $part_boot
		echo "Sistema: " $part_sys

		read comprobar 
				
		copiar_linux
	;;
	2)
		echo "Recuperación: " $part_recu
		echo "Boot: " $part_boot
		echo "Sistema: " $part_sys

		read comprobar 
		
		copiar_win

		# Crear el otro sistema
		if [[ $dualboot == "n" ]];then 
			read -p "Indica si el segundo sistema del dualboot es 1. Linux, 2. Windows o 3. Debian: " so 

			until [[ $so == 1 ]] || [[ $so == 2 ]] || [[ $so == 3 ]]
			do
				read -p "[-]¡ERROR! Debe especificar 1. Linux, 2. Windows o 3. Debian: " so 
			done

			comprobar_nvme=$(lsblk -e 7 -o name,label | awk '{print $1"\t""\t"$2}' | grep "nvme0n1")

			listar_particiones

			seleccionar_particion

			if [[ -n $comprobar_nvme ]]; then
				echo "----Se copiará en un disco NVMe----" 
				nvme=true
			else
				echo "----Se copiará en un disco SSD----" 
				nvme=false
			fi
			
			echo "Compruebe que las particiones son correctas: " 
			case $so in
				1|'')
					echo "Boot: " $part_boot
					echo "Sistema: " $part_sys

					read comprobar 
							
					copiar_linux
				;;
			esac

		#Comprobar si hay disco secundario y crear la partición
		disco_secundario=$(lsblk -e 7 | tail -n 1 | awk '{print $1}')
		
		if [[ $disco_secundario == "nvme1n1" ]] || [[ $disco_secundario == "sdc" ]]; then
			if [[ $disco_secundario == "nvme1n1" ]]; then
				(
				echo select /dev/nvme1n1
				echo mktable gpt
				echo mkpart primary 0% 100%
				echo quit 
				) | sudo parted /dev/nvme1n1
				sudo mkfs.ntfs -vf "/dev/nvme1n1p1" 
				read -p "Indique si quiere que la etiqueta sea 1. Datos o 2. Data: " etiqueta 
				etiqueta=${etiqueta:-1}
				until [[ $etiqueta == "1" ]] || [[ $etiqueta == "2" ]]
				do
					read -p "[-]¡ERROR! La etiqueta debe ser 1. Datos o 2. Data: " etiqueta 
					etiqueta=${etiqueta:-1}
				done
				case $etiqueta in
					1)
						ntfslabel -fv /dev/nvme1n1p1 "Datos"
					;;
					2)
						ntfslabel -fv /dev/nvme1n1p1 "Data"
				esac
				(
				echo name 1
				echo ' '
				) | sudo parted /dev/nvme1n1
			else
				(
				echo select /dev/sdc
				echo mktable gpt
				echo mkpart primary 0% 100%
				echo quit 
				) | sudo parted /dev/sdc
				sudo mkfs.ntfs -vf "/dev/sdc1" 
				read -p "Indique si quiere que la etiqueta sea 1. Datos o 2. Data: " etiqueta 
				etiqueta=${etiqueta:-1}
				until [[ $etiqueta == "1" ]] || [[ $etiqueta == "2" ]]
				do
					read -p "[-]¡ERROR! La etiqueta debe ser 1. Datos o 2. Data: " etiqueta 
					etiqueta=${etiqueta:-1}
				done
				case $etiqueta in
					1)
						ntfslabel -fv /dev/sdc1 "Datos"
					;;
					2)
						ntfslabel -fv /dev/sdc1 "Data"
				esac
				(
				echo name 1
				echo ' '
				) | sudo parted /dev/sdc
			fi
		fi
	;;
	3)
		echo "Boot: " $part_boot
		echo "Sistema: " $part_sys
		echo "Swap: " $part_swap

		read comprobar 
		
		copiar_debian
esac

		echo \

		echo "------------Ha terminado la clonación------------"

		echo \

		delete_errores

		if [[ -s $error ]]; then
				tput setaf 1;cat $error;tput init
			echo "Ha habido algún error al clonar"
		else
			sudo pkill gparted
			sleep 0.5
			setsid gparted &
			sec=10
			while [ $sec -ge 0 ]; do 
				echo -ne "[!]----Se reiniciará en $(printf $sec) segundo(s)...\033[0K\r"
				let "sec=sec-1"
				#sleep 1
				read -t 1 -n 1 -s keypress && break
			done
			reboot
		fi


		echo \

		echo "------------Ha terminado la clonación------------"

		echo \

		delete_errores

		if [[ -s $error ]]; then
				tput setaf 1;cat $error;tput init
			echo "Ha habido algún error al clonar"
		else
			sudo pkill gparted
			sleep 0.5
			setsid gparted &
			sec=10
			while [ $sec -ge 0 ]; do 
				echo -ne "[!]----Se reiniciará en $(printf $sec) segundo(s)...\033[0K\r"
				let "sec=sec-1"
				#sleep 1
				read -t 1 -n 1 -s keypress && break
			done
			reboot
		fi
