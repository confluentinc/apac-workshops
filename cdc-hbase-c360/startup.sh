export DOCKERHOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)

export TNS_ADMIN=/opt/Oracle/product/12.2.0.1.0/instantclient/network/admin

docker-compose up -d

sleep 30

docker logs connect

sleep 30

if [ $1 == "sqlserver" ]
then
    echo "Creating c360 db..."
    cat c360_tables_sqlserver.sql | docker exec -i sqlserver bash -c '/opt/mssql-tools/bin/sqlcmd -U sa -P Password!'

    echo "Creating Debezium SQL Server Source Connector"

    curl -X PUT \
        -H "Content-Type: application/json" \
        --data '{
            "connector.class": "io.debezium.connector.sqlserver.SqlServerConnector",
            
            "tasks.max":1,
            "key.converter": "io.confluent.connect.avro.AvroConverter",
            "key.converter.schema.registry.url": "http://schema-registry:8081",
            "value.converter": "io.confluent.connect.avro.AvroConverter",
            "value.converter.schema.registry.url": "http://schema-registry:8081",
            "confluent.license": "",
            "confluent.topic.bootstrap.servers": "broker:9092",
            "confluent.topic.replication.factor": "1",

            "database.hostname": "sqlserver",
            "database.port": "1433",
            "database.user": "sa",
            "database.password": "Password!",
            "database.server.name": "server1",
            "database.dbname" : "c360",
            "database.history.kafka.bootstrap.servers": "broker:9092",
            "database.history.kafka.topic": "schema-changes.inventory"
        }' \
    http://localhost:8083/connectors/debezium-sqlserver-source/config | jq .
else
    echo "No connector specified"
fi

sleep 60

docker exec -it ksqldb-cli bash -c 'cat /data/scripts/c360_ksql.sql | ksql http://ksqldb-server:8088'

sleep 10

echo "Creating HBase Sink Connector"

curl -X PUT \
    -H "Content-Type: application/json" \
    --data '{
        "connector.class": "io.confluent.connect.hbase.HBaseSinkConnector",

        "tasks.max": "1",
        "key.converter": "org.apache.kafka.connect.storage.StringConverter",
        "key.converter.schema.registry.url": "http://schema-registry:8081",
        "value.converter": "io.confluent.connect.avro.AvroConverter",
        "value.converter.schema.registry.url": "http://schema-registry:8081",
        "confluent.topic.bootstrap.servers": "broker:9092",
        "confluent.topic.replication.factor":1,

        "hbase.zookeeper.quorum": "hbase",
        "hbase.zookeeper.property.clientPort": "2181",
        "auto.create.tables": "true",
        "auto.create.column.families": "true",
        "topics": "C360_STREAM",
        "insert.mode": "upsert"
    }' \
http://localhost:8083/connectors/hbase-sink/config | jq .

sleep 30

echo "Starting up Flask app"

nohup python c360_flask.py &

sleep 5

echo "Flask app querying HBase..."

curl -X GET http://localhost:5000/getallcustomers

sleep 5

pkill -f c360_flask.py
rm nohup.out