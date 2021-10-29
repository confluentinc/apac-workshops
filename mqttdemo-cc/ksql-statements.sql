CREATE STREAM BUS_RAW( \
  key STRING KEY, \
  VP STRING) \
WITH (KAFKA_TOPIC='bus_raw',FORMAT='KAFKA');

CREATE STREAM BUS WITH (KAFKA_TOPIC='bus_prepped',VALUE_FORMAT='JSON_SR', TIMESTAMP='TIME_INT') \
AS SELECT \
  SPLIT(AS_VALUE(KEY), '/')[12] AS HEADSIGN, \
  EXTRACTJSONFIELD(VP, '$.VP.desi') AS ROUTE_NUM, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.dir') AS INT) AS DIRECTION_ID, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.oper') AS INT) AS OPERATOR_ID, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.veh') AS INT) AS VEH_ID, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.tsi') AS BIGINT) AS TIME_INT, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.spd') AS DOUBLE) AS SPEED, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.hdg') AS INT) AS HEADING, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.lat') AS DOUBLE) AS LAT, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.long') AS DOUBLE) AS LONG, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.acc') AS DOUBLE) AS ACCEL, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.dl') AS INT) AS DEVIATION, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.odo') AS INT) AS ODOMETER, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.drst') AS INT) AS DOOR_STATUS, \
  EXTRACTJSONFIELD(VP, '$.VP.start') AS START_TIME, \
  EXTRACTJSONFIELD(VP, '$.VP.loc') AS LOC_SRC, \
  CAST(EXTRACTJSONFIELD(VP, '$.VP.occu') AS INT) AS OCCUPANCY \
FROM BUS_RAW \
PARTITION BY NULL \
EMIT CHANGES;

CREATE STREAM BUS_SAFETY WITH (KAFKA_TOPIC='bus_safety',VALUE_FORMAT='JSON_SR', TIMESTAMP='TIME_INT') \
AS SELECT \
  HEADSIGN, \
  ROUTE_NUM, \
  DIRECTION_ID, \
  OPERATOR_ID, \
  VEH_ID, \
  TIME_INT, \
  DEVIATION, \
  START_TIME, \
  CAST(LAT AS STRING)+', '+CAST(LONG AS STRING) AS LOC, \
  CASE \
    WHEN DOOR_STATUS=1 AND ABS(SPEED)>2.8 \
    THEN 1 \
    ELSE 0 \
  END AS DOOR_OPEN_MOVING, \
  CASE \
    WHEN ABS(ACCEL)>5 \
    THEN 1 \
    ELSE 0 \
  END AS HARSH_BRAKING, \
  CASE \
    WHEN ABS(SPEED)>13.89 \
    THEN 1 \
    ELSE 0 \
  END AS SPEEDING \
FROM BUS \
WHERE LAT IS NOT NULL AND LONG IS NOT NULL \
EMIT CHANGES;

CREATE TABLE BUS_SAFETY_TABLE WITH (KAFKA_TOPIC='bus_safety_table',FORMAT='JSON_SR') \
AS SELECT \
  LATEST_BY_OFFSET(HEADSIGN) AS HEADSIGN, \
  LATEST_BY_OFFSET(ROUTE_NUM) AS ROUTE_NUM, \
  LATEST_BY_OFFSET(DIRECTION_ID) AS DIRECTION_ID, \
  OPERATOR_ID, \
  VEH_ID, \
  AVG(DEVIATION) AS AVERAGE_DEVIATION, \
  LATEST_BY_OFFSET(START_TIME) AS START_TIME, \
  SUM(DOOR_OPEN_MOVING) AS DOOR_OPEN_MOVING_T, \
  SUM(HARSH_BRAKING) AS HARSH_BRAKING_T, \
  SUM(SPEEDING) AS SPEEDING_T, \
  COUNT(*) AS TRIP_T \
FROM BUS_SAFETY \
WINDOW SESSION (60 SECONDS, RETENTION 1 DAY, GRACE PERIOD 10 SECONDS) \
GROUP BY OPERATOR_ID, VEH_ID \
EMIT CHANGES;
