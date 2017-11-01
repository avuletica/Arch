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

configure_users
setup_locale
setup_timezone
