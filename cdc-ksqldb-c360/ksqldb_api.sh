echo "Pull Query with single key"

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from c360_view where KSQL_COL_0 = \'C101|+|SAV101\';",
  "streamsProperties": {}
}' --http2

echo "Pull Query with multiple keys"

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from c360_view where KSQL_COL_0 in (\'C101|+|SAV101\', \'C101|+|CUR101\', \'C102|+|CUR102\');",
  "streamsProperties": {}
}' --http2

echo "Push Query - waiting for new events.."

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from c360_view emit changes;",
  "streamsProperties": {}
}' --http2
