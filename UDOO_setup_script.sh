# ---------------------------------------------------------
# Prepare the system
dnf update -y --nogpgcheck
dnf --comment="Basic software" install  -y --nogpgcheck \
nano mc tree openssh wget curl bash-completion tar gcc gdb git fedora-repos-rawhide policycoreutils-python-utils lynx psmisc


# ---------------------------------------------------------
# Enable SSHD
systemctl status sshd --no-pager
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
dnf --comment="nmcli, wifi" install -y --nogpgcheck NetworkManager-wifi dnsmasq

#   # dmesg | grep iwlwifi -> iwlwifi 0000:03:00.0: Direct firmware load for iwlwifi-3168-23.ucode failed with error -2
#   https://www.intel.com/content/www/us/en/wireless-products/dual-band-wireless-ac-3168-brief.html
#   https://www.intel.com/content/www/us/en/support/articles/000005511/network-and-i-o/wireless-networking.html
#   https://wireless.wiki.kernel.org/_media/en/users/drivers/iwlwifi-3168-ucode-22.361476.0.tgz
#   README, /lib/firmware
cd /tmp && wget https://wireless.wiki.kernel.org/_media/en/users/drivers/iwlwifi-3168-ucode-22.361476.0.tgz && tar -xof iwlwifi-3168-ucode-22.361476.0.tgz && cp iwlwifi-3168-ucode-22.361476.0/iwlwifi-3168-22.ucode /lib/firmware

# !! REBOOT !!
reboot
# !! REBOOT !!

nmcli con add type wifi ifname wlp3s0 con-name UDOO-Hotspot autoconnect no ssid UDOO-Hotspot
nmcli con modify UDOO-Hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli con modify UDOO-Hotspot wifi-sec.key-mgmt wpa-psk
nmcli con modify UDOO-Hotspot wifi-sec.psk "password"
nmcli connection modify UDOO-Hotspot connection.autoconnect-priority 1
nmcli con up UDOO-Hotspot
nmcli con down UDOO-Hotspot


# ---------------------------------------------------------
# Setup user accounts
for I in faramos hemmond hvezdna_lod
do useradd -m $I && echo -e "$I\n$I" | passwd $I; done
usermod -c "Main account to run software for Hvězdná Loď events" hvezdna_lod

# ---------------------------------------------------------
# IRC server

# Set firewall
firewall-cmd --add-port=6667/tcp
firewall-cmd --runtime-to-permanent

# Prepare the IRC server
dnf --comment="IRC server" install -y --nogpgcheck ngircd

# Copy the config file to /etc/ngircd.conf
mv -f ngircd.conf /etc/ngircd.conf
# fix permissions and owner / group of the config file
chmod a-rwx /etc/ngircd.conf
chmod ug+rw /etc/ngircd.conf
chown root:ngircd /etc/ngircd.conf

# Start the server
systemctl enable ngircd && systemctl start ngircd


# ---------------------------------------------------------
# IRC client with a log bot
dnf --comment="IRC client" install -y --nogpgcheck weechat screen tmux

# Tweak the ngircd user
mkdir /home/ngircd && chown ngircd:ngircd /home/ngircd/
sed -i -E "s|^(ngircd:.*)/tmp/:/sbin/nologin|\1/home/ngircd:/bin/bash|" /etc/passwd
usermod -c "Account for both IRC server and IRC client with log bots" ngircd

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
#	  Wants=weechat_client.service
#	  Before=weechat_client.service

# Copy "weechat_client.service" to the "/usr/lib/systemd/system/"
cp weechat_client.service /usr/lib/systemd/system/
systemctl daemon-reload

# Prepare and apply SELinux policy (prepared in POLICY); search for "/var/log/audit/audit.log"

setenforce 0
systemctl start weechat_client
systemctl status weechat_client --no-pager
sleep 1
systemctl stop weechat_client
setenforce 1
audit2allow -a
audit2allow -a -M weechat_client
semodule -i weechat_client.pp

# Test the service
systemctl start weechat_client
systemctl status weechat_client --no-pager


# ---------------------------------------------------------
# Aliases
# copy file to alias.sh  to  /etc/profile.d/alias.sh
cp alias.sh /etc/profile.d/alias.sh


# ---------------------------------------------------------
# BTRFS
# First of all, prepare GRUB for rollbacks to snapshots
grub2-switch-to-blscfg
# create snapshot
btrfs subvolume create /BTRFS
btrfs subvolume snapshot / /BTRFS/fresh_setup

# TODO:
# for each snapshot we would eventually like to boot to, we need update /etc/fstab and change "subvol=root" to "subvol=root/BTRFS/<name_of_snapshot>"
# for each snaphsot then we need to create new grub entry with suffix "rootflags=subvol=root/BTRFS/<name_of_snapshot>" to the "options" setting (right after the "$kernelopts")
# Warning:
# As the kernel may change to new version, the entry may not be bootable anymore, since the "linux" and "initrd" images may change its verion number


# ---------------------------------------------------------
# Configure SUDO
groupadd UDOO_managers_accounts
groupadd UDOO_managed_accounts

usermod -a -G UDOO_managers_accounts faramos
usermod -a -G UDOO_managers_accounts hemmond

usermod -a -G UDOO_managed_accounts hvezdna_lod
#usermod -a -G UDOO_managed_accounts teamspeak
#usermod -a -G UDOO_managed_accounts mumble

echo -e \
"# https://www.sudo.ws/man/1.8.15/sudoers.man.html
Defaults:%UDOO_managers_accounts   timestamp_timeout=60, runas_default=hvezdna_lod, logfile=/var/log/sudolog_UDOO_managers_accounts
Defaults   log_input, log_output
Defaults   shell_noargs

%UDOO_managers_accounts   ALL=(%UDOO_managed_accounts)   ALL" \
> /etc/sudoers.d/UDOO


# ---------------------------------------------------------
# Install VLC
dnf install -y --nogpgcheck https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y --nogpgcheck vlc

# use in terminal with:
# vlc -I ncurses


