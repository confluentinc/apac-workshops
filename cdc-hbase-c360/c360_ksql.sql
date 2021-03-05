
create stream profile_stream with (kafka_topic='server1.dbo.profile', value_format='avro');

set 'auto.offset.reset'='earliest';


CREATE STREAM profile_stream_keyed
  WITH(KAFKA_TOPIC='profile_stream_keyed') AS
  SELECT
  case when after is null then before->customer_id else after->customer_id end as customer_id,
  case when after is null then null else after->first_name end as first_name,
  case when after is null then null else after->last_name end as last_name,
  case when after is null then null else after->dob end as dob
  FROM profile_stream
  PARTITION BY case when after is null then before->customer_id else after->customer_id end
  EMIT CHANGES;


create stream phone_stream with (kafka_topic='server1.dbo.phone', value_format='avro');

CREATE STREAM phone_stream_keyed
  WITH(KAFKA_TOPIC='phone_stream_keyed') AS
  SELECT
  case when after is null then before->customer_id else after->customer_id end as customer_id,
  case when after is null then null else after->phone_type end as phone_type,
  case when after is null then null else after->phone_num end as phone_num
  FROM phone_stream
  PARTITION BY case when after is null then before->customer_id else after->customer_id end
  EMIT CHANGES;


create stream address_stream with (kafka_topic='server1.dbo.address', value_format='avro');


CREATE STREAM address_stream_keyed
  WITH(KAFKA_TOPIC='address_stream_keyed') AS
  SELECT
  case when after is null then before->customer_id else after->customer_id end as customer_id,
  case when after is null then null else after->address_line_1 end as address_line_1,
  case when after is null then null else after->address_line_2 end as address_line_2,
  case when after is null then null else after->pin end as pin,
  case when after is null then null else after->address_type end as address_type
  FROM address_stream
  PARTITION BY case when after is null then before->customer_id else after->customer_id end
  EMIT CHANGES;


create stream c360_stream as
select
pr.customer_id as customer_id, pr.first_name, pr.last_name, pr.dob,
ph.phone_type, ph.phone_num,
ad.address_line_1, ad.address_line_2, ad.pin, ad.address_type
from profile_stream_keyed pr
inner join phone_stream_keyed ph within 1 hours on pr.customer_id=ph.customer_id
inner join address_stream_keyed ad within 1 hours on pr.customer_id=ad.customer_id
emit changes;
