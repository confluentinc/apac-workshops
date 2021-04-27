#!/bin/sh
INTERACTIVE=Y

# add rows to locations table
cat <<EOF >/tmp/cmd.sql
USE user-data\
;INSERT INTO locations (latitude, longitude, description, area) VALUES ("14.54733288", "121.05161762", "7-Eleven South of Market", "Bonifacio-South")\
;INSERT INTO locations (latitude, longitude, description, area) VALUES ("14.55296667", "121.05167165", "Lawson Eco Tower", "Bonifacio-North")\
;
EOF
printf "\n\n================================================================================\n"
printf "Adding rows to locations table...\n"
printf "================================================================================\n\n"
cat /tmp/cmd.sql
docker cp /tmp/cmd.sql mysql:/tmp/cmd.sql
docker exec -it mysql /bin/bash -c "mysql -u root -pmysql-pw < /tmp/cmd.sql"

printf "\n\n================================================================================\n"
printf "Updating ksqlDB queries...\n"
printf "================================================================================\n\n"
# update running queries
docker cp ksql-statements-2.sql ksqldb-server:/tmp/cmd.sql
docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"
