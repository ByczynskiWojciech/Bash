#!/bin/bash

#Script which automate creating raid(0,1 and 5) made while DXC intership

raid(){

mdadm --create --verbose /dev/md0 --level=$RAID_NR --raid-devices=$COUNT_PATH ${PATHS[@]}

if [ $? -eq 0 ]; then
        echo "Operation completed!"
else
        echo "RAID was not created!" 
fi

exit
}

raid_interface(){
count_path

if [ -z $raid_number ] ; then
	echo "You need to set Raid number!"
	interface_opening
fi

if [ -z $disks_path ] ; then
        echo "You need to set disks paths!"
        interface_opening
fi

mdadm --create --verbose /dev/md0 --level=$raid_number  --raid-devices=$path_numbers $disks_path 

if [ $? -eq 0 ]; then
        echo "Operation completed!"
else
        echo "RAID was not created!" 
fi

exit
}

type_of_raid(){
echo -e  "\n-------------------------------------------------------------"
echo "Choose type of RAID you wanna make. Avaliable : 0,1 or 5. Press 6 to leave."
echo -e "\n"
read raid_number

case $raid_number  in

        0) echo -e "You have choosen RAID 0!\n" && interface_opening;;
        1) echo -e "You have choosen RAID 1!\n" && interface_opening;;
        5) echo -e "You have choosen RAID 5!\n" && interface_opening;;
	6) interface_opening ;;
        *) echo -e "Raid number $raid_number is not supported.\n" && raid_number="" && interface_opening ;;
esac
}

count_path(){
path_numbers=$(echo "$disks_path" | wc -w)
#echo $path_numbers

}

check_paths_interface(){
if [ $raid_number = 0 ] ; then
        if [ $path_numbers -lt 2 ]; then
                echo "To do RAID 0, at least two disks are required!"
                exit 1
        fi
elif [ $raid_number = 1 ]; then
        if [  $path_numbers -lt 2 ]; then
                echo "To do RAID 1, at least two disks are required!"
                exit 1
        fi
elif [ $raid_number = 5 ]; then
        if [ $path_numbers -lt 3 ]; then
                echo "To do RAID 5, at least three disks are required!"
                exit 1
        fi
else
        echo "Raid number $raid_number is not supported" & exit 1
fi
}


change_path(){
echo "-------------------------------------------------------------"
echo "All disks"
echo "-------------------------------------------------------------"

for i in `lsblk -dnp | cut -d ' ' -f 1`
do
	echo $i 
done

echo "-------------------------------------------------------------"
echo "Write disks which you want to create Raid of. Separate disks with white-spaces (space)."
echo "-------------------------------------------------------------"
read disks_path

count_path
disk_array=($disks_path)

#check if paths are disk

for ((i=0; $i < path_numbers; i++)) ; do
	check_if=$(lsblk -dnp | grep ${disk_array[i]} | awk -F' ' '{ print $6 }')
	echo $check_if

	if [ "$check_if" = "disk" ] ; then
		echo "This is disk!"
	else
		echo "${disk_array[i]} is not path to disk!"
		path_numbers=""
		disks_path=""
		interface_opening
	fi
done

#check if paths are mounted

for ((i=0; $i < path_numbers; i++)) ; do
        check_if=$(lsblk -dnp | grep ${disk_array[i]} | awk -F' ' '{ print $7 }')
        echo $check_if

        if [ -z $check_if ] ; then
                echo "Disk ${disk_array[i] } is not mounted!"
        else
                echo "Disk ${disk_array[i] } is mounted!"
                path_numbers=""
                disks_path=""
                interface_opening
        fi
done

#check if paths are in raid

for ((i=0; $i < path_numbers; i++)) ; do
	check_if=$(mdadm -- examine $disk_array[i] 2> /dev/null)
        echo $check_if

        if [ -z $check_if ] ; then
                echo "Disk ${disk_array[i] } is not in raid!"
        else
                echo "Disk ${disk_array[i] } is already in raid!"
                path_numbers=""
                disks_path=""
                interface_opening
        fi
done


#check if paths are in volumegroup
for ((i=0; $i < path_numbers; i++)) ; do
        check_if=$(pvs -o vg_name | grep ${disk_array[i]})
        echo $check_if
        
	if [ -z $check_if ] ; then
                echo "Disk ${disk_array[i] } is not in VG!"
        else
                echo "Disk ${disk_array[i] } is in VG!"
                path_numbers=""
                disks_path=""
                interface_opening
        fi
done

check_paths_interface
interface_opening
}

