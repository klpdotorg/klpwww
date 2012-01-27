#!/usr/bin/env python
# replace a string in multiple files

import fileinput
import sys
import os


filenames = ['/home/megha/www/reports/mpmla/cleanfiles/preschool_mp_mla.csv',
             '/home/megha/www/reports/mpmla/cleanfiles/school_mp_mla.csv']
repldict = { 'BASAVANAGAUDI':'BASAVANAGUDI',
'CHAMARJPET':'CHAMARAJPET',
'"DASARAHALLI"':'"T.DASARAHALLI"',
'GOVINDRAJNAGAR':'GOVINDRAJ NAGAR',
'HEBBALA':'HEBBAL',
'JAYANAGARA':'JAYANAGAR',
'K R PURAM':'KR PURAM',
'MAHALAKSHMILAYOUT':'MAHALAKSHMI LAYOUT',
'MALESHWARAM':'MALLESHWARAM',
'PULIKESHINAGARA':'PULAKESHINAGAR',
'RAJAJINAGARA':'RAJAJINAGAR',
'RAJARAJESHVARINAGARA':'RAJARAJESWARINAGARA',
'"T . DASARAHALLI"':'"T.DASARAHALLI"',
'VIAJAYNAGARA':'VIJAYNAGAR'}
try:
  for filename in filenames:
    print 'working on file : ' + filename
    replcount = 0
    of = open(filename,'r')
    nf = open(filename + '.new', 'w')
    for line in of.readlines():
      #print line
      for stext in repldict.keys():
        #print 'checking for replacement of' + stext
        if stext in line:
          replcount = replcount + 1
          rtext = repldict[stext]
          line = line.replace(stext, rtext)
          print 'Replacement count: ' + str(replcount)
      nf.write(line)
    nf.close()
    of.close()
except:
  print 'Unexpected error:', sys.exc_info()
