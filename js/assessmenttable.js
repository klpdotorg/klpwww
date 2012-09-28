var previousPoint = null;
var datasets;
var choiceContainer;
var info;
var domains=['Students/Teachers','Midday Meal','Infrastructure','Library','Water and Sanitation'];

function initCap(str)
{
  str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase();
 return str;
}

function initialise(data)
{
  info= data;
  document.getElementById("heading").innerHTML=initCap(info["programme"]["name"])+"(<i>Partner:"+info["programme"]["partner"]+"</i>)";
  chartData(info["programme"]["pid"],info["programme"]["name"]);
}

function chartData(pid,programme)
{
  var assessmenttable='<div class="div-table">';
  for( domainnum in domains)
  {
    domain=domains[domainnum];
    first=1;
    for( questionnum in info["assessment"][domain])
    {
      for(question in info["assessment"][domain][questionnum])
      {
        assessmenttable=assessmenttable+'<div class="div-table-row">';
        if(first==1)
        {
          assessmenttable=assessmenttable+'<div class="div-table-col" style="width:180px"><b>'+domain+'</b></div>';
        }
        else
        {
          assessmenttable=assessmenttable+'<div class="div-table-col" style="width:180px"></div>';
        }
        assessmenttable=assessmenttable+'<div class="div-table-col" style="width:300px">'+question+'</div>';
        answer=info["assessment"][domain][questionnum][question];
        if (answer=='Yes')
        {
          assessmenttable=assessmenttable+'<div class="div-table-col" style="width:100px"><p style="color:green">'+answer+'</p></div>';
        }
        else if (answer=='No')
        {
          assessmenttable=assessmenttable+'<div class="div-table-col" style="width:100px"><p style="color:red">'+answer+'</p></div>';
        }
        else
        {
          assessmenttable=assessmenttable+'<div class="div-table-col" style="width:100px"><p>'+answer+'</p></div>';
        }  
        first=0;
        assessmenttable=assessmenttable+'</div>';
      }
    }
  }
  assessmenttable=assessmenttable+'</div>';
  document.getElementById("assessment_info").innerHTML=assessmenttable;
}
