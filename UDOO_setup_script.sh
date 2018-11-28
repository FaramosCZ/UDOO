# ---------------------------------------------------------
# Prepare the system
dnf update
dnf --comment="Basic software" install \
nano mc tree openssh wget curl bash-completion tar gcc gdb git fedora-repos-rawhide policycoreutils-python-utils lynx psmisc


# ---------------------------------------------------------
# Enable SSHD
systemctl status sshd
systemctl enable sshd && systemctl start sshd

# Set ssh key authentification from guest to host
# ssh-copy-id <user>@<machine>


# ---------------------------------------------------------
# Customize login screen message - show IP adresses
echo -e "\
IP LAN: \4{enp2s0}
IP WIFI: \4{wlp3s0} (default wifi password: \"password\")
" > /etc/issue


# ---------------------------------------------------------
# Wi-Fi
dnf --comment="nmcli, wifi" install NetworkManager-wifi dnsmasq

#   # dmesg | grep iwlwifi -> iwlwifi 0000:03:00.0: Direct firmware load for iwlwifi-3168-23.ucode failed with error -2
#   https://www.intel.com/content/www/us/en/wireless-products/dual-band-wireless-ac-3168-brief.html
#   https://www.intel.com/content/www/us/en/support/articles/000005511/network-and-i-o/wireless-networking.html
#   https://wireless.wiki.kernel.org/_media/en/users/drivers/iwlwifi-3168-ucode-22.361476.0.tgz
#   README, /lib/firmware
cd /tmp && wget https://wireless.wiki.kernel.org/_media/en/users/drivers/iwlwifi-3168-ucode-22.361476.0.tgz && tar -xof iwlwifi-3168-ucode-22.361476.0.tgz && cp iwlwifi-3168-ucode-22.361476.0/iwlwifi-3168-22.ucode /lib/firmware

# !! REBOOT !!
reboot
# !! REBOOT !!

nmcli con add type wifi ifname wlp3s0 con-name UDOO-Hotspot autoconnect yes ssid UDOO-Hotspot
nmcli con modify UDOO-Hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli con modify UDOO-Hotspot wifi-sec.key-mgmt wpa-psk
nmcli con modify UDOO-Hotspot wifi-sec.psk "password"
nmcli connection modify UDOO-Hotspot connection.autoconnect-priority 1
nmcli con up UDOO-Hotspot
nmcli con down UDOO-Hotspot


# ---------------------------------------------------------
# Setup user accounts
useradd -m faramos && passwd faramos
useradd -m hemmond && passwd hemmond
useradd -m hvezdna_lod && passwd hvezdna_lod


# ---------------------------------------------------------
# IRC server

# Set firewall
firewall-cmd --add-port=6667/tcp
firewall-cmd --runtime-to-permanent

# Prepare the IRC server
dnf --comment="IRC server" install ngircd

# Configure the server in /etc/ngircd.conf; download the config file
# fix permissions and owner / group of the config file
chmod a-rwx /etc/ngircd.conf
chmod ug+rw /etc/ngircd.conf
chown root:ngircd /etc/ngircd.conf

# Start the server
systemctl enable ngircd && systemctl start ngircd


# ---------------------------------------------------------
# IRC client with a log bot
dnf --comment="IRC client" install weechat screen tmux

# Tweak the ngircd user
mkdir /home/ngircd && chown ngircd:ngircd /home/ngircd/
sed -i -E "s|^(ngircd:.*)/tmp/:/sbin/nologin|\1/home/ngircd:/bin/bash|" /etc/passwd

# Configure the wechat client for ngircd user
su -c "weechat" ngircd 
#	/server add memory.alpha localhost
#	/connect memory.alpha
#	/set irc.server.memory.alpha.autoconnect on
#	/set irc.server.memory.alpha.nicks "bot_log,bot,bot_ngircd"
#	/set irc.server.memory.alpha.autojoin "#byt,#hvezdna_lod,#pokec"
#   /quit

# Prepare custom systemd service, so the log bot will be started automaticaly after the IRC server
# Edit "/usr/lib/systemd/system/ngircd.service", add:
#	Wants=weechat_client.service
#	Before=weechat_client.service

# Copy "weechat_client.service" to the "/usr/lib/systemd/system/"
systemctl daemon-reload

# Prepare and apply SELinux policy (prepared in POLICY); search for "/var/log/audit/audit.log"

setenforce 0
systemctl start weechat_client
systemctl status weechat_client
systemctl stop weechat_client
setenforce 1
audit2allow -a
audit2allow -a -M weechat_client
semodule -i weechat_client.pp

# Test the service
systemctl start weechat_client
systemctl status weechat_client


# ---------------------------------------------------------
# Install VLC
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install vlc

# use in terminal with:
# vlc -I ncurses

# ---------------------------------------------------------
# Aliases
# copy file to alias.sh  to  /etc/profile.d/alias.sh
cp alias.sh /etc/profile.d/alias.sh

