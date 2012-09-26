#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp


sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/dblink.sql
sudo -u postgres createlang plpgsql ${DBNAME}

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

echo parsing Dise csvs 
python ../py_scripts/dise_all.py
echo loading DB
psql -u ${OWNER} -d ${DBNAME} -f alter_tables.sql
psql -u ${OWNER} -d ${DBNAME} -f load/tb_dise_basic.sql
psql -u ${OWNER} -d ${DBNAME} -f load/tb_dise_facility.sql
psql -u ${OWNER} -d ${DBNAME} -f load/tb_dise_general.sql
psql -u ${OWNER} -d ${DBNAME} -f load/tb_dise_teacher.sql
psql -u ${OWNER} -d ${DBNAME} -f load/tb_dise_rte.sql
psql -u ${OWNER} -d ${DBNAME} -f load/tb_dise_enrol.sql
echo "Seeding data done!"
psql -u ${OWNER} -d ${DBNAME} -f agg_dise.sql
echo "Aggregating data done!"
echo "All done!"

