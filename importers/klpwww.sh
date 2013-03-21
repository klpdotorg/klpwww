#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
# Setup dblink
sudo -u postgres psql -d ${DBNAME} -c "CREATE EXTENSION dblink"

# For the types that will be queried through the dblink to klp_coord
sudo -u postgres createlang plpgsql ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
# Grant privileges
sudo -u postgres psql -d ${DBNAME} -f grants.sql

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

# Load ${DBNAME}
python klp-exp.py

echo Loading data into ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f load/load.sql


#fixing ang repeat test
python ang-repeat.py
psql -U ${OWNER} -d ${DBNAME} -f fixang.sql

echo Running fixes for ${DBNAME} 
psql -U ${OWNER} -d ${DBNAME} -f fixes.sql 

echo Computing aggregates for ${DBNAME}
psql -U ${OWNER} -d ${DBNAME} -f agg.sql 


echo Running inserts for pratham mysore
psql -U ${OWNER} -d ${DBNAME} -f pratham/db_scripts/load/pratham_assessment.sql
psql -U ${OWNER} -d ${DBNAME} -f pratham/db_scripts/load/pratham_assessment_agg.sql

echo Utility functions for library on ${DBNAME}
psql -U ${OWNER} -d ${DBNAME} -f utilityfunct.sql
