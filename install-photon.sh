#!/bin/bash

if [ -z "$DOCKER_USE_DIR" ]; then
    DOCKER_USE_DIR="/opt/container"
fi

if [ -z $1 ]; then
    echo "You must specify the user to create in photon"
    echo "usage: install-photon.sh <username>"
    exit 1
fi
username=$1

if [ -z $2 ]; then
    echo "You must specify the public key for the new user"
    echo "even as string or URL"
    exit 1
fi
if [[ $2 == http* ]]; then
    pubkey=`curl -s $2`
else
    pubkey="$2"
fi


tdnf update -y
tdnf install -y nano lsof rsync diffutils

# set Europe/Berlin timezone - https://www.elasticsky.de/2019/10/zeitzone-in-photon-os-einstellen/
set Europe/Berline timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# create new os user
useradd -m -G sudo $username
usermod -a -G docker $username

echo -e “\nsemjon ALL= NOPASSWD:/usr/bin/rsync“ >> /etc/sudoers

mkdir /home/$username/.ssh
echo "$pubkey" > /home/$username/.ssh/authorized_keys
chown -R $username:users /home/$username/.ssh
chmod 750 /home/$username/.ssh
chmod 640 /home/$username/.ssh/authorized_keys

systemctl start docker

curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chown root:users /usr/local/bin/docker-compose
chmod 770 /usr/local/bin/docker-compose


sed -i 's/^PermitRootLogin .*/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/^UsePAM .*/UsePAM no/g' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication no/g' /etc/ssh/sshd_config

systemctl start sshd

echo "Installation completed"
echo
echo "Before logout from actual session try ssh login with user $username"
echo

