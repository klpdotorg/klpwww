var newwindow;
function popwindow(url)
{
  newwindow=window.open(url,'Downloads','height=620,width=600,scrollbars=1');
  if (window.focus) {newwindow.focus()}
}
