SET 'auto.offset.reset' = 'earliest';

CREATE OR REPLACE STREAM user_locations
WITH (KAFKA_TOPIC='user_locations', FORMAT='JSON_SR')
AS SELECT rowkey as userid,
  ROWTIME AS timestamp,
  CAST(latitude AS DECIMAL(10,7)) AS latitude,
  CAST(longitude AS DECIMAL(10,7)) AS longitude,
  CASE
    WHEN CAST(latitude AS DECIMAL(10,7)) BETWEEN 14.5467125 AND 14.5506089
      AND CAST(longitude AS DECIMAL(10,7)) BETWEEN 121.045773 AND 121.0496694
    THEN 'Bonifacio-West'
    WHEN CAST(latitude AS DECIMAL(10,7)) BETWEEN 14.5453847 AND 14.5492811
      AND CAST(longitude AS DECIMAL(10,7)) BETWEEN 121.0496694 AND 121.0535658
    THEN 'Bonifacio-South'
    WHEN CAST(latitude AS DECIMAL(10,7)) BETWEEN 14.5510185 AND 14.5549149
      AND CAST(longitude AS DECIMAL(10,7)) BETWEEN 121.0497235 AND 121.0536199
    THEN 'Bonifacio-North'
    END AS area
FROM user_locations_raw;
