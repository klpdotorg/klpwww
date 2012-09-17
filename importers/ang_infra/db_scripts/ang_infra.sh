#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

#sudo -u postgres dropuser ${OWNER}
#sudo -u postgres createuser -S -D -R -E -P ${OWNER}

#sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/dblink.sql
sudo -u postgres createlang plpgsql ${DBNAME}
# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

echo parsing ang infra  csvs 
python ../py_scripts/ang_infra.py 1>log.txt 2.err.txt
echo loading DB
sudo -u postgres psql -d ${DBNAME} -f load/insertquestions.sql
sudo -u postgres psql -d ${DBNAME} -f load/insertanswers.sql
echo Done!
psql -U ${OWNER} -d ${DBNAME} -f agg_infra.sql 
