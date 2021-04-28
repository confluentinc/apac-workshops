SET 'auto.offset.reset' = 'earliest';

CREATE STREAM `transactions_fraud_predictions`
AS SELECT `transaction_id`,
  predictFraud(
    `purchase_date`,
    `card_id`,
    `merchant_id`,
    `merchant_category_id`,
    `item_category`,
    `purchase_amount`,
    `signature_provided`,
    `card_first_active_month`,
    `card_reward_program`,
    `card_latitude`,
    `card_longitude`,
    `card_fico_score`,
    `card_age`,
    `merchant_subsector_description`,
    `merchant_latitude`,
    `merchant_longitude`,
    `merchant_cardholder_distance`,
    'http://dataiku-dss:port/public/api/v1/fraud_prediction/fraud_prediction/predict'
  ) AS `prediction_raw`
FROM `transactions_prepared_unknown`;
