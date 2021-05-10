## Changes:

__docker-compose.yml__
* Updated Confluent images to 6.1.0
* Changed ksqlDB to use community image ksqldb-server:0.15.0
  * Removed monitoring interceptor configs (which are not on the community image)
  * Added configs required for embedded connect worker
  * mount Confluent Hub connector files from local copy rather than installing from within container
* Removed unused containers:
  * connect (unneeded, connectors run on ksqldb-server)
  * ksqldb-cli (unneeded, ksqldb-server has the CLI and removes need to juggle server and CLI versions)
  * rest-proxy (does not seem to be used)
  * mongo-express (does not seem to be used)
* Removed curl commands from postgres, dataiku-dss and ksqldb-server and included in setup instructions (remove need to download every time demo is run, demo can now run offline assuming setup steps below are followed)

__sql.zip__
* Modify SQL files (cardholders.sql, merchants.sql, transactions_known.sql and transactions_unknown.sql) to insert all lines at once (clearer output from start script)
* Remove duplicate transaction ids from transactions_known.sql: 500005, 500015

__dss.zip__
* in `dss/config/users.json`: change `userProfile` to `DATA_SCIENTIST` (full access) to avoid permissions issues when starting API endpoint.

__start.sh__
* Added to automate startup and streamline docker-compose file. Startup is now fully automated including starting the Dataiku API endpoint.

__ksql-queries.sql and ksql-queries2.sql__
* Use default all caps for all stream and table names so that ksqlDB flow diagram works properly.
