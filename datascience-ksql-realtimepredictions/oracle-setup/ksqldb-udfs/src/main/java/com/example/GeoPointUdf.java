package com.example;

import io.confluent.ksql.function.udf.Udf;
import io.confluent.ksql.function.udf.UdfDescription;
import io.confluent.ksql.function.udf.UdfParameter;

@UdfDescription(name = "geopoint",
        author = "Jerrold Law",
        version = "1.0.0",
        description = "A custom UDF for generating GeoPoints.")
public class GeoPointUdf {
    @Udf(description = "Returning GeoPoints from lat and lon.")
    public String geopoint(@UdfParameter("lat") double lat, @UdfParameter("lon") double lon) {
        return "POINT(" + lon + " " + lat + ")";
    }
}