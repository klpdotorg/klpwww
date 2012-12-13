var info;
var map;
var tab;

if (!Array.prototype.indexOf)
{
  Array.prototype.indexOf = function(elt /*, from*/)
  {
    var len = this.length;

    var from = Number(arguments[1]) || 0;
    from = (from < 0)
         ? Math.ceil(from)
         : Math.floor(from);
    if (from < 0)
      from += len;

    for (; from < len; from++)
    {
      if (from in this &&
          this[from] === elt)
        return from;
    }
    return -1;
  };
}


function getSchoolPages(id,type,tab)
{
    YUI({base: '/yui/build/',timeout: 50000}).use("io-base","json-parse",
    function(Y, result) {
      if (!result.success) {
        Y.log('Load failure: ' + result.msg, 'warn', 'program');
      }
      var callback = {
        on: { success:
          function(id, o) {
            var info;
            try {
              info= Y.JSON.parse(o.responseText); 
            } catch (e) {
              Y.log('Could not parse json', 'error', 'info');
              return;
            }
            continueBuildUp(info);  
          },
          failure: function(id, o) {
            Y.log('Could not retrieve school page data ','error','info');
          }
        }
      };
      var url = '';
      url = "/schoolpage/";
      if (type == 1)
        url = url + "school/";
      else
        url = url + "preschool/";
      url = url + id ;
      url = url + "/" + tab;
      url = url + "?is_ajax=true";
      var request = Y.io(url, callback);
    });
}

function initialise(data)
{
  info=data;
  document.getElementById("school_info").innerHTML ="Loading <img style='vertical-align:middle' src='/images/ajax-loader-bar.gif'/>";
  document.getElementById("student_gend").innerHTML = "Loading <img style='vertical-align:middle' src='/images/ajax-loader-bar.gif'/>";
  document.getElementById("assessment_info").innerHTML = "Loading <img style='vertical-align:middle' src='/images/ajax-loader-bar.gif'/>";
  document.getElementById("mdm_info").innerHTML = "Loading <img style='vertical-align:middle' src='/images/ajax-loader-bar.gif'/>";
  document.getElementById("infra_info").innerHTML = "Loading <img style='vertical-align:middle' src='/images/ajax-loader-bar.gif'/>";
  document.getElementById("sys_data").innerHTML = "Loading <img style='vertical-align:middle' src='/images/ajax-loader-bar.gif'/>";
  if(info["type"] == 1) {
  	document.getElementById("finances_txt").innerHTML = "Loading <img style='vertical-align:middle' src='/images/ajax-loader-bar.gif'/>";
  	document.getElementById("mdm_info").innerHTML = "Loading <img style='vertical-align:middle' src='/images/ajax-loader-bar.gif'/>";
  }
  tab = info["tab"]

  document.getElementById("maintab").tabber.tabShow(tab-1);
  for(var i=1;i<=7;i++) {
   if (tab != i)
     getSchoolPages(info["id"],info["type"],i);
  }
  info["name"]=info["name"].toUpperCase();
  populateHeader();
  continueBuildUp(info);
}


function continueBuildUp(data)
{
  info=data;
  tab = info["tab"]
  if (tab == 1) {
    	showMap();
    	populateAddress();
    	populateSchoolInfo();
    	populatePics();
  	populateEReps();
  } else if (tab == 2) { 
    populateDemographics();
  } else if (tab == 3) {
    populatePrograms();
  } else if (tab == 4) {
    populateFinances();
  } else if (tab == 5) {
    populateInfra();
    populateRTE();
    populateLibrary();
    populatePTR();
  } else if (tab == 6) {
    populateMDM();
  } else if (tab == 7) {
    populateSYS();
  } else {}

}

function showMap()
{
  var latlng = new google.maps.LatLng(info["lat"],info["lon"]);
  var myOptions = {
      zoom: 14,
      center: latlng,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      disableDoubleClickZoom:false
  };

  marker_name = "school.png";
  if(info['type'] == 2)
  	marker_name = "preschool.png";

  map = new google.maps.Map(document.getElementById("map"),myOptions);
  var marker = new google.maps.Marker({
        position: latlng,
        title:info["name"],
        icon:"/images/"+marker_name
      });
  marker.setMap(map);  
}

