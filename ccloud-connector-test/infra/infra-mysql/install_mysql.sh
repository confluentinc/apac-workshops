#! /bin/bash

sudo yum -y install mariadb-server mariadb-libs mariadb mariabackup

# enable logging
sudo sh -c 'echo "log-bin=mysql-bin.log" >> /etc/my.cnf.d/server.cnf'
sudo sh -c 'echo "binlog_format=ROW" >> /etc/my.cnf.d/server.cnf'
sudo sh -c 'echo "server-id=1" >> /etc/my.cnf.d/server.cnf'

service mariadb start

echo $'GRANT ALL PRIVILEGES ON *.* TO \'root\'@\'%\' IDENTIFIED BY \'password\';' | sudo mysql

echo $'FLUSH PRIVILEGES;' | sudo mysql

echo $'create database employee;' | sudo mysql

echo $'use employee; create table departments (id int, code int); insert into departments values (1, 101); insert into departments values (1, 201); commit;' | sudo mysql
