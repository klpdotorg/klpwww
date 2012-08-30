#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
# Setup dblink
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/dblink.sql

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

# Load ${DBNAME}
python klpsys-exp.py
echo Loading data into ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f sysload/load.sql

echo "Cleaning the db"
python checksysimages.py
sudo -u postgres psql -d ${DBNAME} -f updatesysdb.sql

echo Reset tb_sys_data seq into ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f sysload/counter.sql

echo Run fixes on ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f fixes.sql
