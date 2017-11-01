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

configure_users
