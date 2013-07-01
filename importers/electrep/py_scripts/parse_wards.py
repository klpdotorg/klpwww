#!/usr/bin/env python
import csv
import sys
import os
abspath = os.path.dirname(__file__)
sys.path.append(abspath)

rootdir = '../'

sqlfile=open(rootdir+"db_scripts/load/tb_electedrep_insertwards.sql",'w')
datafile=open(rootdir+"data/Ward_info.csv",'r')

def main():
  data = csv.reader(datafile)
  for row in data:
    sqlfile.write("INSERT INTO tb_electedrep_master (parent,const_ward_name,const_ward_type,elec_comm_code,current_elected_rep,current_elected_party,entry_year) values(3,"+row[1].strip().upper()+",'Ward',"+row[0].strip()+","+row[3].strip()+","+row[4].strip()+",'2012');\n")
  sqlfile.close()
  datafile.close()

main()
