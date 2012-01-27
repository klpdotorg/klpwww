#!/usr/bin/env python
import csv
import sys
import re
import os
import difflib
import traceback
import Utility.KLPDB

rootdir = '/home/megha/www/reports/mpmla/'

dbschoollist = []

def populateLookups():
  dictfile = open(rootdir+'data/missing_schids_Aug10.csv','r')
  lines = dictfile.readlines()
  for line in lines[2:-2]:
    dbschoollist.append(str(line).strip())
  dictfile.close()
    
def missing_all():
  filedict = {}
  for i in range(1,13):
    readfile = open(rootdir+'data/missinglist_sch_' + str(i) + '.csv','r')
    for line in readfile.readlines()[1:]:
      row = line.split(',')
      try:
        school_id = int(row[4].strip())
        if school_id in dbschoollist:
          print "Found " + str(school_id) + " in the file missinglist_sch_" + str(i) + ".csv"
        else:
          print "No matches yet"
      except:
        print "Invalid schoolid" + row[4].strip()
        print "Unexpected error:", sys.exc_info()
        print "Exception in user code:"
        print '-'*60
        traceback.print_exc(file=sys.stdout)
        print '-'*60

populateLookups()
missing_all()
