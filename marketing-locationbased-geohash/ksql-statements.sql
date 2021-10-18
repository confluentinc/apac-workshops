SET 'auto.offset.reset' = 'earliest';

CREATE STREAM users_raw
WITH (KAFKA_TOPIC='user-data-db.user-data.users', FORMAT='JSON_SR');

CREATE TABLE users
WITH (KAFKA_TOPIC='users', FORMAT='JSON_SR')
AS SELECT ROWKEY->userid AS userid,
  LATEST_BY_OFFSET(after->firstname, false) AS firstname,
  LATEST_BY_OFFSET(after->phone, false) AS phone,
  LATEST_BY_OFFSET(after->level, false) AS level
FROM users_raw
GROUP BY ROWKEY->userid;

CREATE STREAM merchant_locations_raw
WITH (KAFKA_TOPIC='user-data-db.user-data.locations', FORMAT='JSON_SR');

CREATE TABLE merchant_locations
WITH (KAFKA_TOPIC='merchant_locations', FORMAT='JSON_SR')
AS SELECT ROWKEY->id AS id,
  LATEST_BY_OFFSET(after->description, false) AS description,
  CAST(LATEST_BY_OFFSET(after->latitude, false) AS DECIMAL(10,7)) AS latitude,
  CAST(LATEST_BY_OFFSET(after->longitude, false) AS DECIMAL(10,7)) AS longitude
FROM merchant_locations_raw
GROUP BY ROWKEY->id;

CREATE TABLE merchant_lookups
WITH (KAFKA_TOPIC='merchant_lookups', FORMAT='JSON_SR')
AS SELECT GEO_HASH(latitude, longitude, 6) AS geohash,
  COLLECT_LIST(id) as idlist
FROM merchant_locations
WHERE description IS NOT null
GROUP BY GEO_HASH(latitude, longitude, 6);

CREATE STREAM user_locations_raw
WITH (KAFKA_TOPIC='user_locations_raw', FORMAT='JSON_SR');

CREATE STREAM user_locations
WITH (KAFKA_TOPIC='user_locations', VALUE_FORMAT='JSON_SR')
AS SELECT rowkey as userid,
  ROWTIME AS timestamp,
  CAST(latitude AS DECIMAL(10,7)) AS latitude,
  CAST(longitude AS DECIMAL(10,7)) AS longitude,
  GEO_HASH(CAST(latitude AS DECIMAL(10,7)), CAST(longitude AS DECIMAL(10,7)), 6) AS geohash
FROM user_locations_raw
PARTITION BY null;

CREATE STREAM alerts_raw
WITH (KAFKA_TOPIC='alerts_raw', VALUE_FORMAT='JSON_SR')
AS SELECT userloc.userid as userid,
 userloc.latitude AS latitude,
 userloc.longitude AS longitude,
 userloc.timestamp AS timestamp,
 userloc.geohash AS geohash,
 EXPLODE(merchantloc.idlist) AS merchantid
FROM user_locations userloc
LEFT JOIN merchant_lookups merchantloc ON userloc.geohash = merchantloc.geohash
PARTITION BY null;

CREATE STREAM promo_alerts WITH (KAFKA_TOPIC='promo_alerts', VALUE_FORMAT='JSON_SR')
AS SELECT userloc.userid AS userid,
 userloc.geohash AS geohash,
 userlist.firstname AS firstname,
 merchantloc.description AS description,
 CAST(GEO_DISTANCE(userloc.latitude, userloc.longitude, merchantloc.latitude, merchantloc.longitude, 'KM')*1000 AS INT) as distance_meters,
 STRUCT("lat" := CAST(userloc.latitude AS DOUBLE),"lon" := CAST(userloc.longitude AS DOUBLE)) AS geopoint,
 userloc.timestamp as timestamp
FROM alerts_raw userloc
LEFT JOIN users userlist on userloc.userid = userlist.userid
LEFT JOIN merchant_locations merchantloc on userloc.merchantid = merchantloc.id
WHERE GEO_DISTANCE(userloc.latitude, userloc.longitude, merchantloc.latitude, merchantloc.longitude, 'KM') < 0.2
AND userlist.level = 'Gold'
PARTITION BY null
EMIT CHANGES;
