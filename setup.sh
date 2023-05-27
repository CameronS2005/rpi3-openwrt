## ALOT OF THIS SED CAN BE REPLACED WITH EXAMPLE uci "dropbear.@dropbear[0].RootPasswordAuth='off'"
# New Lan & Adguard DNS Config (adguard_port must be same you set in Adguard Gui install!)
lan_addr="10.71.71.1"
adguard_port="5353"
dns1="208.67.222.222"; dns2="208.67.220.220" # backend dns servers (currently: opendns)
# Config Backup Location
conf_backup="/etc/config/conf_backup"
# Pastebin Config
pastebin_ovpn_conf="https://pastebin.com/raw/UPLOAD-YOURS" # ovpn conf file (add auth-user-pass client.conf and redirect-gateway def1 ipv6 to the bottom of your conf!)
pastebin_ovpn_auth="https://pastebin.com/raw/UPLOAD-YOURS" # first line username, second line password!
pastebin_pub_key="https://pastebin.com/raw/UPLOAD-YOURS" # your public rsa key so you can ssh into the router!
#
##
status="0" # MODIFY NEEDED LINES! (MODIFY WIFI INFO AND PASTEBIN LINKS!)

## Requesting wifi-details
wifi_enc="psk2" # none=open, psk2=wpa2 (if none wifi_password is ignored in /etc/config/wireless)
echo "Enter Your Wifi Details Below!"
echo "Enter SSID:"
read -r wifi_ssid
echo "Enter PASSWORD: (Longer than 8 Characters (I think))"
read -r wifi_password
echo "Enter CHANNEL (1-11)"
read -r wifi_channel

if [[ "${status}" == "0" ]]; then
  echo "Requesting Set of Hardcoded Root Password!"
  passwd

  echo "Creating Conf File Backups! @ ${conf_backup}"

  mkdir -p ${conf_backup}
  cp /etc/config/network ${conf_backup}/network.bk
  cp /etc/config/wireless ${conf_backup}/wireless.bk
  cp /etc/config/uhttpd ${conf_backup}/uhttpd.bk
  cp /etc/config/firewall ${conf_backup}/firewall.bk
  cp /etc/config/dhcp ${conf_backup}/dhcp.bk
  cp /etc/config/dropbear ${conf_backup}/dropbear.bk

  echo "Starting Wireless Configuration..."

  cat <<EOF > /etc/config/network
config interface 'loopback'
  option device 'lo'
  option proto 'static'
  option ipaddr '127.0.0.1'
  option netmask '255.0.0.0'

config globals 'globals'
  option ula_prefix 'fd94:badb:911d::/48'

config device
  option name 'br-lan'
  option type 'bridge'
  list ports 'eth0'

config interface 'lan'
  option device 'br-lan'
  option proto 'static'
  option ipaddr '${lan_addr}'
  option netmask '255.255.255.0'
  option ip6assign '60'
  option force_link '1'

config interface 'wwan'
  option proto 'dhcp'
  option peerdns '0'
  option dns '1.1.1.1'

config interface 'vpnclient'
  option ifname 'tun0'
  option proto 'none'
EOF

  cat <<EOF > /etc/config/wireless
config wifi-device 'radio0'
  option type 'mac80211'
  option path 'platform/soc/3f300000.mmcnr/mmc_host/mmc1/mmc1:0001/mmc1:0001:1'
  option channel '${wifi_channel}'
  option band '2g'
  option htmode 'HT20'
  option disabled '0'
  option short_gi_40 '0'
  option cell_density '0'

config wifi-iface 'wifinet1'
  option device 'radio0'
  option mode 'sta'
  option network 'wwan'
  option ssid '${wifi_ssid}' # WIFI SSID
  option encryption '${wifi_enc}' # WIFI ENCRYPTION (none=open) (psk2=wpa2)
  option key '${wifi_password}' # WIFI KEY
EOF

  sed -i '4,6d' /etc/config/uhttpd
  sed -i '20s/.*/ option input    ACCEPT/' /etc/config/firewall

  uci commit network
  uci commit wireless
  uci commit uhttpd
  uci commit firewall

  sed -i 's/status="0"/status="1"/' "$0"

  read -p "Press Enter To Continue! (WILL BE DISCONNECTED) (RECONNECT TO FINISH INSTALL RUN SETUP SCRIPT AGAIN)"

  /etc/init.d/uhttpd restart
  /etc/init.d/firewall restart
  /etc/init.d/network restart