change_mount(){
echo -e "\n"
echo "-------------------------------------------------------------"
echo "Write where to mount raid."
echo "-------------------------------------------------------------"
echo -e "\n"

read mount_path

echo -e "\n------------------------------------------------------------"
echo "You have choosen $mount_path mount path!"
echo -e "\n"

interface_opening
}

mount_disks(){
mkfs.ext4 -F $MOUNT
echo $MOUNT
mkdir -p /mnt/md0
echo $MOUNT
mount $MOUNT /mnt/md0
}

if_mount(){
if [ -n  $MOUNT ]
then
	echo "String nie jest pusty!"
	echo $MOUNT
	mount_disks
fi
}

mount_disks_inter(){
mkfs.ext4 -F $mount_path

mkdir -p /mnt/md0

mount $mount_path /mnt/md0
}

if_mount_inter(){
if [ -n $mount_path]
then
        #echo "String nie jest pusty!"
        mount_disks_inter
fi
}

interface_opening(){
echo "-------------------------------------------------------------"
echo "Write 1 -Choose type of raid."
echo "Write 2 -Add/change paths of disks."
echo "Write 3 -Add/change path where to mount raid."
echo "Write 4 -To start creating raid."
echo "Wrtie 5 -To exit."
echo "-------------------------------------------------------------"
echo -e "\n"

read choose

case $choose in
	1) type_of_raid ;;
	2) change_path ;;
	3) change_mount ;;
	4) raid_interface ;;
	5) echo "Goodbye!";  exit 2;;
	*) echo "Number is out of context. Choose number from list." & interface_opening ;;

esac
}

help_menu(){
	echo -e "
	\nSYNTAX:
	\nraid [OPTIONS]
	\n
	\nOptions:
	\n\tRequired:
	\n\t-r		Type of Raid (0,1 or 5)
	\n\t-d 		Path of disks, you to list paths to disks between quotation marks. For example : \"dev/sdc dev/sdd\"
	\n
	\n\tOptionals:
 	\n\t-m		Path where to mount
	\n\t-h		Prints help menu
	\n\t-i		Opens interface
	"
exit 1
}

check_raid_nr(){
case $RAID_NR in

	0) ;;
	1) ;;
	5) ;;
	*) echo "Raid number $RAID_NR is not supported" &  exit 1;; 
esac
}

check_paths(){
if [ $RAID_NR = 0 ] ; then
	if [ $COUNT_PATH -lt 2 ]; then
		echo "To do RAID 0, at least two disks are required!"
		exit 1
	fi
elif [ $RAID_NR = 1 ]; then
	if [  $COUNT_PATH -lt 2 ]; then
		echo "To do RAID 1, at least two disks are required!"
		exit 1
	fi
elif [ $RAID_NR = 5 ]; then
	if [ $COUNT_PATH -lt 3 ]; then
		echo "To do RAID 5, at least three disks are required!"
		exit 1
	fi
else
	echo "Raid number $RAID_NR is not supported" & exit 1
fi
}

#Passing arguments to variables

while getopts "m:r:d:ih" option; do
	case "${option}" in
	r) 
		RAID_NR=${OPTARG} 
		;;
	d)
		#echo "$OPTARG"
		set -f 
		IFS=' ' 
		PATHS=($OPTARG)
		;;
	m) 
		MOUNT=${OPTARG} 
		;;
	i) 
		interface_opening
		;;
	h) 
		help_menu
		;;
	*) 	echo "Invalid options!"
		exit 1;;	
	esac
done

if [ -z "${RAID_NR}" ] || [ -z "${PATHS}" ]; then
	echo "Options -r and -d are required!"
	exit 1
fi

echo $RAID_NR
for i in "${PATHS[@]}"; do
	echo -n "${i} "
done
echo -e "\n$MOUNT"

#Getting number of paths and paths to variable

COUNT_PATH=${#PATHS[@]}

echo $COUNT_PATH

#COUNT_PATH=$(echo "$ALL" | awk -F "-" '{print $3}' | wc -w)
#PATHS=$(echo "$ALL" | awk -F "-" '{print $3}' | cut -d ' '  -f 2-$COUNT_PATH)
#COUNT_PATH=$((COUNT_PATH-1))

#Creating raid

check_raid_nr
check_paths
raid
if_mount
