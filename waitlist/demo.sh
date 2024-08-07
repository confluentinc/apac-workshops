#!/bin/bash

printf "\n\n================================================================================\n"
printf "Waitlist demo...\n"
printf "================================================================================\n\n"

docker exec -it ksqldb-server ksql -e "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S1111111A', 'add', 'user');"
printf "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S1111111A', 'add', 'user');"
printf "\n\n"
printf "Inserted first user into waitlist. "
read -p "Press Enter to insert second user into waitlist..."

docker exec -it ksqldb-server ksql -e "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S2222222B', 'add', 'user');"
printf "\n"
printf "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S2222222B', 'add', 'user');"
printf "\n\n"
printf "Inserted second user into waitlist. "
read -p "Press Enter to insert third user into waitlist..."

docker exec -it ksqldb-server ksql -e "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S3333333C', 'add', 'user');"
printf "\n"
printf "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S3333333C', 'add', 'user');"
printf "\n\n"
printf "Inserted third user into waitlist. Second user has decided to cancel their waitlist. "
read -p "Press Enter to continue..."

docker exec -it ksqldb-server ksql -e "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S2222222B', 'remove', 'user');"
printf "\n"
printf "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S2222222B', 'remove', 'user');"
printf "\n\n"
printf "Second user removed from waitlist. Second user now wants the waitlist again. "
read -p "Press Enter to continue..."

docker exec -it ksqldb-server ksql -e "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S2222222B', 'add', 'user');"
printf "\n"
printf "INSERT INTO waitlist_reqs (appt_time, nric, req_type, source) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S2222222B', 'add', 'user');"
printf "\n"
read -p "Press Enter to continue..."

printf "\n\n================================================================================\n"
printf "Waitlist demo - matching cancellation...\n"
printf "================================================================================\n\n"

docker exec -it ksqldb-server ksql -e "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "\n"
printf "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "\n\n"
printf "Cancellation has been received that matches a user on the waitlist. "
printf "Waitlist notification sent and timeslot is not freed up. \n"
read -p "Press Enter to continue..."

printf "\n\n================================================================================\n"
printf "Cancellation demo...\n"
printf "================================================================================\n\n"
docker exec -it ksqldb-server ksql -e "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "\n"
sleep 2
docker exec -it ksqldb-server ksql -e "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "\n"
printf "Waitlist has been cleared. Cancellations should now free up the timeslot. "
read -p "Press Enter to continue..."

docker exec -it ksqldb-server ksql -e "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "\n"
printf "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-15 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "\n"
sleep 2
docker exec -it ksqldb-server ksql -e "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-14 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "\n"
printf "INSERT INTO cancellations (appt_time, nric) VALUES (PARSE_TIMESTAMP('2022-01-14 10:30', 'yyyy-MM-dd HH:mm', 'Asia/Singapore'), 'S4444444D');"
printf "\n"
