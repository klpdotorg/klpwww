#!/bin/sh

DBNAME=ang_infra
OWNER=klp

if expr length $1 ; then
echo parsing ang infra only questions to csvs 
python py_scripts/loaddb.py $1 1>log.txt 2.err.txt

echo "loading DB"
psql -U ${OWNER} -d ${DBNAME} -f 'db_scripts/load/insertanswers'$1'.sql'
psql -U ${OWNER} -d ${DBNAME} -f 'db_scripts/load/insertanginfo'$1'.sql'

echo Done!
psql -U ${OWNER} -d ${DBNAME} -c "select agg_ang_infra('$1')"
else
echo "please pass year for this file (ex: sh loaddb.sh '2011-2012')"
fi
