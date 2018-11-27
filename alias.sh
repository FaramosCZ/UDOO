# User defined aliases

alias EDITOR='nano'
alias UAEDITOR='nano'
alias VISUAL='nano'

alias N='nano '

alias DNF_U='dnf update'
alias DNF_R='dnf remove '
alias DNF_I='dnf install '

alias TMP='cd /tmp'
alias BACKUP_THIS_DIRECTORY='cp -r ../ /var/tmp'

alias GB='git branch'
alias GBA='git branch -a'
alias GM='git merge'
alias GMM='git merge master'
alias GCH='git checkout'

alias L='ls -Alh'

alias SSS='systemctl status '
alias SST='systemctl start '
alias SSP='systemctl stop '

alias HELP='echo -e \
"
 # Set ssh key authentification from guest to host
 $ ssh-copy-id <user>@<machine>

 # Wi-Fi
 # Default password: \"password\"
 $ nmcli con modify UDOO-Hotspot wifi-sec.psk "password"
 $ nmcli con up UDOO-Hotspot
 $ nmcli con down UDOO-Hotspot

 # Set firewall
 firewall-cmd --add-port=6667/tcp
 firewall-cmd --runtime-to-permanent

 # Run VLC in terminal with:
 $ vlc -I ncurses
 # volume up / down with 'a' 'z'

 # Edit Aliases
 /etc/profile.d/alias.sh

 # Allow user to install software
 $ echo \"<user> ALL= NOPASSWD: /usr/bin/dnf\" >> /etc/sudoers.d/<username>

 # Useful commands for login track
 $ aureport -au -i
 $ last
 $ lastb
 $ lastlog


"
'
