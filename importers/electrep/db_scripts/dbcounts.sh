#!/bin/sh

DBNAME=electrep_new
OWNER=klp

sudo -u postgres psql -d ${DBNAME} -f load/generate_db_counts.sql
