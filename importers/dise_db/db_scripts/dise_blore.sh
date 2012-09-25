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

echo parsing Dise csvs 
python ../py_scripts/dise_blore.py
echo loading DB
sudo -u postgres psql -d ${DBNAME} -f load/disedata.sql
echo Correcting DISE
python ../py_scripts/utilscripts/verify_dise_blore.py 1>log.txt 2>err.txt
echo loading DB
sudo -u postgres psql -d ${DBNAME} -f load/update_dise_codes.sql
psql -U ${OWNER} -d ${DBNAME} -f agg_dise.sql 
echo Done!
