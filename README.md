# Introduction
Custom Arch Linux installation (shell) script 

<img src="https://github.com/avuletica/Arch/blob/master/images/sample.gif" width="535" height="365">

## How to use
* [Download arch-iso from official site](https://www.archlinux.org/download/)
* [Make bootable usb](https://wiki.archlinux.org/index.php/USB_flash_installation_media)
* Boot from usb.
* Run following commands in terminal:
    * `wget https://raw.githubusercontent.com/avuletica/Arch/master/arch.sh`
    * `chmod +x ./arch.sh`
    * `./arch.sh`
* During instalation you will be asked following:
    * To choose Linux partition. 
    * To provide username & password for root and user. 
    * Choice for desktop environment
    * Choice to install custom packages (pacaur etc.) 

## Project status
|Description|Name|Supported|Tested|
|:----------|:----------|:----------|:----------|
|desktop environment|xfce|yes|no|
|desktop environment|kde|yes|no|
|desktop environment|gnome|yes|yes|
|desktop environment|cinnamon|yes|no|
|window manager|i3|no|no|
|window manager|i3-sway|no|no|
|firmware|UEFI with systemd|yes|yes|
|firmware|BIOS with grub|yes|yes|
|utility|dual-boot|no|no|
