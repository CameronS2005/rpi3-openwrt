status="0"

read -rp "Press Enter To Continue! (WARNING: THIS MUST BE DONE OVER ETHERNET!)"

if [[ ${status}=="0" ]]; then
# Backup wireless configuration (only done on first run)
cp /etc/config/wireless /etc/config/conf_backup/wireless-pre-ap.bk
sed -i 's/statkus="0"/status="1"/' "$0"
fi

# Prompt to attach USB WiFi adapter
echo "REMOVE NETWORK ADAPTER!"
read -rp "Press Enter after detaching USB WiFi adapter!"
sed -i '19,100d' /etc/config/wireless # removes any wireless config besides our wifi connection

read -rp "Press Enter after attaching USB WiFi adapter!"
sleep 3

# Check if adapter is found
if lsusb | grep -iq "WLAN"; then
    echo "Adapter Found!"
else
    echo "No Adapter Found!"
    exit 1
fi

#if [[ ${status}=="0" ]]; then
ifconfig wlan1 up
#fi

# Prompt for AP configuration
echo "Enter AP SSID:"
read -r ssid
echo "Enter AP Key: (must be longer than 8 digits)"
read -r key
echo "Enter AP Channel (1-11):"
read -r channel
# add channel check (must be between 1 and 11!)

# Prompt for hidden AP configuration
echo "Hidden AP? (0/1) (1=hidden):"
read -r hidden
if ! [[ "${hidden}" =~ ^[0-1]$ ]]; then
    echo "Error: Invalid hidden value. Must be either 0 or 1. Exiting..."
    exit 1
fi

# modify lines in wireless config
sed -i "23s/.*/        option channel '${channel}'/" /etc/config/wireless  # sets channel
sed -i "26s/.*/        option disabled '0'/" /etc/config/wireless # enables wifi-adapter
sed -i "32s/.*/        option ssid '${ssid}'/" /etc/config/wireless  # sets channel
sed -i "33s/.*/        option encryption 'psk2'/" /etc/config/wireless # enables wifi-adapter
cat <<EOF >>/etc/config/wireless
        option key '${key}'
        option hidden '${hidden}'
EOF

sed -i '34d' /etc/config/wireless # removes empty line

echo "TIP: IF WIFI DOESNT SHOW UP PASSWORD IS PROBABLY TOO SHORT!"
read -p "Press Enter to Start AP! (Will Reboot!)"

#rm /root/adapter.sh

uci commit wireless
wifi
sleep 10
reboot now
