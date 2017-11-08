#!/bin/bash

configure_users()
{
# Setup your hostname
  echo "Type desired hostname: "
  read -r hostname

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
  echo "Type password for user $usrnm"
  passwd "$usrnm"
  export usrnm
  sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
  sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
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
  ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
  hwclock --systohc --utc
}

configure_bootloader()
{
  vendor=$(cat /proc/cpuinfo | grep vendor | uniq)
  intel_cpu=false

  if [[ $vendor == *"GenuineIntel"* ]]; then
    pacman -S intel-ucode --noconfirm
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
    partuuid=$(blkid -s PARTUUID -o value $root)
    echo $options$partuuid "rw" >> arch.conf
  else
    echo "title Arch Linux" > arch.conf
    echo "linux /vmlinuz-linux" >> arch.conf
    echo "initrd /initramfs-linux.img" >> arch.conf
    partuuid=$(blkid -s PARTUUID -o value $root)
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
    while [ "$second_choice" != "1" ] && [ "$second_choice" != "gnome" ] && [ "$second_choice" != "2" ] && [ "$second_choice" != "kde" ] && [ "$second_choice" != "" ]; do
      echo -e "Choose desktop environment"
      echo -e "1)gnome (default)\n2)kde"
      read -r second_choice
    done
  fi

  case $second_choice in
    1|gnome|"")  install_gnome;;
    2|kde)  install_kde;;
  esac

  echo "Install custom packages (Y,n)?"
  read -r answer_custom_install
  while [ "$answer_custom_install" != "y" ] && [ "$answer_custom_install" != "n" ] && [ "$answer_custom_install" != "" ]; do
    error_44
    read -r answer_custom_install
  done
  if [ "$answer_custom_install" == "y" ] || [ "$answer_custom_install" == "" ] ;  then
    install_custom_packages
  fi
}

install_gnome()
{
  pacman -S gnome gnome-tweak-tool --noconfirm
  pacman -S file-roller unrar lrzip --noconfirm
  pacman -S gedit transmission-gtk --noconfirm
  systemctl enable gdm
  systemctl enable NetworkManager
}

install_kde()
{
  pacman -S plasma konsole dolphin --noconfirm
  pacman -S gwenview okular ffmpegthumbs --noconfirm
  systemctl enable sddm
  systemctl enable NetworkManager
}

install_i3()
{
  echo "TBA"
}

install_custom_packages()
{
  su -c "gpg --recv-keys 1EB2638FF56C0C53" -s /bin/sh "$usrnm"

  git clone https://aur.archlinux.org/cower.git /tmp/cower
  git clone https://aur.archlinux.org/pacaur.git /tmp/pacaur

  chown -R "$usrnm" /tmp/cower
  chown -R "$usrnm" /tmp/pacaur

  cd /tmp/cower
  su -c "makepkg -si --noconfirm" -s /bin/sh "$usrnm"
  cd /tmp/pacaur
  su -c "makepkg -si --noconfirm" -s /bin/sh "$usrnm"
  su -c "numix-circle-icon-theme-git numix-folders-git adapta-gtk-theme --noconfirm" -s /bin/sh "$usrnm"
  
  sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
}

error_42()
{
  case $first_choice in
    1|2|de|wm|"") return 0;;
    *) echo -e "\nError 42 - Invalid choice\n1)de (default)\n2)wm"
  esac
}

error_43()
{
  echo "Invalid name, please try again."
}

error_44()
{
  echo "Invalid choice"
  echo "Install custom packages (Y,n)?"
}

setup_locale
setup_timezone
configure_users
configure_bootloader
install_essential_packages
setup_desktop_env
