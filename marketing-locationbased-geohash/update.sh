#!/bin/sh
INTERACTIVE=Y

# add rows to locations table
cat <<EOF >/tmp/cmd.sql
USE user-data\
;INSERT INTO locations (id, latitude, longitude, description) VALUES ("2", "14.54733288", "121.05161762", "7-Eleven South of Market")\
;INSERT INTO locations (id, latitude, longitude, description) VALUES ("3", "14.55296667", "121.05167165", "Lawson Eco Tower")\
;DELETE FROM locations WHERE id = 1\
;UPDATE users SET level = "Silver" WHERE userid = 6\
;UPDATE users SET level = "Silver" WHERE userid = 7\
;UPDATE users SET level = "Silver" WHERE userid = 8\
;UPDATE users SET level = "Silver" WHERE userid = 9\
;UPDATE users SET level = "Silver" WHERE userid = 10\
;
EOF
printf "\n\n================================================================================\n"
printf "Adding rows to locations table...\n"
printf "================================================================================\n\n"
cat /tmp/cmd.sql
docker cp /tmp/cmd.sql mysql:/tmp/cmd.sql
docker exec -it mysql /bin/bash -c "mysql -u root -pmysql-pw < /tmp/cmd.sql"
