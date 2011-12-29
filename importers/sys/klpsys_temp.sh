#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

# Create schema
psql -U ${OWNER} -d ${DBNAME} -f ${DBNAME}.sql 

