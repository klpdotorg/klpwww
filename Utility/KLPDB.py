import psycopg2
import web
import os,sys
import traceback
from ConfigParser import SafeConfigParser

def getConfigValue(section,key):
  try:
    config = SafeConfigParser()
    config_fp = open(os.path.join(os.getcwd(),'config/klpconfig.ini'),'r')
    config.readfp(config_fp)
    value = config.get(section,key)
    config_fp.close()
    return value
  except:
    print "Unexpected error:", sys.exc_info()
    print "Exception in user code:"
    print '-'*60
    traceback.print_exc(file=sys.stdout)
    print '-'*60

def getConnection():
  db = getConfigValue('Database','dbname')
  username = getConfigValue('Database','user')
  passwd = getConfigValue('Database','passwd')
  dsn = "dbname="+db+" user="+username+" host='localhost' password="+passwd
  connection = psycopg2.connect(dsn)
  return connection

def getSysConnection():
  db = getConfigValue('SysDatabase','sysdbname')
  username = getConfigValue('SysDatabase','sysuser')
  passwd = getConfigValue('SysDatabase','syspasswd')
  dsn = "dbname="+db+" user="+username+" host='localhost' password="+passwd
  connection = psycopg2.connect(dsn)
  return connection

def getWebDbConnection():
  dbname = getConfigValue('Database','dbname')
  username = getConfigValue('Database','user')
  passwd = getConfigValue('Database','passwd')
  dbtype='postgres'
  connection = web.database(dbn=dbtype,user=username,pw=passwd,db=dbname)
  return connection
