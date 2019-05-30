#!/bin/bash

# Install docker on Amazon Linux 2

# https://gist.github.com/npearce/6f3c7826c7499587f00957fee62f8ee9

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

yum update -y
amazon-linux-extras install docker
usermod -a -G docker ec2-user
systemctl enable docker
systemctl start docker

yum install -y git

curl --retry 120 --retry-delay 1 --location "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
