#!/bin/bash
# ArchLinux install script

startup() 
{
  lsblk
  echo -e "\nOn which device you want to install Arch Linux? (e.g sda)\n"
  read -r pname

  if [ -b /dev/"$pname" ]; then
    parted /dev/"$pname" mklabel GPT
    parted /dev/"$pname" mkpart primary 1MiB 512MiB
    parted /dev/"$pname" mkpart primary 512MiB 100%
    yes | mkfs.fat -F32 -v -I /dev/"$pname"1    
    yes | mkfs.ext4 /dev/"$pname"2    
    parted /dev/sda set 1 boot on    
  else
    echo -e "\nSelected device does not exist, installation interrupted.\n"
    exit
  fi
  
  efi_pname=/dev/"$pname"1
  root=/dev/"$pname"2
  export root
	
  mount "$root" /mnt
  mkdir /mnt/boot
  mount "$efi_pname" /mnt/boot  

  setup $root
}

setup()
{
  pacstrap /mnt base base-devel
  genfstab -U -p /mnt >> /mnt/etc/fstab
  wget https://raw.githubusercontent.com/avuletica/Arch/master/chroot.sh
  cp chroot.sh /mnt
  chmod +x /mnt/chroot.sh
  arch-chroot /mnt ./chroot.sh
  echo "Install finished, reboot (y,n)?"
  read -r answer
  if [ "$answer" == "y" ]; then
    reboot
  else
    return 0
  fi
}

startup

