#!/bin/sh

DBNAME=klpwww_ver2
OWNER=klp


echo parsing Dise csvs 
python ../py_scripts/utilscripts/update_klpwww_dise.py
echo loading DB
psql -U ${OWNER} -d ${DBNAME} -f load/update_klpwww_codes.sql
echo "All done!"

echo parsing Blore Dise csvs 
python ../py_scripts/utilscripts/verify_blore_dise_codes.py
echo loading DB
psql -U ${OWNER} -d ${DBNAME} -f load/update_blore_dise_codes.sql
echo "All done!"
