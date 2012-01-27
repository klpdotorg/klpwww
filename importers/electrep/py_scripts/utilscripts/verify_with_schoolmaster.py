#!/usr/bin/env python
import os,sys

datafile = open('../data/school_master.csv','r')
dbfile = open('../data/dbs_with_rep.lst','r')
updatefile = open('../data/tb_school_rep.csv','w')
dbschooldict = {}
updatefile.write('TYPE,DIST,BLK,CLUS,SCH ID,SCH NAME,WARD NAME, MLA CONST NAME, MP CONST NAME\n')
for line in dbfile.readlines()[2:-2]:
  row = line.split('|')
  dbschooldict[str(row[0]).strip()]='"'+row[1].strip()+'","'+row[2].strip()+'","'+row[3].strip()+'"'

for line in datafile.readlines()[1:]:
  row = line.split(',')
  schid = int(row[4])
  if row[4] in dbschooldict.keys():
      sch_info_str = row[0].strip()+','+row[1].strip()+','+row[2].strip()+','+row[3].strip()+','+row[4].strip()+','+row[5].strip()
      updatefile.write(sch_info_str + ',' + dbschooldict[row[4]] + '\n')

datafile.close()
dbfile.close()
updatefile.close()
