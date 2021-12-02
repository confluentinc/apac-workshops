
create stream account_stream with (kafka_topic='XE.MYUSER.CUSTACCOUNT', value_format='avro');

set 'auto.offset.reset'='earliest';
set 'processing.guarantee' = 'exactly_once';


CREATE STREAM account_stream_keyed
  WITH(KAFKA_TOPIC='account_stream_keyed') AS
  SELECT
  case when op_type = 'R' or op_type = 'I' or op_type = 'U' then account_id else account_id end as account_id,
  case when op_type = 'R' or op_type = 'I' or op_type = 'U' then customer_id else customer_id end as customer_id,
  case when op_type = 'R' or op_type = 'I' or op_type = 'U' then account_type else null end as account_type,
  case when op_type = 'R' or op_type = 'I' or op_type = 'U' then account_opening_date else null end as account_opening_date
  FROM account_stream
  PARTITION BY case when op_type = 'R' or op_type = 'I' or op_type = 'U' then account_id else account_id end
  EMIT CHANGES;

create stream transactions_stream with (kafka_topic='XE.MYUSER.CUSTTRANSACTIONS', value_format='avro');

CREATE STREAM transactions_stream_keyed
  WITH(KAFKA_TOPIC='transactions_stream_keyed') AS
  SELECT
  case when op_type = 'R' or op_type = 'I' or op_type = 'U' then account_id else account_id end as account_id,
  case when op_type = 'R' or op_type = 'I' or op_type = 'U' then transaction_type else null end as transaction_type,
  case when transaction_type = 'DEPOSIT' then cast(transaction_amount as bigint)
  else cast(transaction_amount as bigint) * -1 end as transaction_amount
  FROM transactions_stream
  PARTITION BY case when op_type = 'R' or op_type = 'I' or op_type = 'U' then account_id else account_id end
  EMIT CHANGES;


create stream account_master_stream as
select
ask.account_id as account_id, ask.customer_id as customer_id, ask.account_type as account_type,
ask.account_opening_date as account_opening_date,
tsk.transaction_amount as transaction_amount, tsk.transaction_type as transaction_type
from account_stream_keyed ask
inner join transactions_stream_keyed tsk within 1 hours on ask.account_id=tsk.account_id
emit changes;




create stream profile_stream with (kafka_topic='server1.dbo.profile', value_format='avro');

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
ad.address_line_1, ad.address_line_2, ad.pin, ad.address_type,
am.account_id, am.account_type, am.account_opening_date,
am.transaction_amount, am.transaction_type
from profile_stream_keyed pr
inner join phone_stream_keyed ph within 1 hours on pr.customer_id=ph.customer_id
inner join address_stream_keyed ad within 1 hours on pr.customer_id=ad.customer_id
inner join account_master_stream am within 1 hours on pr.customer_id=am.customer_id
emit changes;


create table c360_view with (kafka_topic='c360', format='avro', partitions=1)
as
select customer_id, account_id,
latest_by_offset(first_name, false) as first_name,
latest_by_offset(last_name, false) as last_name,
latest_by_offset(datetostring(dob, 'yyyy-MM-dd')) as dob,
latest_by_offset(phone_type, false) as phone_type,
latest_by_offset(phone_num, false) as phone_num,
latest_by_offset(address_line_1, false) as address_line_1,
latest_by_offset(address_line_2, false) as address_line_2,
latest_by_offset(pin, false) as pin,
latest_by_offset(address_type, false) as address_type,
latest_by_offset(account_type, false) as account_type,
latest_by_offset(format_date(account_opening_date, 'yyyy-MM-dd'), false) as account_opening_date,
sum(transaction_amount) as account_balance
from c360_stream
group by customer_id, account_id
emit changes;

