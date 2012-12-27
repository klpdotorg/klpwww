#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp


sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/dblink.sql
sudo -u postgres createlang plpgsql ${DBNAME}

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

echo parsing AP MDM csvs 
rm load/tb_middaymeal.sql
python ${DBNAME}.py
echo loading DB
psql -U ${OWNER} -d ${DBNAME} -f load/tb_middaymeal.sql
psql -U ${OWNER} -d ${DBNAME} -f fixes.sql
echo "Seeding data done!"
psql -U ${OWNER} -d ${DBNAME} -f agg_apmdm.sql
echo "All done!"

