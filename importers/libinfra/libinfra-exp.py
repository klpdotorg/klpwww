import csv
import Utility.KLPDB

outputfile=open("libinfra_load.sql",'wb')


connection=Utility.KLPDB.getConnection()
cursor=connection.cursor()

query="select count(id) from tb_school where id=%s"

def checkdata(data):
  if data=='':
    return 'null'
  else:
    return data


def checksid(sid):
  cursor.execute(query,(sid,))
  result=cursor.fetchall()
  for data in result:
    if data[0]==0:
      print "Invalid sid "+str(sid)
  
    

def main():
  data=csv.reader(open('libinfra.csv','r'),delimiter='|')
  for row in data:
    sid=row[3]
    checksid(sid)
    status=row[8]
    year=checkdata(row[9])
    type=row[10]
    books=checkdata(row[11])
    racks=checkdata(row[12])
    tables=checkdata(row[13])
    chairs=checkdata(row[14])
    computers=checkdata(row[15])
    ups=checkdata(row[16])
    outputfile.write("insert into tb_libinfra values("+sid+",'"+status+"',"+year+",'"+type+"',"+books+","+racks+","+tables+","+chairs+","+computers+","+ups+");\n")

main()
