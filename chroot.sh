#!/bin/bash

configure_users()
{
  echo "Type desired hostname: "
  read -r hostname

  while [ "$hostname" == "" ]; do
    display_message_3
    echo "Type desired hostname: "
    read -r hostname
  done

  echo "$hostname" > /etc/hostname
  echo -e "\nType desired root password"
  passwd

  echo -e "\nCreating user & setting password...\n"
  echo "Type desired username: "
  read -r usrnm

  while [ "$usrnm" == "" ]; do
    display_message_3
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
  echo "LANG=en_US.UTF­8" > "/etc/locale.conf"
}

setup_timezone()
{
  ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
  hwclock --systohc --utc
}

configure_bootloader()
{
  firmware=$([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
  if [  "$firmware" == "BIOS"  ]
  then
      pacman -S grub os-prober --noconfirm
      grub-install --target=i386-pc "/dev/$disk"
      grub-mkconfig -o /boot/grub/grub.cfg
  else
      configure_systemd
  fi
}

configure_systemd()
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

setup_environment()
{
  local option_chosen

  display_message_1
  read -r option_1
  option_chosen=$(error_1 $option_1)

  while [ "$option_chosen" == "-1" ]; do
    display_message_1
    read -r option_1
    option_chosen=$(error_1 $option_1)
  done

  if [ "$option_1" == "wm" ] || [ "$option_1" == "2" ]; then
    install_i3
    return 0;
  fi

  if [ "$option_1" == "de" ] || [ "$option_1" == "1" ] || [ "$option_1" == "" ];  then
    display_message_2
    read -r option_2
    option_chosen=$(error_2 $option_2)
    while [ "$option_chosen" == "-1"  ]; do
      display_message_2
      read -r option_2
      option_chosen=$(error_2 $option_2)
    done
  fi

  case $option_2 in
    1|gnome|"")  install_gnome;;
    2|kde)  install_kde;;
    3|cinnamon)  install_cinnamon;;
    4|xfce)  install_xfce;;
  esac

}

install_gnome()
{
  pacman -S gnome gnome-tweak-tool --noconfirm
  pacman -S file-roller unrar lrzip --noconfirm
  pacman -S gedit transmission-gtk --noconfirm
  pacman -S gst-libav gst-plugins-ugly --noconfirm
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

install_xfce()
{
  pacman -S xfce4 --noconfirm
  systemctl enable lightdm
  systemctl enable NetworkManager
}

install_cinnamon()
{
  pacman -S cinnamon --noconfirm
  systemctl enable lightdm
  systemctl enable NetworkManager
}

install_i3()
{
  pacman -S xorg-server xorg-xinit --noconfirm
  pacman -S i3 --noconfirm
  echo "exec i3" >> ~/.xinitrc  
}

install_package_manager()
{
  git clone https://aur.archlinux.org/cower.git /tmp/cower
  git clone https://aur.archlinux.org/pacaur.git /tmp/pacaur

  chown -R "$usrnm" /tmp/cower
  chown -R "$usrnm" /tmp/pacaur

  cd /tmp/cower
  su -c "makepkg --skippgpcheck -si --noconfirm" -s /bin/sh "$usrnm"
  cd /tmp/pacaur
  su -c "makepkg --skippgpcheck -si --noconfirm" -s /bin/sh "$usrnm"
}

enable_multilib()
{
  old="\#\[multilib\]"
  new="\[multilib\]"
  pacfile="/etc/pacman.conf"
  sed -i "s/$old/$new/" $pacfile

  old="\#Include = \/etc\/pacman.d\/mirrorlist"
  new="Include = \/etc\/pacman.d\/mirrorlist"

  # Start at line 0, continue until you match '$old', execute the substitution in curly brackets.
  tac $pacfile | sed "0,/$old/{s/$old/$new/}" | tac  > temp.txt
  cp temp.txt $pacfile
  rm temp.txt

  # Enable color option
  old="#Color"
  new="Color"
  sed -i "s/$old/$new/" $pacfile

  pacman -Syu --noconfirm
}

error_1()
{
  case $option_1 in
    1|2|de|wm|"") echo 0;;
    *) echo -1;;
  esac
}

error_2()
{
  case $option_2 in
    1|2|3|4|gnome|kde|xfce|cinnamon|"") echo 0;;
    *) echo -1;;
  esac
}


display_message_1()
{
  echo -e "\nInstall desktop environment or window manager?\n"
  echo -e "1)de (default)\n2)wm"
}

display_message_2()
{
  echo -e "\nChoose desktop environment"
  echo -e "1)gnome (default)\n2)kde\n3)cinnamon\n4)xfce"
}

display_message_3()
{
  echo "Invalid (empty) name, please try again."
}

setup_locale
setup_timezone
configure_users
configure_bootloader
install_essential_packages
install_package_manager
setup_environment
enable_multilib
