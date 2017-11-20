#!/bin/bash

startup()
{
  lsblk
  echo -e "\nOn which device you want to install Arch Linux? (e.g sda)\n"
  read -r disk
  
  efi_pname=/dev/"$disk"1
  root=/dev/"$disk"2
  export efi_pname
  export root
  export disk  

  if [ -b /dev/"$disk" ]; then  
    firmware=$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)    
    if [  "$firmware" == "UEFI"  ]
    then
        parted /dev/"$disk" mklabel GPT
        pratition             
    else
        parted /dev/"$disk" mklabel msdos
        pratition
        set 1 boot on       
    fi    
  else
    echo -e "\nSelected device does not exist, installation interrupted.\n"
    exit
  fi  

  mount "$root" /mnt
  mkdir /mnt/boot
  mount "$efi_pname" /mnt/boot

  setup $root $disk
}

pratition()
{
  parted /dev/"$disk" mkpart primary 1MiB 512MiB
  parted /dev/"$disk" mkpart primary 512MiB 100%
  yes | mkfs.fat -F32 -v -I "$efi_pname"
  yes | mkfs.ext4 "$root"
}

setup()
{
  pacstrap /mnt base base-devel
  genfstab -U -p /mnt >> /mnt/etc/fstab
  wget https://raw.githubusercontent.com/avuletica/Arch/master/chroot.sh
  cp ./chroot.sh /mnt
  chmod +x /mnt/chroot.sh
  arch-chroot /mnt ./chroot.sh
  echo "Install finished, reboot (y,n)?"
  read -r answer
  if [ "$answer" == "y" ]; then
    umount -R /mnt
    reboot
  else
    return 0
  fi
}

startup
