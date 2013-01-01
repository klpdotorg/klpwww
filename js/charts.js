var previousPoint = null;
var datasets;
var choiceContainer;
var info;

google.load('visualization', '1', {'packages':['corechart','table','imagechart']});

var color={"0":"red","O":"red","L":"orange","W":"#ffe438","S":"blue","P":"green","Boys":"blue","Girls":"pink"};

var preschooltypeIndex={"Preschooldistrict":0,"Project":1,"Circle":2,"School":3};
var typeIndex={"District":0,"Block":1,"Cluster":2,"School":3};

var generalChart={"Pie":{1:1,2:1,3:1,7:1,8:1,9:1,10:1,11:1,12:1,13:1,14:1,19:1},"Bar":{5:1,6:1,15:1,18:1,23:1}};

var progtext={"readingprogram":'<br><hr/><br>The <a href=\"/text/reading\"><b>Reading program</b></a> measures the competency of a child using the following levels:<br><ul><li>0:- Child not able to read</li><li>L:- Child able to read letters</li><li>W:- Child able to read words</li><li>S:- Child able to read sentences</li><li>P:- Child able te read Paragaphs</li></ul>',
              "mathprogram":'<br><hr/><br>The <a href=\"/text/maths\"><b>Math program</b></a> measures the competency of a child using the following levels:<br><ul><li>Rung1:- 0-20</li><li>Rung2:- 21-40 </li><li>Rung3: -41-60 </li><li>Rung4:- 61-80 </li><li>Rung5:- 81-100</li></ul>',
               "englishprogram_5_6": '<br><hr/><br>The <a href=\"/text/english\"><b>English program</b></a> measures the competency of a child using the following levels:<br><ul><b>For Class 5:</b><li>Can recognizes the objects in picture</li><li>Picture Reading-Can construct simple sentences</li><li>Can read words</li><li>Can read simple passage</li><li>Can give one word answer orally</li></ul><br><ul><b>For Class 6:</b><li>Can recognizes the objects in picture</li><li>Picture Reading-Can construct simple sentences</li><li>Can read words</li><li>Can read simple passage</li><li>Can write one word answers</li></ul>',
               "englishprogram_3_4":'<br><hr/><br>The <a href=\"/text/english\"><b>English program</b></a> measures the competency of a child using the following levels:<br><ul><b>For Class 3:</b><li>Can write letters of the alphabet</li><li>Can follow simple instruction</li><li>Can give one word answer</li></ul><br><ul><b>For Class 4:</b><li>Picture label Reading</li><li>Can answer in sentence</li><li>Can read a simple sentence</li></ul>',
               "anganwadiprogram":'<br><hr/><br>The <a href=\"/text/preschool\"><b>Anganwadi Program'+"'s</b></a> diagnostic test measures children's abilities across the following competencies:<br><ul><li>General awareness</li><li>Gross Motor</li><li>Fine Motor</li><li>Language</li><li>Intellectual</li><li>Socio-emotional</li><li>Pre-academic</li></ul>"
}
 

var programinfo={
  1:progtext["readingprogram"],
  2:progtext["mathprogram"],
  3:progtext["mathprogram"],
  4:progtext["readingprogram"],
  6:progtext["englishprogram_5_6"],
  5:progtext["anganwadiprogram"],
  7:progtext["readingprogram"],
  8:progtext["readingprogram"],
  9:progtext["mathprogram"],
  10:progtext["mathprogram"],
  11:progtext["mathprogram"],
  12:progtext["mathprogram"],
  13:progtext["readingprogram"],
  14:progtext["mathprogram"],
  15:progtext["englishprogram_3_4"],
  16:progtext["mathprogram"],
  18:progtext["anganwadiprogram"],
  19:progtext["readingprogram"],
  25:progtext["anganwadiprogram"]
}

var baselinedata=new Object();
var baselinegenderdata=new Object();
var baselinemtdata=new Object();
var baselinechart=new Object();
var baselinegenderchart=new Object();
var baselinemtchart=new Object();
var baselineoptions=new Object();
var baselinegenderoptions=new Object();
var baselinemtoptions=new Object();