function populateHeader()
{
  
  if(info["type"] != 2)
  	document.title = "School Information"; 
  else
  	document.title = "Preschool Information"; 

  document.getElementById("school_name").innerHTML= info["name"];
  add = '<div class="div-table">'
  if (info["address"] != "-")
  {
          add = add + '<div class="div-table-row">' +
                          '<div id="div-col-90width" class="div-table-col" >District</div>' +
                          '<div class="div-table-col">:' + info["b"] +'</div>' +
                          '</div>' 
          
          add = add + '<div class="div-table-row">' 
          if(info["type"] != 2)
          {
            add = add + '<div id="div-col-90width" class="div-table-col" >Block</div>' 
          }else{
            add = add + '<div id="div-col-90width" class="div-table-col" >Project</div>' 
          }
          add = add + '<div class="div-table-col">:' + info["b1"] +'</div>' +
                              '</div>'
  
  
          add = add + '<div class="div-table-row">' 
          if(info["type"] != 2)
          {
            add = add + '<div id="div-col-90width" class="div-table-col" >Cluster</div>' 
          }else{
            add = add + '<div id="div-col-90width" class="div-table-col" >Circle</div>' 
          }
          add = add + '<div class="div-table-col">:' + info["b2"] +'</div>' +
                            '</div>'
  }
  add=add+'</div>' 
  document.getElementById("school_hier").innerHTML= add;
  
}

function populateAddress()
{
  address = '<div class="div-table">'
  if (info["address"] != "-")
  {       

        address = address + '<div class="div-table-row">' + 
                            '<div id="div-col-90width" class="div-table-col" >Address</div>' +
                            '<div class="div-table-col">:'+info["address"]+ "-" + info["postcode"]+'</div></div>' 
        address = address + '<div class="div-table-row">' +
                            '<div id="div-col-90width" class="div-table-col" >Landmark</div>' +
                            '<div class="div-table-col">:'+ info["landmark_1"] + '</div></div>' 
        address = address + '<div class="div-table-row">' + 
                            '<div id="div-col-90width" class="div-table-col" >Identifiers</div>' +
                            '<div class="div-table-col">:'+info["inst_id_1"] + ',' + info["inst_id_2"] + '</div></div>' 
        address = address + '<div class="div-table-row">' + 
                            '<div id="div-col-90width" class="div-table-col" >Buses</div>' +
                            '<div class="div-table-col">:'+info["bus_no"] + '</div></div>' 
  }else{
        address = address + '<div class="div-table-row">' + 
                            '<div id="div-col-90width" class="div-table-col" >Address</div>' +
                            '<div class="div-table-col">:'+info["address"]+'</div></div>' 
  }
  address=address+'</div>'
  document.getElementById("school_geo").innerHTML= address;
 
}

function populateSchoolInfo()
{
   if (info["type"]==2)
   {
	document.getElementById("school_info_heading").innerHTML = "Preschool Information";
   }
   else
   {
	document.getElementById("school_info_heading").innerHTML = "School Information";
   }
  document.getElementById("const_info_heading").innerHTML = "Constituency Information";
  document.getElementById("address_heading").innerHTML = "Address";
  document.getElementById("srcinfo1").innerHTML = 'Source : KLP Database (2011-12)';
  infotable = '<div class="div-table">'
  if(info["status"] == 0){
    if(info["type"] != 2) {
      infotable = infotable + '<div class="div-table-row"><div class="div-table-col">' 
      infotable = infotable + 'This School is reported to have been CLOSED.</div></div>' 
    } else {
      infotable = infotable + '<div class="div-table-row"><div class="div-table-col">' 
      infotable = infotable + 'This Preschool is reported to have been CLOSED.</div></div>' 
    }      
  }
  infotable = infotable + '<div class="div-table-row">' + 
                          '<div id="div-col-125width" class="div-table-col">Category</div>' 
  infotable = infotable + '<div class="div-table-col">:'+info["cat"]+'</div></div>' 
  if(info["type"] !=2)
  {
    infotable = infotable + '<div class="div-table-row">' + 
                            '<div id="div-col-125width" class="div-table-col">Gender</div>' 
    infotable = infotable + '<div class="div-table-col">:'+info["sex"]+'</div></div>' 
    infotable = infotable + '<div class="div-table-row">' +
                            '<div id="div-col-125width" class="div-table-col">Medium of Instruction</div>' 
    infotable = infotable + '<div class="div-table-col">:'+info["moi"]+'</div></div>' 
    infotable = infotable + '<div class="div-table-row">' +
                            '<div id="div-col-125width" class="div-table-col">DISE Code</div>' 
    infotable = infotable + '<div class="div-table-col">:'+info["dise_code"]+'</div></div>' 
  }
  infotable = infotable + '</div>'
  document.getElementById("school_info").innerHTML= infotable;
}

