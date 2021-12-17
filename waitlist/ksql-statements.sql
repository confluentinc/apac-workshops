SET 'auto.offset.reset' = 'earliest';

CREATE STREAM cancellations (
  appt_time TIMESTAMP,
  nric VARCHAR
) WITH (KAFKA_TOPIC = 'cancellations', VALUE_FORMAT = 'JSON_SR', PARTITIONS = 1);

CREATE STREAM waitlist_reqs (
  appt_time TIMESTAMP,
  nric VARCHAR,
  req_type VARCHAR,
  source VARCHAR
) WITH (KAFKA_TOPIC = 'waitlist_reqs', VALUE_FORMAT = 'JSON_SR', PARTITIONS = 1);

CREATE TABLE patients (
  nric VARCHAR PRIMARY KEY,
  name VARCHAR,
  mobile VARCHAR
) WITH (KAFKA_TOPIC = 'patients', VALUE_FORMAT = 'JSON_SR', PARTITIONS = 1);

CREATE TABLE waitlist_raw
WITH (KAFKA_TOPIC = 'waitlist_raw', FORMAT = 'JSON_SR', PARTITIONS = 1)
AS SELECT appt_time,
  nric,
  LATEST_BY_OFFSET(source) AS source,
  LATEST_BY_OFFSET(req_type) AS req_type
FROM waitlist_reqs
GROUP BY appt_time, nric EMIT CHANGES;

CREATE TABLE waitlist
WITH (KAFKA_TOPIC = 'waitlist', FORMAT = 'JSON_SR', PARTITIONS = 1)
AS SELECT appt_time,
  COLLECT_LIST(nric) AS nric_list
FROM waitlist_raw
WHERE req_type = 'add'
GROUP BY appt_time EMIT CHANGES;

INSERT INTO waitlist_reqs
SELECT c.appt_time AS appt_time,
  w.nric_list[1] AS nric,
  'remove' AS req_type,
  'system' AS source
FROM cancellations c
LEFT JOIN waitlist w
ON c.appt_time = w.appt_time
WHERE ARRAY_LENGTH(w.nric_list) > 0 AND ARRAY_LENGTH(w.nric_list) IS NOT NULL
PARTITION BY NULL EMIT CHANGES;

CREATE STREAM cancellations_final
WITH (KAFKA_TOPIC = 'cancellations_final', VALUE_FORMAT = 'JSON_SR', PARTITIONS = 1)
AS SELECT c.appt_time AS appt_time,
  c.nric as nric
FROM cancellations c
LEFT JOIN waitlist w
ON c.appt_time = w.appt_time
WHERE ARRAY_LENGTH(w.nric_list) = 0 OR ARRAY_LENGTH(w.nric_list) IS NULL
PARTITION BY NULL EMIT CHANGES;

CREATE STREAM waitlist_notifications
WITH (KAFKA_TOPIC = 'whitelist_notifications', VALUE_FORMAT = 'JSON_SR', PARTITIONS = 1)
AS SELECT
  CONCAT('Dear ', p.name, ', your waitlisted appointment on ',
    FORMAT_TIMESTAMP(r.appt_time, 'yyyy-MM-dd HH:mm', 'Asia/Singapore'),
    ' is confirmed. Please do not be late for your appointment.') AS message,
  p.mobile AS mobile
FROM waitlist_reqs r
LEFT JOIN patients p
ON r.nric = p.nric
WHERE r.req_type = 'remove' AND r.source = 'system'
PARTITION BY NULL EMIT CHANGES;

INSERT INTO patients (nric, name, mobile) VALUES ('S1111111A', 'David Ang', '+6581111111');
INSERT INTO patients (nric, name, mobile) VALUES ('S2222222B', 'Barry Tan', '+6592222222');
INSERT INTO patients (nric, name, mobile) VALUES ('S3333333C', 'Lakshmi Desai', '+6583333333');
INSERT INTO patients (nric, name, mobile) VALUES ('S4444444D', 'Jane Lee', '+6594444444');
