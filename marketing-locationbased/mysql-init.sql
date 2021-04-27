GRANT ALL PRIVILEGES ON *.* TO 'example-user' WITH GRANT OPTION;
ALTER USER 'example-user'@'%' IDENTIFIED WITH mysql_native_password BY 'example-pw';
FLUSH PRIVILEGES;
USE user-data;
CREATE TABLE users (userid INT not null primary key, firstname TEXT not null, lastname TEXT not null, phone INT not null, level TEXT not null);
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("1", "Elwyn", "Vanyard", 11111111, "Gold");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("2", "Curran", "Vears", 22222222, "Gold");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("3", "Hanson", "Garrity", 33333333, "Silver");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("4", "Woodrow", "Trice", 44444444, "Silver");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("5", "Ferd", "Tomini", 55555555, "Silver");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("6", "Reeva", "Jushcke", 66666666, "Silver");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("7", "Antonio", "De Banke", 77777777, "Silver");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("8", "Arlyne", "Pask", 88888888, "Silver");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("9", "Dimitri", "Rockhill", 99999999, "Silver");
INSERT INTO users (userid, firstname, lastname, phone, level) VALUES ("10", "Oriana", "Romagosa", 10000000, "Silver");
CREATE TABLE locations (latitude TEXT not null, longitude TEXT not null, description TEXT not null, area TEXT not null);
INSERT INTO locations (latitude, longitude, description, area) VALUES ("14.54866069", "121.04772111", "7-Eleven RCBC Center", "Bonifacio-West");
