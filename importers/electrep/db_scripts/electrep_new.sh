#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

#sudo -u postgres dropuser ${OWNER}
#sudo -u postgres createuser -S -D -R -E -P ${OWNER}

sudo -u postgres dropdb ${DBNAME}
sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/dblink.sql

# For the types that will be queried through the dblink to klp_coord
sudo -u postgres createlang plpgsql ${DBNAME}
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/postgis-1.5/postgis.sql
sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/postgis-1.5/spatial_ref_sys.sql

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

echo School Aggs fetched
#School Aggregates are being fetched from Oracle
python ../py_scripts/schoolagg.py
sudo -u postgres psql -d ${DBNAME} -f load/schoolcount.sql
echo Parsing Elected Rep datasources
#Data sources for this ac_pc - xmls from eci.gov.in, elected rep information from sarkaritel.com, complete list for bangalore verified with bbmpelections.in
python ../py_scripts/parse_ac_pc.py
sudo -u postgres psql -d ${DBNAME} -f load/tb_electedrep_insert.sql
python ../py_scripts/parse_wards.py
sudo -u postgres psql -d ${DBNAME} -f load/tb_electedrep_insertwards.sql
#Lists for Bangalore verified with bbmpelections.in
sudo -u postgres psql -d ${DBNAME} -f load/fixes.sql
sudo -u postgres psql -d ${DBNAME} -f load/generate_id_file.sql
echo Parsing school files and loading School related info
#original list as defined by akshara team and subsequent missing school lists being processed here
python ../py_scripts/parse_school_rep.py
sudo -u postgres psql -d ${DBNAME} -f load/tb_school_electedrep.sql
echo Co-ord DB updated too...
#AC, PC coordinates obtained from xmls
./update-coord.sh
echo Updated ACs with Neighbours - bangalore
#Neighbours determined by verifying against map on bbmpelections.in
python ../py_scripts/parse_neighbours.py
sudo -u postgres psql -d ${DBNAME} -f load/update_ac_neighbours.sql
sudo -u postgres psql -d ${DBNAME} -f load/update_pc_neighbours.sql
echo Done!
