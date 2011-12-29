import psycopg2
import os
from ConfigParser import SafeConfigParser


def getConnection():
  config = SafeConfigParser()
  config.read(os.path.join(os.getcwd(),'config/klpconfig.ini'))
  db = config.get('Database','dbname')
  username = config.get('Database','user')
  passwd = config.get('Database','passwd')
  dsn = "dbname="+db+" user="+username+" host='localhost' password="+passwd
  connection = psycopg2.connect(dsn)
  return connection

