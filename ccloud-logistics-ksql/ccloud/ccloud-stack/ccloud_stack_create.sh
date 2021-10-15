#!/bin/bash

#########################################
# This script uses real Confluent Cloud resources.
# To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it.
#########################################
# Logistics Demo Vehicle Config
VEHICLE_WAREHOUSE_LAT=1.2836217252073074
VEHICLE_WAREHOUSE_LONG=103.81727340410173
VEHICLE_SPEED=0.00025

# Source library
source ../utils/helper.sh
source ../utils/ccloud_library.sh

SCHEMA_REGISTRY_GEO=apac

ccloud::validate_version_ccloud_cli $CCLOUD_MIN_VERSION || exit 1
check_jq || exit 1
ccloud::validate_logged_in_ccloud_cli || exit 1

ccloud::prompt_continue_ccloud_demo || exit 1

echo PositionStack Secret:
read POSITIONSTACK_SECRET

enable_ksqldb=true

if [[ -z "$ENVIRONMENT" ]]; then
  STMT=""
else
  STMT="PRESERVE_ENVIRONMENT=true"
fi

export EXAMPLE="logistics-demo-ccloud"

echo
ccloud::create_ccloud_stack $enable_ksqldb || exit 1

echo
echo "Validating..."
SERVICE_ACCOUNT_ID=$(ccloud kafka cluster list -o json | jq -r '.[0].name' | awk -F'-' '{print $4;}')
CONFIG_FILE=stack-configs/java-service-account-$SERVICE_ACCOUNT_ID.config
ccloud::validate_ccloud_config $CONFIG_FILE || exit 1
ccloud::generate_configs $CONFIG_FILE > /dev/null
source delta_configs/env.delta

if $enable_ksqldb ; then
  MAX_WAIT=720
  echo "Waiting up to $MAX_WAIT seconds for Confluent Cloud ksqlDB cluster to be UP"
  retry $MAX_WAIT ccloud::validate_ccloud_ksqldb_endpoint_ready $KSQLDB_ENDPOINT || exit 1
fi

ccloud::validate_ccloud_stack_up $CLOUD_KEY $CONFIG_FILE $enable_ksqldb || exit 1

echo
echo "ACLs in this cluster:"
ccloud kafka acl list

echo "Creating vehicles topic..."
ccloud kafka topic create vehicles --cluster ${CLUSTER}
ccloud schema-registry schema create --subject vehicles-value --schema ../../docs/schemas/vehicle.avsc --type AVRO --api-key `echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $1}'` --api-secret `echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $2}'`
echo "Creating purchases topic..."
ccloud kafka topic create purchases --cluster ${CLUSTER}
ccloud schema-registry schema create --subject purchases-value --schema ../../docs/schemas/orders.avsc --type AVRO --api-key `echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $1}'` --api-secret `echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $2}'`

echo
echo "Creating vehicles table in ksqlDB..."
curl -X "POST" "${KSQLDB_ENDPOINT}/ksql" \
     -H "Accept: application/vnd.ksql.v1+json" \
     --basic --user "$KSQLDB_CREDS" \
     -d $'{
  "ksql": "CREATE TABLE vehicle_table ( id string primary key, state string, deliveryCode string, lat double, long double, destLat double, destLong double, warehouseLat double, warehouseLong double, temperature double, tirePressure double ) WITH (KAFKA_TOPIC=\'vehicles\', VALUE_FORMAT=\'AVRO\', KEY_FORMAT=\'KAFKA\');",
  "streamsProperties": {}
}'

echo
echo "Creating queryable vehicles table in ksqlDB..."
curl -X "POST" "${KSQLDB_ENDPOINT}/ksql" \
     -H "Accept: application/vnd.ksql.v1+json" \
     --basic --user "$KSQLDB_CREDS" \
     -d $'{
  "ksql": "CREATE TABLE QUERYABLE_VEHICLE_TABLE WITH ( KAFKA_TOPIC=\'QUERYABLE_VEHICLE_TABLE\', PARTITIONS=6, REPLICAS=3 ) AS SELECT * FROM VEHICLE_TABLE EMIT CHANGES;",
  "streamsProperties": {}
}'

