#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

echo Loading data into ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f load/load.sql
