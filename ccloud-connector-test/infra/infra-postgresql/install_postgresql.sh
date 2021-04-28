#! /bin/bash

sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get install postgresql postgresql-contrib

# allow external access
sudo sh -c 'echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/12/main/pg_hba.conf'
sudo sh -c 'echo "listen_addresses='"'"'*'"'"'" >> /etc/postgresql/12/main/postgresql.conf'
sudo sh -c 'echo "wal_level=logical" >> /etc/postgresql/12/main/postgresql.conf'

sudo /etc/init.d/postgresql restart

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'password';"

sudo -u postgres psql -c "CREATE DATABASE testdb;"
sudo -u postgres psql -d testdb -c "create table test (id int, code int);"
sudo -u postgres psql -d testdb -c "insert into test values (1, 101);"
sudo -u postgres psql -d testdb -c "insert into test values (2, 201);"
sudo -u postgres psql -d testdb -c "insert into test values (3, 301);"
