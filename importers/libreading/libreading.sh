#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp


sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -c "CREATE EXTENSION dblink"
sudo -u postgres createlang plpgsql ${DBNAME}

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

echo parsing lib reading csvs 
python ${DBNAME}.py
echo loading DB
psql -U ${OWNER} -d ${DBNAME} -f load/tb_assessment.sql
#psql -U ${OWNER} -d ${DBNAME} -f fixes.sql
psql -U ${OWNER} -d ${DBNAME} -f agg.sql

echo "Seeding data done!"
