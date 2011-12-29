var info;
var map;
var type;
var image={"school":"school.png","preschool":"preschool.png"}

function initialise(data)
{
  info=data;
  //alert(document.location.href);
  //alert(document.location.host);
  info["name"]=info["name"].toUpperCase();
  if (info["type"]==2)
  {
    type="preschool";
    document.getElementById("school_info_heading").innerHTML = "Preschool Information";
    document.getElementById("school_visits_heading").innerHTML = "Preschool Visits";
    document.title = "Preschool Information";
  }
  else
  {
    type="school";
    document.getElementById("school_info_heading").innerHTML = "School Information";
    document.getElementById("school_visits_heading").innerHTML = "School Visits";
    document.title = "School Information";
  }

  document.getElementById("student_info_heading").innerHTML = "Student Information";
  document.getElementById("const_info_heading").innerHTML = "Constituency Information";
  var latlng = new google.maps.LatLng(info["lat"],info["lon"]);
  var myOptions = {
      zoom: 14,
      center: latlng,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      disableDoubleClickZoom:false
  };
  map = new google.maps.Map(document.getElementById("map"),myOptions);
  var marker = new google.maps.Marker({
        position: latlng,
        title:info["name"],
        icon:"/images/"+image[type]
      });
                  
  marker.setMap(map);  
  
  document.getElementById("school_name").innerHTML= info["name"];
  address = '<div class="div-table">'

  if (info["address"] != "-")
  {
        address = address + '<div class="div-table-row">' +
                        '<div id="div-col-90width" class="div-table-col" >District</div>' +
                        '<div class="div-table-col">:' + info["b"] +'</div>' +
                        '</div>' 
        
        address = address + '<div class="div-table-row">' 
        if(info["type"] != 2)
        {
          address = address + '<div id="div-col-90width" class="div-table-col" >Block</div>' 
        }else{
          address = address + '<div id="div-col-90width" class="div-table-col" >Project</div>' 
        }
        address = address + '<div class="div-table-col">:' + info["b1"] +'</div>' +
                            '</div>'


        address = address + '<div class="div-table-row">' 
        if(info["type"] != 2)
        {
          address = address + '<div id="div-col-90width" class="div-table-col" >Cluster</div>' 
        }else{
          address = address + '<div id="div-col-90width" class="div-table-col" >Circle</div>' 
        }
        address = address + '<div class="div-table-col">:' + info["b2"] +'</div>' +
                            '</div>'

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
  }
  infotable = infotable + '</div>'
	document.getElementById("school_info").innerHTML= infotable;

  studentinfo='<img src=\"http://chart.apis.google.com/chart'+
                        '?chf=bg,s,67676704'+
                        '&chs=300x225'+
                        '&cht=p'+
                        '&chco=EFB136|B56F1C|67676704'+
                        '&chdl=No.+of+Boys: '+info["numBoys"]+' ('+ Math.round(info["numBoys"]/info["numStudents"]*100)+'%)' +
                                '|No.+of+Girls: '+ info["numGirls"] +' ('+ Math.round(info["numGirls"]/info["numStudents"]*100)+'%)' + 
                                '|Total: '+info["numStudents"]+
                        '&chd=t:'+ info["numBoys"]+','+ info["numGirls"]+'\"'+ 
                        'width=\"300\" height=\"225\"/>'
  document.getElementById("student_info").innerHTML= studentinfo;


  systable = '<div class="div-table"><div class="div-table-row">' +
             '<div class="div-table-col"> No. of Visits:</div>' +
             '<div class="div-table-col">' + info["syscount"] + '</div>';
            if( info["syscount"]>0)
            {
              systable = systable+'<div class="div-table-row">Dates of Visit</div>';
              for(entry in info["sysdate"])
              {
                date = info["sysdate"][entry];
                if(date !="") 
                  systable = systable+'<div class="div-table-row">'+date+'</div>';
              }
            }
  systable = systable+'<div class="div-table-row"><b><a href=\"javascript:void(0);\" onclick=window.open("../../shareyourstory'+type+'?type='+type+'?id='+info["id"]+'","mywindow")>Share your Experience</a></b></div>';
  document.getElementById("sys_info").innerHTML= systable;

  if(info["images"])
  {
    school_pics= '<a rel=\"lightbox['+ info['id']+']\" href=\"' + info["image_dir"] + info["images"][0]+'\"><img class="album" src=\"' + info["image_dir"] + 
                info["images"][0]+'\"/>'
    for(i=1;i<info["images"].length;i++)
    {
      school_pics = school_pics+'<a rel=\"lightbox['+ info['id']+']\" href=\"' + info["image_dir"] + info["images"][i] +'\"></a>' 
    }
  }else{
    school_pics='This school does not have a picture album yet.<br/><br/>'
  }
  document.getElementById("school_pics").innerHTML=school_pics;
 
  tweet='<iframe allowtransparency=\"true\" frameborder=\"0\" scrolling=\"no\" src=\"http://platform.twitter.com/widgets/tweet_button.html?url=' + document.location.href + '&text='+ 'I visited ' + info["name"] +' and shared my story. More on the school here:' +'\" style=\"vertical-align:top; width:130px; height:50px;\"></iframe>'

  fb_like='<iframe src=\"http://www.facebook.com/plugins/like.php?href='+ document.location.href + '&amp;layout=standard&amp;show_faces=true&amp;width=350&amp;action=like&amp;colorscheme=light&amp;height=80\" scrolling=\"no\" frameborder=\"0\" style=\"vertical-align:top; border:none; overflow:hidden; width:350px; height:80px;\" allowTransparency=\"true\"></iframe>'

  document.getElementById("sharing").innerHTML = tweet + fb_like;

  const_table = '<div class="div-table">' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MLA Constituency</div>' + 
                '<div class="div-table-col">:' + info['mla'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MLA Details</div>' + 
                '<div class="div-table-col">:' + info['mlaname'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MP Constituency</div>' + 
                '<div class="div-table-col">:' + info['mp'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><div id="div-col-125width" class="div-table-col">MP Details</div>' + 
                '<div class="div-table-col">:' + info['mpname'].toUpperCase() + '</div><div>' +
                '<div class="div-table-row"><a href="" onclick="javascript:popwindow(\'/listFiles/1\')" style="color:#43AD2F">Please find Constituency-wise Reports here.</a></div>' +
                '</div>';
  document.getElementById("school_const").innerHTML = const_table

  var assessArr = info.assessments.split(",");
  var assessmentInfo = '';
   for( num in assessArr)
   {
     var assessment = assessArr[num].split("|");
     var asstext = assessment[0];
     assessmentInfo = assessmentInfo+'<a href=\"javascript:void(0);\" onclick=window.open("../../assessment/'+type+'/'+assessment[1]+'/'+info['id']+'","mywindow")>'+asstext+'</a><br>'
   }

  document.getElementById("assessment_info").innerHTML = '<div class="div-table">' +
                '<div class="div-table-row"><div class="div-table-col">Akshara Programmes</div>' +
                '<div class="div-table-col">' + assessmentInfo + '</div><div>' +
                '</div>';

}