function populateDemographics()
{
  document.getElementById("student_info_heading").innerHTML = "Student Information";
  if (info["type"]==2)
    document.getElementById("srcinfo2").innerHTML = 'Source : KLP Database (2011-12)';
  else {
    document.getElementById("dise_gender_heading").innerHTML = "DISE Student Profile";
    document.getElementById("srcinfo2").innerHTML = 'Source : KLP Database (2011-12), <a href="http://schoolreportcards.in" target="_blank"><span style="color:#43AD2F">NUEPA-DISE</span></a>(' + info['acyear'] + ')';
  }
  var data = new google.visualization.DataTable();
  data.addColumn('string', "Gender");
  data.addColumn('number', "Count");
  data.addRows([
    ['Boys' + ' (' + info["numBoys"] + ')', parseInt(info["numBoys"])],
    ['Girls' + ' (' + info["numGirls"] + ')', parseInt(info["numGirls"])],
    //[Math.round(info["numGirls"]/info["numStudents"]*100) + '% are Girls', info["numGirls"]],
  ]);
  //var table2 = new google.visualization.Table(document.getElementById('gendsch_tb'));
  //table2.draw(data,{width:350, height: 120});
  //var chart1 = new BarsOfStuff(document.getElementById('student_gend'));
  //chart1.draw(data, {width:600, height: 400, title:"Gender Profile"});
  var chart1 = new google.visualization.PieChart(document.getElementById('student_gend'));
  chart1.draw(data, {width: 550, height: 260, title:  'Gender Profile', backgroundColor: 'transparent', pieSliceText:'label', colors: ['D78103','F49406','E35804','F7AA33','FBBC59']});
  if(info.boys_count) { 
    var data = new google.visualization.DataTable();
    data.addColumn('string', "Gender");
    data.addColumn('number', "Count");
    data.addRows([
      ['Boys' + ' (' + info["boys_count"] + ')', parseInt(info["boys_count"])],
      ['Girls' + ' (' + info["girls_count"] + ')', parseInt(info["girls_count"])],
    ]);
  
    var chart5 = new google.visualization.PieChart(document.getElementById('student_dise_gend'));
    chart5.draw(data, {width: 550, height: 260, title:  'DISE: Gender Profile', backgroundColor: 'transparent', pieSliceText:'label', colors: ['D78103','F49406','E35804','F7AA33','FBBC59']});
  }

  var data = new google.visualization.DataTable();
  data.addColumn('string', 'Language');
  data.addColumn('number', 'Number of Students');
  for (var key in info["school_mt_tb"]){
    data.addRow([key + ' (' + info["school_mt_tb"][key] + ')', parseInt(info["school_mt_tb"][key])]);
  }
  //var table = new google.visualization.Table(document.getElementById('mtsch_tb'));
  //table.draw(data,{width: 400});
  var chart2 = new google.visualization.PieChart(document.getElementById('student_mt'));
  chart2.draw(data, {width: 550, height: 260, title:  'Mother Tongue Profile', backgroundColor: 'transparent', pieSliceText:'label', colors: ['D78103','F49406','E35804','F7AA33','FBBC59']});

}

function populatePics()
{
  if(info["images"] && info["images"].length>0)
  {
    school_pics= '<a href=\"' + info["image_dir"] + info["images"][0]+'\" rel=\"lightbox['+ info['id']+']\"><img class="album" src=\"' + info["image_dir"] + info["images"][0]+'\"></img></a>'
    for(i=1;i<info["images"].length;i++)
    {
      school_pics = school_pics+'<a href=\"' + info["image_dir"] + info["images"][i] +'\" rel=\"lightbox['+ info['id']+']\"></a>' 
    }
  }else{
    school_pics='&nbsp;&nbsp;&nbsp;&nbsp;This school does not have a picture album yet.<br/><br/>'
  }
  document.getElementById("school_pics").innerHTML=school_pics;
}
 
