var newwindow;
function popwindow(url)
{
  newwindow=window.open(url,'Downloads','height=620,width=800,scrollbars=1');
  if (window.focus) {newwindow.focus()}
}

//Util for home page only
function getSysInfo()
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
            populateSys(info);
          },
          failure: function(id, o) {
            Y.log('Could not retrieve school page data ','error','info');
          }
        }
      };
      var url = '';
      url = "/sysinfo";
      var request = Y.io(url, callback);
    });
}
 
function populateSys(info)
{
  document.getElementById("sysinfo").innerHTML = "Share your stories of visits to schools... We are counting <a href=\"/visualization\" target=\"_blank\"> <img src='/images/sys_icon.png'/><span style='color:white;font-weight:bold'> " + info["numstories"] + "</span> shared experiences  <img src='/images/cam_icon.png'/><span style='color:white;font-weight:bold'> " + info["numimages"] + "</span> shared images</a> today!"
}
