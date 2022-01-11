#!/bin/bash

source ./ccloud_library.sh
source ./helper.sh
confluent login --save

export CLUSTER_CLOUD=${CLUSTER_CLOUD:-gcp}
export CLUSTER_REGION=${CLUSTER_REGION:-asia-southeast1}
export CHECK_CREDIT_CARD=false
export KSQL_CSU=${KSQL_CSU:-4}
export EXAMPLE="kafkageodemo"

ccloud::create_ccloud_stack true
export SERVICE_ACCOUNT_ID=$(confluent kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4 "-" $5;}')
export CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
export CCLOUD_CLUSTER_ID=$(confluent kafka cluster list -o json | jq -c -r '.[] | select (.name == "'"demo-kafka-cluster-$SERVICE_ACCOUNT_ID"'")' | jq -r .id)

ccloud::generate_configs $CONFIG_FILE
source delta_configs/env.delta

echo
echo "Sleep an additional 90s to wait for all Confluent Cloud metadata to propagate"
sleep 90

confluent kafka topic create bus_raw --partitions 1 --config="retention.ms=3600000"

docker-compose up -d

MAX_WAIT=720
echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud ksqlDB cluster to be UP"
retry $MAX_WAIT ccloud::validate_ccloud_ksqldb_endpoint_ready $KSQLDB_ENDPOINT
echo
echo "Writing ksqlDB queries in Confluent Cloud"
ksqlDBAppId=$(confluent ksql app list | grep "$KSQLDB_ENDPOINT" | awk '{print $1}')
confluent ksql app describe $ksqlDBAppId -o json
confluent ksql app configure-acls $ksqlDBAppId bus_raw

printf "\n\n================================================================================\n"
printf "Creating MQTT source connector...\n"
printf "================================================================================\n\n"
DATA=$( cat << EOF
{
  "connector.class": "io.confluent.connect.mqtt.MqttSourceConnector",
  "value.converter": "org.apache.kafka.connect.converters.ByteArrayConverter",
  "mqtt.server.uri": "tcp://mqtt.hsl.fi:1883",
  "mqtt.clean.session.enabled": "false",
  "kafka.topic": "bus_raw",
  "mqtt.topics": "/hfp/v2/journey/ongoing/vp/bus/#",
  "confluent.topic.bootstrap.servers": "${BOOTSTRAP_SERVERS}",
  "confluent.topic.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${CLOUD_KEY}\" password=\"${CLOUD_SECRET}\";",
  "confluent.topic.security.protocol": "SASL_SSL",
  "confluent.topic.sasl.mechanism": "PLAIN"
}
EOF
)
curl -X PUT \
-H "Content-Type:application/json" \
--data "${DATA}" http://localhost:8083/connectors/mqtt-source/config | jq
printf "\n"

while read ksqlCmd; do
  echo -e "\n$ksqlCmd\n"
  curl -X POST $KSQLDB_ENDPOINT/ksql \
       -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" \
       -u $KSQLDB_BASIC_AUTH_USER_INFO \
       --silent \
       -d @<(cat <<EOF
{
  "ksql": "$ksqlCmd",
  "streamsProperties": {}
}
EOF
)
done < ./ksql-statements.sql

printf "\n\n================================================================================\n"
printf "Preparing Elasticsearch index...\n"
printf "================================================================================\n\n"
curl -X PUT "localhost:9200/bus_safety/?pretty" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "dynamic_templates": [
    {
      "dates": {
        "mapping": {
          "format": "epoch_second",
          "type": "date"
        },
        "match": "TIME_INT"
      }
    },
    {
      "locations": {
        "mapping": {
          "type": "geo_point"
        },
        "match": "*LOC"
      }
    }
    ]
  }
}
'

printf "\n\n================================================================================\n"
printf "Creating sink connector...\n"
printf "================================================================================\n\n"
DATA=$( cat << EOF
{
  "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
  "key.converter": "io.confluent.connect.json.JsonSchemaConverter",
  "value.converter": "io.confluent.connect.json.JsonSchemaConverter",
  "topics": "bus_safety",
  "key.ignore": "true",
  "schema.ignore": "true",
  "value.converter.schemas.enable": "false",
  "connection.url": "http://elasticsearch:9200",
  "key.converter.schema.registry.url": "${SCHEMA_REGISTRY_URL}",
  "key.converter.basic.auth.credentials.source": "USER_INFO",
  "key.converter.schema.registry.basic.auth.user.info": "${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO}",
  "value.converter.schema.registry.url": "${SCHEMA_REGISTRY_URL}",
  "value.converter.basic.auth.credentials.source": "USER_INFO",
  "value.converter.schema.registry.basic.auth.user.info": "${SCHEMA_REGISTRY_BASIC_AUTH_USER_INFO}",
  "confluent.topic.bootstrap.servers": "${BOOTSTRAP_SERVERS}",
  "confluent.topic.sasl.jaas.config": "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${CLOUD_KEY}\" password=\"${CLOUD_SECRET}\";",
  "confluent.topic.security.protocol": "SASL_SSL",
  "confluent.topic.sasl.mechanism": "PLAIN"
}
EOF
)
curl -X PUT \
     -H "Content-Type:application/json" \
     --data "${DATA}" http://localhost:8083/connectors/elastic-sink/config | jq
printf "\n"

printf "\n\n================================================================================\n"
printf "Importing Kibana dashboard...\n"
printf "================================================================================\n\n"
curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" \
  -H "securitytenant: global" --form file=@busops.ndjson
printf "\n"

echo
echo
echo "Confluent Cloud Environment:"
echo
echo "  export CONFIG_FILE=$CONFIG_FILE"
echo "  export SERVICE_ACCOUNT_ID=$SERVICE_ACCOUNT_ID"
echo "  export CCLOUD_CLUSTER_ID=$CCLOUD_CLUSTER_ID"
