#initcap!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}

sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/dblink.sql

# For the types that will be queried through the dblink to klp_coord
sudo -u postgres createlang plpgsql ${DBNAME}

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

python libinfra-exp.py

psql -U ${OWNER} -d ${DBNAME} -f libinfra_load.sql


