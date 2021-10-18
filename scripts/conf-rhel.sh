#!/bin/bash
set -euo pipefail

# ubuntu, yes this is for centos/rhel
USERNAME=ubuntu 

# Create user and immediately expire password to force a change on login
useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"
passwd --delete "${USERNAME}"
chage --lastday 0 "${USERNAME}"


# Create SSH directory for sudo user and move keys over
home_directory="$(eval echo ~${USERNAME})"
mkdir --parents "${home_directory}/.ssh"
cp /root/.ssh/authorized_keys "${home_directory}/.ssh"
chmod 0700 "${home_directory}/.ssh"
chmod 0600 "${home_directory}/.ssh/authorized_keys"
chown --recursive "${USERNAME}":"${USERNAME}" "${home_directory}/.ssh"

sleep 1

# Disable root SSH login with password
sed --in-place 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
if sshd -t -q; then systemctl restart sshd fi

sudo sh -c 'echo "* hard nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "* soft nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root hard nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root soft nofile 100000" >> /etc/security/limits.conf'

sleep 1

# SSH
sudo sed -i '/^TrustedUserCAKeys/d' /etc/ssh/sshd_config
sudo sed -i '/^AuthorizedPrincipalsFile/d' /etc/ssh/sshd_config
sudo tee -a /etc/ssh/sshd_config << EOF
TrustedUserCAKeys /etc/ssh/trusted
AuthorizedPrincipalsFile /etc/ssh/principals
EOF
sudo tee /etc/ssh/principals << EOF
emergency
EXAMPLE_ROLE_1
EXAMPLE_ROLE_2
EXAMPLE_ROLE_3
EOF
sudo tee /etc/ssh/trusted << EOF
ssh-rsa EXAMPLE_SSH_PUB_KEY_1
ssh-rsa EXAMPLE_SSH_PUB_KEY_2
EOF


sudo yum -y install ntp || true
sudo apt-get --assume-yes install ntp || true
sudo sed -i '/^server/d' /etc/ntp.conf
sudo tee -a /etc/ntp.conf << EOF
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
EOF
sudo systemctl restart ntp &> /dev/null || true
sudo systemctl restart ntpd &> /dev/null || true
sudo service ntp restart &> /dev/null || true
sudo service ntpd restart &> /dev/null || true
sudo restart ntp &> /dev/null || true
sudo restart ntpd &> /dev/null || true
ntpq -p


# f242a9db6a0ad1846de7b6d94d507915d14062660616a61ef7c808a76e4f1676
curl -L https://golang.org/dl/go1.17.2.linux-amd64.tar.gz | sudo tar -C /usr/local -xz
tee -a ~/.bashrc << EOF
export GOPATH=\$HOME/go
export PATH=/usr/local/go/bin:\$PATH
EOF
source ~/.bashrc


sudo yum -y install dkms kernel-devel kernel-uek-devel make gcc wget 

sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

sudo yum -y groupinstall "Workstation"
