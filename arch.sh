#!/bin/bash
# ArchLinux install script

partition() 
{
  lsblk
  echo -e "\nOn which device you want to install Arch Linux? (e.g sda)\n"
  read -r pname

  if [ -b /dev/"$pname" ]; then
    parted /dev/"$pname" mklabel GPT  
    parted /dev/"$pname" mkpart P1 1MiB 512MiB
    parted /dev/"$pname" mkpart P2 512MiB 100%  
    yes | mkfs.fat -F32 /dev/"$pname"1
    yes | mkfs.ext4 /dev/"$pname"2
    parted /dev/"$pname" set 1 boot on
  else
    echo -e "\nSelected device does not exist, installation interrupted.\n"
  fi
  
}

partition
