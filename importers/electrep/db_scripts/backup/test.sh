#!/bin/sh

DBNAME=electedrep
OWNER=klp

#sudo -u postgres dropuser ${OWNER}
#sudo -u postgres createuser -S -D -R -E -P ${OWNER}

#sudo -u postgres dropdb ${DBNAME}
#sudo -u postgres createdb -O ${OWNER} -E UTF8 ${DBNAME}
#sudo -u postgres psql -d ${DBNAME} -f /usr/share/postgresql/8.4/contrib/dblink.sql

# Create schema
#psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

echo School Aggs fetched
#python ../py_scripts/schoolagg.py
#sudo -u postgres psql -d ${DBNAME} -f load/schoolcount.sql
echo Parsing Elected Rep datasources
#python ../py_scripts/parse_ac_pc.py
#sudo -u postgres psql -d ${DBNAME} -f load/tb_electedrep_insert.sql
#python ../py_scripts/parse_wards.py
#sudo -u postgres psql -d ${DBNAME} -f load/tb_electedrep_insertwards.sql
#sudo -u postgres psql -d ${DBNAME} -f load/fixes.sql
sudo -u postgres psql -d ${DBNAME} -f load/generate_sch_list.sql
python ../py_scripts/compare_with_schmaster.py
echo Parsing school files and loading School related info
#python ../py_scripts/parse_school_rep.py
#sudo -u postgres psql -d ${DBNAME} -f load/tb_school_electedrep.sql
echo DB Loaded!!