echo
echo "Creating vehicle stream in ksqlDB..."
curl -X "POST" "${KSQLDB_ENDPOINT}/ksql" \
     -H "Accept: application/vnd.ksql.v1+json" \
     --basic --user "$KSQLDB_CREDS" \
     -d $'{
  "ksql": "CREATE STREAM vehicle_stream ( id string key, state string, deliveryCode string, lat double, long double, destLat double, destLong double, warehouseLat double, warehouseLong double, temperature double, tirePressure double ) WITH (KAFKA_TOPIC=\'vehicles\', VALUE_FORMAT=\'AVRO\', KEY_FORMAT=\'KAFKA\');",
  "streamsProperties": {}
}'

echo
echo "Creating purchases stream in ksqlDB..."
curl -X "POST" "${KSQLDB_ENDPOINT}/ksql" \
     -H "Accept: application/vnd.ksql.v1+json" \
     --basic --user "$KSQLDB_CREDS" \
     -d $'{
  "ksql": "CREATE STREAM purchases_stream ( id string key, name string, email string, address string, order string, order_total double ) WITH (KAFKA_TOPIC=\'purchases\', VALUE_FORMAT=\'AVRO\', KEY_FORMAT=\'KAFKA\');",
  "streamsProperties": {}
}'

echo
echo "Creating masked purchases stream in ksqlDB..."
curl -X "POST" "${KSQLDB_ENDPOINT}/ksql" \
     -H "Accept: application/vnd.ksql.v1+json" \
     --basic --user "$KSQLDB_CREDS" \
     -d $'{
  "ksql": "CREATE STREAM PURCHASES_STREAM_MASKED WITH (KAFKA_TOPIC=\'PURCHASES_STREAM_MASKED\', PARTITIONS=6, REPLICAS=3) AS SELECT PURCHASES_STREAM.ID ID, MASK(PURCHASES_STREAM.NAME) MASKED_NAME, MASK(PURCHASES_STREAM.EMAIL) MASKED_EMAIL, MASK(PURCHASES_STREAM.ADDRESS) MASKED_ADDRESS, PURCHASES_STREAM.ORDER ORDER, PURCHASES_STREAM.ORDER_TOTAL ORDER_TOTAL FROM PURCHASES_STREAM PURCHASES_STREAM EMIT CHANGES;",
  "streamsProperties": {}
}'

echo
echo "Creating purchases table in ksqlDB..."
curl -X "POST" "${KSQLDB_ENDPOINT}/ksql" \
     -H "Accept: application/vnd.ksql.v1+json" \
     --basic --user "$KSQLDB_CREDS" \
     -d $'{
  "ksql": "CREATE TABLE PURCHASES_TABLE ( id string primary key, name string, email string, address string, order string, order_total double ) WITH (KAFKA_TOPIC=\'purchases\', VALUE_FORMAT=\'AVRO\', KEY_FORMAT=\'KAFKA\');",
  "streamsProperties": {}
}'

echo
echo "Creating queryable purchases table in ksqlDB..."
curl -X "POST" "${KSQLDB_ENDPOINT}/ksql" \
     -H "Accept: application/vnd.ksql.v1+json" \
     --basic --user "$KSQLDB_CREDS" \
     -d $'{
  "ksql": "CREATE TABLE QUERYABLE_PURCHASES_TABLE WITH (KAFKA_TOPIC=\'QUERYABLE_PURCHASES_TABLE\', PARTITIONS=6, REPLICAS=3) AS SELECT * FROM PURCHASES_TABLE PURCHASES_TABLE EMIT CHANGES;",
  "streamsProperties": {}
}'

