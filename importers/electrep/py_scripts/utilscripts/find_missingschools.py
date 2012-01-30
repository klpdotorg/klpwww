#!/usr/bin/env python
import Utility.EXIF
import os,sys
import psycopg2
import Utility.KLPDB

connection = Utility.KLPDB.getConnection()
cursor = connection.cursor()

#datafile = open('../data/masterlist_sch.csv','r')
datafile = open('../data/allschool.csv','r')
#newdatafile = open('../data/missinglist_sch.csv','w')
newdatafile = open('../data/missing_schids_Aug10.csv','w')
dbschoollist = []
dbcount = 0
cursor.execute("select distinct sid from tb_school_electedrep;")
result = cursor.fetchall()
for row in result:
  dbschoollist.append(str(row[0]).strip())
  dbcount = dbcount + 1
print "Count in db: " , dbcount
count = 0
for line in datafile.readlines():
  #row=line.split(',')
  #if str(row[4]).strip() not in dbschoollist:
  if str(line.strip()) not in dbschoollist:
    newdatafile.write(line)
    count = count + 1
print "Count in missing list: " , count
newdatafile.write('Number of schools found in DB:'+str(dbcount)+',Number of schools missing:'+str(count)+',Total number of schools:'+str(count+dbcount)+'\n')

datafile.close()
newdatafile.close()
cursor.close()
