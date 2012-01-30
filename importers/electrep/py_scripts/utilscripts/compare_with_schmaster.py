#!/usr/bin/env python
import os,sys

datafile = open('../data/school_master.csv','r')
dbfile = open('../data/school_heirarchy.lst','r')
updatefile = open('../db_scripts/load/update_tb_school_rep.sql','w')
dbschooldict = {}

for line in dbfile.readlines()[2:-2]:
  row = line.split('|')
  dbschooldict[str(row[0]).strip()]=row[1].strip()

for line in datafile.readlines()[1:]:
  row = line.split(',')
  schid = int(row[4])
  heirarchy = 2 if row[0].strip() == '"PRESCHOOL"' else 1
  if row[4] in dbschooldict.keys():
    if int(dbschooldict[row[4]]) != int(heirarchy):     
      #print '*' + str(heirarchy) + '*'
      #print '*' + str(dbschooldict[row[4]]) + '*'
      updatefile.write('update tb_school_electedrep set heirarchy=' + str(heirarchy) + ' where sid=' + str(schid) +';\n')

datafile.close()
dbfile.close()
updatefile.close()
