var schoolid;
var handle;
var cal1;
var typeform="schoolform";
var type;

function initCap(str)
{
  str = str.substring(0,1).toUpperCase() + str.substring(1,str.length).toLowerCase();
 return str;
}


function isNumeric(str)
{
  if (!(/^\d*$/.test(str.value)))
  {
    alert(str.id+" should only be numeric");
    str.value="";
    str.focus();
    return false;
  }
  return true;
}

function textCounter(field,cntfield,maxlimit) {
  if (field.value.length > maxlimit) // if too long...trim it!
    field.value = field.value.substring(0, maxlimit);
  // otherwise, update 'characters left' counter
  else
    cntfield.value = maxlimit - field.value.length;
}

function initialise()
{
   var query= window.location.search.substring(1);
   var variables = query.split("?");
   type=variables[0].split("=")[1];
   schoolid=variables[1].split("=")[1];
   document.schoolform.action ="/postSYS/"+type
   getSchoolInfo();
   document.getElementById("schoolid").value = schoolid;
}


function initializeDate()
{
  YUI({
    base: 'yui/build/',
    modules: {
        'gallery-aui-skin-base': {
            fullpath: '/gallery/build/gallery-aui-skin-base/css/gallery-aui-skin-base-min.css',
            type: 'css'
        },
        'gallery-aui-skin-classic': {
            fullpath: '/gallery/build/gallery-aui-skin-classic/css/gallery-aui-skin-classic-min.css',
            type: 'css',
            requires: ['gallery-aui-skin-base']
        }
    }
  }).use('gallery-aui-calendar-datepicker-select', function(Y) {
    var datePickerSelect = new Y.DatePickerSelect({
    displayBoundingBox: '#calendar',
    dateFormat: '%m/%d/%y',
    yearRange: [ 2009, 2012 ],
    dayField: Y.one("#dayselect"),
    dayFieldName: "day",
    monthField: Y.one("#monthselect"),
    monthFieldName: "month",
    yearField: Y.one("#yearselect"),
    yearFieldName: "year"
    }).render();
  });

}


function handleCal1Select(type,args,obj) {
  cal1.hide();
  var dates = args[0];
  var date = dates[0];
  var year = date[0], month = date[1], day = date[2];
  var txtDate1 = document.getElementById("dateofvisit");
  txtDate1.value = day + "-" + month + "-" + year;
}

function getSchoolInfo()
{
  YUI({base: 'yui/build/',
    timeout: 10000}).use("io-base","json-parse",
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
              populateInfo(info);
            },
            failure: function(id, o) {
               Y.log('Could not retrieve data ','error','info');
            } 
          }
        };
        url = "schoolInfo/"+schoolid;
        var request = Y.io(url, callback);
       });
}

function populateInfo(info)
{
  var content = ''
  if(info.type==1)
    {
      content = '<div><h1>' + info.schoolname.toUpperCase() + '</h1></div>' +
            '<div><b>District: </b>' + info.district + '<b> Block: </b>' + info.block +
            '<b> Cluster: </b>' + info.cluster + 
            '</div><div> Is this the school you visited? If yes, please fill the form below. ' +
      'If not, find the school from the <a href="visualization?type=school">map</a> and Share your Story! '
    } 
    else
    {
      content = '<div><h1>' + info.schoolname.toUpperCase() + '</h1></div>' +
           '<div><b>District: </b>' + info.district + '<b> Project: </b>' + info.block +
           '<b> Circle: </b>' + info.cluster + 
           '</div><div> Is this the school you visited? If yes, please fill the form below. ' +
      'If not, find the preschool from the <a href="visualization?type=preschool">map</a> and Share your Story! '
    }
    content = content + 'If you have any trouble, please call us at +91 80 25429726 or e-mail us at  <a href="mailto:team@klp.org.in">team@klp.org.in</a>';
    document.getElementById("schoolInfo").innerHTML= content
}


function submitData()
{
  var columnValues = [];
  var info = document.forms[typeform];
  var email= document.getElementById("email").value;
  var dov= document.getElementById("dateofvisit").value;
  var checkboxvals = [];

  if(email.length == 0 || isBlank(email) || isEmpty(email)) {
    alert("Please enter a valid e-mail id.");
    return false;
  }

  if(dov.length == 0 || isBlank(dov) || isEmpty(dov)) {
    alert("Please enter a valid Date for your visit.");
    return false;
  }

  for (num in info.elements )
  {
    var element = info.elements[num];
    if( element.type =="radio" || element.type=="checkbox")
    {
      if(element.checked)
      {
        checkboxvals.push(element.id + '|' + 'yes');
      }
    }
    if( element.id == "comments")
    {
      //alert(element.value);
      var strSingleLineText = element.value.replace(
        // Replace out the new line character.
        new RegExp( "\\n", "g" )," "
      );
      element.value = strSingleLineText;
      //alert(element.value);
    } 
  }
  document.getElementById("chkboxes").value = checkboxvals;

  return true;
}

var hash = {
  '.png'  : 1,
  '.jpeg' : 1,
  '.jpg' : 1,
  '.PNG' : 1,
  '.JPEG' : 1,
  '.JPG' : 1,
  '.gif' : 1,
  '.tiff' : 1,
  '.bmp' : 1,
};

function check_extension(filename,submitId) {
      var re = /\..+$/;
      var ext = filename.match(re);
      //alert(ext);
      var submitEl = document.getElementById(submitId);
      //alert(submitEl);
      if (hash[ext]) {
        submitEl.disabled = false;
        return true;
      } else {
        alert("Invalid filename for a photo, please select another file");
        submitEl.disabled = true;

        return false;
      }
}

function verifyEmail(emailstr,submitEl){
  var emailRegEx = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i;
  if (emailstr.search(emailRegEx) == -1) {
    alert("Please enter a valid e-mail address.");
    submitEl.disabled = true;
    return false;
  } else {
    submitEl.disabled = false;
    return true;
  }
}

function isBlank(str) {
    return (!str || /^\s*$/.test(str));
}

function isEmpty(str) {
    return (!str || 0 === str.length);
}
function postData()
{
    var form = document.createElement("form");
    form=document.forms['story'];
    form.setAttribute("method", "post");
    form.setAttribute("action", "/postSYS/"+schoolType);
    var result = form.submit();
}
