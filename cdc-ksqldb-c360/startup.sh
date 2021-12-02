export DOCKERHOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)

docker-compose up -d

sleep 60

docker logs connect-source -f

if [ $1 == "oracle" ] || [ $2 == "oracle" ]
then
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
            "oracle.sid": "XE",
            "oracle.username": "MYUSER",
            "oracle.password": "password",
            
            "redo.log.consumer.bootstrap.servers":"broker:9092",
            
            "table.inclusion.regex": ".*CUST.*",
            "table.topic.name.template": "${databaseName}.${schemaName}.${tableName}",
            "connection.pool.max.size": 20,
            "confluent.topic.replication.factor":1,
            "redo.log.row.fetch.size":1,
            "snapshot.row.fetch.size":1,
            "start.from":"snapshot",
            "numeric.mapping":"best_fit"
        }' \
    http://localhost:8083/connectors/oracle-cdc-source/config | jq .
fi

if [ $1 == "sqlserver" ] || [ $2 == "sqlserver" ]
then
    echo "Creating c360 db..."
    cat c360_tables_sqlserver.sql | docker exec -i sqlserver bash -c '/opt/mssql-tools/bin/sqlcmd -U sa -P Password!'

    echo "Creating Debezium SQL Server Source Connector"

    curl -X PUT \
        -H "Content-Type: application/json" \
        --data '{
            "name": "debezium-sqlserver-source",
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
fi

sleep 30

docker exec -it ksqldb-cli bash -c 'cat /data/scripts/c360_materialized_view_ksql.sql | ksql http://ksqldb-server:8088'

sleep 30

echo "Pull Query with single key"

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from c360_view where CUSTOMER_ID = \'C101\' and ACCOUNT_ID = \'SAV101\';",
  "streamsProperties": {}
}' --http2

echo "Pull Query with multiple keys"

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from c360_view where CUSTOMER_ID in (\'C101\', \'C102\') and ACCOUNT_ID in (\'SAV101\', \'CUR102\');",
  "streamsProperties": {}
}' --http2

echo "Push Query - waiting for new events.."

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from c360_view emit changes;",
  "streamsProperties": {}
}' --http2
