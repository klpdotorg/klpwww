#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

#sudo -u postgres dropuser ${OWNER}
#sudo -u postgres createuser -S -D -R -E -P ${OWNER}

sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -c "CREATE EXTENSION dblink"

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

echo parsing pratham mysore data
python ../py_scripts/pratham_mysore.py
echo loading DB
sudo -u postgres psql -d ${DBNAME} -f load/pratham_mysore.sql
sudo -u postgres psql -d ${DBNAME} -f load/pratham_assessment.sql
sudo -u postgres psql -d ${DBNAME} -f load/pratham_assessment_eval.sql
echo Done!
