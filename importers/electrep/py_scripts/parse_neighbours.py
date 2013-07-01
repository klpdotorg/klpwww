#!/usr/bin/env python
import csv
import sys
import os
abspath = os.path.dirname(__file__)
sys.path.append(abspath)

rootdir = '../'

ac_sqlfile=open(rootdir+"db_scripts/load/update_ac_neighbours.sql",'w')
ac_datafile=open(rootdir+"data/AC_neighbours_blore.csv",'r')
pc_sqlfile=open(rootdir+"db_scripts/load/update_pc_neighbours.sql",'w')
pc_datafile=open(rootdir+"data/PC_neighbours_blore.csv",'r')

def main():
  lines = ac_datafile.readlines()
  for row in lines[1:]:
    line = row.split(',')
    ac_sqlfile.write("UPDATE tb_electedrep_master set neighbours ='" + line[2].strip() + "' where elec_comm_code =" + line[1].strip() + " and status = 'active' and const_ward_type = 'MLA Constituency' and parent=2;\n")
  ac_sqlfile.close()
  ac_datafile.close()
  
  lines = pc_datafile.readlines()
  for row in lines[1:]:
    line = row.split(',')
    pc_sqlfile.write("UPDATE tb_electedrep_master set neighbours ='" + line[2].strip() + "' where elec_comm_code =" + line[1].strip() + " and status = 'active' and const_ward_type = 'MP Constituency' and parent=4;\n")
  pc_sqlfile.close()
  pc_datafile.close()

def ward_neighbours():
  sqlfile = open(rootdir + "db_scripts/load/update_ward_neighbours.sql",'w')
  datafile = csv.reader(open('../data/ward_neighbors.csv','r'),delimiter=',')
  for row in datafile:
    sqlfile.write("UPDATE tb_electedrep_master set neighbours ='" + '|'.join(row[1:]) + "' where elec_comm_code =" + row[0].strip() + " and status = 'active' and const_ward_type = 'Ward' and parent=3;\n")
  sqlfile.close() 

main()
ward_neighbours()
