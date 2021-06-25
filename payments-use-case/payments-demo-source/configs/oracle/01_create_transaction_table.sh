#!/bin/sh

echo 'Creating TRANSACTION table in CDB'

sqlplus C\#\#MYUSER/mypassword@//localhost:1521/ORCLCDB  <<- EOF
  create table transaction (transaction_id VARCHAR(100), card_id VARCHAR(100), paid VARCHAR(50), lat VARCHAR(50), longd VARCHAR(50));
EOF
