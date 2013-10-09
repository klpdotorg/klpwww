#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
# Setup dblink
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/dblink.sql

# For the types that will be queried through the dblink to klp_coord
sudo -u postgres createlang plpgsql ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/postgis-1.5/postgis.sql
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/postgis-1.5/spatial_ref_sys.sql
# Grant privileges
sudo -u postgres psql -d ${DBNAME} -f grants.sql

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f sslcdata.sql 

# Load ${DBNAME}
# convert mdb to csv using sslc_exp.py 

echo Loading data into ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f load/load.sql

# Agg functions
echo "Add new year info to agg_sslc.sql then load agg_sslc.sql to sslcdata database"
