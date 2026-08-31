-- Default database used by www/dbtest.php to verify the complete LAMP stack.
CREATE DATABASE IF NOT EXISTS tswdb
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'tswuser'@'localhost'
IDENTIFIED BY 'tswpass';

GRANT ALL PRIVILEGES
ON tswdb.*
TO 'tswuser'@'localhost';
