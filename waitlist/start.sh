#!/bin/sh

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

# create streams and queries, populate patients table
printf "\n\n================================================================================\n"
printf "Preparing streams and tables...\n"
printf "================================================================================\n\n"
docker cp ksql-statements.sql ksqldb-server:/tmp/cmd.sql
docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

# RUN THESE IN SEPARATE WINDOWS
# docker exec -it ksqldb-server ksql
# set 'auto.offset.reset'='earliest';
# select * from waitlist emit changes;
# select * from cancellations_final emit changes;
# select * from waitlist_notifications emit changes;
