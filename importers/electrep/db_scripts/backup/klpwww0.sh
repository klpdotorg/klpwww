#!/bin/sh

DBNAME=$(basename $0 .sh)
OWNER=klp

#sudo -u postgres dropuser ${OWNER}
#sudo -u postgres createuser -S -D -R -E -P ${OWNER}
psql -U ${OWNER} -d ${DBNAME} -f agg_chart.sql 