elif [[ "${status}" == "1" ]]; then
  #sleep 30
  echo "Starting Part 2 of Configuration!"

  if ! ping -c 1 1.1.1.1 >/dev/null; then
    echo "Ping to 1.1.1.1 failed. Exiting... (WIFI IS DOWN!) (Part 2 Requires WIFI!)"
    exit 1
  fi

  if ! opkg update >/dev/null 2>&1; then
    echo "opkg update failed. Exiting... (If this persists, simply reboot; it will fix it) (or do /etc/init.d/network restart)"
    exit 1
  else
    echo "opkg update completed successfully."
  fi

  mkdir -p /opt/ && cd /opt/
  wget -c https://static.adguard.com/adguardhome/release/AdGuardHome_linux_arm64.tar.gz
  tar xfvz AdGuardHome_linux_arm64.tar.gz
  rm AdGuardHome_linux_arm64.tar.gz

  cd ~

  opkg install luci-app-openvpn openvpn-openssl nano curl wget screen kmod-rt2800-lib kmod-rt2800-usb kmod-rt2x00-lib kmod-rt2x00-usb kmod-usb-core kmod-usb-uhci kmod-usb-ohci kmod-usb2 usbutils
  opkg list-upgradable | cut -f 1 -d ' ' | xargs opkg upgrade

  echo "Setting Up OpenVPN Config!"

  echo "" > /etc/config/openvpn # clears the sample configs

  wget -O /etc/openvpn/client.conf ${pastebin_ovpn_conf} # vpn conf file
  wget -O /etc/openvpn/client.auth ${pastebin_ovpn_auth} # vpn cred file (line 1 user, line 2 pass)

  /etc/init.d/openvpn restart

  for OVPN_CONF in /etc/openvpn/*.conf; do
    OVPN_ID="$(basename "${OVPN_CONF%.*}" | sed -e "s/\W/_/g")"
    uci -q delete openvpn."${OVPN_ID}"
    uci set openvpn."${OVPN_ID}"="openvpn"
    uci set openvpn."${OVPN_ID}".enabled="1" # this line force enables the ovpn conf!
    uci set openvpn."${OVPN_ID}".config="${OVPN_CONF}"
  done
  uci commit openvpn
  /etc/init.d/openvpn restart

  uci rename firewall.@zone[0]="lan"
  uci rename firewall.@zone[1]="wan"
  uci del_list firewall.wan.device="tun+"
  uci add_list firewall.wan.device="tun+"
  
  uci commit firewall
  /etc/init.d/firewall restart

  echo "Starting AdGuard Install!"
  echo "Set DNS port to ${adguard_port}"
  /opt/AdGuardHome/AdGuardHome -s install

  read -p "Press Enter When Finished Installing AdGuard!"

  cp /opt/AdGuardHome/AdGuardHome.yaml /etc/config/conf_backup/AdGuardHome.yaml.bk

  echo "Final DNS Configurations & AdGuard Config!"

  sed -i "30s/.*/    - ${dns1}\n    - ${dns2}/" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i '36,37d' /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "34s/.*/    - ${dns1}/" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "35s/.*/    - ${dns2}/" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "54s/.*/  enable_dnssec: true/" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "57s/.*/    enabled: true/" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "107s/.*/  interval: 24h/" /opt/AdGuardHome/AdGuardHome.yaml
  sed -i "120s/.*/  - enabled: true/" /opt/AdGuardHome/AdGuardHome.yaml

  sed -i "26s/.*/        option dns '${lan_addr}:${adguard_port}'/" /etc/config/network
  sed -i "16s/.*/        list server '${lan_addr}#${adguard_port}'/" /etc/config/dhcp

  uci commit network
  uci commit dhcp

  # generating new rsa keys
  rm /etc/dropbear/dropbear_rsa_host_key
  rm /etc/dropbear/dropbear_ed25519_host_key
  dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
  dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key
  chown root:root /etc/dropbear/dropbear_rsa_host_key
  chown root:root /etc/dropbear/dropbear_ed25519_host_key
  chmod 600 /etc/dropbear/dropbear_rsa_host_key
  chmod 600 /etc/dropbear/dropbear_ed25519_host_key

  cat <<EOF > /etc/config/dropbear
config dropbear
        option PasswordAuth 'off'
        option RootPasswordAuth 'off'
        option Port '2202'
#       option BannerFile   '/etc/banner'
        option interface 'br-lan'
EOF


  wget -O /etc/dropbear/authorized_keys ${pastebin_pub_key} # public key for ssh
  ## ADD CHECK FOR FAIL (CAUSE IF NO KEY YOU WONT BE ABLE TO SSH...)

  uci commit dropbear

  echo "Do you want to download adapter.sh? (y/n)"
  read -r ques
if [[ ${ques}=="y" ]]; then
  cd ~
  wget https://raw.githubusercontent.com/CameronS2005/rpi3-openwrt/main/adapter.sh
fi

  rm /root/setup.sh

  echo "FINISHED!"

  read -p "Press Enter To Reboot! (Run adapter-setup.sh to set up access point)"

  reboot
fi
