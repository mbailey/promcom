#!/bin/bash

# install docker on Amazon Linux 2

# https://gist.github.com/npearce/6f3c7826c7499587f00957fee62f8ee9

sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo chkconfig docker on

sudo yum install -y git

sudo curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose



