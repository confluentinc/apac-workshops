SET 'auto.offset.reset' = 'earliest';

CREATE STREAM users_raw
WITH (KAFKA_TOPIC='user-data-db.user-data.users', FORMAT='JSON_SR');

CREATE TABLE users
WITH (KAFKA_TOPIC='users', FORMAT='JSON_SR')
AS SELECT ROWKEY->userid AS userid,
  LATEST_BY_OFFSET(after->firstname) AS firstname,
  LATEST_BY_OFFSET(after->phone) AS phone,
  LATEST_BY_OFFSET(after->level) AS level
FROM users_raw
GROUP BY ROWKEY->userid;

CREATE STREAM merchant_locations_raw
WITH (KAFKA_TOPIC='user-data-db.user-data.locations', VALUE_FORMAT='JSON_SR');

CREATE TABLE merchant_locations
WITH (KAFKA_TOPIC='merchant_locations', FORMAT='JSON_SR')
AS SELECT LATEST_BY_OFFSET(after->description) AS description,
  CAST(LATEST_BY_OFFSET(after->latitude) AS DECIMAL(10,7)) AS latitude,
  CAST(LATEST_BY_OFFSET(after->longitude) AS DECIMAL(10,7)) AS longitude,
  after->area as area
FROM merchant_locations_raw
GROUP BY after->area;

CREATE STREAM user_locations_raw
WITH (KAFKA_TOPIC='user_locations_raw', FORMAT='JSON_SR');

CREATE STREAM user_locations
WITH (KAFKA_TOPIC='user_locations', FORMAT='JSON_SR')
AS SELECT rowkey as userid,
  CAST(latitude AS DECIMAL(10,7)) AS latitude,
  CAST(longitude AS DECIMAL(10,7)) AS longitude,
  'Bonifacio-West' AS area
FROM user_locations_raw;

CREATE STREAM output WITH (KAFKA_TOPIC='output', FORMAT='JSON_SR')
AS SELECT userloc.userid as userid,
 userloc.area as area,
 userlist.firstname as firstname,
 merchantloc.description as description,
 CAST(GEO_DISTANCE(userloc.latitude, userloc.longitude, merchantloc.latitude, merchantloc.longitude, 'KM')*1000 AS INT) as distance_meters
FROM user_locations userloc
LEFT JOIN users userlist on userloc.userid = userlist.userid
LEFT JOIN merchant_locations merchantloc on userloc.area = merchantloc.area
WHERE GEO_DISTANCE(userloc.latitude, userloc.longitude, merchantloc.latitude, merchantloc.longitude, 'KM') < 0.2
PARTITION BY userloc.userid;
