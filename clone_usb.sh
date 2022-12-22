#!/bin/bash

#Comprobar si el disco nvme0n1 está usado
disco_lleno_nvme=$(lsblk -e 7 | awk '{print $1}' | grep "nvme0n1p1")
disco_lleno_sda=$(lsblk -e 7 | awk '{print $1}' | grep "sda1")
error=~/Desktop/error.txt

# Eliminando la tabla de particiones si hubieran particiones ya creadas 
if [[ -n $disco_lleno_nvme ]] || [[ -n $disco_lleno_sda ]] ; then
	echo -ne "Eliminando la tabla de particiones..."
	sleep 0.5
	if [[ -n $disco_lleno_nvme ]]; then
		sudo wipefs -a /dev/nvme0n1 &>/dev/null
	elif [[ -n $disco_lleno_sda ]]; then
		sudo wipefs -a /dev/sda &>/dev/null
	fi
	if [[ -s ${error} ]]; then
		echo -ne "Error al crear la tabla GPT\u2717\033[0K\r"
	else
		echo -e "Tabla GPT creada correctamente\033[0K\r" 
	fi
fi

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
	grep -v "Information: You may need to update /etc/fstab." $error > tmp && rm $error && mv tmp error.txt
	sed -i '/^$/d' $error
}

function check_clone() {
	lista=$(lsblk -e 7 | wc -l)
	clone=false
	until [[ $clone = true ]];do
		tput civis
		lista_clone=$(lsblk -e 7 | wc -l)
		cargando
		read -t 0.3 -r -s -n 1 keypress && break
		if [[ $lista_clone -gt $lista ]];then
			clone=true
		fi
	done

	tput cnorm
}

function listar_particiones() {
	echo "Lista de discos y particiones:" 2>&1
	comando_filas=$(lsblk -e 7 | wc -l)
	j=2
	
	#lsblk -e 7 -o name,label,partlabel | awk '{print $1 "\t" $2 "\t" $3}' | head -n 1 | sed 's/NAME/Dispositivo/' | sed 's/LABEL/Label/'| sed 's/PARTLABEL/Fecha/'

    	printf "%-15s%-15s%-15s\n" Disp. Label Fecha    

	for ((i=1;i<=$comando_filas-1;i++))
	do
        	echo $i-$(lsblk -e 7 -o NAME,LABEL,PARTLABEL | head -n $j | tail -n +$j | sed 's/PARTLABEL/Fecha/')
        	((j=j+1))
	done | column -t
}

function seleccionar_particion() {
	case $so in 
		1|'')
			read -p "Elija la partición de sistema que desee clonar. Se clonará automáticamente el boot asociado: " numero 2>&1
		;;
		2)
			read -p "Elija la partición de sistema que desee clonar. Se clonará automáticamente la recuperación y el boot asociados: " numero 2>&1
		;;
		3)
			read -p "Elija la partición de sistema que desee clonar. Se clonará automáticamente el swap y el boot asociados: " numero 2>&1
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
				if [[ $nvme = true ]] && [[ $so == 3 ]]; then
					size_disk_bytes=$(lsblk -b -e 7 -o name,size | awk '{ print $1 $2 }' | grep "nvme0n1" | sed -e 's/nvme0n1//g')
				elif [[ $nvme = false ]] && [[ $so == 3 ]]; then	
					size_disk_bytes=$(lsblk -b -e 7 -o name,size | awk '{ print $1 $2 }' | grep "sda" | sed -e 's/sda//g')
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
			sudo mkfs.ntfs -v "/dev/nvme0n1p1" 2>&1
		else # En sda
			end_recu=$((size_recu+2047))
			(
			echo select /dev/sda
			echo mktable gpt
			echo mkpart recu 2048s "$end_recu"s
			echo quit
			) | sudo parted /dev/sda
			sudo mkfs.ntfs -v "/dev/sda1" 2>&1
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
		sudo mkfs -t vfat -F 32 /dev/nvme0n1p1 2>&1
	else # En sda
		end_boot=$((size_boot+2047))
		(
		echo select /dev/sda
		echo mktable gpt
		echo mkpart boot 2048s "$end_boot"s
		echo quit
		) | sudo parted /dev/sda
		sudo mkfs -t vfat -F 32 /dev/sda1 2>&1
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
		sudo mkfs -t vfat -F 32 /dev/nvme0n1p2 2>&1
	else # En sda
		start_boot=$((end_recu+1))
		end_boot=$((size_boot+end_recu))
		(
		echo select /dev/sda
		echo mkpart boot "$start_boot"s "$end_boot"s
		echo quit
		) | sudo parted /dev/sda
		sudo mkfs -t vfat -F 32 /dev/sda2 2>&1
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
		sudo mkfs -t vfat -F 32 /dev/nvme0n1p2 2>&1
	else # En sda
		end_boot=$((size_boot+2047))
		(
		echo select /dev/sda
		echo mkpart boot 2048s "$end_boot"s
		echo quit
		) | sudo parted /dev/sda
		sudo mkfs -t vfat -F 32 /dev/sda2 2>&1
	fi
}

