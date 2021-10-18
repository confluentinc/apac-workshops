SET 'auto.offset.reset' = 'earliest';

CREATE SOURCE CONNECTOR `mysql_cdc` WITH (
  "connector.class" = 'io.debezium.connector.mysql.MySqlConnector',
  "database.hostname" = 'mysql',
  "database.port" = '3306',
  "database.user" = 'example-user',
  "database.password" = 'example-pw',
  "database.allowPublicKeyRetrieval" = 'true',
  "database.server.id" = '184054',
  "database.server.name" = 'user-data-db',
  "database.whitelist" = 'user-data',
  "database.history.kafka.bootstrap.servers" = 'kafka:29092',
  "database.history.kafka.topic" = 'users_ddl',
  "table.whitelist" = 'user-data.users,user-data.locations',
  "include.schema.changes" = 'false',
  "key.converter" = 'io.confluent.connect.json.JsonSchemaConverter',
  "value.converter.schema.registry.url" = 'http://schema-registry:8081',
  "key.converter.schema.registry.url" = 'http://schema-registry:8081',
  "value.converter" = 'io.confluent.connect.json.JsonSchemaConverter');

CREATE SOURCE CONNECTOR `datagen_locations` WITH (
  "connector.class" = 'io.confluent.kafka.connect.datagen.DatagenConnector',
  "schema.string" = '{
    "namespace": "locations_raw",
    "name": "values",
    "type": "record",
    "fields": [
      {"name": "userid",
        "type": {
          "type": "int",
          "arg.properties": {
            "range": {
              "min": 1,
              "max": 11}
          }
        }
      },
      {"name": "latitude",
        "type": {
          "type": "float",
          "arg.properties": {
            "range": {
              "min": 14.545898440000000,
              "max": 14.556884760000000}
          }
        }
      },
      {"name": "longitude",
        "type": {
          "type": "float",
          "arg.properties": {
            "range": {
              "min": 121.0473632850000,
              "max": 121.0583496150000}
          }
        }
      }
    ]
  }',
  "schema.keyfield" = 'userid',
  "key.converter" = 'io.confluent.connect.json.JsonSchemaConverter',
  "value.converter" = 'io.confluent.connect.json.JsonSchemaConverter',
  "value.converter.schema.registry.url" = 'http://schema-registry:8081',
  "key.converter.schema.registry.url" = 'http://schema-registry:8081',
  "kafka.topic" = 'user_locations_raw',
  "maxInterval" = '200');

CREATE SINK CONNECTOR `promos_elastic` WITH (
  "connector.class" = 'io.confluent.connect.elasticsearch.ElasticsearchSinkConnector',
  "value.converter" = 'io.confluent.connect.json.JsonSchemaConverter',
  "topics" = 'promo_alerts',
  "key.ignore" = 'true',
  "schema.ignore" = 'true',
  "value.converter.schemas.enable" = 'false',
  "connection.url" = 'http://elasticsearch:9200',
  "value.converter.schema.registry.url" = 'http://schema-registry:8081');
