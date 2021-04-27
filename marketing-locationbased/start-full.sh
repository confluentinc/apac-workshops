#!/bin/sh
INTERACTIVE=Y

docker-compose up -d

# wait for ksqlDB to be ready to serve requests
printf "\n\nWaiting for ksqlDB to be available...\n";
while [ $(curl -s -o /dev/null -w %{http_code} http://localhost:8088/) -eq 000 ]
do
  printf "ksqlDB Server HTTP state: "
  printf $(curl -s -o /dev/null -w %{http_code} http://localhost:8088/)
  printf " (waiting for 200)\n"
  sleep 5
done
while [ $(curl -s http://localhost:8088/info | jq -r ".KsqlServerInfo.serverStatus") != "RUNNING" ] ;
do
  printf "ksqlDB Server Status: "
  printf $(curl -s http://localhost:8088/info | jq -r ".KsqlServerInfo.serverStatus")
  printf " (waiting for RUNNING)\n" ;
  sleep 5 ;
done

# create and populate user and locations table
# 10 users with userid 1-10 inclusive
# 1 location (Bonifacio-West), two others will be added during the demo
printf "\n\n================================================================================\n"
printf "Configuring MySQL, creating and populating users and locations tables...\n"
printf "================================================================================\n\n"
cat mysql-init.sql
docker cp mysql-init.sql mysql:/tmp/cmd.sql
docker exec -it mysql /bin/bash -c "mysql -u root -pmysql-pw < /tmp/cmd.sql"

# create CDC connector and datagen connector
# Datagen generates userid between 1-10 inclusive and locations (lat, long) within
# (14.546734278498768, 121.04761980788055) and (14.554372672056836, 121.0545504237969)
printf "\n\n================================================================================\n"
printf "Creating Debezium CDC and datagen source connectors...\n"
printf "================================================================================\n\n"
docker cp ksql-init.sql ksqldb-server:/tmp/cmd.sql
docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

# wait for topics to be created and schema available
printf "\n\nWaiting for topic creation...\n";
while [ $(curl -s -o /dev/null -w %{http_code} http://localhost:8081/subjects/user_locations_raw-key/versions) -eq 000 ]
do
  printf "Schema Registry HTTP state: "
  printf $(curl -s -o /dev/null -w %{http_code} http://localhost:8081/subjects/user_locations_raw-key/versions)
  printf " (waiting for 200)\n"
  sleep 5
done

# run ksqlDB queries
printf "\n\n================================================================================\n"
printf "Running ksqlDB queries...\n"
printf "================================================================================\n\n"
docker cp ksql-statements.sql ksqldb-server:/tmp/cmd.sql
docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"