function crear_sys() {
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
				sudo mkfs.ext4 -F "/dev/nvme0n1p2" 2>&1
			;;
			2) #Win
				sudo mkfs.ntfs -vf "/dev/nvme0n1p3" 2>&1
			;;
		esac
	else # En sda
		start_sys=$((end_boot+1))
		(
		echo select /dev/sda
		echo mkpart sys "$start_sys"s 100%
		echo quit
		) | sudo parted /dev/sda
		case $so in 
			1|'') #linux
				sudo mkfs.ext4 -F "/dev/sda2" 2>&1
			;;
			2) #Win
				sudo mkfs.ntfs -vf "/dev/sda3" 2>&1
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
		sudo mkfs.ext4 -F "/dev/nvme0n1p3" 2>&1
	else #En sda
		start_sys=$((end_boot+1))
		end_sys=$((start_swap-1))
		(
		echo select /dev/sda
		echo mkpart sys "$start_sys"s "$end_sys"s
		echo quit
		) | sudo parted /dev/sda
		sudo mkfs.ext4 -F "/dev/sda3" 2>&1
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
	else # En sda
		start_swap=$((size_disk_sec-size_swap))
		start_swap=$((start_swap-688))
		(
		echo select /dev/sda
		echo mktable gpt
		echo mkpart swap "$start_swap"s 100%
		echo quit
		) | sudo parted /dev/sda
	fi
}

function copiar_en_linux() {
	echo "--------------COPIANDO BOOT-------------------"
	#Comprobar errores de part boot
	sudo fsck.fat -a -w -v "/dev/$part_boot" 2>&1

	#Crear partición y copiar boot
	crear_boot_linux
	if [ $nvme = true ]; then
			sudo dd if=/dev/$part_boot of=/dev/nvme0n1p1 status=progress 2>&1
			
			echo "-------------COPIANDO SYS---------------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 2>&1

			#Crear partición y copiar sys
			crear_sys

			sudo e2image -ra -p "/dev/$part_sys" "/dev/nvme0n1p2" 2>&1

			#Comprobar errores de nvme0n1p2
			sudo e2fsck -f -y -v -C 0 "/dev/nvme0n1p2" 2>&1

			#Llenamos la partición
			sudo resize2fs -p "/dev/nvme0n1p2" 2>&1

			#Cambiar label
			sudo e2label "/dev/nvme0n1p2" '' 2>&1
			
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
	else
			sudo dd if=/dev/$part_boot of=/dev/sda1 status=progress 2>&1

			echo "------------COPIANDO SISTEMA--------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 2>&1

			#Crear partición y copiar sys
			crear_sys
			
			sudo e2image -ra -p "/dev/$part_sys" "/dev/sda2" 2>&1

			#Comprobar errores de sda2
			sudo e2fsck -f -y -v -C 0 "/dev/sda2" 2>&1

			#Llenamos la partición
			sudo resize2fs -p "/dev/sda2" 2>&1

			#Cambiar label
			sudo e2label "/dev/sda2" '' 2>&1

			echo "----------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			echo select /dev/sda
			echo set 1 boot ON
			echo set 1 esp ON
			echo name 1 
			echo ' '
			echo name 2 
			echo ' '
			) | sudo parted /dev/sda
	fi
}

