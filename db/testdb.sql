CREATE DATABASE testdb;

CREATE USER 'testuser'@'localhost'
IDENTIFIED BY 'testpass';

GRANT ALL PRIVILEGES
ON testdb.*
TO 'testuser'@'localhost';

FLUSH PRIVILEGES;