var progressdata=new Object();

var tabberOptions = {

  'manualStartup':true,


  'onLoad': function(argsObj) {
    /* Display an alert only after tab2 */
    if (argsObj.tabber.id == 'tab2') {
      alert('Finished loading tab2!');
    }
  },

  'onClick': function(argsObj) {

    var t = argsObj.tabber; /* Tabber object */
    var id = t.id; /* ID of the main tabber DIV */
    var i = argsObj.index; /* Which tab was clicked (0 is the first tab) */
    var e = argsObj.event; /* Event object */

    if (id == 'tab2') {
      return confirm('Swtich to '+t.tabs[i].headingText+'?\nEvent type: '+e.type);
    }
  },

  /* Optional: set an ID for each tab navigation link */
  'addLinkId': true

};


/*Function to Camel case the string*/
function initCap(str)
{
  str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase();
 return str;
}

/*init function, creates analytics tab if needed and calls charting functions*/
function initialise(data)
{
  info= data;
  document.getElementById("tabview-heading").innerHTML="Assessments (<i>Partner:"+info["programme"]["partner"]+"</i>)";
  if( info["type"] == "school" || info["type"] == "preschool")//show analytics
  {
    var maintab=document.getElementById('maintab');
    var analtab=document.createElement('div');
    analtab.setAttribute('id','analytics');
    analtab.setAttribute('class','tabbertab');
    maintab.appendChild(analtab);
    document.getElementById("analytics").innerHTML='<h2>Analytics</h2> <div id="analytics-info"> </div> <div id="analytics-content"> </div>';
  }
  tabberAutomatic(tabberOptions);
  chartData(info["programme"]["pid"],info["programme"]["name"]);
}

/*Calls the various charting function*/
function chartData(pid,programme)
{
  enrollment(pid,programme);
  baseline(programme);
  progress(pid,programme); 
  if ( info["type"]=="school" || info["type"]=="preschool")
  {
    analytics(programme);
  }
}

/*Shows the enrolllment data*/
function enrollment(pid,programme)
{
  syear = Number(info["programme"]["year"]);
  eyear = syear+1;
  document.getElementById("program-school_name").innerHTML='<br><b>'+programme+' Program, enrollment data for '+info["name"]+'('+initCap(info["type"])+') in '+syear+'-'+eyear+':-</b><br>'
  tablecontent='<br><table class=\"chart-table\" width=\"550\" border=\"1\" style=\"border-width:1px; border-style:dotted; border-color:#CCCCCC;\"><tr><td>Class/ Age-Group</td><td>Number of Boys</td><td>Number of Girls</td><td>Total</td></tr>';

  classnames=[];
  for(classname in info["base"]["classes"])
  {
    classnames.push(classname);
  }
  classnames.sort();
  for(var i = 0; i < classnames.length; i++)
  {
    var classname=classnames[i];
    var total=parseInt(info["base"]["classes"][classname]["Boys"])+parseInt(info["base"]["classes"][classname]["Girls"]);
    tablecontent=tablecontent+"<tr><td>"+classname+"</td><td>"+info["base"]["classes"][classname]["Boys"]+"</td><td>"+info["base"]["classes"][classname]["Girls"]+"</td><td>"+total+"</td></tr>";
  }
  tablecontent=tablecontent+"</table>";
  document.getElementById("numchild").innerHTML=tablecontent;

  document.getElementById("programinfo").innerHTML=programinfo[pid];
}

/*Shows the baseline general and when clicked by mt and gender*/
function baseline(programme)
{
   basegeneral();
   levelbar(info["baseline"],"gender",baselinegenderdata,baselinegenderoptions,"By Gender");
   levelbar(info["baseline"],"mt",baselinemtdata,baselinemtoptions,"By Mother tongue");
}