echo
echo "Creating order tracker in ksqlDB..."
curl -X "POST" "${KSQLDB_ENDPOINT}/ksql" \
     -H "Accept: application/vnd.ksql.v1+json" \
     --basic --user "$KSQLDB_CREDS" \
     -d $'{
  "ksql": "CREATE TABLE ORDER_TRACKER WITH (KAFKA_TOPIC=\'ORDER_TRACKER\', PARTITIONS=6, REPLICAS=3) AS SELECT P.ID ORDER_ID, LATEST_BY_OFFSET(V.ID) VEHICLE_ID, LATEST_BY_OFFSET(V.STATE) STATE, LATEST_BY_OFFSET(V.LAT) LAT, LATEST_BY_OFFSET(V.LONG) LONG, LATEST_BY_OFFSET(V.DESTLAT) DESTLAT, LATEST_BY_OFFSET(V.DESTLONG) DESTLONG, LATEST_BY_OFFSET(ROUND(GEO_DISTANCE(CAST(V.LAT as DOUBLE), cast(V.LONG as DOUBLE), cast(V.DESTLAT as DOUBLE), cast(V.DESTLONG as DOUBLE), \'KM\'), 2)) DISTANCE_FROM_DESTINATION, LATEST_BY_OFFSET(ROUND(GREATEST(ABS(V.LAT - V.DESTLAT), ABS(V.LONG - V.DESTLONG)) / (0.5 / 10 / 10) * 4, 2)) ETA_SECONDS FROM VEHICLE_STREAM V JOIN QUERYABLE_PURCHASES_TABLE P ON ((V.DELIVERYCODE = P.ID)) GROUP BY P.ID EMIT CHANGES;",
  "streamsProperties": {}
}'

LOGISTICS_DEMO_CONFIG_FILE="config.properties-$SERVICE_ACCOUNT_ID"

cat <<EOF > $LOGISTICS_DEMO_CONFIG_FILE
sasl.mechanisms=PLAIN
security.protocol=SASL_SSL
bootstrap.servers=${BOOTSTRAP_SERVERS}
sasl.username=${CLOUD_API_KEY}
sasl.password=${CLOUD_API_SECRET}
basic.auth.credentials.source=USER_INFO
schema.url=${SCHEMA_REGISTRY_ENDPOINT}
schema.username=`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $1}'`
schema.password=`echo $SCHEMA_REGISTRY_CREDS | awk -F: '{print $2}'`
ksql.url=${KSQLDB_ENDPOINT}
ksql.username=`echo $KSQLDB_CREDS | awk -F: '{print $1}'`
ksql.password=`echo $KSQLDB_CREDS | awk -F: '{print $2}'`

services.ksql.url=http://logistics-ksql:3000
services.vehicle.url=http://logistics-fleet
external.positionstack.secret=$POSITIONSTACK_SECRET
external.positionstack.url=http://api.positionstack.com
vehicle.warehouse.lat=$VEHICLE_WAREHOUSE_LAT
vehicle.warehouse.long=$VEHICLE_WAREHOUSE_LONG
vehicle.speed=$VEHICLE_SPEED
EOF

echo
echo "Logistics demo client configuration file written to $LOGISTICS_DEMO_CONFIG_FILE"
echo

mv $LOGISTICS_DEMO_CONFIG_FILE ../../env/
cd ../../logistics-demo
export CONFIG_FILE=$LOGISTICS_DEMO_CONFIG_FILE
docker-compose -f docker-compose.yml up -d

echo
echo "To destroy this Confluent Cloud stack run ->"
echo "    $STMT ./ccloud_stack_destroy.sh $CONFIG_FILE"
echo

echo
ENVIRONMENT=$(ccloud::get_environment_id_from_service_id $SERVICE_ACCOUNT_ID)
echo "Tip: 'ccloud' CLI has been set to the new environment $ENVIRONMENT"
