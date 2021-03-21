#! /bin/bash

sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo chkconfig docker on
sudo yum install -y git

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sleep 10

cd /home/ec2-user

git clone https://github.com/confluentinc/apac-workshops.git

cp -r apac-workshops/ccloud-workshop .

rm -r apac-workshops

cd ccloud-workshop

cp -r notebooks notebooks-1
cp -r notebooks notebooks-2
cp -r notebooks notebooks-3
cp -r notebooks notebooks-4
cp -r notebooks notebooks-5
cp -r notebooks notebooks-6

rm -r notebooks

chmod 700 infra/get-participants-lab-tokens.sh

docker-compose up -d
