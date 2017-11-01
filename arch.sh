#!/bin/bash
# ArchLinux install script

startup() 
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
  reboot
}

startup

