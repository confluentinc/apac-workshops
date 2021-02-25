docker exec -i sqlserver /opt/mssql-tools/bin/sqlcmd -U sa -P Password! << EOF
use c360;
update address set address_line_2='abcdef' where customer_id='C101';
GO
EOF

docker exec -i sqlserver /opt/mssql-tools/bin/sqlcmd -U sa -P Password! << EOF
use c360;
delete from address where customer_id='C102';
GO
EOF

docker exec -i sqlserver /opt/mssql-tools/bin/sqlcmd -U sa -P Password! << EOF
use c360;
delete from phone where customer_id='C102';
GO
EOF

docker exec -i sqlserver /opt/mssql-tools/bin/sqlcmd -U sa -P Password! << EOF
use c360;
delete from profile where customer_id='C102';
GO
EOF

docker exec -i sqlserver /opt/mssql-tools/bin/sqlcmd -U sa -P Password! << EOF
use c360;
insert into profile (customer_id, first_name, last_name) values ('C102', 'back', 'here');
GO
EOF