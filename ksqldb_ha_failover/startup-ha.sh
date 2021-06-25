
export DOCKERHOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)

docker-compose -f docker-compose-ha.yml up -d

sleep 30

docker exec -it ksqldb-cli bash -c 'cat /data/scripts/materialized_view.ksql | ksql http://ksqldb-server-1:8088'

sleep 5

echo -e "\n ksqldb cluster status \n"
curl -sX GET http://ksqldb-server-1:8088/clusterStatus

sleep 10

echo -e "\n query materialized view using primary ksqldb server \n"
curl -X "POST" "http://ksqldb-server-1:8088/query-stream" -d $'{
  "sql": "select * from wip_current where LAB = \'EOLT\';",
  "streamsProperties": {}
}' --http2

sleep 5

echo -e "\n bring down primary ksqldb server \n"
docker-compose -f docker-compose-ha.yml stop ksqldb-server-1

sleep 10

echo -e "\n check ksqldb cluster status \n"
curl -sX GET http://ksqldb-server-2:8089/clusterStatus

sleep 10

echo -e "\n query materialized view on standby ksqldb server \n"
curl -X "POST" "http://ksqldb-server-2:8089/query-stream" -d $'{
  "sql": "select * from wip_current where LAB = \'EOLT\';",
  "streamsProperties": {}
}' --http2

sleep 5

echo -e "\n restart ksqldb primary server \n"
docker-compose -f docker-compose-ha.yml start ksqldb-server-1

sleep 30

echo -e "\n check ksqldb cluster status \n"
curl -sX GET http://ksqldb-server-2:8089/clusterStatus

sleep 10

echo -e "\n query materialized view \n"
curl -X "POST" "http://ksqldb-server-1:8088/query-stream" -d $'{
  "sql": "select * from wip_current where LAB = \'EOLT\';",
  "streamsProperties": {}
}' --http2

sleep 5

echo -e "\n bring down both ksqldb servers \n"
docker-compose -f docker-compose-ha.yml stop ksqldb-server-1
docker-compose -f docker-compose-ha.yml stop ksqldb-server-2

sleep 30

echo -e "\n start up both ksqldb servers \n"
docker-compose -f docker-compose-ha.yml start ksqldb-server-1
docker-compose -f docker-compose-ha.yml start ksqldb-server-2

sleep 30

echo -e "\n query materialized view to check status after ksqldb cluster restart \n"
curl -X "POST" "http://ksqldb-server-1:8088/query-stream" -d $'{
  "sql": "select * from wip_current where LAB = \'EOLT\';",
  "streamsProperties": {}
}' --http2

