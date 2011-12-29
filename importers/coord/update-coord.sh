#!/bin/sh

DBNAME=klp-coord
OWNER=klp

echo Loading data...
psql -U ${OWNER} -d ${DBNAME} -f load/update-klp-coord.sql && echo done.
