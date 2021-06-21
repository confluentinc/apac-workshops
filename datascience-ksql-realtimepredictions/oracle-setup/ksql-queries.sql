SET 'auto.offset.reset' = 'earliest';

CREATE TABLE cardholders (
  id STRING PRIMARY KEY,
  first_active_month STRING,
  reward_program STRING,
  latitude DOUBLE,
  longitude DOUBLE,
  fico_score DOUBLE,
  age DOUBLE,
  `table` STRING,
  scn STRING,
  op_type STRING,
  op_ts STRING,
  current_ts STRING,
  username STRING)
WITH (KAFKA_TOPIC='ORCLPDB1.ORDERMGMT.CARDHOLDERS', value_format='AVRO');

CREATE TABLE merchants (
  id STRING PRIMARY KEY,
  merchant_category_id DOUBLE,
  subsector_description STRING,
  latitude DOUBLE,
  longitude DOUBLE,
  `table` STRING,
  scn STRING,
  op_type STRING,
  op_ts STRING,
  current_ts STRING,
  username STRING)
WITH (KAFKA_TOPIC='ORCLPDB1.ORDERMGMT.MERCHANTS', value_format='AVRO');

CREATE STREAM transactions (
  id DOUBLE,
  authorized_flag DOUBLE,
  purchase_date STRING,
  card_id STRING,
  merchant_id STRING,
  merchant_category_id DOUBLE,
  item_category STRING,
  purchase_amount DOUBLE,
  signature_provided DOUBLE,
  `table` STRING,
  scn STRING,
  op_type STRING,
  op_ts STRING,
  current_ts STRING,
  username STRING
  )
WITH (KAFKA_TOPIC='ORCLPDB1.ORDERMGMT.TRANSACTIONS', value_format='AVRO');

CREATE STREAM transactions_prepared_unknown
WITH (KAFKA_TOPIC='transactions_prepared_unknown', value_format='AVRO')
AS SELECT CAST(t.id AS STRING) AS transaction_id,
  t.authorized_flag AS authorized_flag,
  t.purchase_date AS purchase_date,
  t.card_id AS card_id,
  t.merchant_id AS merchant_id,
  t.merchant_category_id AS merchant_category_id,
  t.item_category AS item_category,
  t.purchase_amount AS purchase_amount,
  t.signature_provided AS signature_provided,
  c.first_active_month AS card_first_active_month,
  c.reward_program AS card_reward_program,
  c.latitude AS card_latitude,
  c.longitude AS card_longitude,
  c.fico_score AS card_fico_score,
  c.age AS card_age,
  m.subsector_description AS merchant_subsector_description,
  m.latitude AS merchant_latitude,
  m.longitude AS merchant_longitude,
  GEO_DISTANCE(c.latitude, c.longitude, m.latitude, m.longitude) AS merchant_cardholder_distance
FROM transactions t
INNER JOIN cardholders c ON t.card_id = c.id
INNER JOIN merchants m ON t.merchant_id = m.id
WHERE authorized_flag IS NULL
PARTITION BY CAST(t.id AS STRING);

CREATE STREAM transactions_prepared
WITH (KAFKA_TOPIC='transactions_prepared', value_format='AVRO')
AS SELECT CAST(t.id AS STRING) AS transaction_id,
  t.authorized_flag AS authorized_flag,
  t.purchase_date AS purchase_date,
  t.card_id AS card_id,
  t.merchant_id AS merchant_id,
  t.merchant_category_id AS merchant_category_id,
  t.item_category AS item_category,
  t.purchase_amount AS purchase_amount,
  t.signature_provided AS signature_provided,
  c.first_active_month AS card_first_active_month,
  c.reward_program AS card_reward_program,
  c.latitude AS card_latitude,
  c.longitude AS card_longitude,
  c.fico_score AS card_fico_score,
  c.age AS card_age,
  m.subsector_description AS merchant_subsector_description,
  m.latitude AS merchant_latitude,
  m.longitude AS merchant_longitude,
  GEO_DISTANCE(c.latitude, c.longitude, m.latitude, m.longitude) AS merchant_cardholder_distance
FROM transactions t
INNER JOIN cardholders c ON t.card_id = c.id
INNER JOIN merchants m ON t.merchant_id = m.id
WHERE authorized_flag IS NOT NULL
PARTITION BY CAST(t.id AS STRING);
