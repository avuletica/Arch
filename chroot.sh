#!/bin/bash

configure_users()
{
    # Setup your hostname
    echo "Type desired hostname: "
    read -r _hostname
    echo "$_hostname" > /etc/hostname

    # Setting root password
    echo -e "\nType desired root password"
    passwd

    # Creating user & setting password
    echo -e "\nCreating user & setting password...\n"
    echo "Type desired username: "
    read -r _usrnm
    useradd -m -g users -G wheel,storage,power -s /bin/bash "$_usrnm"
    echo "Type password for user"
    passwd "$_usrnm"
    sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers
}

setup_locale()
{    
  old="\#en_US.UTF-8 UTF-8"
  new="en_US.UTF-8 UTF-8"
  location="/etc/locale.gen"
  sed -i "s/$old/$new/" $location    
  locale-gen
  echo LANG=en_US.UTF­8 > /etc/locale.conf  
}

setup_timezone() 
{
  ln -s /usr/share/zoneinfo/Europe/Zagreb > /etc/localtime
  hwclock --systohc --utc
}

configure_bootloader()
{
  vendor=$(cat /proc/cpuinfo | grep vendor | uniq)
  intel_cpu=false

  if [[ $vendor == *"GenuineIntel"* ]]; then
    pacman -S intel-ucode
    intel_cpu=true
  fi

  bootctl --path=/boot install
  touch loader.conf
  echo "default arch" > loader.conf
  echo "editor 0" >> loader.conf
  mv loader.conf boot/loader/loader.conf

  touch arch.conf
  options="options root=PARTUUID="
  if [ $intel_cpu ]; then
    echo "title Arch Linux" > arch.conf
    echo "linux /vmlinuz-linux" >> arch.conf
    echo "initrd /intel-ucode.img" >> arch.conf
    echo "initrd /initramfs-linux.img" >> arch.conf
    partuuid=$(lsblk -no UUID $root)
    echo $options$partuuid "rw" >> arch.conf
  else
    echo "title Arch Linux" > arch.conf
    echo "linux /vmlinuz-linux" >> arch.conf
    echo "initrd /initramfs-linux.img" >> arch.conf
    partuuid=$(lsblk -no UUID $root)
    echo $options$partuuid "rw" >> arch.conf
  fi

  mv arch.conf boot/loader/entries/arch.conf
}

setup_locale
setup_timezone
configure_users
configure_bootloader

