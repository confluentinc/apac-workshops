package com.example;

import java.io.IOException;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

import io.confluent.ksql.function.udf.Udf;
import io.confluent.ksql.function.udf.UdfDescription;
import io.confluent.ksql.function.udf.UdfParameter;

import org.apache.kafka.common.Configurable;

import java.util.Map;

@UdfDescription(name = "predictFraud",
        author = "Jerrold Law",
        version = "1.0.0",
        description = "A custom UDF for predicting fraud based on trained model in Dataiku.")

public class PredictFraudUdf { // implements Configurable
    //    @Override
    //    public void configure(final Map<String, ?> map) {
    //        String s = (String) map.get("ksql.functions.fraud.url");
    //        url = s;
    //    }

    public static final MediaType JSON = MediaType.get("application/json; charset=utf-8");

    OkHttpClient client = new OkHttpClient();

    String post(String url, String json) throws IOException {
        RequestBody body = RequestBody.create(json, JSON);
        Request request = new Request.Builder()
                .url(url)
                .post(body)
                .build();
        try (Response response = client.newCall(request).execute()) {
            return response.body().string();
        }
    }

    @Udf(description = "Predict Fraud Results")
    public String predictFraud(@UdfParameter("purchaseDate") String purchaseDate,
                               @UdfParameter("cardId") String cardId,
                               @UdfParameter("merchantId") String merchantId,
                               @UdfParameter("merchantCategoryId") long merchantCategoryId,
                               @UdfParameter("itemCategory") String itemCategory,
                               @UdfParameter("purchaseAmount") double purchaseAmount,
                               @UdfParameter("signatureProvided") long signatureProvided,
                               @UdfParameter("cardFirstActiveMonth") String cardFirstActiveMonth,
                               @UdfParameter("cardRewardProgram") String cardRewardProgram,
                               @UdfParameter("cardLatitude") double cardLatitude,
                               @UdfParameter("cardLongitude") double cardLongitude,
                               @UdfParameter("cardFicoScore") long cardFicoScore,
                               @UdfParameter("cardAge") long cardAge,
                               @UdfParameter("merchantSubsectorDescription") String merchantSubsectorDescription,
                               @UdfParameter("merchantLatitude") double merchantLatitude,
                               @UdfParameter("merchantLongitude") double merchantLongitude,
                               @UdfParameter("merchantCardholderDistance") double merchantCardholderDistance,
                               @UdfParameter("url") String url) throws IOException {

        String json =  "{\"features\": {"
                + "\"purchase_date\": \""                     + purchaseDate + "\","
                + "\"card_id\": \""                           + cardId + "\","
                + "\"merchant_id\": \""                       + merchantId + "\","
                + "\"merchant_category_id\": \""              + merchantCategoryId + "\","
                + "\"item_category\": \""                     + itemCategory + "\","
                + "\"purchase_amount\": \""                   + purchaseAmount + "\","
                + "\"signature_provided\": \""                + signatureProvided + "\","
                + "\"card_first_active_month\": \""           + cardFirstActiveMonth + "\","
                + "\"card_reward_program\": \""               + cardRewardProgram + "\","
                + "\"card_latitude\": \""                     + cardLatitude + "\","
                + "\"card_longitude\": \""                    + cardLongitude + "\","
                + "\"card_fico_score\": \""                   + cardFicoScore + "\","
                + "\"card_age\": \""                          + cardAge + "\","
                + "\"merchant_subsector_description\": \""    + merchantSubsectorDescription + "\","
                + "\"merchant_latitude\": \""                 + merchantLatitude + "\","
                + "\"merchant_longitude\": \""                + merchantLongitude + "\","
                + "\"merchant_cardholder_distance\": \""      + merchantCardholderDistance + "\""
                + "}}";

        String response = post(url, json);
        return response;
    }
}