CREATE DATABASE c360;
GO
USE c360;
EXEC sys.sp_cdc_enable_db;

create table profile (
	customer_id varchar(10) not null primary key,
	first_name varchar(20) not null,
	last_name varchar(20) not null,
	dob date not null default getdate()
);
insert into profile (customer_id, first_name, last_name) values ('C101', 'abc', 'def');
insert into profile (customer_id, first_name, last_name) values ('C102', 'ghi', 'jkl');
EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = 'profile', @role_name = NULL, @supports_net_changes = 0;
GO

create table phone (
	customer_id varchar(10) not null,
	phone_type varchar(10),
	phone_num int not null
);
insert into phone (customer_id, phone_type, phone_num) values ('C101', 'mobile', 12345678);
insert into phone (customer_id, phone_type, phone_num) values ('C102', 'mobile', 87654321);
EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = 'phone', @role_name = NULL, @supports_net_changes = 0;
GO

create table address (
	customer_id varchar(10) not null,
	address_line_1 varchar(20) not null,
	address_line_2 varchar(20),
	pin integer not null,
	address_type varchar(10)
);
insert into address (customer_id, address_line_1, address_line_2, pin, address_type) values ('C101', 'abcdef', 'ghijkl', 123456, 'home');
insert into address (customer_id, address_line_1, address_line_2, pin, address_type) values ('C102', 'ghijkl', 'abcdef', 654321, 'office');
EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = 'address', @role_name = NULL, @supports_net_changes = 0;
GO