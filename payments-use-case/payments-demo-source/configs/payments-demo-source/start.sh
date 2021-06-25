docker-compose -f docker-compose.yml up -d

# Start Data Sources
echo "=============== Starting data sources ==================="

# Verify MySQL has started within MAX_WAIT seconds
MAX_WAIT=900
CUR_WAIT=0
echo "Waiting up to $MAX_WAIT seconds for MySQL to start"
docker container logs mysql > /tmp/out.txt 2>&1
while [[ ! $(cat /tmp/out.txt) =~ "ready for connections" ]]; do
sleep 10
docker container logs mysql > /tmp/out.txt 2>&1
CUR_WAIT=$(( CUR_WAIT+10 ))
if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
     echo "ERROR: Did not manage to start."
     exit 1
fi
done
rm /tmp/out.txt
echo "MySQL has started!"

# Verify RabbitMQ has started within MAX_WAIT seconds
MAX_WAIT=900
CUR_WAIT=0
echo "Waiting up to $MAX_WAIT seconds for RabbitMQ to start"
docker container logs rabbitmq > /tmp/out.txt 2>&1
while [[ ! $(cat /tmp/out.txt) =~ "Ready to start client connection listeners" ]]; do
sleep 10
docker container logs rabbitmq > /tmp/out.txt 2>&1
CUR_WAIT=$(( CUR_WAIT+10 ))
if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
     echo "ERROR: Did not manage to start."
     exit 1
fi
done
rm /tmp/out.txt
echo "RabbitMQ has started!"

# Verify sftp has started within MAX_WAIT seconds
MAX_WAIT=900
CUR_WAIT=0
echo "Waiting up to $MAX_WAIT seconds for sftp to start"
docker container logs sftp > /tmp/out.txt 2>&1
while [[ ! $(cat /tmp/out.txt) =~ "Server listening on" ]]; do
sleep 10
docker container logs sftp > /tmp/out.txt 2>&1
CUR_WAIT=$(( CUR_WAIT+10 ))
if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
     echo "ERROR: Did not manage to start."
     exit 1
fi
done
rm /tmp/out.txt
echo "sftp has started!"

# # Verify oracle has started within MAX_WAIT seconds
# MAX_WAIT=900
# CUR_WAIT=0
# echo "Waiting up to $MAX_WAIT seconds for oracle to start"
# docker container logs oracle > /tmp/out.txt 2>&1
# while [[ ! $(cat /tmp/out.txt) =~ "DATABASE IS READY TO USE!" ]]; do
# sleep 10
# docker container logs oracle > /tmp/out.txt 2>&1
# CUR_WAIT=$(( CUR_WAIT+10 ))
# if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
#      echo "ERROR: Did not manage to start."
#      exit 1
# fi
# done
# rm /tmp/out.txt
# echo "oracle has started!"

# Start Confluent Demo Server
echo "=============== Starting demo server ==================="
docker exec -it demo-server touch /tmp/go

# Verify connect has started within MAX_WAIT seconds
MAX_WAIT=900
CUR_WAIT=0
echo "Waiting up to $MAX_WAIT seconds for connect to start"
docker container logs connect > /tmp/out.txt 2>&1
while [[ ! $(cat /tmp/out.txt) =~ "Kafka Connect started" ]]; do
sleep 10
docker container logs connect > /tmp/out.txt 2>&1
CUR_WAIT=$(( CUR_WAIT+10 ))
if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
     echo "ERROR: Did not manage to start."
     exit 1
fi
done
rm /tmp/out.txt
echo "connect has started!"

sleep 15

# Populate sources
echo "=============== Populating data sources ==================="
curl http://localhost:3010/transit
curl http://localhost:3010/retail
curl http://localhost:3010/parking
curl http://localhost:3010/toll

# Create connectors
echo "=============== Creating connectors ==================="
curl -X POST -H "Content-Type: application/json" -d @../connectors/connector_mysql-cdc-source_config.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" -d @../connectors/connector_sftp-source_config.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" -d @../connectors/connector_rabbitmq-source_config.json http://localhost:8083/connectors

sleep 20

# KSQL Queries
echo "=============== Running KSQL queries ==================="
# Verify ksqldb-server has started within MAX_WAIT seconds
MAX_WAIT=900
CUR_WAIT=0
echo "Waiting up to $MAX_WAIT seconds for ksqldb-server to start"
docker container logs ksqldb-server > /tmp/out.txt 2>&1
while [[ ! $(cat /tmp/out.txt) =~ "Server up and running" ]]; do
sleep 10
docker container logs ksqldb-server > /tmp/out.txt 2>&1
CUR_WAIT=$(( CUR_WAIT+10 ))
if [[ "$CUR_WAIT" -gt "$MAX_WAIT" ]]; then
     echo "ERROR: Did not manage to start."
     exit 1
fi
done
rm /tmp/out.txt
echo "ksqldb-server has started!"

source ../ksql/queries.sh
docker exec ksqldb-cli /bin/bash -c 'echo "'"$offset $transit1"'" | ksql http://ksqldb-server:8088'
docker exec ksqldb-cli /bin/bash -c 'echo "'"$offset $transit2"'" | ksql http://ksqldb-server:8088'
docker exec ksqldb-cli /bin/bash -c 'echo "'"$offset $retail1"'" | ksql http://ksqldb-server:8088'
docker exec ksqldb-cli /bin/bash -c 'echo "'"$offset $retail2"'" | ksql http://ksqldb-server:8088'
docker exec ksqldb-cli /bin/bash -c 'echo "'"$offset $retail3"'" | ksql http://ksqldb-server:8088'

sleep 20

# Sink connectors
echo "=============== Starting sink connectors ==================="
curl -X POST -H "Content-Type: application/json" -d @../connectors/connector_postgres-sink-json_config.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" -d @../connectors/connector_postgres-sink-avro_config.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" -d @../connectors/connector_rabbitmq-sink_config.json http://localhost:8083/connectors
# Start Alerts microservice
# echo "=============== Starting Alerts microservice ==================="
# docker exec -it demo-alerts touch /tmp/go
