#!/bin/bash

configure_users()
{
# Setup your hostname
  echo "Type desired hostname: "
  read -r hostname
  echo "$hostname"

  while [ "$hostname" == "" ]; do
    error_43
    echo "Type desired hostname: "
    read -r hostname
  done

  echo "$hostname" > /etc/hostname

# Setting root password
  echo -e "\nType desired root password"
  passwd

# Creating user & setting password
  echo -e "\nCreating user & setting password...\n"
  echo "Type desired username: "
  read -r usrnm

  while [ "$usrnm" == "" ]; do
    error_43
    echo "Type desired username: "
    read -r usrnm
  done

  useradd -m -g users -G wheel,storage,power -s /bin/bash "$usrnm"
  echo "Type password for user"
  passwd "$usrnm"
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

install_essential_packages()
{
  pacman -S git vim openssh ntfs-3g bash-completion --noconfirm
}

setup_desktop_env()
{
  local first_choice="de"
  local second_choice="gnome"

  echo -e "\nInstall desktop environment or window manager?\n"
  echo -e "1)de (default)\n2)wm"
  read -r first_choice
  while [ "$first_choice" != "1" ] && [ "$first_choice" != "de" ] && [ "$first_choice" != "2" ] && [ "$first_choice" != "wm" ] && [ "$first_choice" != "" ]; do
    error_42 $first_choice
    read -r first_choice
  done

  if [ "$first_choice" == "wm" ] || [ "$first_choice" == "2" ]; then
    install_i3
    return 0;
  fi

  if [ "$first_choice" == "de" ] || [ "$first_choice" == "1" ] || [ "$first_choice" == "" ];  then
    echo -e "Choose desktop environment"
    echo -e "1)gnome (default)\n2)kde"
    read -r second_choice
  fi

  case $second_choice in
    1|gnome)  install_gnome;;
    2|kde)  install_kde;;
    *)  install_gnome;;
  esac
}

install_gnome()
{
  pacman -S gnome gnome-tweak-tool --noconfirm
  pacman -S file-roller unrar lrzip --noconfirm
  systemctl enable gdm
}

install_kde()
{
  pacman -S plasma konsole dolphin --noconfirm
  pacman -S gwenview okular ffmpegthumbs --noconfirm
  systemctl enable sddm
}

install_i3()
{
  echo "TBA"
}

error_42()
{
  case $second_choice in
    1|2|de|wm|"")  return 0;;
    *)  echo "Error 42 - Invalid choice"
  esac
}

setup_locale
setup_timezone
configure_users
configure_bootloader
install_essential_packages
setup_desktop_env

