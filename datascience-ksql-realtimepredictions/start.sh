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
printf "\n\n================================================================================\n"
printf "Preparing PostgreSQL DB...\n"
printf "================================================================================\n\n"
printf "Creating 3 tables, inserting merchants (70086 rows), cardholders (44335 rows) and transactions (254326 + 72781 rows)...\n\n"; \
docker exec postgres /bin/bash -c "export PGPASSWORD=mysecretpassword; \
  psql -U postgres -f /tmp/init/init.sql; \
  psql -U postgres -f /tmp/init/merchants.sql; \
  psql -U postgres -f /tmp/init/cardholders.sql; \
  psql -U postgres -f /tmp/init/transactions_known.sql; \
  psql -U postgres -f /tmp/init/transactions_unknown.sql"

# Source connectors
printf "\n\n================================================================================\n"
printf "Creating source connectors...\n"
printf "================================================================================\n\n"
docker cp ksql-connect-source.sql ksqldb-server:/tmp/cmd.sql
docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

sleep 10

# KSQL Queries
printf "\n\n================================================================================\n"
printf "Running KSQL queries...\n"
printf "================================================================================\n\n"
docker cp ksql-queries.sql ksqldb-server:/tmp/cmd.sql
docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

sleep 10

# Sink connectors
printf "\n\n================================================================================\n"
printf "Creating sink connectors...\n"
printf "================================================================================\n\n"
docker cp ksql-connect-sink.sql ksqldb-server:/tmp/cmd.sql
docker exec -it ksqldb-server bash -c "ksql http://ksqldb-server:8088 < /tmp/cmd.sql"

printf "\n\n================================================================================\n"
printf "Done! Access UI at:\n"
printf "Control Center : localhost:9021\n"
printf "Dataiku DSS    : localhost:10000\n"
printf "** Remember to start the API endpoint for fraud_demo project in API Designer **\n"
printf "   API Designer URL: http://localhost:10000/projects/FRAUD_DEMO/api-designer/fraud_prediction/endpoints/\n"
printf "   Dataiku username: admin\n"
printf "   Dataiku password: admin\n"
printf "================================================================================\n\n"
