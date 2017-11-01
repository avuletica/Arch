#!/bin/bash
# ArchLinux install script

partition() 
{
  lsblk
  echo -e "\nOn which device you want to install Arch Linux? (e.g sda)\n"
  read -r pname

  if [ -b /dev/"$pname" ]; then
    parted /dev/"$pname" mklabel GPT
    parted /dev/"$pname" mkpart primary fat32 1MiB 512MiB
    parted /dev/"$pname" mkpart primary ext4 512MiB 100%      
    parted /dev/"$pname" set 1 boot on
  else
    echo -e "\nSelected device does not exist, installation interrupted.\n"
  fi
  
}

partition
