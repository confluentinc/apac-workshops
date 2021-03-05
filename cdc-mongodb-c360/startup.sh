export DOCKERHOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)

export TNS_ADMIN=/opt/Oracle/product/12.2.0.1.0/instantclient/network/admin

docker-compose up -d

sleep 120

docker logs connect-1

sleep 5

docker logs connect-2

sleep 30

if [ $1 == "oracle" ] || [ $2 == "oracle" ]
then
    echo "Creating c360 db..."
    cat c360_tables_oracle.sql | sqlplus C##myuser/mypassword@ORCLCDB

    echo "Creating Oracle CDC Source Connector"

    curl -X PUT \
        -H "Content-Type: application/json" \
        --data '{
            "name": "oracle-cdc-source",
            "connector.class": "io.confluent.connect.oracle.cdc.OracleCdcSourceConnector",

            "tasks.max":1,
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "key.converter.schema.registry.url": "http://schema-registry:8081",
            "value.converter": "io.confluent.connect.avro.AvroConverter",
            "value.converter.schema.registry.url": "http://schema-registry:8081",
            "confluent.license": "",
            "confluent.topic.bootstrap.servers": "broker:9092",
            "confluent.topic.replication.factor": "1",

            "oracle.server": "oracle",
            "oracle.port": 1521,
            "oracle.sid": "ORCLCDB",
            "oracle.username": "C##myuser",
            "oracle.password": "mypassword",
            "redo.log.topic.name": "oracle-redo-log-topic",
            "redo.log.consumer.bootstrap.servers":"broker:9092",
            "table.inclusion.regex": ".*CUST.*",
            "table.topic.name.template": "${databaseName}.${schemaName}.${tableName}",
            "connection.pool.max.size": 20,
            "confluent.topic.replication.factor":1,
            "redo.log.row.fetch.size":1,
            "snapshot.row.fetch.size":1,
            "start.from":"snapshot",
            "numeric.mapping":"best_fit",

            "topic.creation.enable": true,
            "topic.creation.groups": "redo",
            "topic.creation.redo.include": "oracle-redo-log-topic",
            "topic.creation.redo.replication.factor": 1,
            "topic.creation.redo.partitions": 1,
            "topic.creation.redo.cleanup.policy": "delete",
            "topic.creation.redo.retention.ms": 1209600000,
            "topic.creation.default.replication.factor": 1,
            "topic.creation.default.partitions": 1,
            "topic.creation.default.cleanup.policy": "compact"
        }' \
    http://localhost:8083/connectors/oracle-cdc-source/config | jq .
fi

sleep 60

docker exec -it ksqldb-cli bash -c 'cat /data/scripts/c360_ksql.sql | ksql http://ksqldb-server:8088'

sleep 10

log "Initialize MongoDB replica set"
docker exec -i mongodb mongo --eval 'rs.initiate({_id: "myuser", members:[{_id: 0, host: "mongodb:27017"}]})'

sleep 5

log "Create a user profile"
docker exec -i mongodb mongo << EOF
use admin
db.createUser(
{
user: "myuser",
pwd: "mypassword",
roles: ["dbOwner"]
}
)
EOF

sleep 5

echo "Creating MongoDB Sink Connector"

curl -X PUT \
    -H "Content-Type: application/json" \
    --data '{
        "name": "mongodb-sink",
        "connector.class" : "com.mongodb.kafka.connect.MongoSinkConnector",

        "tasks.max": "1",
        "key.converter": "org.apache.kafka.connect.storage.StringConverter",
        "key.converter.schema.registry.url": "http://schema-registry:8081",
        "value.converter": "io.confluent.connect.avro.AvroConverter",
        "value.converter.schema.registry.url": "http://schema-registry:8081",
        "confluent.topic.bootstrap.servers": "broker:9092",
        "confluent.topic.replication.factor":1,

        "connection.uri" : "mongodb://myuser:mypassword@mongodb:27017",
        "database":"accounts",
        "collection":"customers",
        "topics":"ACCOUNT_MASTER_STREAM"
    }' \
http://localhost:8084/connectors/mongodb-sink/config | jq .

docker logs connect-2

sleep 5

echo "Starting up Flask app"

nohup python3 c360_flask.py &

sleep 5

echo "Flask app querying MongoDB..."

curl -X GET http://localhost:5000/getaccountmaster

sleep 5

pkill -f c360_flask.py
rm nohup.out