import csv
import psycopg2
import sys
import re
import os
import Utility.KLPDB
import shutil

abspath = os.path.dirname(__file__)
rootdir = abspath

#TODO change depending on where the files are stored
#odir="/srv/klpwww_new/uploaded_images/sys/"
odir="/home/megha/www/klpwww_mock/uploaded_images/sys/"

#Create dirs if not already there
newodir=rootdir+"correctedsys/sys/"
if not os.path.exists(newodir):
    os.makedirs(newodir)

newverifiedodir=rootdir+"correctedsys/verifiedsys/"
if not os.path.exists(newverifiedodir):
    os.makedirs(newverifiedodir)

#hdir="/srv/klpwww_new/uploaded_images/school_pics_hash/"
hdir="/home/megha/www/klpwww_mock/uploaded_images/school_pics_hash/"

newhdir=rootdir+"correctedsys/school_pics_hash/"
if not os.path.exists(newhdir):
    os.makedirs(newhdir)

connection = Utility.KLPDB.getSYSConnection()
cursor = connection.cursor()

getsysimages ='select sysid,original_file,hash_file, verified from tb_sys_images'
checkorigfile='select sysid from tb_sys_images where original_file=%s'
checkhashfile='select sysid from tb_sys_images where hash_file=%s'

outputfile=open(rootdir+'sysoutput.csv','wb')
#origfile=open(rootdir+'sysorig.csv','wb')
#hashfile=open(rootdir+'syshash.csv','wb')
updatedb=open(rootdir+'updatesysdb.sql','wb')

def getRow(row):
  line = str(row).strip('(')
  line = line.strip(')')
  return line

outputfile.write("sysid,origfile,orig file status, hash file,hash file status\n")

def checkSYSImages(row):
  sysid=str(row[0]).strip()
  ofile=row[1].strip()
  hfile=row[2].strip()
  verified=row[3].strip()
  

  outputfile.write(str(sysid)+","+ofile+",")
  if not os.path.isfile(odir+ofile):
    outputfile.write("not present")
    updatedb.write("delete from tb_sys_images where hash_file='"+hfile+"';\n")
    return
  else:
    outputfile.write("present")
    if verified=='Y':
      shutil.copy(odir+ofile,newverifiedodir+hfile)
    else:
      shutil.copyfile(odir+ofile,newodir+hfile)
    
  if verified=='Y':
    outputfile.write(","+hfile+",")
    if not os.path.isfile(hdir+hfile):
      outputfile.write("not present")
      shutil.copyfile(newverifiedodir+hfile,newhdir+hfile)
      os.system("mogrify -resize 50% "+newhdir+hfile)
    else:
      outputfile.write("present")
      shutil.copyfile(hdir+hfile,newhdir+hfile)
  outputfile.write("\n")


def verifyFile(filename,query,outfile):
 cursor.execute(query,(filename,))
 result = cursor.fetchall() 
 if len(result)> 0:
    outfile.write(filename+", image found \n")
 else:
    outfile.write(filename+", image not found \n")

def checkFiles():
  for dirname,subdirs,filenames in os.walk(odir):
     for filename in filenames:
        verifyFile(filename,checkorigfile,origfile)

  for dirname,subdirs,filenames in os.walk(hdir):
     for filename in filenames:
        verifyFile(filename,checkhashfile,hashfile)
    
    
     

def main():
 cursor.execute(getsysimages)
 result = cursor.fetchall() 
 for data in result:
   checkSYSImages(data)

 #checkFiles()

main()
