#!/usr/bin/env bash

## update system and install seLinux tools
sudo yum update -y
sudo yum install -y policycoreutils-python selinux-policy-devel jq

# ## Install the SELinux Tools -- install RPMS without dependancies, in order to get around cyclic dependancies
cd ~
wget https://rpmfind.net/linux/centos/7.7.1908/os/x86_64/Packages/setroubleshoot-server-3.2.30-7.el7.x86_64.rpm
wget https://rpmfind.net/linux/centos/7.7.1908/os/x86_64/Packages/setroubleshoot-plugins-3.0.67-4.el7.noarch.rpm
sudo rpm -i  --nodeps setroubleshoot-server-3.2.30-7.el7.x86_64.rpm
sudo rpm -i  --nodeps setroubleshoot-plugins-3.0.67-4.el7.noarch.rpm
#Then yum re-install to include dependancies
sudo yum reinstall -y setroubleshoot-server-3.2.30-7.el7.x86_64.rpm
sudo yum reinstall -y setroubleshoot-plugins-3.0.67-4.el7.noarch.rpm

## Installing the Container-SELinux Policy
sudo yum install -y http://vault.centos.org/7.6.1810/extras/x86_64/Packages/container-selinux-2.68-1.el7.noarch.rpm

## Update SELinux Config Files
sudo sed -i 's/SELINUX=disabled/SELINUX=enforcing/g' /etc/selinux/config

## updating the docker runtime config
VAL=$(cat /etc/docker/daemon.json)
sudo mv /etc/docker/daemon.json /etc/docker/daemon.json_bak
echo $VAL | jq '. += {"selinux-enabled":true}' | sudo tee -a /etc/docker/daemon.json

## Restart system
sudo reboot
