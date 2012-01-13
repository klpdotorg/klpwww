#!/usr/bin/env python
import Utility.EXIF
import os,sys
import psycopg2
import Utility.KLPDB



connection = Utility.KLPDB.getConnection()
cursor = connection.cursor()


queries=[{'tb_sys_data': 'select * from tb_sys_data'},
         {'tb_sys_qans': 'select * from tb_sys_qans'},
         {'tb_sys_images': 'select * from tb_sys_images'}]


loadfile=open('sysload/load.sql','w',0)
countfile=open('sysload/counter.sql','w',0)

def getRow(row):
  line=str(row).strip('(')
  line = line.strip(')')
  line = line.strip()
  line = line.replace('\'','"')
  line = line.replace('None','')
  return line


def make_csv(tbname,query):
  filename='sysload/'+tbname+'.csv'
  loadfile.write("copy "+tbname+" from "+"'"+os.getcwd()+"/"+filename+"' with csv;\n")
  file=open(filename,'w',0)
  print "Executing qurey"
  sys.stdout.flush()
  cursor.execute(query)
  print "Finished executing query"
  sys.stdout.flush()
  #result = cursor.fetchall()
  #count=0
  for row in cursor:
    firstdata=1
    for data in row:
      data=str(data)
      if firstdata:
        if data=="":
          file.write(data)
        elif data=='None':
          file.write('')
        else:
          file.write('"'+data+'"')
        firstdata=0
      else:
        if data=="":
          file.write(","+data)
        elif data=="None":
          file.write(',')
        else:
          file.write(',"'+data+'"')
    if tbname=='tb_sys_data':
      file.write(',"N"')
    file.write("\n")
  

for query in queries:
  for tbname in query:
    print tbname
    sys.stdout.flush()
    make_csv(tbname,query[tbname])
cursor.execute('select last_value from tb_sys_data_id_seq')
result = cursor.fetchall()
for row in result:
  lastvalue = row[0]
  countfile.write('ALTER SEQUENCE tb_sys_data_id_seq restart with ' + str(lastvalue + 1) + ';');
  countfile.close();

connection.close()
