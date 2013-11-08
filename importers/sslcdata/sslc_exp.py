import sys, subprocess, os
import datetime

DATABASE = sys.argv[1] # .mdb filename with path (exp: mdbs/SSLC_APR_2010.mdb)
filename = sys.argv[2] # output csv filename (exp: KSSEB_SSLC_STATE_RESULT_APR10.csv)
year = sys.argv[3] # academic year id (exp: for 2009-2010 results id is 119)

# Get the list of table names with "mdb-tables"
table_names = subprocess.Popen(["mdb-tables", "-1", DATABASE],
                               stdout=subprocess.PIPE).communicate()[0]
tables = table_names.splitlines()

# start a transaction, speeds things up when importing
sys.stdout.flush()

"""def change_date_format(value):
	print value
	if value:
		try:
			date=value.split(' ')[0]
			return '"'+datetime.datetime.strptime(date, '%d/%m/%y').strftime('%d-%b-%Y')+'"'
		except:
			return 'null'
	else:
		return 'null' """

def rm_spc_char(value):
	if len(value)>0:
		return '"'+str(value).strip('"')+'"'
	else:
		return 'null'

def chk_len(value): # this function for checking the length of results
	if len(value)<=5:
		return value
	else:
		return int(value)

# Dump each table as a CSV file using "mdb-export",
# converting " " in table names to "_" for the CSV filenames.
for table in tables:
    if table != '':
        #filename = "KSEEB_SSLC_STATE_RESULT_"+table.replace(" ","_") + ".csv"
	errfile=open('err','w')  # for wrong entries
        file = open(filename, 'w') 
        print("Dumping " + table)
        contents = subprocess.Popen(["mdb-export", DATABASE, table],
                                    stdout=subprocess.PIPE).communicate()[0]
        #file.write(contents)
	#print contents
	contents=contents.split('\n')
	keys=contents[0].upper().replace("NRC_","").split(',')
	values=range(0,len(keys))
	cols=dict(zip(keys,values)) # getting index of the columns
	for row in contents[1:]:
		try:
			row=row.split(',')
			row.append('null')
			DIST_CODE=rm_spc_char(row[cols.get("DIST_CODE",len(row)-1)])   # check for value else return null .....
        	        TALUQ_CODE=rm_spc_char(row[cols.get("TALUQ_CODE",len(row)-1)])
        	        SCHOOL_CODE=rm_spc_char(row[cols.get("SCHOOL_CODE",len(row)-1)])
        	        SCHOOL_TYPE=rm_spc_char(row[cols.get("SCHOOL_TYPE",len(row)-1)])
        	        URBAN_RURAL=rm_spc_char(row[cols.get("URBAN_RURAL",len(row)-1)])
        	        REG_NO=rm_spc_char(row[cols.get("REG_NO",len(row)-1)])
        	        DOB=rm_spc_char(row[cols.get("DOB",len(row)-1)])
        	        STUDENT_NAME=rm_spc_char(row[cols.get("STUDENT_NAME",len(row)-1)])
        	        MOTHER_NAME=rm_spc_char(row[cols.get("MOTHER_NAME",len(row)-1)])
        	        FATHER_NAME=rm_spc_char(row[cols.get("FATHER_NAME",len(row)-1)])
        	        CASTE_CODE=rm_spc_char(row[cols.get("CASTE_CODE",len(row)-1)])
        	        GENDER_CODE=rm_spc_char(row[cols.get("GENDER_CODE",len(row)-1)])
        	        MEDIUM=rm_spc_char(row[cols.get("MEDIUM",len(row)-1)])
        	        PHYSICAL_CONDITION=rm_spc_char(row[cols.get("PHYSICAL_CONDITION",len(row)-1)])
        	        CENTER_CODE=rm_spc_char(row[cols.get("CENTER_CODE",len(row)-1)])
        	        L1_MARKS=rm_spc_char(row[cols.get("L1_MARKS",len(row)-1)])
        	        L1_RESULT=chk_len(rm_spc_char(row[cols.get("L1_RESULT",len(row)-1)]))
        	        L2_MARKS=rm_spc_char(row[cols.get("L2_MARKS",len(row)-1)])
        	        L2_RESULT=chk_len(rm_spc_char(row[cols.get("L2_RESULT",len(row)-1)]))
        	        L3_MARKS=rm_spc_char(row[cols.get("L3_MARKS",len(row)-1)])
        	        L3_RESULT=chk_len(rm_spc_char(row[cols.get("L3_RESULT",len(row)-1)]))
        	        S1_MARKS=rm_spc_char(row[cols.get("S1_MARKS",len(row)-1)])
        	        S1_RESULT=chk_len(rm_spc_char(row[cols.get("S1_RESULT",len(row)-1)]))
        	        S2_MARKS=rm_spc_char(row[cols.get("S2_MARKS",len(row)-1)])
        	        S2_RESULT=chk_len(rm_spc_char(row[cols.get("S2_RESULT",len(row)-1)]))
        	        S3_MARKS=rm_spc_char(row[cols.get("S3_MARKS",len(row)-1)])
        	        S3_RESULT=chk_len(rm_spc_char(row[cols.get("S3_RESULT",len(row)-1)]))
        	        TOTAL_MARKS=rm_spc_char(row[cols.get("TOTAL_MARKS",len(row)-1)])
        	        RESULT=rm_spc_char(row[cols.get("RESULT",len(row)-1)])
        	        CLASS=rm_spc_char(row[cols.get("CLASS",len(row)-1)])
        	        CANDIDATE_TYPE=rm_spc_char(row[cols.get("CANDIDATE_TYPE",len(row)-1)])
        	        SCHOOL_NAME=rm_spc_char(row[cols.get("SCHOOL_NAME",len(row)-1)])
			YEAR=rm_spc_char(year)
			file.write(DIST_CODE+","+SCHOOL_CODE+","+REG_NO+","+DOB+","+STUDENT_NAME+","+MOTHER_NAME+","+FATHER_NAME+","+CASTE_CODE+","+GENDER_CODE+","+MEDIUM+","+PHYSICAL_CONDITION+","+CENTER_CODE+","+L1_MARKS+","+L1_RESULT+","+L2_MARKS+","+L2_RESULT+","+L3_MARKS+","+L3_RESULT+","+S1_MARKS+","+S1_RESULT+","+S2_MARKS+","+S2_RESULT+","+S3_MARKS+","+S3_RESULT+","+TOTAL_MARKS+","+RESULT+","+CLASS+","+SCHOOL_NAME+","+YEAR+","+TALUQ_CODE+","+SCHOOL_TYPE+","+URBAN_RURAL+","+CANDIDATE_TYPE+"\n")   # writing to csv
		except:
			errfile.write(table+'----'+str(row)+'---exception:'+str(sys.exc_info()[0])+'\n') # writing wrong entries to err file
        file.close()
