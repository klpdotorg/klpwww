#!/usr/bin/env python
import xml.dom.minidom
import csv
#import Levenshtein
import difflib
from xml.dom.minidom import Node

ac_datasource = open('../data/AC_LATLONG.xml')
pc_datasource = open('../data/PC_LATLONG.xml')
ward_datasource = open('../data/Ward_latlongs.csv','r')
wf = open('../db_scripts/load/load-electoral-coords.sql','w')

ac_dom = xml.dom.minidom.parse(ac_datasource)
pc_dom = xml.dom.minidom.parse(pc_datasource)

wardDict = {}
mpDict = {}
mlaDict = {}

def populateLookup():
  dictfile = open('../data/tb_elected_rep.lst','r')
  lines = dictfile.readlines()
  for line in lines[2:-2]:
    data = line.split('|')
    if data[2].strip().strip('\n') == 'Ward':
      wardDict[data[1].strip()] = data[0].strip()
    elif data[2].strip().strip('\n') == 'MP Constituency':
      mpDict[data[1].strip()] = data[0].strip()
    else:
      mlaDict[data[1].strip()] = data[0].strip()
  dictfile.close()

def handleConstituency(dom,isAC):
  if isAC == 'Y':
    parentAttr = 'AC_LATLONG'
    constAttr = 'AC_NAME'
    latAttr = 'latitude'
    lonAttr = 'longitude'
  else:
    parentAttr = 'PC_LATLONG'
    constAttr = 'PC_NAME'
    latAttr = 'lat'
    lonAttr = 'long'
  #print mpDict
  #print mlaDict
  for node in dom.getElementsByTagName(parentAttr):
    if 'KARNATAKA' in node.getElementsByTagName('ST_NAME')[0].toxml():
      const_ward_id = -1
      const_ward_type = 'null'
      ac_name = node.getElementsByTagName(constAttr)[0].toxml()
      ac_name_str = ac_name[9:len(ac_name)-10].upper()
      lat = node.getElementsByTagName(latAttr)[0].toxml()
      lon = node.getElementsByTagName(lonAttr)[0].toxml()
      if isAC == 'Y':
        key_str = difflib.get_close_matches(ac_name_str,mlaDict.keys())
        #print key_str
        if len(key_str) > 0:
          const_ward_id = mlaDict[key_str[0]]
          const_ward_type = 'MLA Constituency'
          lat_str = lat[10:len(lat)-11].upper()
          lon_str = lon[11:len(lon)-12].upper()
      else:
        key_str = difflib.get_close_matches(ac_name_str,mpDict.keys())
        if len(key_str) > 0:
          const_ward_id = mpDict[key_str[0]]
          const_ward_type = 'MP Constituency'
          lat_str = lat[5:len(lat)-6].upper()
          lon_str = lon[6:len(lon)-7].upper()
      if const_ward_id != -1:
        wf.write('INSERT INTO electoral_coord (const_ward_id,const_ward_type,coord) VALUES(' + const_ward_id + ',\'' + const_ward_type + '\',' + 'GeomFromText(\'POINT(' + lat_str + ' ' + lon_str + ')\'));\n')


# This function will take care of the constiuencies missed in the AC/ PC Lat Long XMLs and but available in the CSV with elected rep names.
def handleWards():
  lines = ward_datasource.readlines()
  #print wardDict
  for line in lines:
    const_ward_type = 'null'
    const_ward_id = -1
    data = line.split(',')
    key_str = difflib.get_close_matches(data[1].strip().upper(),wardDict.keys())
    if len(key_str) > 0:
      const_ward_id = wardDict[key_str[0]]
      const_ward_type = 'Ward'
      lat_str = data[4].strip()
      lon_str = data[5].strip()
    if const_ward_id != -1:
      wf.write('INSERT INTO electoral_coord (const_ward_id,const_ward_type,coord) VALUES(' + const_ward_id + ',\'' + const_ward_type + '\',' + 'GeomFromText(\'POINT(' + lat_str + ' ' + lon_str + ')\'));\n')
  ward_datasource.close()

populateLookup()
handleConstituency(ac_dom,'Y')
handleConstituency(pc_dom,'N')
handleWards()
ac_dom.unlink()
pc_dom.unlink()
wf.close()
