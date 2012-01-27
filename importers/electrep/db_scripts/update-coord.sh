#!/bin/sh

DBNAME=klp-coord
OWNER=klp

echo Loading data...
python ../py_scripts/parse_for_coords.py
psql -U ${OWNER} -d ${DBNAME} -f electoral-coord.sql && echo done.
psql -U ${OWNER} -d ${DBNAME} -f load/load-electoral-coords.sql && echo done.
