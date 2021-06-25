# Toll Fraud
```
CREATE STREAM `demo_toll_records` AS
select
         extractJsonField(payload,'$.transaction_id') as transaction_id
         , extractJsonField(payload,'$.tollgate_id') as tollgate_id
         , extractJsonField(payload,'$.user_id') as user_id
         , extractJsonField(payload,'$.lat') as lat
         , extractJsonField(payload,'$.long') as long
        , extractJsonField(payload,'$.fare') as fare
         from demo_toll;
```

```
CREATE STREAM `demo_toll_records_2` AS SELECT * FROM `demo_toll_records`;
```

```
SELECT
	 TIMESTAMPTOSTRING(d1.ROWTIME, 'yyyy-MM-dd HH:mm:ss'),
   TIMESTAMPTOSTRING(d2.ROWTIME, 'yyyy-MM-dd HH:mm:ss'),
   d1.user_id,
   d2.user_id,
   d1.transaction_id,
   d2.transaction_id,
   d1.fare,
   d2.fare,
   d1.lat,
   d1.long,
   d2.lat,
   d2.long,
   GEO_DISTANCE(CAST(d1.lat as DOUBLE), cast(d1.long as DOUBLE), cast(d2.lat as DOUBLE), cast(d2.long as DOUBLE), 'KM') as distance
   FROM `demo_toll_records` d1
   INNER JOIN `demo_toll_records_2` d2
   WITHIN (0 MINUTES, 3 MINUTES)
   ON d1.user_id = d2.user_id
   WHERE d1.transaction_id != d2.transaction_id
   AND GEO_DISTANCE(CAST(d1.lat as DOUBLE), cast(d1.long as DOUBLE), cast(d2.lat as DOUBLE), cast(d2.long as DOUBLE), 'KM') > 20
emit changes;
```

# Oracle DB Transaction Fraud

```
CREATE STREAM DEMO_CARD_TRANSACTIONS (TRANSACTION_ID STRING, CARD_ID STRING, PAID STRING, LAT STRING, LONGD STRING) WITH (kafka_topic='demo_CARD_TRANSACTIONS', value_format='AVRO');

CREATE STREAM `transactions_prepared` AS SELECT
  TRANSACTION_ID,
  CARD_ID,
  CAST(replace(paid, ' INR', '') AS double) as PAID,
  CAST(lat AS double) as LAT,
  CAST(longd AS double) as LONGD
FROM DEMO_CARD_TRANSACTIONS;
```

```
CREATE STREAM `transactions_prepared_2` AS SELECT * FROM `transactions_prepared`;
```

```
CREATE STREAM `demo_transactions_potential_fraud` AS
SELECT
	 TIMESTAMPTOSTRING(t1.ROWTIME, 'yyyy-MM-dd HH:mm:ss'),
   TIMESTAMPTOSTRING(t2.ROWTIME, 'yyyy-MM-dd HH:mm:ss'),
   t1.card_id,
   t2.card_id,
   t1.transaction_id,
   t2.transaction_id,
   t1.paid,
   t2.paid,
   t1.lat,
   t1.longd,
   t2.lat,
   t2.longd,
   GEO_DISTANCE(t1.lat, t1.longd, t2.lat, t2.longd, 'KM') as distance
   FROM `transactions_prepared` t1
   INNER JOIN `transactions_prepared_2` t2
   WITHIN (0 MINUTES, 3 MINUTES)
   ON t1.card_id = t2.card_id
   WHERE t1.transaction_id != t2.transaction_id
   AND GEO_DISTANCE(t1.lat, t1.longd, t2.lat, t2.longd, 'KM') > 20;
```
