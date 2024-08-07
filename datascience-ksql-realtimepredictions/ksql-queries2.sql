SET 'auto.offset.reset' = 'earliest';

CREATE STREAM transactions_fraud_predictions_raw
WITH (KAFKA_TOPIC='transactions_fraud_predictions_raw', value_format='AVRO')
AS SELECT transaction_id,
  predictFraud(
    purchase_date,
    card_id,
    merchant_id,
    merchant_category_id,
    item_category,
    purchase_amount,
    signature_provided,
    card_first_active_month,
    card_reward_program,
    card_latitude,
    card_longitude,
    card_fico_score,
    card_age,
    merchant_subsector_description,
    merchant_latitude,
    merchant_longitude,
    merchant_cardholder_distance,
    'http://dataiku-dss:8888/public/api/v1/fraud_prediction/fraud_prediction/predict'
  ) AS prediction_raw
FROM transactions_prepared_unknown;

CREATE STREAM transactions_fraud_predictions
WITH (KAFKA_TOPIC='transactions_fraud_predictions', value_format='AVRO')
AS SELECT transaction_id,
  CAST(EXTRACTJSONFIELD(prediction_raw, '$.result.prediction') AS BIGINT) AS prediction,
  CAST(EXTRACTJSONFIELD(prediction_raw, '$.result.probaPercentile') AS BIGINT) AS percentile
FROM transactions_fraud_predictions_raw;
