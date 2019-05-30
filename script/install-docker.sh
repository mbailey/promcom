#!/bin/bash

# Install docker on Amazon Linux 2

# https://gist.github.com/npearce/6f3c7826c7499587f00957fee62f8ee9

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

yum update -y
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user

chkconfig docker on

yum install -y git

curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose



