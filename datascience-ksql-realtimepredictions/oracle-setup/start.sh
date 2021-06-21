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

# initiate PostgreSQL
#printf "\n\n================================================================================\n"
#printf "Preparing PostgreSQL DB...\n"
#printf "================================================================================\n\n"
#printf "Creating 3 tables, inserting merchants (70086 rows), cardholders (44335 rows) and transactions (254326 + 72781 rows)...\n\n"; \
#docker exec postgres /bin/bash -c "export PGPASSWORD=mysecretpassword; \
#  psql -U postgres -f /tmp/init/init.sql; \
#  psql -U postgres -f /tmp/init/merchants.sql; \
#  psql -U postgres -f /tmp/init/cardholders.sql; \
#  psql -U postgres -f /tmp/init/transactions_known.sql; \
#  psql -U postgres -f /tmp/init/transactions_unknown.sql"

# initiate Oracle DB
printf "\n\n================================================================================\n"
printf "Preparing Oracle DB...\n"
printf "================================================================================\n\n"
printf "Give database 2 minutes\n\n"; 
sleep 120
printf "Creating 3 tables, inserting merchants (70086 rows), cardholders (44335 rows) and transactions (70000 rows)...\n\n"; \
docker exec oradb122 /bin/bash -c "/u01/app/oracle/product/12.2.0/dbhome_1/bin/sqlplus /nolog  @/tmp/scripts/00_setup_DB.sql"

printf "\n\n================================================================================\n"
printf "Please execute manually in a second terminal windows...\n"
cat oracle/01_db_logging.sql
printf "================================================================================\n\n"
read


# Oracle CDC Source connectors
printf "\n\n================================================================================\n"
printf "Creating Oracle CDC source connectors...\n"
printf "================================================================================\n\n"
docker cp ksql-connect-source-cdc-oracle.sql ksqldb-server:/tmp/cmd.sql
docker-compose exec -T  ksqldb-server ksql http://localhost:8088 <<EOF
run script '/tmp/cmd.sql';
exit ;
EOF
# docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"
printf "================================================================================\n\n"
printf "Give cdc connector database 10 minutes\n\n"; 
sleep 600

# Source PostGRES connectors
#printf "\n\n================================================================================\n"
#printf "Creating source connectors...\n"
#printf "================================================================================\n\n"
#docker cp ksql-connect-source.sql ksqldb-server:/tmp/cmd.sql
#docker-compose exec -T  ksqldb-server ksql http://localhost:8088 <<EOF
#run script '/tmp/cmd.sql';
#exit ;
#EOF
## docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

sleep 10

# KSQL queries
printf "\n\n================================================================================\n"
printf "Running KSQL queries...\n"
printf "================================================================================\n\n"
docker cp ksql-queries.sql ksqldb-server:/tmp/cmd.sql
docker-compose exec -T  ksqldb-server ksql http://localhost:8088 <<EOF
run script '/tmp/cmd.sql';
exit ;
EOF
#docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

sleep 10

# Sink connectors
printf "\n\n================================================================================\n"
printf "Creating sink connectors...\n"
printf "================================================================================\n\n"
docker cp ksql-connect-sink.sql ksqldb-server:/tmp/cmd.sql
docker-compose exec -T  ksqldb-server ksql http://localhost:8088 <<EOF
run script '/tmp/cmd.sql';
exit ;
EOF
#docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

# Dataiku API node
printf "\n\n================================================================================\n"
printf "Preparing Dataiku API node...\n"
printf "================================================================================\n\n"
docker cp fraud_prediction_v1.zip dataiku-dss:/tmp/fraud_prediction_v1.zip
docker exec -it dataiku-dss bash -c "/home/dataiku/dataiku-dss-8.0.2/installer.sh -t api -d /home/dataiku/api -p 8888 -l /home/dataiku/dss/config/license.json; \
  /home/dataiku/api/bin/dss start; \
  /home/dataiku/api/bin/apinode-admin service-create fraud_prediction; \
  /home/dataiku/api/bin/apinode-admin service-import-generation fraud_prediction /tmp/fraud_prediction_v1.zip; \
  /home/dataiku/api/bin/apinode-admin service-switch-to-newest fraud_prediction"

# KSQL queries part 2
printf "\n\n================================================================================\n"
printf "Running KSQL queries (using ML models)...\n"
printf "================================================================================\n\n"
docker cp ksql-queries2.sql ksqldb-server:/tmp/cmd.sql
docker-compose exec -T  ksqldb-server ksql http://localhost:8088 <<EOF
run script '/tmp/cmd.sql';
exit ;
EOF
#docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

printf "\n\n================================================================================\n"
printf "Done! Access UI at:\n"
printf "Control Center : localhost:9021\n"
printf "Dataiku DSS    : localhost:10000\n"
printf "   Dataiku username: admin\n"
printf "   Dataiku password: admin\n"
printf "================================================================================\n\n"
