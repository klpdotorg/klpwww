var schoolid;
var handle;
var cal1;
var typeform="schoolform";
var type;
var myEditor;

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


function initialise(schoolinfo)
{
   type=schoolinfo['type'];
   schoolid=schoolinfo['schoolid'];
   document.schoolform.action ="/postSYS/"+type
   getSchoolInfo(schoolid);
   document.getElementById("schoolid").value = schoolid;
   //initialiseEditor()
}

function initialiseEditor() 
{
  //Setup some private variables
  var Dom = YAHOO.util.Dom,
  Event = YAHOO.util.Event;

  //The SimpleEditor config
  var myConfig = {
    height: '300px',
    width: '600px',
    dompath: true,
    focusAtStart: true,
     toolbar: {
        buttons: [
            { group: 'textstyle', label:'Font Name and Size',
               buttons:[
                     { type: 'select', label: 'Arial', value: 'fontname',
                        menu: [
                            { text: 'Arial', checked: true },
                            { text: 'Arial Black' },
                            { text: 'Comic Sans MS' },
                            { text: 'Courier New' },
                            { text: 'Lucida Console' },
                            { text: 'Tahoma' },
                            { text: 'Times New Roman' },
                            { text: 'Trebuchet MS' },
                            { text: 'Verdana' }
                        ]
                    },
                    { type: 'spin', label: '13', value: 'fontsize', range: [ 9, 75 ]},
               ]
            },
            { type: 'separator' }, 
            { group: 'textstyle', label: 'Font Style',
                buttons: [
                    { type: 'push', label: 'Bold', value: 'bold' },
                    { type: 'push', label: 'Italic', value: 'italic' },
                    { type: 'push', label: 'Underline', value: 'underline' },
                ]
            },
            { type: 'separator' }, 
            { group: 'alignment', label: 'Alignment', 
	        buttons: [ 
	            { type: 'push', label: 'Align Left CTRL + SHIFT + [', value: 'justifyleft' }, 
	            { type: 'push', label: 'Align Center CTRL + SHIFT + |', value: 'justifycenter' }, 
	            { type: 'push', label: 'Align Right CTRL + SHIFT + ]', value: 'justifyright' }, 
	            { type: 'push', label: 'Justify', value: 'justifyfull' } 
	        ] 
	    }, 
	    { type: 'separator' }, 
            { group: 'indentlist', label: 'Indenting and Lists', 
	        buttons: [ 
	            { type: 'push', label: 'Indent', value: 'indent'}, 
	            { type: 'push', label: 'Outdent', value: 'outdent'}, 
	            { type: 'push', label: 'Create an Unordered List', value: 'insertunorderedlist' }, 
	            { type: 'push', label: 'Create an Ordered List', value: 'insertorderedlist' } 
	        ] 
	    }
        ]
    }
  };

  myEditor = new YAHOO.widget.Editor('comments', myConfig);
  myEditor.render();

}


function initializeDate()
{
  YUI({
    base: '/yui/build/',
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

function getSchoolInfo(schoolid)
{
  YUI({base: '/yui/build/',
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
        url = "/schoolInfo/"+schoolid;
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
      'If not, find the school from the <a href="/map">map</a> and Share your Story! '
    } 
    else
    {
      content = '<div><h1>' + info.schoolname.toUpperCase() + '</h1></div>' +
           '<div><b>District: </b>' + info.district + '<b> Project: </b>' + info.block +
           '<b> Circle: </b>' + info.cluster + 
           '</div><div> Is this the school you visited? If yes, please fill the form below. ' +
      'If not, find the preschool from the <a href="/map">map</a> and Share your Story! '
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
      //commenting rich text box
      //myEditor.saveHTML();
      //The var html will now have the contents of the textarea
      //var textboxdata= myEditor.get('element').value;
      //element.value = textboxdata;
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
      //var re = /\..+$/;
      var re=/\.[0-9a-z]+$/i;
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
