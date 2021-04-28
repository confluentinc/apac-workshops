SET 'auto.offset.reset' = 'earliest';

CREATE SINK CONNECTOR `fraud-demo-mongo-sink` WITH (
  "connector.class" = 'com.mongodb.kafka.connect.MongoSinkConnector',
  "tasks.max" = '1',
  "key.converter" = 'org.apache.kafka.connect.storage.StringConverter',
  "value.converter" = 'io.confluent.connect.avro.AvroConverter',
  "transforms" = 'key',
  "topics" = 'transactions_prepared, transactions_prepared_unknown, transactions_fraud_predictions',
  "transforms.key.type" = 'org.apache.kafka.connect.transforms.HoistField$Key',
  "transforms.key.field" = '_id',
  "connection.uri" = 'mongodb://root:example@mongo:27017',
  "database" = 'fraud_demo',
  "delete.on.null.values" = 'true',
  "document.id.strategy" = 'com.mongodb.kafka.connect.sink.processor.id.strategy.FullKeyStrategy',
  "value.converter.schema.registry.url" = 'http://schema-registry:8081',
  "key.converter.schema.registry.url" = 'http://schema-registry:8081');"
