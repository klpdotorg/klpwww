import csv
import Utility.KLPDB
import sys

inputfile=sys.argv[2]

qstarter=6

sysconnection = Utility.KLPDB.getSysConnection()
syscursor = sysconnection.cursor()

connection = Utility.KLPDB.getConnection()
cursor = connection.cursor()

schoolqs=["schoolq1","schoolq2","schoolq3","schoolq7","schoolq8","schoolq5","schoolq6","schoolq4","schoolq9","schoolq16","schoolq17","schoolq10","schoolq18","schoolq19","schoolq13","schoolq11","schoolq20","schoolq21"]
angqs=["angq2","angq13","angq14","angq5","angq6","angq11","angq12","angq10","angq7","angq9","angq15","angq16","angq17","angq18","angq1","angq4","angq22","angq23","angq24","angq3","angq19"]

def getValue(data):
  if data=='':
    return 'null'
  else:
     return "'"+data+"'"

def getQuestionDict():
    qidsdict = {}
    try:
      syscursor.execute("select id, qfield from tb_sys_questions order by id")
      result = syscursor.fetchall()
      for row in result:
        qidsdict[row[1]] = row[0]
      sysconnection.commit()
      return qidsdict
    except:
      traceback.print_exc(file=sys.stderr)
      sysconnection.rollback()
      return None


def testsid(sid,type):
  cursor.execute("select count(*) from tb_school s,tb_boundary b where s.bid=b.id and s.id="+str(sid)+" and b.type="+str(type))
  result=cursor.fetchall()
  for row in result:
    if row[0]==0:
      print "invalid sid "+str(sid)+" type: "+str(type)
      return 0
    else:
      return 1
  

def main():
  data=csv.reader(open(inputfile,'r'),delimiter='|')
  qdict=getQuestionDict()
  count=1
  for row in data:
    if count<3:
      count=count+1
      continue
    qdata={}
    sid=row[0]
    name=getValue(row[1])
    email=getValue(row[2])
    phone=getValue(row[3])
    dateofvisit=getValue(row[4])
    comments=getValue(row[5])
    for i in range(6,len(row)):
      if sys.argv[1]=="school":
        type=1
        qfield=schoolqs[i-qstarter]
        print str(i)+" "+qfield
      else:
        type=2
        qfield=angqs[i-qstarter]
      qdata[qdict[qfield]]=row[i]
    if testsid(sid,type)==0:
       continue
    query="insert into tb_sys_data(schoolid,name,email,telephone,dateofvisit,comments) values("+sid+","+name+","+email+","+phone+","+dateofvisit+","+comments+")"
    syscursor.execute("BEGIN")
    syscursor.execute("LOCK TABLE tb_sys_data IN ROW EXCLUSIVE MODE");
    syscursor.execute(query)
    syscursor.execute("select currval('tb_sys_data_id_seq')")
    result = syscursor.fetchall()
    syscursor.execute("COMMIT")
    for rows in result:
      sysid=rows[0]
    qansquery="insert into tb_sys_qans(sysid,qid,answer) values( %(sysid)s,%(qid)s,%(answer)s)"
    for q in qdata.keys():
      syscursor.execute(qansquery,{'sysid':sysid,'qid':q,'answer':qdata[q]})
    sysconnection.commit()

  
main()
