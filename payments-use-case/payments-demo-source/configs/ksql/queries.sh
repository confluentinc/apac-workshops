# transit

offset="SET 'auto.offset.reset'='earliest'; "

transit1="CREATE STREAM DEMO_TRANSIT_RAW (transaction_id STRING, user_id STRING, transport_id STRING, type STRING, fare STRING) WITH (kafka_topic='demo_transit_raw', value_format='AVRO');"
transit2="CREATE STREAM \\\`demo_transit\\\` AS SELECT user_id, type, transport_id, CAST(replace(fare, 'RM', '') AS double) AS fare from DEMO_TRANSIT_RAW EMIT CHANGES;"

# retail

retail1="CREATE STREAM DEMO_RETAIL_RAW (transaction_id STRING, user_id STRING, shop_id STRING, paid STRING) WITH (kafka_topic='demo_retail_raw', value_format='AVRO');"
retail2="CREATE STREAM \\\`demo_retail\\\` AS SELECT * from DEMO_RETAIL_RAW WHERE paid is not null EMIT CHANGES;"
retail3="CREATE STREAM \\\`demo_retail_error\\\` AS SELECT * from DEMO_RETAIL_RAW WHERE paid is null EMIT CHANGES;"
