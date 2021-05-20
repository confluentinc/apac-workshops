
export DOCKERHOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)

docker-compose -f docker-compose-local.yml up -d

sleep 30

echo "create stream and tables... initialize..."

docker exec -it ksqldb-cli bash -c 'cat /data/scripts/wip-initialize.ksql | ksql http://ksqldb-server:8088'

sleep 5

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from wip_current where lab in (\'EOLT\', \'EMTC\');",
  "streamsProperties": {}
}' --http2

sleep 5

echo "update jobs events..."

docker exec -it ksqldb-cli bash -c 'cat /data/scripts/update-jobs.ksql | ksql http://ksqldb-server:8088'

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from wip_current where lab in (\'EOLT\', \'EMTC\');",
  "streamsProperties": {}
}' --http2

sleep 5

echo "re-initialize..."

docker exec -it ksqldb-cli bash -c 'cat /data/scripts/wip-reinitialize.ksql | ksql http://ksqldb-server:8088'

sleep 5

curl -X "POST" "http://ksqldb-server:8088/query-stream" -d $'{
  "sql": "select * from wip_current where lab in (\'EOLT\', \'EMTC\');",
  "streamsProperties": {}
}' --http2

