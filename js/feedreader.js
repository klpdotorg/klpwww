var months = new Array("Nothing","Jan","Feb","March","April","May","June","July","Aug","Sept","Oct","Nov","Dec");


function processRequest(feed)
{
  var entries = feed.entry || [];
  var html = ['<ul>'];

  for (var i = 0; i < 2; ++i) {
    var entry = entries[i];
    var title = entry.title.$t;
    var content = entry.content.$t;
    var re=/<\S[^>]*>/g;
    content=content.replace(re,"");
    content = content.substring(0,100);
    year = entry.published.$t.substring(0,4);
    month = entry.published.$t.substring(5,7);
    if( month.charAt(0) == "0")
    {
      month=month.charAt(1)
    }
    month = parseInt(month)
    date = entry.published.$t.substring(8,10);
    for(var num=0;num<entry.link.length;num++){
      if(entry.link[num].rel=='alternate')
      {
        link=entry.link[num].href;
        break;
      }
    }
    html.push(months[month],' ',date,',',year,'<br>','<b><a href="',link,'">',title,'</a></b>','<br>',content,'...','<br>','<br>');
  }
  html.push('</ul>');
  document.getElementById("blog").innerHTML = html.join("");
}
