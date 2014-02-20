function filterTable(phrase, _id){
  var words = phrase.value.toLowerCase().split(" ");
  var table = document.getElementById(_id);
  var ele;
  for (var r = 1; r < table.rows.length; r++){
    ele = table.rows[r].innerHTML.replace(/<[^>]+>/g,"");
    var displayStyle = 'none';
    for (var i = 0; i < words.length; i++) {
      if (ele.toLowerCase().indexOf(words[i])>=0)
        displayStyle = '';
      else {
        displayStyle = 'none';
        break;
      }
    }
    table.rows[r].style.display = displayStyle;
  }
}


function listFiles(fileList)
{
  var type = parseInt(fileList["listtype"])
  if( type == 1 || type == 3) {
    if( type == 1){
      document.getElementById('selections').style.display = "block";
    } else {
      document.getElementById('selections').style.display = "none";
      document.getElementById('mp_files').style.display = "block";
      document.getElementById('mla_files').style.display = "block";
      document.getElementById('disclaimer').style.display = "block";
    }
    var mptable = document.getElementById('mp_files');
    var mlatable = document.getElementById('mla_files');
    var fileNames = fileList["mpnames"].sort();
    var reporttypes = fileList["reptype"];
    tableHTML = "<div class='div-table'>" + "<div class='div-table-caption'>List of Reports</div>" ;
    tableHTML = tableHTML + "<div class='div-table-row'><div class='div-table-col'>"
			  + "<span style='text-align:center;color:#43AD2F;font-weight:bold'>CONSTITUENCY</span></div>";

    for( eachtype in reporttypes) {
      tableHTML = tableHTML + "<div class='div-table-col'><span style='color:#43AD2F;font-weight:bold'>" 
                            + reporttypes[eachtype].toUpperCase() + "</span></div>";
    }

    tableHTML = tableHTML + "</div>";

    for( each in fileNames) {
          tableHTML = tableHTML + "<div class='div-table-row'>" + "<div class='div-table-col'>" + fileNames[each] + "</div>";
          for( eachtype in reporttypes) {
            tableHTML = tableHTML + "<div class='div-table-col'>" + "<a target='_blank' href='" 
                                  + fileList["directory"] + "/" + reporttypes[eachtype] 
                                  + fileList["subdir1"] + "/" + fileNames[each] + "'/>" + "Kannada</a>&nbsp;&nbsp;";
            tableHTML = tableHTML + "<a target='_blank' href='" + fileList["directory"] + "/" + reporttypes[eachtype] 
                                  + fileList["subdir2"] + "/" + fileNames[each] + "'/>" + "English</a></div>" ;
          }
          tableHTML = tableHTML + "</div>";
    }

    
    if (type ==1 ) {
      mptable.innerHTML = tableHTML + '</div></div>';
      tableHTML = "<div class='div-table'>" ;
      tableHTML = tableHTML + "<div class='div-table-caption'>List of Reports</div>" ;
      tableHTML = tableHTML + "<div class='div-table-row'><div class='div-table-col'>"
                            + "<span style='color:#43AD2F;font-weight:bold'>CONSTITUENCY</span></div>";
   
      for( eachtype in reporttypes) {
        tableHTML = tableHTML + "<div class='div-table-col'><span style='color:#43AD2F;font-weight:bold'>" 
                            + reporttypes[eachtype].toUpperCase() + "</span></div>";
      }
      tableHTML = tableHTML + "</div>";
    }
    fileNames = fileList["mlanames"].sort();

    for( each in fileNames) {
        tableHTML = tableHTML + "<div class='div-table-row'>" + "<div class='div-table-col'>" + fileNames[each] + "</div>";
        for( eachtype in reporttypes) {
            tableHTML = tableHTML + "<div class='div-table-col'>" + "<a target='_blank' href='" 
                                  + fileList["directory"] + "/" + reporttypes[eachtype] 
                                  +  fileList["subdir1"] + "/" + fileNames[each] + "'/>" + "Kannada</a>&nbsp;&nbsp;";
            tableHTML = tableHTML + "<a target='_blank' href='" + fileList["directory"] + "/" + reporttypes[eachtype] 
                                  + fileList["subdir2"] + "/" + fileNames[each] + "'/>" + "English</a></div>" ;
        }
        tableHTML = tableHTML + "</div>";
    }
    mlatable.innerHTML = tableHTML + "</div></div>"

  } else if (type == 2) {
      document.getElementById('raw_files').style.display = "block";
      document.getElementById('top_menu').style.display = "block";

      document.getElementById('license').style.display = "block";
      var rawfiletable = document.getElementById('raw_files');
      var fileNames = fileList["rawfiles"].sort();
      tableHTML = "<div class='div-table'>" + "<div class='div-table-caption'>List of Reports</div>" ;
      tableHTML = tableHTML + "<div class='div-table-row'> Right click and use \"Save As\" to download files below:</div>";
      for( each in fileNames) {
          tableHTML = tableHTML + "<div class='div-table-row'>" +
                                  "<div class='div-table-col' style='width:200px;'>" +
                      "<a target='_blank' href='" + fileList["directory"] + "/" + fileNames[each] + "'/>" +
                      fileNames[each] + "</a></div></div>";
      }
        rawfiletable.innerHTML = tableHTML + "</div>"
  } else if (type == 4) {
      document.getElementById('ig_files').style.display = "block";
      var igfiletable = document.getElementById('ig_files');
      var fileNames = fileList["ig_files"].sort();
                    
      var newTable = "&nbsp;&nbsp;<a href='/listFiles/1'>Click here for KLP's Reports</a><br/><form id='filter'>Search by Name:&nbsp;<input name='filter' onkeyup='filterTable(this, \"filterable\");' type='text'><br><a href='/text/reports#ig' target='_blank'>Click here</a> to know more about IndiaGoverns.</form>";
      newTable = newTable + "<table id='filterable' class='filterable'><thead><tr><th>Consitiuency</th><th>Year 1</th><th>Year 2</th><th>Year 3</th><th>Year 4</th></tr></thead><tbody>";
      for ( each in fileNames) {
        newTable = newTable + "<tr><td>" + fileNames[each] + "</td>";
        newTable = newTable + "<td><a target='_blank' href='" + fileList["directory"] + fileList["subdir"][0] + "/" + fileNames[each] + "'>2008-09</a></td>";
        newTable = newTable + "<td><a target='_blank' href='" + fileList["directory"] + fileList["subdir"][1] + "/" + fileNames[each] + "'>2009-10</a></td>";
        newTable = newTable + "<td><a target='_blank' href='" + fileList["directory"] + fileList["subdir"][2] + "/" + fileNames[each] + "'>2010-11</a></td>";
        newTable = newTable + "<td><a target='_blank' href='" + fileList["directory"] + fileList["subdir"][3] + "/" + fileNames[each] + "'>2011-12</a></td>";
        newTable = newTable + "</td></tr>";
      }
      newTable = newTable + "</tbody></table>";
      igfiletable.innerHTML = newTable;
  }
}

function selectFiles()
{
      elm = document.getElementById('filetype').value;
      if(elm.length != 0) {
          div_ids=["mla_files","mp_files","corp_files"]
          for (var i = 0; i < div_ids.length; i++) {
            var layer = document.getElementById(div_ids[i]);
            if (elm!= div_ids[i]) {
              layer.style.display = "none";
            } else {
              layer.style.display = "block";
      	      document.getElementById('disclaimer').style.display = "block";
            }
          }
      }
}

