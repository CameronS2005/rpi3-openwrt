# rpi3-openwrt

If you need any help feel free to ask any questions!

## OpenWrt Raspberry Pi Wiki (With Downloads) (https://openwrt.org/toh/raspberry_pi_foundation/raspberry_pi)

## Raspberry Pi Imager (https://www.raspberrypi.com/software/)

Custom setup script for a Raspberry Pi running OpenWrt (This was tested on a Raspberry Pi 3b+ running OpenWrt 22.03.5)

This setup is designed to be ran on a fresh install of OpenWrt on a raspberry pi, the script will automatically configure your wireless connection to your wifi and setup your vpn configuration!

This will also setup AdguardHome DNS Server!
------------------------------------------------------------------------

Running the setup.sh script guide below...

BE SURE YOU MODIFY LINES 9,10,11 in setup.sh with your uploaded ovpn conf, auth, and your computers public key for ssh!

-----

ssh into raspberry pi; ssh root@openwrt

create and edit setup script: vi setup.sh (press i to edit)

copy the raw of setup.sh and modify the config in the first few lines to fit your wifi!

copy your modified setup.sh and paste it into setup.sh (press ESC then : then wq then press enter)

make the setup script executable; chmod +x setup.sh

execute the setup script for the first time; ./setup.sh

Will prompt you to set the root passwd!

Will prompt you to enter your wifi details!

Press Enter when it tell you to, it will disconnect you, but your raspberry pi isnt rebooting, so just wait like 5 seconds for network to restart then you can reconnect.

execute the setup script for the second time; ./setup.sh

!! IF PART TWO FAILS RERUN IF IT KEEPS FAILING YOU CAN EITHER REBOOT OR DO /etc/init.d/network restart (both should fix it!) (part2 will also fail if you misconfigured your wifi!)

Wait until opkg and all config installs finish!

When it Says "Press Enter When Finished Installing AdGuard!" go to http://openwrt:3000 and finish the Adguard install via the web-gui

After you finish in the web-gui press enter to reboot! Your Setup should be finished!

------------------------------------------------------------------------

The adapter.sh script is meant to be ran after the setup is finished and it will help configure your access-point for your router! (This script is configured for an RTL3070 Adapter) (SHOULD STILL WORK)

------------------------------------------------------------------------

Running the adapter.sh script guide below...

-----

ssh into raspberry pi; ssh root@openwrt

wget https://raw.githubusercontent.com/CameronS2005/rpi3-openwrt/main/adapter.sh # much easier now that we have wifi!

chmod +x adapter.sh

./adapter.sh

##