function copiar_en_win() {
	if [ $nvme = true ]; then
			echo "-------------COPIANDO RECUPERACIÓN-------------------"
			#Comprobar errores del origen
			sudo ntfsresize -i -f -v "/dev/$part_recu" 2>&1

			#Crear partición y copiar recu
			crear_recu
			sudo ntfsclone -f --overwrite "/dev/nvme0n1p1" "/dev/$part_recu" 2>&1

			#Comprobación errores del destino
			#ntfsresize -i -f -u "/dev/nvme0n1p1"
			
			echo "-------------COPIANDO BOOT---------------------------"
			#Comprobar errores de part boot
			sudo fsck.fat -a -w -v "/dev/$part_boot" 2>&1

			#Crear partición y copiar boot
			crear_boot_win
			sudo dd if=/dev/$part_boot of=/dev/nvme0n1p2 status=progress 2>&1

			#echo "---------Cambiar label-------------"
			#sudo fatlabel "/dev/nvme0n1p2" ' ' 

			#Comprobar errores del destino
			#sudo fsck.fat -a -w -v "/dev/nvme0n1p2"

			echo "-------------COPIANDO SISTEMA------------------------"
			#Comprobar errores de par sys
			sudo ntfsresize -i -f -v "/dev/nvme0n1p3" 2>&1
			
			#Crear partición y copiar sys
			crear_sys

			sudo ntfsclone -f --overwrite "/dev/nvme0n1p3" "/dev/$part_sys" 2>&1

			#Comprobar errores de destino sys
			sudo ntfsresize -i -f -v "/dev/nvme0n1p3" 2>&1

			#Ejecutamos simulación para aumentar tamaño sys files
			sudo ntfsresize --force --force --no-action "/dev/nvme0n1p3" 2>&1
			resize=$(sudo ntfsresize --force --force --no-action "/dev/nvme0n1p3" 2>&1)

			#Comprobamos simulación
			if $resize; then
				sudo ntfsresize --force --force "/dev/nvme0n1p3" 2>&1
			else
				echo "------------------Falló el resize, exit status: $?----------------------"
			fi

			#Cambiar label
			sudo ntfslabel -fv "/dev/nvme0n1p3" ' ' 2>&1

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
			) | sudo parted /dev/nvme0n1 2>&1
		else
			echo "-------------RECUPERACIÓN-------------------"
			echo \
			
			#echo "--------------Comprobar errores del origen----------"
			sudo ntfsresize -i -f -v "/dev/$part_recu" 2>&1

			#echo "-----------Crear partición y copiar recu------------"
			crear_recu
			sudo ntfsclone -f --overwrite "/dev/sda1" "/dev/$part_recu" 2>&1

			#echo "------------------Comprobación errores del destino---------"
			#ntfsresize -i -f -u "/dev/sda1"
			
			echo "-------------BOOT---------------------------"
			echo \
			
			#echo "-----------Comprobar errores de part boot------------"
			sudo fsck.fat -a -w -v "/dev/$part_boot" 2>&1

			#echo "--------------Crear partición y copiar boot-----------"
			crear_boot_win
			sudo dd if=/dev/$part_boot of=/dev/sda2 status=progress 2>&1

			#echo "---------Cambiar label-------------"
			sudo fatlabel "/dev/sda2" ' ' 

			#Comprobar errores del destino
			#sudo fsck.fat -a -w -v "/dev/sda2" 

			echo "-------------SISTEMA------------------------"
			echo \
			
			#echo "------------Comprobar errores de par sys-----------"
			sudo ntfsresize -i -f -v "/dev/$part_sys" 
			
			#echo "-------------Crear partición y copiar sys---------"
			crear_sys
			sudo ntfsclone -f --overwrite "/dev/sda3" "/dev/$part_sys" 

			#echo "-------Comprobar errores de destino sys------"
			sudo ntfsresize -i -f -v "/dev/sda3" 

			#echo "------Simulación para aumentar tamaño sys files"
			sudo ntfsresize --force --force --no-action "/dev/sda3" 
			resize=$(sudo ntfsresize --force --force --no-action "/dev/sda3" )

			#Comprobamos simulación
			if $resize ; then
				sudo ntfsresize --force --force "/dev/sda3" 
			else
				echo "--------------Falló el resize, exit status: $? -----------------------"
			fi

			#echo "---------Cambiar label-------------"
			sudo ntfslabel -fv "/dev/sda3" ' ' 

			#Comprobar errores?
			#ntfsresize -i -f -v "/dev/nvme0n1p3"

			echo "------------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			echo select /dev/sda
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
			) | sudo parted /dev/sda
	fi
}