function populateEReps()
{
  const_table = '<div class="div-table">' 
  if ('mla' in info){
    const_table = const_table + '<div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MLA Details</div>' + 
                '<div class="div-table-col">:' + info['mla'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MLA Details</div>' + 
                '<div class="div-table-col">:' + info['mlaname'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MP Constituency</div>' + 
                '<div class="div-table-col">:' + info['mp'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MP Details</div>' + 
                '<div class="div-table-col">:' + info['mpname'].toUpperCase() + '</div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">Ward</div>' + 
                '<div class="div-table-col">:' + info['ward'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">Corporator Details</div>' + 
                '<div class="div-table-col">:' + info['wardname'].toUpperCase() + '</div>' +
                '</div></div>';
    report_links = '<a href="" onclick="javascript:popwindow(\'/listFiles/3|'+info['mp'] +'|'+info['mla'] + '\')" style="color:#43AD2F">Please find Constituency Reports here.</a>';
  }
  else{
    const_table = const_table + 
                '<div class="div-table-row">' + 
                '<div class="div-table-col">Not Available</div></div>' ;
    report_links = '';
  }
  const_table = const_table + '</div>'
  document.getElementById("school_const").innerHTML = const_table;
  document.getElementById("reportlinks").innerHTML = report_links;
  
}  

function populatePrograms()
{
  if(info.assessments) {
    document.getElementById("assmt_info_heading").innerHTML = "Programme Information";
    document.getElementById("srcinfo3").innerHTML = 'Source : KLP Partner Data (2011-12)';
    var assessArr = info.assessments.split(",");
    var assdict = {};
    var asskeys = [];
    var assessmentInfo = '';
    var assessment = []; 
    for( num in assessArr)
    {
       assessment = assessArr[num].split("|");
       assdict[assessment[1]+'-'+assessment[2]] = [assessment[3]+'-'+assessment[0],assessment[2]];
       asskeys.push(assessment[1]+'-'+assessment[2]);
    }
    asskeys.sort();
    var asstext = ''; 
    var asstype = '';
    var each = '';
    for(var i = 0; i< asskeys.length; i++)
    {
       each = asskeys[i];
       asstext = assdict[each][0] + ' (' + each.split("-")[0] + ')';
       asstype = assdict[each][1];
       assessmentInfo = assessmentInfo+'<a href=\"javascript:void(0);\" onclick=window.open("/assessment/'+type+'/'+asstype+'/'+info['id']+'","_blank")><span style="color:#43AD2F">'+asstext+'</span></a><br/><br/>'
    }
  } else {
    assessmentInfo = 'No Programmes\' information yet.'
  }

  document.getElementById("assessment_info").innerHTML = '<div class="div-table">' +
                '<div class="div-table-row">' + assessmentInfo + '</div><div>' +
                '</div>';
}

function populateSYS()
{
  if (info["type"]==2)
  {
	document.getElementById("school_visits_heading").innerHTML = "Preschool Visits";
	document.getElementById("sys_data_heading").innerHTML = "Information from Preschool Visits";	
  }
  else
  {
	document.getElementById("school_visits_heading").innerHTML = "School Visits";
	document.getElementById("sys_data_heading").innerHTML = "Information from School Visits";		
  }
  document.getElementById("sys_comments_heading").innerHTML = "Visitors' Comments";
  systable = '<div class="div-table">' +
             '<div class="div-table-row">No. of Visits:' + info["syscount"] + '</div>';
  systable = systable+ 'If you have visited this school, please' + '<div class="div-table-row"><b><a href=\"javascript:void(0);\" onclick=window.open("../../shareyourstory'+type+'?type='+type+'?id='+info["id"]+'","_blank") style="color:#43AD2F">share your experience </a></b>here.</div>';
            if( info["syscount"]>0)
            {
              systable = systable+'<div class="div-table-row">Dates of Visit</div><div class="div-table-row"><b>';
              for(entry in info["sysdate"])
              {
                date = info["sysdate"][entry];
                if(date !="") 
                  systable = systable + date + '&nbsp;&nbsp;'
              }
              systable = systable + '</b></div>';
            }
  document.getElementById("sys_info").innerHTML= systable;
  if(info["syscomment"]){
    var syscomm = '<br><hr id="hrmod"/>';
    for(entry in info["syscomment"]){
      syscomm = syscomm +'<div id="name">'+info["syscomment"][entry]["name"] +'</div><div id="timestamp">'+"Posted on :"+info["syscomment"][entry]["timestamp"]+'</div><br><br>'+info["syscomment"][entry]["comments"]+'<br>';
      for(i in info["syscomment"][entry]["images"])
      {
         syscomm=syscomm+'<a href=\"' + info["image_dir"] + info["syscomment"][entry]["images"][0]+'\"><img id=\"sys_images\" src=\"' + info["image_dir"] + info["syscomment"][entry]["images"][i]+'\"></img></a>'
      }
      syscomm = syscomm + '<br><hr id="hrmod"/></div>'
    }
  } else {
    syscomm = "<div class='div-table'><div class='div-table-row'>No remarks yet.</div></div>"
  } 
  document.getElementById("sys_comments").innerHTML = syscomm;


  if(info["sysdata"]){
    var sysdata = '<div class="div-table">';
    sysdata = sysdata + '<div class="div-table-caption">This data is gathered from vistors sharing their experiences. It indicates whether or not the school has facilities under the headings below: </div>'
    for(entry in info["sysdata"]){
      tdata = info["sysdata"][entry].split('|');
      sysdata = sysdata + '<div class="div-table-row" id="div-row-border"><div class="div-table-col" id="div-col-350width">' + tdata[0] + '</div>'
                      + '<div class="div-table-col">:' + tdata[1] + '</div></div>'
    }
    sysdata = sysdata + '</div>'
  } else {
    sysdata = "<div class='div-table'><div class='div-table-row'>No information available from visits yet.</div></div>"
  }
  document.getElementById("sys_data").innerHTML = sysdata;
      
}


function populateFinances()
{
	fin_info = "";
		

        if (info["type"]==2) {
           fin_info = "SSA Grants are not applicable to Preschools";
	} else if (info.tlm_amount) {
           document.getElementById("fin_info_heading").innerHTML = "SSA Grants Allocation";
	   document.getElementById("fin_dise_heading").innerHTML = "DISE Finance Reporting";
	   document.getElementById("srcinfo4").innerHTML = '<br/><br/>Source : <a href="http://www.accountabilityindia.in/paisa-planning-allocations-and-expenditures-institutions-studies-accountability%22" target="_blank"><span style="color:#43AD2F">PAISA</span></a>, <a href="http://schoolreportcards.in" target="_blank"><span style="color:#43AD2F">NUEPA-DISE</span></a> ('+ info['acyear'] +')';
	   fin_info = "<dl><dt>School Maintenance Grant (SMG)</dt><dd><img src=\"/images/Rupee.png\"/> 5,000 for upto 3 classrooms " +
	              "and <img src=\"/images/Rupee.png\"/> 10,000 for more than 3 classrooms. </dd><dt>School Grant (SG)</dt><dd>" +
	              "<img src=\"/images/Rupee.png\"/> 5,000 for lower primary schools and <img src=\"/images/Rupee.png\"/> 7,000 " +
	              "for upper and model  primary schools</dd><dt>Teacher Learning Material Grant (TLM)</dt><dd><img src=\"/images/Rupee.png\"/> " +
	              "500 per teacher</div></dd></dl>";
          fin_text = "This school " + info["classroom_count"].toLowerCase() + " has " + info["teacher_count"] + " teachers as per DISE sources. It is known to receive a total annual SSA grant of " + ConvertToIndian(String(parseInt(info["tlm_amount"]) + parseInt(info["sg_amount"])+parseInt(info["smg_amount"]))) + ". <BR/><BR/>"
	  var data = new google.visualization.DataTable();
          data.addColumn('string', 'Grant Type');
          data.addColumn('number', 'Grant Amount');
          //data.addColumn('string', 'Grant Amount');
          data.addRow(['TLM', parseInt(info["tlm_amount"])]);
          data.addRow(['SG', parseInt(info["sg_amount"])]);
          data.addRow(['SMG', parseInt(info["smg_amount"])]);
          table_txt = '<div class="div-table">' +
		      '<div class="div-table-row"><div class="div-table-col" id="div-col-90width">TLM</div><div class="div-table-col">' + ConvertToIndian(String(info["tlm_amount"])) + '</div>' +
		      '<div class="div-table-row"><div class="div-table-col" id="div-col-90width">SG</div><div class="div-table-col">' + ConvertToIndian(String(info["sg_amount"])) + '</div>' +
		      '<div class="div-table-row"><div class="div-table-col" id="div-col-90width">SMG</div><div class="div-table-col">' + ConvertToIndian(String(info["smg_amount"])) + '</div>' + '</div>';
          
	  dise_table_txt = '<div class="div-table">' +
		      '<div class="div-table-row"><div class="div-table-col" style="text-align:left;width:200px">DISE reported TLM received</div><div class="div-table-col">' + ConvertToIndian(String(info["tlm_recd"])) + '</div>' +
		      '<div class="div-table-row"><div class="div-table-col" style="text-align:left;width:200px">DISE reported TLM expenditure</div><div class="div-table-col">' + ConvertToIndian(String(info["tlm_expnd"])) + '</div>' +
		      '<div class="div-table-row"><div class="div-table-col" style="text-align:left;width:200px">DISE reported SG received</div><div class="div-table-col">' + ConvertToIndian(String(info["sg_recd"])) + '</div>' +
		      '<div class="div-table-row"><div class="div-table-col" style="text-align:left;width:200px">DISE reported SG expenditure</div><div class="div-table-col">' + ConvertToIndian(String(info["sg_expnd"])) + '</div>' + '</div>'

          /*data.addRow(['TLM', parseInt(info["tlm_amount"]),ConvertToIndian(String(info["tlm_amount"]))]);
          data.addRow(['SG', parseInt(info["sg_amount"]),ConvertToIndian(String(info["sg_amount"]))]);
          data.addRow(['SMG', parseInt(info["smg_amount"]),ConvertToIndian(String(info["smg_amount"]))]);

	  var tabview = new google.visualization.DataView(data);
          tabview.setColumns([0,2]);
          var table1 = new google.visualization.Table(document.getElementById('finance_tb'));
          table1.draw(tabview,{width: 500 ,  allowHtml: true, showRowNumber: false, backgroundColor:'transparent'});*/

          //var chartview = new google.visualization.DataView(data);
          //chartview.setColumns([0,1]);
          var chart4 = new google.visualization.PieChart(document.getElementById('finance_chart'));
          chart4.draw(data, {width: 500, height: 250, title: 'Grant summary',backgroundColor: 'transparent', pieSliceText:'label', colors: ['D78103','F49406','E35804','F7AA33','FBBC59']});
          //chart4.draw(chartview, {width: 500, height: 250, title: 'Grant summary',backgroundColor: 'transparent', pieSliceText:'label', colors: ['D78103','F49406','E35804','F7AA33','FBBC59']});
	   document.getElementById("finance_tb").innerHTML = table_txt;
	   document.getElementById("finance_dise_tb").innerHTML = dise_table_txt;
	   document.getElementById("finances_txt").innerHTML = fin_text;
           
	} else {
           fin_info = "This information is currently unavailable";
        } 
	document.getElementById("finances_info").innerHTML = fin_info;
}

function populateInfra()
{
        var outer_dict;

	infra_info = "";
        if (info["type"]==2)
	{
  	  document.getElementById("infra_info_heading").innerHTML = "Infrastructure Summary";
   	  document.getElementById("srcinfo5").innerHTML = 'Source : KLP Database (2011-12)';
   	}
	else
	{	
  	  document.getElementById("infra_info_heading").innerHTML = "Infrastructure Summary";
  	  document.getElementById("ptr_info_heading").innerHTML = "Academics Summary ( " + info['acyear'] + ')';
  	  document.getElementById("lib_infra_heading").innerHTML = "Akshara Library Details";
  	  document.getElementById("rte_info_heading").innerHTML = "Additional RTE Information";
  	  document.getElementById("srcinfo5").innerHTML = '<br/><br/>Source : KLP Database (2011-12), <a href="http://schoolreportcards.in" target="_blank"><span style="color:#43AD2F">NUEPA-DISE</span></a> (' + info['acyear'] + ')';
	}

	if (info["type"]==2 && info.ang_infra) {
          outer_dict = info["ang_infra"]
	} else if (info.dise_facility) {
          outer_dict = info["dise_facility"]
        }
        if (outer_dict) {
           var tabletxt = ''
           tabletxt = '<div class="div-table">';

           for(group in outer_dict){
             innerdict = outer_dict[group];
             var firstrow = 0;
             for(key in innerdict){
               tabletxt += '<div class="div-table-row" style="border-bottom:1px solid #F89400">';
	       if(firstrow > 0){
                  tabletxt += '<div class="div-table-col" style="width:180px"></div>';
               } else {
                  firstrow = firstrow + 1;
                  tabletxt += '<div class="div-table-col" style="width:180px">' + group + '</div>';
	       }
               tabletxt += '<div class="div-table-col" style="width:300px">' + key + '</div>';
               if(innerdict[key] == 100){
                	tabletxt += '<div class="div-table-col" style="width:30px;text-align:center"><img src="/images/green_round.png" width="15px"/></div>';
               } else if (innerdict[key] == 0) {
                        tabletxt += '<div class="div-table-col" style="width:30px;text-align:center"><img src="/images/red_round.png" width="15px"/></div>';
               } else {
                  tabletxt += '<div class="div-table-col" style="width:30px;text-align:center"><img src="/images/grey_round.png" width="15px"/></div>';
               }
	       tabletxt += '</div>';
             }
	   }
           tabletxt += '<div class="div-table-row"><div class="div-table-col" style="width:500px"><img src="/images/red_round.png" style="width:15px"> - indicates that the infrastructure does not exist, <img src="/images/green_round.png" style="width:15px"> - indicates that it exists and <br/><img src="/images/grey_round.png" style="width:15px"> - indicates that information is unavailable.</div></div>';
           tabletxt += '</div>';
	   infra_info=tabletxt;
        } else {
           infra_info = "This information is currently unavailable";
        }
	document.getElementById("infra_info").innerHTML = infra_info;
}

function populatePTR()
{
	if (info["type"]==2) {
           tabletxt = ''
        } else if (info.student_count) {
           tabletxt = '<div class="div-table">';
           tabletxt += '<div class="div-table-row" style="border-bottom:1px solid #F89400">';
           tabletxt += '<div class="div-table-col" style="width:180px">Number of Classrooms</div>';
           tabletxt += '<div class="div-table-col" style="width:80px">' + info['classroom_count'] + '</div></div>';
           tabletxt += '<div class="div-table-row" style="border-bottom:1px solid #F89400">';
           tabletxt += '<div class="div-table-col" style="width:180px">Classes</div>';
           tabletxt += '<div class="div-table-col" style="width:80px">' + info['lowest_class'] +'-' + info['highest_class'] + '</div></div>';
           tabletxt += '<div class="div-table-row" style="border-bottom:1px solid #F89400">';
           tabletxt += '<div class="div-table-col" style="width:180px">Number of Teachers</div>';
           tabletxt += '<div class="div-table-col" style="width:80px">' + info['teacher_count'] + '</div></div>';
           tabletxt += '<div class="div-table-row" style="border-bottom:1px solid #F89400">';
           tabletxt += '<div class="div-table-col" style="width:180px">Number of Students</div>';
           tabletxt += '<div class="div-table-col" style="width:80px">' + info['student_count'] + '</div></div>';
           tabletxt += '<div class="div-table-row" style="border-bottom:1px solid #F89400">';
           tabletxt += '<div class="div-table-col" style="width:180px">Pupil-to-Teacher ratio</div>';
           if( parseInt(info['student_count']/info['teacher_count']) > 30 ) {
             tabletxt += '<div class="div-table-col" style="width:30px;text-align:center"><img src="/images/red_round.png" width="15px"/>';
           } else {
             tabletxt += '<div class="div-table-col" style="width:30px;text-align:center"><img src="/images/green_round.png" width="15px"/>';
           }
           tabletxt += '(' + parseInt(info['student_count']/info['teacher_count']) + ':1)</div></div>';
           tabletxt += '<div class="div-table-row"><div class="div-table-col" style="width:300px"><img src="/images/red_round.png" style="width:15px"> - indicates that the ratio is greater than 30:1,<br/> <img src="/images/green_round.png" style="width:15px"> - indicates that the ratio is lesser than 30:1.</div></div>';
        } else {
           tabletxt = 'Information currently unavailable'
        }
	document.getElementById("ptr_info").innerHTML = tabletxt;
}

function populateRTE()
{
	if (info["type"]==2) {
           tabletxt = "";
        } else if (Object.keys(info.dise_rte).length > 0) {
           tabletxt = '<div class="div-table">';
           for(group in info["dise_rte"]){
             innerdict = info["dise_rte"][group];
             var firstrow = 0;
             for(key in innerdict){
               tabletxt += '<div class="div-table-row" style="border-bottom:1px solid #F89400">';
	       if(firstrow > 0){
                  tabletxt += '<div class="div-table-col" style="width:180px"></div>';
               } else {
                  firstrow = firstrow + 1;
                  tabletxt += '<div class="div-table-col" style="width:180px">' + group + '</div>';
	       }
               tabletxt += '<div class="div-table-col" style="width:300px">' + key + '</div>';
               tabletxt += '<div class="div-table-col" style="width:30px;text-align:center">' + innerdict[key] + '</div>';
	       tabletxt += '</div>';
             }
	   }
           tabletxt += '</div>';
        } else {
           tabletxt = 'Information currently unavailable'
        }
	document.getElementById("rte_info").innerHTML = tabletxt;
}

function populateMDM()
{
   if (info["type"]==2) {
           tabletxt = "Meal information for Anganwadis is not available";
        } else if (Object.keys(info.ap_mdm).length > 0) {
           document.getElementById("mdm_info_heading").innerHTML = "Mid day meal Summary";
           document.getElementById("srcinfo6").innerHTML = '<br/><br/>Source : <a href="http://www.akshayapatra.org/" target="_blank"><span style="color:#43AD2F">Akshaya Patra (2012)</span></a>';

           tabletxt = "";
           var data = new google.visualization.DataTable();
           data.addColumn('string', 'Month_Week');
           data.addColumn('number', 'Food Indent');
           data.addColumn('number', 'Attendance');
           data.addColumn('number', 'DISE-enrollment');
           data.addColumn('number', 'KLP-enrollment');
           var months = ['January','February','March','April','May','June','July','August','September','October','November','December'] 
           for (var each in months ){
              if(months[each] in info["ap_mdm"]) {
                mon = months[each];
                for(var wk=1; wk<5;wk++) {
                  data.addRow([mon + ' (Week ' + wk + ')', info["ap_mdm"][mon][wk][0], info["ap_mdm"][mon][wk][1], parseInt(info["student_count"]),parseInt(info["numGirls"])+ parseInt(info["numBoys"])]);
                }
              }
	   }
           var chart = new google.visualization.LineChart(document.getElementById('mdm_chart'));
           chart.draw(data, {width: 750, height: 500, title:  'Food Indent vs. Attendance Tracking', backgroundColor: 'transparent', pieSliceText:'label', pointSize:5, colors: ['green','E35804','F49406','white'],vAxis:{title:'Number of Children'},hAxis:{slantedText:true, slantedTextAngle:45}});

        } else {
           tabletxt = 'Information currently unavailable'
        }
	document.getElementById("mdm_info").innerHTML = tabletxt;
}

function populateLibrary()
{
	if (info["type"]==2) {
           tabletxt = "";
        } else if (Object.keys(info.lib_infra).length > 0) {
           tabletxt = '<div class="div-table">';
           for(key in info.lib_infra){
               tabletxt += '<div class="div-table-row" style="border-bottom:1px solid #F89400">';
               tabletxt += '<div class="div-table-col" style="width:300px">' + key + '</div>';
               tabletxt += '<div class="div-table-col" style="width:30px;text-align:center">' + info.lib_infra[key] + '</div>';
	       tabletxt += '</div>';
	   }

           tabletxt += '</div>';
	   tabletxt += '<br/><br/>DISE reports Number of Books as : ';
           tabletxt +=  info.dise_books 
        } else {
           tabletxt = 'Information currently unavailable'
        }
	document.getElementById("lib_infra").innerHTML = tabletxt;
}

function ConvertToIndian(inputString) {
      inputString = inputString.toString();
      var numberArray = inputString.split('.', 2);
      var pref = parseInt(numberArray[0]);
      var suf = numberArray[1];
      var outputString = '';
      if (isNaN(pref)) return '';
      var minus = '';
      if (pref < 0) minus = '-';
      pref = Math.abs(pref).toString();
      if (pref.length > 3) {
      var lastThree = pref.substr(pref.length - 3, pref.length);
      pref = pref.substr(0, pref.length - 3);
      if (pref.length % 2 > 0) {
      outputString += pref.substr(0, 1) + ',';
      pref = pref.substr(1, pref.length - 1);
      }

      while (pref.length >= 2) {
      outputString += pref.substr(0, 2) + ',';
      pref = pref.substr(2, pref.length);
      }

      outputString += lastThree;
      } else {

      outputString = minus + pref;
      }

      if (!isNaN(suf)) outputString += '.' + suf;
      return '<img src="/images/Rupee.png" style="vertical-align:middle"/>&nbsp;' + outputString;
}

