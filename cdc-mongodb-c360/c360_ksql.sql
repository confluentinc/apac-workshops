
create stream account_stream with (kafka_topic='ORCLCDB.C__MYUSER.CUSTACCOUNT', value_format='avro');

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

create stream transactions_stream with (kafka_topic='ORCLCDB.C__MYUSER.CUSTTRANSACTIONS', value_format='avro');

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

show topics;
