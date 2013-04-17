#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -c "CREATE EXTENSION dblink"
sudo -u postgres createlang plpgsql ${DBNAME}
# Create schema
psql -U ${OWNER} -d ${DBNAME} -f 'db_scripts/'${DBNAME}.sql 

echo parsing ang infra only questions to csvs 
python py_scripts/ang_infranew.py

echo "loading DB (only questions)"
psql -U ${OWNER} -d ${DBNAME} -f db_scripts/load/insertquestions.sql

echo Done!
psql -U ${OWNER} -d ${DBNAME} -f db_scripts/agg_infra.sql 
