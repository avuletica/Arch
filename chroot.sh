#!/bin/bash

configure_users()
{
  echo "Type desired hostname: "
  read -r hostname

  while [ "$hostname" == "" ]; do
    display_message_4
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
    display_message_4
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

setup_desktop_env()
{
  local option_chosen     
 
  display_message_1
  read -r first_choice  
  option_chosen=$(error_1 $option_1)
  
  while [ "$option_chosen" == "-1" ]; do
    display_message_1
    read -r first_choice   
    option_chosen=$(error_1 $option_1)       
  done

  if [ "$option_1" == "wm" ] || [ "$option_1" == "2" ]; then
    install_i3
    return 0;
  fi

  if [ "$option_1" == "de" ] || [ "$option_1" == "1" ] || [ "$option_1" == "" ];  then
    display_message_2
    read -r second_choice 
    option_chosen=$(error_2 $option_2)  
    while [ "$option_chosen" == "-1"  ]; do
      display_message_2 
      read -r second_choice
      option_chosen=$(error_2 $option_2)      
    done
  fi

  case $option_2 in
    1|gnome|"")  install_gnome;;
    2|kde)  install_kde;;
    3|cinnamon)  install_cinnamon;;
    4|xfce)  install_xfce;;
  esac

  echo "Install custom packages (Y,n)?"
  read -r answer_custom_install
  option_chosen=$(error_3 $option_3)

  while [ "$option_chosen" == "-1" ]; do
    display_message_3
    read -r answer_custom_install
  done

  if [ "$option_3" != "Y" ] && [ "$option_3" == "y" ] || [ "$option_3" == "" ] ;  then
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
  echo "TBA"
}

install_custom_packages()
{
  git clone https://aur.archlinux.org/cower.git /tmp/cower
  git clone https://aur.archlinux.org/pacaur.git /tmp/pacaur

  chown -R "$usrnm" /tmp/cower
  chown -R "$usrnm" /tmp/pacaur 

  cd /tmp/cower
  su -c "makepkg --skippgpcheck -si --noconfirm" -s /bin/sh "$usrnm"
  cd /tmp/pacaur
  su -c "makepkg --skippgpcheck -si --noconfirm" -s /bin/sh "$usrnm"
  pacaur -S numix-circle-icon-theme-git numix-folders-git adapta-gtk-theme --noconfirm
  
  sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
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

error_3()
{
  case $option_3 in
    Y|y|n|N|"") echo 0;;
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
  echo "Invalid choice"
  echo "Install custom packages (Y,n)?"
}

display_message_4()
{
    echo "Invalid (empty) name, please try again."
}

setup_locale
setup_timezone
configure_users
configure_bootloader
install_essential_packages
setup_desktop_env