function copiar_en_debian() {
	if [ $nvme = true ]; then
			echo "--------------SWAP-------------------"
			#Crear partición
			crear_swap

			#Recrear sistema de archivos
			uuid=$(blkid | grep $part_swap | awk '{ print $2 }' | sed -e 's/UUID="//g' | sed -e 's/"//g')
			sudo mkswap -L 'linux_swap' -U "$uuid" "/dev/nvme0n1p1" 2>&1
			
			echo "--------------BOOT-------------------"
			#Comprobar errores de part boot
			sudo fsck.fat -a -w -v "/dev/$part_boot" 2>&1

			#Crear partición y copiar boot
			crear_boot_debian
			sudo dd if=/dev/$part_boot of=/dev/nvme0n1p2 status=progress 2>&1


			echo "-------------SYS---------------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 2>&1

			#Crear partición y copiar sys
			crear_sys_debian
			sudo e2image -ra -p "/dev/$part_sys" "/dev/nvme0n1p3" 2>&1

			#Comprobar errores de sda3
			sudo e2fsck -f -y -v -C 0 "/dev/nvme0n1p3" 2>&1
 
			#Llenamos la partición
			sudo resize2fs -p "/dev/nvme0n1p3" 2>&1

			#Cambiar label
			sudo e2label "/dev/nvme0n1p3" '' 2>&1

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
			) | sudo parted /dev/nvme0n1 2>&1
    else
			echo "--------------SWAP-------------------"
			#Crear partición
			crear_swap

			#Recrear sistema de archivos
			uuid=$(blkid | grep $part_swap | awk '{ print $2 }' | sed -e 's/UUID="//g' | sed -e 's/"//g')
			sudo mkswap -L 'linux_swap' -U $uuid '/dev/sda1'

			echo "--------------BOOT-------------------"
			#Comprobar errores de part boot
			sudo fsck.fat -a -w -v "/dev/$part_boot" 

			#Crear partición y copiar boot
			crear_boot_debian
			sudo dd if=/dev/$part_boot of=/dev/sda2 bs=64K status=progress 

			#Cambiar label
			#sudo fatlabel "/dev/sda2" ''

			echo "-------------SYS---------------------"
			#Comprobar errores de part sys
			sudo e2fsck -f -y -v -C 0 "/dev/$part_sys" 

			#Crear partición y copiar sys
			crear_sys_debian
			sudo e2image -ra -p "/dev/$part_sys" "/dev/sda3"

			#Comprobar errores de sda3

			#Llenamos la partición
			sudo resize2fs -p "/dev/sda3"

			#Cambiar label
			sudo e2label "/dev/sda3" ''

			echo "------------SETEANDO FLAGS Y NOMBRES---------------"
			#Seteamos flags y nombre de la partición
			(
			echo select /dev/sda
			echo set 1 swap ON
			echo set 2 boot ON
			echo set 2 esp ON
			echo name 1 
			echo ' '
			echo name 2
			echo ' ' 
			echo name 3
			echo ' '
			) | sudo parted /dev/sda
	fi
}

check_clone

echo -ne "\r\033[K"; read -p "Indica si el sistema es 1. Linux, 2. Windows o 3. Debian: " so 2>&1

until [[ $so == 1 ]] || [[ $so == 2 ]] || [[ $so == 3 ]]
do
	read -p "[-]¡ERROR! Debe especificar 1. Linux, 2. Windows o 3. Debian: " so 2>&1
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

