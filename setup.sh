#!/usr/bin/env bash

# Setup HomeServer on Xubuntu 20.04

# Setup Mount Points
mkdir /media/adrian
mkdir /media/adrian/ssd
mkdir /media/adrian/ext-hdd
# prevent access to unmounted mount points: https://serverfault.com/questions/313994/how-to-prevent-access-to-unmounted-mount-point
sudo chattr +i /media/adrian/ssd
sudo chattr +i /media/adrian/ext-hdd

# Install Disks & GParted
sudo apt install gnome-disk-utility gparted -y

# Install xrdp
sudo apt install xfce4 xfce4-goodies -y
sudo apt install xrdp -y

# Install SSH
sudo apt install openssh-server -y

# Install Printer Support
sudo apt install system-config-printer -y

# Install Scanner Support
sudo apt install xsane -y
sudo apt install simple-scan -y

# Install HP Printer and Scanner drivers
cd ~/Downloads || echo "Error cd-ing into user Downloads folder" && exit
wget "https://ftp.hp.com/pub/softlib/software13/printers/SS/SL-M4580FX/uld_V1.00.39_01.17.tar.gz"
tar xf uld_V1.00.39_01.17.tar.gz
sudo sed -i '/^show_license/ s/$/ \n return/' ~/Downloads/uld/noarch/pre_install.sh
sudo ./uld/install.sh

# Disable sleep on lid close
sudo tee -a /etc/systemd/logind.conf > /dev/null <<EOT

HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOT

systemctl restart systemd-logind

# Configure max battery charge at 60-80%
sudo add-apt-repository ppa:linrunner/tlp -y
sudo apt update
sudo apt install tlp tlp-rdw -y
sudo systemctl enable tlp.service

sudo tee -a /etc/tlp.conf > /dev/null <<EOT

STOP_CHARGE_THRESH_BAT0=1
EOT

sudo systemctl restart tlp

#########
# Install Backup Software
# Install Kopia - not needed currently
#sudo curl -s https://kopia.io/signing-key | sudo gpg --dearmor -o /usr/share/keyrings/kopia-keyring.gpg
#echo "deb [signed-by=/usr/share/keyrings/kopia-keyring.gpg] http://packages.kopia.io/apt/ stable main" | sudo tee /etc/apt/sources.list.d/kopia.list
#sudo apt update
#sudo apt install kopia -y
# Set Kopia to be able to read all system files even without root
#sudo setcap cap_dac_read_search=+ep /usr/bin/kopia
#sudo tee -a /etc/crontab > /dev/null <<EOT
#
#@reboot setcap cap_dac_read_search=+ep /usr/bin/kopia
#@reboot /usr/bin/kopia server start --insecure --without-password
#EOT


# Install rsync
sudo apt install rsync

mkdir /media/adrian/ssd/system-backup/
mkdir /media/adrian/ext-hdd/ssd-backup/

# Setup a daily full system backup using rsync based on https://wiki.archlinux.org/title/Rsync#Full_system_backup
sudo tee -a /etc/crontab > /dev/null <<EOT

0 1 * * * root rsync -aAXHv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} / /media/adrian/ssd/system-backup/
0 2 * * * root rsync -aAXHv /media/adrian/ssd/ /media/adrian/ext-hdd/ssd-backup/
EOT
#########

# Install Docker
sudo apt install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Install Portainer

# Install DynDNS - not needed as using ISP Dynamic DNS

# Install Printer / Scanner stuff

# Install FTP Server
sudo apt install vsftpd -y
sudo systemctl enable vsftpd
mkdir /media/adrian/ssd/ftp
sudo sed -i 's/#write_enable=NO/write_enable=YES/g' /etc/vsftpd.conf
sudo tee -a /etc/vsftpd.conf > /dev/null <<EOT

allow_writeable_chroot=YES
chroot_local_user=YES
local_root=/media/adrian/ssd/ftp
EOT
sudo systemctl restart vsftpd.service

# Install Certbot
#sudo snap install core; sudo snap refresh core
#sudo apt-get remove certbot
#sudo snap install --classic certbot
#sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Install OwnCloud Infinite Scale
cd /media/adrian/ssd/ || echo 'OwnCloud SSD root not found'; exit
mkdir -p $PWD/ocis/ocis-config
mkdir -p $PWD/ocis/ocis-data
sudo chown -Rfv 1000:1000 $PWD/ocis/

docker run --rm -it \
    --mount type=bind,source=$PWD/ocis/ocis-config,target=/etc/ocis \
    owncloud/ocis init

docker run \
    --name ocis_runtime \
    -d --restart always \
    -it \
    -p 9200:9200 \
    --mount type=bind,source=$PWD/ocis/ocis-config,target=/etc/ocis \
    --mount type=bind,source=$PWD/ocis/ocis-data,target=/var/lib/ocis \
    -e OCIS_INSECURE=true \
    -e PROXY_HTTP_ADDR=0.0.0.0:9200 \
    -e OCIS_URL=https://$HOSTNAME:9200 \
    owncloud/ocis

# Install NFS Server
sudo apt install nfs-kernel-server -y
sudo tee -a /etc/exports > /dev/null <<EOT

/media/adrian/ 192.168.1.0/24(rw,nohide,no_subtree_check,crossmnt,nohide)
EOT
sudo exportfs -arv
sudo systemctl restart nfs-kernel-server

# Install Samba
#sudo apt install samba -y
#sudo smbpasswd -a adrian
#sudo tee -a /etc/samba/smb.conf > /dev/null <<EOT
#
#[homeserver]
#    path = /media/adrian/ssd
#    writeable = no
#    browseable = yes
#    read only = yes
#    guest ok = yes
#EOT
#cat << EOF | sudo sed -i '/^\[global\]$/ r /dev/stdin' /etc/samba/smb.conf
#client min protocol = SMB2
#client max protocol = SMB3
#protocol = SMB3
#client ntlmv2 auth = yes
#EOF
#sudo systemctl restart smbd
