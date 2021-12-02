echo 'Creating transaction tables'

sqlplus MYUSER/password@//localhost:1521/XE  <<- EOF

create table custaccount (
	customer_id varchar(10) not null,
	account_id varchar(10) not null,
	account_type varchar(10) not null,
	account_opening_date date default sysdate
);
insert into custaccount (customer_id, account_id, account_type) values ('C101', 'SAV101', 'savings');
insert into custaccount (customer_id, account_id, account_type) values ('C101', 'CUR101', 'current');
insert into custaccount (customer_id, account_id, account_type) values ('C102', 'CUR102', 'current');

create table custtransactions (
	account_id varchar(10) not null,
	transaction_amount varchar(10) not null,
	transaction_type varchar(10) not null
);
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('SAV101', 1000, 'DEPOSIT');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('SAV101', 500, 'WITHDRAWAL');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('SAV101', 800, 'DEPOSIT');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('CUR101', 2300, 'DEPOSIT');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('CUR101', 300, 'DEPOSIT');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('CUR102', 1000, 'DEPOSIT');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('CUR102', 1500, 'DEPOSIT');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('CUR102', 100, 'WITHDRAWAL');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('CUR102', 600, 'WITHDRAWAL');
insert into custtransactions (account_id, transaction_amount, transaction_type) values ('CUR102', 250, 'WITHDRAWAL');

commit;

exit;