echo "Compruebe que las particiones son correctas: " 2>&1
case $so in
	1|'')
		echo "Boot: " $part_boot 2>&1
		echo "Sistema: " $part_sys 2>&1

		read comprobar 
				
		copiar_en_linux
	;;
	2)
		echo "Recuperación: " $part_recu 2>&1
		echo "Boot: " $part_boot 2>&1
		echo "Sistema: " $part_sys 2>&1

		read comprobar 
		
		copiar_en_win

		#Comprobar si hay disco secundario y crear la partición
		disco_secundario=$(lsblk -e 7 | tail -n 1 | awk '{print $1}')
		
		if [[ $disco_secundario == "nvme1n1" ]] || [[ $disco_secundario == "sda" ]]; then
			echo "-------Disco secundario encontrado--------"
			if [[ $disco_secundario == "nvme1n1" ]]; then
				(
				echo select /dev/nvme1n1
				echo mktable gpt
				echo mkpart primary 0% 100%
				echo name 1
				echo ' '
				echo set 1 msftdata ON
				echo quit 
				) | sudo parted /dev/nvme1n1
				sudo mkfs.ntfs -vf "/dev/nvme1n1p1" 2>&1
				read -p "Indique si quiere que la etiqueta sea 1. Datos o 2. Data: " etiqueta 2>&1
				etiqueta=${etiqueta:-1}
				until [[ $etiqueta == "1" ]] || [[ $etiqueta == "2" ]]
				do
  				read -p "[-]¡ERROR! La etiqueta debe ser 1. Datos o 2. Data: " etiqueta 2>&1
  				etiqueta=${etiqueta:-1}
				done
				case $etiqueta in
					1)
						sudo ntfslabel -fv /dev/nvme1n1p1 "Datos" 2>&1
					;;
					2)
						sudo ntfslabel -fv /dev/nvme1n1p1 "Data" 2>&1
				esac
				(
				echo name 1
				echo ' '
				) | sudo parted /dev/nvme1n1
			else
				(
				echo select /dev/sda
				echo mktable gpt
				echo mkpart primary 0% 100%
				echo set 1 msftdata ON
				echo quit 
				) | sudo parted /dev/sda
				sudo mkfs.ntfs -vf "/dev/sda1" 
				read -p "Indique si quiere que la etiqueta sea 1. Datos o 2. Data: " etiqueta 2>&1
				etiqueta=${etiqueta:-1}
				until [[ $etiqueta == "1" ]] || [[ $etiqueta == "2" ]]
				do
  				read -p "[-]¡ERROR! La etiqueta debe ser 1. Datos o 2. Data: " etiqueta 2>&1
  				etiqueta=${etiqueta:-1}
				done
				case $etiqueta in
					1)
						sudo ntfslabel -fv /dev/sda1 "Datos" 2>&1
					;;
					2)
						sudo ntfslabel -fv /dev/sda1 "Data" 2>&1
				esac
				(
				echo name 1
				echo ' '
				) | sudo parted /dev/sda
			fi
		fi
	;;
	3)
		echo "Boot: " $part_boot 2>&1
		echo "Sistema: " $part_sys 2>&1
		echo "Swap: " $part_swap 2>&1

		read comprobar 
		
		copiar_en_debian
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
	enter=$(echo "")
	while [ $sec -ge 0 ]; do 
	  tput civis
	  echo -ne "[!]----Se reiniciará en $(printf $sec) segundo(s)...\033[0K\r"
	  let "sec=sec-1"
	  #sleep 1
	  read -r -t 1 -n 1 -s keypress
	  enter=$(echo $?) 
	  if [ "$enter" -eq 0 ] && [ "$keypress" = "" ]; then
	    echo -ne "\033[0K\r" && lsblk && break #lsblk = reboot
	  elif [ "$keypress" = $'\e' ]; then
	    echo -e "Reinicio cancelado!\033[0K\r"
	    break
	  elif [ "$enter" -eq 142 ]; then
	    continue
	  else 
	    sec=10   
	  fi
	done
fi
