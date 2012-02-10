#!/bin/sh

DBNAME=klp-coord
OWNER=klp

echo Loading data...
psql -U ${OWNER} -d ${DBNAME} -f load/update_circle.sql && echo done.
