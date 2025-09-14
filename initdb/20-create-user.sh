#!/bin/bash
set -e
user=$(cat /run/secrets/db_user)
pass=$(cat /run/secrets/db_password)
mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
  CREATE USER IF NOT EXISTS '$user'@'%' IDENTIFIED BY '$pass';
  GRANT SELECT, INSERT, UPDATE ON appdb.* TO '$user'@'%';
  FLUSH PRIVILEGES;
EOSQL
