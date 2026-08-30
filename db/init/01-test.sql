CREATE DATABASE tswdb;

CREATE USER 'tswuser'@'localhost'
IDENTIFIED BY 'tswpass';

GRANT ALL PRIVILEGES
ON tswdb.*
TO 'tswuser'@'localhost';