function fillOptions(options,classname,title,width,height)
{ 
  options = {
    title: 'Class-'+classname+" "+title,
    width: width, height: height,
    chartArea: {width:"50%",height:"75%",left:"100"},
    backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'},
    hAxis:{'title':'% of students','maxValue':100,'minValue':0},
    colors: ['006D2C','31A354','74C476','BAE4B3','EDF8E9']
  };
  options['chartArea']={'width':200};

  if(info["programme"]["pid"]==15)
  {
    options['chartArea']['left']='225';
    options['chartArea']['width']='40%';
  }
  if(info["programme"]["pid"]==6)
  {
    options['chartArea']['left']='350';
    options['chartArea']['width']='30%';
  }
  if (info["programme"]["pid"]==23)
  {
    options['chartArea']['left']='150';
    options['chartArea']['width']='35%';
  }
  return options;
}

/*creates the baeline general graphs*/
function basegeneral()
{
  var count=0;
  var classcount=0;
  var classnames=[];
  var grid=12;
  for(classname in info["baseline"])
  {
    classnames.push(classname);
    classcount=classcount+1;
  }
  classnames.sort();
  grid=grid/2;
  var width=400;
  var numgraphs=2;
  if(info["programme"]["pid"]==6 || info["programme"]["pid"]==15)
  {
    width=700;
    numgraphs=1
  }
  var height=300;
  var count=0;
  for(var i = 0; i < classnames.length; i++)
  {
    count=count+1;
    var classname=classnames[i];
    baselinedata[classname]=new google.visualization.DataTable();
    baselinedata[classname].addColumn('string',"Domain");
    for(textcount in info["base"]["classes"][classname]["assesstext"])
    {
      var text=info["base"]["classes"][classname]["assesstext"][textcount];
      baselinedata[classname].addColumn('number',text);
    }
    var colors=[];
    var chartdata={};
    var graphdata=[];
    for(domain in info["baseline"][classname])
    {
      var datarow=[];
      datarow.push(domain);
      for(textcount in info["base"]["classes"][classname]["assesstext"])
      {
        var text=info["base"]["classes"][classname]["assesstext"][textcount];
        if(text in info["baseline"][classname][domain])
        {  
          value=Math.round(info["baseline"][classname][domain][text]["value"]);
          index=info["baseline"][classname][domain][text]["order"]+1;
          datarow[index]=value;
        }
        else
          datarow[parseInt(textcount)+1]=0;
        if(text in color)
          colors.push(color[text]);
      }
      index=info["baseline"][classname][domain]["order"];
      graphdata[index]=datarow;
    }
    for(datacount in graphdata)
    {
      baselinedata[classname].addRow(graphdata[datacount]);
    }
   
    
    var divIdName = classname+"-general";
    var general_div=createBaselineContent(classname,divIdName,grid);

    baselinechart[classname] = new google.visualization.BarChart(document.getElementById(divIdName));


    baselineoptions[classname]=fillOptions(baselineoptions[classname],classname,"",width,height);
    if(info['type']=="preschool"|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
    {
      baselineoptions[classname]['chartArea']['left']=50;
    }
    baselinechart[classname].draw(baselinedata[classname],baselineoptions[classname]);

    if(count==numgraphs)
    {
      var br=document.createElement('div');
      br.setAttribute('style','height:14px');
      br.setAttribute('class','grid_12');
      general_div.appendChild(br);
      count=0;
    }
  
    google.visualization.events.addListener(baselinechart[classname], 'select',(function(x)
    {
      return function()
      {
        selectHandler(x);
      }
    })(classname));
  } 
}

/*Creates the html content for baseline graphs*/
function createBaselineContent(classname,divIdName,grid)
{
  var general_div=document.getElementById("general-content");
  var newdiv=document.createElement('div');
  newdiv.setAttribute('id',divIdName);
  newdiv.setAttribute('class','grid_'+grid);
  general_div.appendChild(newdiv);

  var detailsdivIdName = classname+"-breakdown";
  var breakdowndiv=document.createElement('div');
  breakdowndiv.setAttribute('id',detailsdivIdName);
  breakdowndiv.setAttribute('class','white_content');
  breakdowndiv.setAttribute('style','display:none');

  var backbutton=document.createElement('a');
  backbutton.setAttribute('href',"javascript:void(0)")
  backbutton.setAttribute('onclick',"document.getElementById('"+classname+"-breakdown').style.display='none';document.getElementById('fade').style.display='none'");
  backbutton.setAttribute('class','link');
  backbutton.innerHTML="back";

  var br=document.createElement("br");

  var genderdivIdName=classname+"-gender";
  var genderdiv=document.createElement('div');
  genderdiv.setAttribute('id',genderdivIdName);
  genderdiv.setAttribute('style','float:left');

  var mtdivIdName=classname+"-mt";
  var mtdiv=document.createElement('div');
  mtdiv.setAttribute('id',mtdivIdName);
  mtdiv.setAttribute('style','float:right');
 
  breakdowndiv.appendChild(backbutton);
  breakdowndiv.appendChild(br);
  breakdowndiv.appendChild(br);
  breakdowndiv.appendChild(genderdiv);
  breakdowndiv.appendChild(mtdiv);

  general_div.appendChild(breakdowndiv);
  return general_div;
}

/*Creates further breakdown bar graphs based on category*/
function levelbar(assesstype,category,data,options,title)
{
  var count=0;
  var classcount=0;
  var classnames=[];
  var grid=12;
  for(classname in assesstype)
  {
    classnames.push(classname);
    classcount=classcount+1;
  }
  classnames.sort();
  grid=grid/2;
  var width=400;
  var numgraphs=2;
  if(info['type']=='preschool'|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
  {
    width=650;
    numgraphs=1
  }
  if(info["programme"]["pid"]==6 || info["programme"]["pid"]==15)
  {
    width=700;
    numgraphs=1
  }
  var height=300;

  var count=0;
  
  for(var i = 0; i < classnames.length; i++)
  {
    count=count+1;
    var classname=classnames[i];
    var colors=[];
    var chartdata={};
    var graphdata=[];

    data[classname]=new google.visualization.DataTable();
    data[classname].addColumn('string',"Domain-Text");
    for(type in info["base"][category])
    {
      data[classname].addColumn('number',type);
      if(type in color)
      {
        colors.push(color[type]);
      }
    }
    for(domain in  assesstype[classname]) 
    {
      for(text in assesstype[classname][domain])
      {  
        var datarow=[];
        if( text=='order')
          continue;
        if(domain !='')
          datarow.push(domain+" ("+text+")");
        else
          datarow.push(text);
        value=Math.round(info["baseline"][classname][domain][text]["value"]);
        for(type in info["base"][category])
        {
          if(type in assesstype[classname][domain][text][category])
            datarow.push(assesstype[classname][domain][text][category][type]);
          else
            datarow.push(0);
        }
        index=info["baseline"][classname][domain]["order"]*info["base"]["classes"][classname]["assesstext"].length+info["baseline"][classname][domain][text]["order"];
        graphdata[index]=datarow;
      }
    }
    for(datacount in graphdata)
    {
      data[classname].addRow(graphdata[datacount]);
    }
    options[classname]=fillOptions(options[classname],classname,title,width,height);
    if(colors.length >0 )
      options[classname]['colors']=colors;
  }
}

/*event handler for base graphs*/
function selectHandler(classname)
{
  var selection=baselinechart[classname].getSelection();
  if( selection.length==0)
  {
    alert("Nothing selected");
    return;
  }
  var item=selection[0];
  var rowindex=item.row*info["base"]["classes"][classname]["assesstext"].length+item.column-1;
  populateChart(baselinegenderdata,classname,rowindex,baselinegenderoptions,"gender");
  populateChart(baselinemtdata,classname,rowindex,baselinemtoptions,"mt");
}


/*Function to populate drill down graphs */
function populateChart(inputdata,classname,rowindex,options,type)
{
  var data=new Array();
  data[0]=new Array();
  data[1]=new Array();
  data[0][0]="Domain-Rung";
  for(colcount=1;colcount<inputdata[classname].getNumberOfColumns();colcount++)
  {
     data[0][colcount]=inputdata[classname].getColumnLabel(colcount);
  }
  for(colcount=0;colcount<inputdata[classname].getNumberOfColumns();colcount++)
  {
     data[1][colcount]=inputdata[classname].getValue(rowindex,colcount);
  }
  var chartdata=google.visualization.arrayToDataTable(data);
  var divIdName = classname+"-"+type;
  document.getElementById(classname+'-breakdown').style.display='block';
  document.getElementById('fade').style.display='block';
  if( options[classname].width > 600)
  {
     document.getElementById(divIdName).style.float='left';
  }
  var typechart = new google.visualization.BarChart(document.getElementById(divIdName));
  typechart.draw(chartdata,options[classname]);
}


/*progress graphs*/
function progress(pid,programme)
{
  document.getElementById("progress-info").innerHTML='<p align=\"left\"><b>Progress performance for '+info["name"]+'</b></p>';

  var count=0;
  var classcount=0;
  var classnames=[];
  var grid=12;
  for(classname in info["progress"])
  {
     classnames.push(classname);
     classcount=classcount+1;
  }
  classnames.sort();
  grid=grid/2;
  var width=400;
  var numgraphs=2;
  if(info['type']=='preschool'|| info['type']=='project' || info['type']=='circle' || info['type']=='preschooldistrict')
  {
    width=600;
    numgraphs=1
  }
  if(info["programme"]["pid"]==6 || info["programme"]["pid"]==15)
  {
    width=700;
    numgraphs=1
  }
  var height=300;

  var count=0;
  for(var i = 0; i < classnames.length; i++)
  {  
    var classname=classnames[i];
    var starttimes=[]
    for(starttime in  info["base"]["progress"][classname]) 
    {
      starttimes.push(starttime);
    }

    starttimes.sort();
    count=count+1;
    var colors=[];
    var chartdata={};
    var graphdata=[];

    progressdata[classname]=new google.visualization.DataTable();
    progressdata[classname].addColumn('string',"Domain-Text");

    for(var j=0; j<starttimes.length;j++)
    {
      starttime=starttimes[j]
      progressdata[classname].addColumn('number',info["base"]["progress"][classname][starttime]);
    }

    for(domain in  info["progress"][classname]) 
    {
      for(text in info["progress"][classname][domain])
      {  
        var datarow=[];
        if( text=='order')
          continue;
        if( domain !='')
          datarow.push(domain+" ("+text+")");
        else
          datarow.push(text);
        for(var j=0; j<starttimes.length;j++)
        {
          starttime=starttimes[j]
          for(assessname in info["progress"][classname][domain][text][starttime])
          {
            datarow.push(info["progress"][classname][domain][text][starttime][assessname]);
          }
        }
        index=info["progress"][classname][domain]["order"]*info["base"]["classes"][classname]["assesstext"].length+info["progress"][classname][domain][text]["order"];
        graphdata[index]=datarow;
      }
    }
    for(datacount in graphdata)
    {
      progressdata[classname].addRow(graphdata[datacount]);
    }

    var general_div=document.getElementById("progress-content");
    var divIdName = "progress-"+classname;
    var newdiv=document.createElement('div');
    newdiv.setAttribute('id',divIdName);
    newdiv.setAttribute('class','grid_'+grid);
    general_div.appendChild(newdiv);
    var options= {};
    options=fillOptions(options,classname,"",width,height);
    var chart = new google.visualization.BarChart(document.getElementById(divIdName));
    chart.draw(progressdata[classname],options);
    if(count==numgraphs)
    {
      var br=document.createElement('div');
      br.setAttribute('style','height:14px');
      br.setAttribute('class','grid_12');
      general_div.appendChild(br);
      count=0;
    }
  }
}


function analytics(programme)
{
  var count=0;
  var classcount=0;
  var classnames=[];
  var grid=12;
  for(classname in info["analytics"])
  {
    classnames.push(classname);
    classcount=classcount+1;
  }
  classnames.sort();
  grid=grid/2;
  var width=400;
  var height=300;
  var numgraphs=2;
  if(info["programme"]["pid"]==6 || info["programme"]["pid"]==15 || info["programme"]["pid"]==5 || info["programme"]["pid"]==18)
  {
    width=750;
    numgraphs=1
  }

  var count=0;
  var analyticsinfo="<ul>"
  for(var i = 0; i < classnames.length; i++)
  {
    var classname=classnames[i];
    analyticsinfo=analyticsinfo+'<li><a href="#analytics-class-'+classname+'"><b>Class-'+classname+"</b></a></li>"
    var general_div=document.getElementById("analytics-content");
    var parentdivIdName = "analytics-class-"+classname
    var newdiv=document.createElement('div');
    newdiv.setAttribute('id',parentdivIdName);
    newdiv.setAttribute('class','grid_12');
    general_div.appendChild(newdiv);

    var parent_div=document.getElementById(parentdivIdName);
    var headerdiv=document.createElement('div')
    headerdiv.setAttribute('id',parentdivIdName+"-header");
    parent_div.appendChild(headerdiv)
   
    document.getElementById(parentdivIdName+"-header").innerHTML='<p>Class-'+classname+'  <a href="#top"><b>(Back to Top)</b></a></p>';
   
    var starttimes=[];
    for( starttime in info["analytics"][classname])
    {
      starttimes.push(starttime);
    }
    starttimes.sort();

    for(var j=0;j< starttimes.length;j++)
    {
      var starttime=starttimes[j];
      count=count+1;
      var data=new google.visualization.DataTable();
      data.addColumn('string',"Domain-Text");
      for( test in info["analytics"][classname][starttime])
      {
        var graphdata=[];
        for(bcount in info["base"]["analytics"])
        {
          type=info["base"]["analytics"][bcount]["type"]
          data.addColumn('number',info["base"]["analytics"][bcount]["name"]+"("+type+")");
        }
        for(domain in info["analytics"][classname][starttime][test])
        {
          for(text in info["analytics"][classname][starttime][test][domain])
          {
            if(text=="order")
              continue;
            var rowdata=[];
            if(domain != '')
              rowdata.push(domain+"("+text+")");
            else
              rowdata.push(text);
            for(bcount in info["base"]["analytics"])
            {
              type=info["base"]["analytics"][bcount]["type"];
              if( type in info["analytics"][classname][starttime][test][domain][text]["value"])
                rowdata.push(info["analytics"][classname][starttime][test][domain][text]["value"][type]["value"]);
              else
                rowdata.push(0);
            }
            index=info["analytics"][classname][starttime][test][domain]["order"]*info["base"]["classes"][classname]["assesstext"].length+info["analytics"][classname][starttime][test][domain][text]["order"];
            graphdata[index]=rowdata;
          }
        }       
        for(datacount in graphdata)
        {
           data.addRow(graphdata[datacount]);
        }
        var divIdName = "analytics-"+classname+"-"+test;
        var newdiv=document.createElement('div');
        newdiv.setAttribute('id',divIdName);
        newdiv.setAttribute('class','grid_'+grid);
        parent_div.appendChild(newdiv);
        var options = {
          title: 'Class-'+classname+" ("+test+")",
          width: width, height: height,
          chartArea: {width:"40%",height:"75%",left:"50"},
          backgroundColor: {stroke:'#000000',strokeWidth:'1',fill:'#F4E193'},
          hAxis:{'title':'% of students','maxValue':100,'minValue':0},
          colors: ['006D2C','31A354','74C476','BAE4B3','EDF8E9']
        };
        if(info["programme"]["pid"]==5 || info["programme"]["pid"]==18)
        {
          options['chartArea']['left']='200';
          options['chartArea']['width']='30%';
        }
        if(info["programme"]["pid"]==6)
        {
          options['chartArea']['left']='325';
          options['chartArea']['width']='30%';
        }
        if(info["programme"]["pid"]==15)
        {
          options['chartArea']['left']='225';
          options['chartArea']['width']='40%';
        }
        if (info["programme"]["pid"]==23)
        {
          options['chartArea']['left']='110';
          options['chartArea']['width']='32%';
        }
        var chart = new google.visualization.BarChart(document.getElementById(divIdName));
        chart.draw(data,options);
        if(count==numgraphs)
        {
          var br=document.createElement('div');
          br.setAttribute('style','height:14px');
          br.setAttribute('class','grid_12');
          parent_div.appendChild(br);
          count=0
        }
      }
    }
  }
  analyticsinfo=analyticsinfo+'</ul>'
  document.getElementById("analytics-info").innerHTML=analyticsinfo;
} 
