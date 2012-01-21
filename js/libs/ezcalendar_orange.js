/*==============================================================================
	EZCalendar v0.9.1 Created by Stewart Orr (www.qodo.co.uk)
	http://www.qodo.co.uk/blog/javascript-pop-up-dhtml-calendar-using-css/
	Created: Oct 2006
	Updated: January 2008
	
	You are free to use this wherever you like, maybe you could contact me
	to let me know where/how you are using it.

	Usage:
		- Expects dates in the UK format DD/MM/YYYY.
		- Uses JS and CSS file to determine appearance
		- CSS File should have all necessary styles to ensure it appears
		correctly in YOUR page. Remember other CSS styles will affect this...
		
	To Do:
		- Position the calendar differently if it spills over the viewable space.
		- Improve Code
		- Allow different date separators
		- Allow different date formats (YYYY/MM/DD and MM/DD/YYYY)
		- Allow for date restrictions
		
	ChangeLog:
		- Jan 2008: Improvements to code and added fadeOut effect, added tooltips
		- March 2007: Added fading in effect
		- February 2007: Updated and improved coding
		- October 2006: created first version
	
==============================================================================*/

	var EZcalendar = false; 	// Loaded or not?
	var bCalendarFade = true;	// Fade in or not? Not suitable for slow machines
	var iCalendarFadeSpd = 25;	// Lower the number, faster it is.
	var selectedDate;			// whether the users cursor is over the calendar
	var target;					// the target element for the date value
	var dateSeparator = "/";	// date separator unit 
	var overCalendar = false;	// whether the users cursor is over the calendar
	var shortMonths = new Array("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	var fullMonths = new Array("January","February","March","April","May","June","July","August","September","October","November","December");

	// simply return an object by id
	function getID(id) {
		return document.getElementById(id);
	}

	// return a number with 2 digits ("2" becomes "02")
	function formatNumber(n) {
		return (n<10) ? "0"+n : n;
	}
	
	function getScrollFromTop() {
		if (self.pageYOffset) {
			return self.pageYOffset;
		} else if (document.documentElement && document.documentElement.scrollTop) {
			return document.documentElement.scrollTop;
		} else {
			return document.body.scrollTop;
		}	
	}

	// return a number > 10 as one single digit ("09" becomes "9")
	function removeFormatNumber(n) {
		return (n.substr(0,1)=="0") ? n.substr(1,1) : n;
	}
	
	// return the on-screen LEFT(x) position of an element
	function getPageOffsetLeft(el) {
		return (el.offsetParent != null) ? el.offsetLeft + getPageOffsetLeft(el.offsetParent) : el.offsetLeft;
	}
	
	// return the on-screen TOP(y) position of an element	
	function getPageOffsetTop(el) {
		return (el.offsetParent != null) ? el.offsetTop + getPageOffsetTop(el.offsetParent) : el.offsetTop;
	}

	// Checks a string to see if it in a valid date format
	// of (D)D/(M)M/(YY)YY and returns true/false
	function isValidDate(s) {
		// format D(D)/M(M)/(YY)YY
		var dateFormat = /^\d{1,2}\/\d{1,2}\/\d{2,4}$/;
		if (dateFormat.test(s)) {
			// remove any leading zeros from date values
			s = s.replace(/0*(\d*)/gi,"$1");
			var dateArray = s.split("/");
			// correct month value
			dateArray[1] = dateArray[1]-1;
			// correct year value
			if (dateArray[2].length<4) {
				// correct year value
				dateArray[2] = (parseInt(dateArray[2]) < 50) ? 2000 + parseInt(dateArray[2]) : 1900 + parseInt(dateArray[2]);
			}
			var testDate = new Date(dateArray[2], dateArray[1], dateArray[0]);
			if (testDate.getDate()!=dateArray[0] || testDate.getMonth()!=dateArray[1] || testDate.getFullYear()!=dateArray[2]) {
				return false;
			} else {
				return true;
			}
		} else {
			return false;
		}
	}
	
	
	// get the calendar week of a date
	function getWeek(d) {
		/* thanks to http://www.quirksmode.org/js/week.html */
		var today = new Date(d);
		Year = today.getFullYear();
		Month = today.getMonth();
		Day = today.getDate();
		now = Date.UTC(Year,Month,Day+1,0,0,0);
		var Firstday = new Date();
		Firstday.setYear(Year);
		Firstday.setMonth(0);
		Firstday.setDate(1);
		then = Date.UTC(Year,0,1,0,0,0);
		var Compensation = Firstday.getDay();
		if (Compensation > 3) Compensation -= 4;
		else Compensation += 3;
		NumberOfWeek =  Math.round((((now-then)/86400000)+Compensation)/7);
		return formatNumber(NumberOfWeek);
	}

	// change the calendar to the PREVIOUS month
	function prevMonth() {
		var months = getID("months");
		var years = getID("years");
		if (parseInt(months.value) - 1 >= 0) {
			months.value = parseInt(months.value) - 1;
		} else if (parseInt(years.value) > 1901) {
			months.value = 11;
			years.value = parseInt(years.value) - 1;
		}
		updateCalendar();	
	}

	// change the calendar to the NEXT month
	function nextMonth() {
		var months = getID("months");
		var years = getID("years");
		if (parseInt(months.value) + 1 < 12) {
			months.value = parseInt(months.value) + 1;
		} else if (parseInt(years.value) < 2099) {
			months.value = 0;
			years.value = parseInt(years.value) + 1;
		}
		updateCalendar();	
	}

	// change the calendar to the PREVIOUS year
	function prevYear() {
		var years = getID("years");
		if (parseInt(years.value) > 1901) {
			years.value = parseInt(years.value) - 1;
		}
		updateCalendar();	
	}

	// change the calendar to the NEXT year
	function nextYear() {
		var years = getID("years");
		if (parseInt(years.value) < 2099) {
			years.value = parseInt(years.value) + 1;
		}
		updateCalendar();	
	}

	// update the calendars values
	// this changes the <a> tags innerHTML and href values
	function updateCalendar() {
		var today = new Date();
		var y = getID("years");
		var m = getID("months");
		y = y.value;
		m = m.value;
		
		var calendarDate = new Date(y,m,1);
		getID("EZcalendar_text").innerHTML =  shortMonths[calendarDate.getMonth()] + " " + calendarDate.getFullYear();
		
		var defaultMonth = calendarDate.getMonth();
		var difference = calendarDate.getDay()+6;
		calendarDate.setDate(calendarDate.getDate()-difference);
		
		for (r=0;r<6;r++) {
			getID("week"+r).innerHTML = getWeek(calendarDate);
				for (c=0;c<7;c++) {
					if (calendarDate.getMonth()!=defaultMonth) {
						getID("cell"+r+c).className="outsideMonth";
					} else {
						getID("cell"+r+c).className="";
					}

					// is it today's date?
					if (calendarDate.getDate()+"/"+calendarDate.getMonth()+"/"+calendarDate.getFullYear()==today.getDate()+"/"+today.getMonth()+"/"+today.getFullYear()) {
						getID("cell"+r+c).className="today";
					}
					
					getID("cell"+r+c).title = "";
					getID("cell"+r+c).innerHTML = calendarDate.getDate();					
					getID("cell"+r+c).href = "javascript:setDateValue('" + formatNumber(calendarDate.getDate()) + dateSeparator + formatNumber(calendarDate.getMonth()+1) + dateSeparator + calendarDate.getFullYear() + "')";
					getID("cell"+r+c).title = calendarDate.getDate() + " " + fullMonths[calendarDate.getMonth()] + ", " + calendarDate.getFullYear();
					calendarDate.setDate(calendarDate.getDate()+1);
				}
		}
	}

	// when a user click the show calendar link, this function opens 
	// the calendar and tries to show the correct calendar for the date in
	// the input field.
	function showCalendar(el) {
		if (EZcalendar) {
			if (typeof el == "string") {
				var el = getID(el);
			}
			target=el.id;
			var y = getID("years");
			var m = getID("months");
			var calendar = getID("EZcalendar");

			// test if string is valid date and if so, show calendar relative to the date they have chosen.
			if (isValidDate(el.value)) {
				var elDate = el.value.replace(/0*(\d*)/gi,"$1");
				var dateArray = elDate.split(dateSeparator);
				// correct month value
				dateArray[1] = dateArray[1]-1;
				if (dateArray[2].length<4) {
					// correct year value
					dateArray[2] = (parseInt(dateArray[2]) < 50) ? 2000 + parseInt(dateArray[2]) : 1900 + parseInt(dateArray[2]);
				}
				m.value = dateArray[1];
				y.value = dateArray[2];
			} else {
				m.value = selectedDate.getMonth();
				y.value = selectedDate.getFullYear();
			}
		
			updateCalendar();
			
			var x = getPageOffsetLeft(el);
			var y = getPageOffsetTop(el) + el.clientHeight;
			calendar.style.top = (y+5)+"px";
			calendar.style.left = x+"px";
			if (bCalendarFade) {
				calendar.style.opacity = 0;
				calendar.style.filter = "alpha(opacity=0)";
				calendar.MozOpacity = 0;
				calendar.KhtmlOpacity = 0;
				setTimeout("fadeIn(5)",iCalendarFadeSpd);
			}
			calendar.style.display = "block";
		} else {
			alert("NOTICE:\n\nCalendar not finished loading, please wait...");	
		}


	}

	/* When the user clicks, this function tries to detect 
	if they have clicked outside the calendar and if so 
	it tries to hide it. */
	function clickbg(e) {
		if (!overCalendar) {
			getID("EZcalendar").style.display="none";
		}
	}

	/* When a user click the calendar date, this function updates the input field */
	function setDateValue(d,el) {
		if (bCalendarFade) {
			setTimeout("fadeOut(95)",iCalendarFadeSpd);
		} else {
			getID("EZcalendar").style.display = "none";
		}
		getID(target).value=d;
	}

	/* Fading in the calendar in a nice way */
	function fadeIn(percentage) {
		var EZcalendar = getID("EZcalendar");
		// apply opacity for all browsers
		EZcalendar.style.opacity = percentage/100;
		EZcalendar.style.filter = "alpha(opacity="+percentage+")";
		EZcalendar.MozOpacity = (percentage / 100);
		EZcalendar.KhtmlOpacity = (percentage / 100);		
		if (percentage<100) {
			setTimeout("fadeIn("+(percentage+5)+")",iCalendarFadeSpd);
		}
	}
	/* Fading in the calendar in a nice way */
	function fadeOut(percentage) {
		var EZcalendar = getID("EZcalendar");
		// apply opacity for all browsers
		EZcalendar.style.opacity = percentage/100;
		EZcalendar.style.filter = "alpha(opacity="+percentage+")";
		EZcalendar.MozOpacity = (percentage / 100);
		EZcalendar.KhtmlOpacity = (percentage / 100);		
		if (percentage>0) {
			setTimeout("fadeOut("+(percentage-5)+")",iCalendarFadeSpd);
		} else {
			EZcalendar.style.display = "none";
		}
	}

	/* Loads the calendar for the first time by creating all the HTML */
	function initCalendar() {
		// create our container DIV and add javascript to it
		var EZCalendarDIV = document.createElement('div');
		EZCalendarDIV.id = "EZcalendar"; 
		EZCalendarDIV.onmouseover = function() { overCalendar=true; }
		EZCalendarDIV.onmouseout  = function() { overCalendar=false; }
		// hide calendar by default
		EZCalendarDIV.style.display = "none";
		document.body.appendChild(EZCalendarDIV);
			
		var calendarHTML = "";
		selectedDate = new Date();
		calendarHTML += '<form action="#" method="get">';
		calendarHTML += '	<input id="months" name="months" type="hidden" value="' + selectedDate.getMonth() + '" />';
		calendarHTML += '	<input id="years" name="years" type="hidden" value="' + selectedDate.getFullYear() + '" />';
		calendarHTML += '	<div id="EZcalendar_table">';
		calendarHTML += '		<table border="1" cellpadding="0" cellspacing="0">';
		calendarHTML += '			<tr>';
		calendarHTML += '				<td><input type="button" value="&laquo;" onclick="prevYear()" title="Previous Year" /></td>';
		calendarHTML += '				<td><input type="button" value="&lsaquo;" onclick="prevMonth()" title="Previous Month" /></td>';
		calendarHTML += '				<td colspan="4" id="EZcalendar_text">' + shortMonths[selectedDate.getMonth()] + " " + selectedDate.getFullYear() + '</td>';
		calendarHTML += '				<td><input type="button" value="&rsaquo;" onclick="nextMonth()" title="Next Month" /></td>';
		calendarHTML += '				<td><input type="button" value="&raquo;" onclick="nextYear()" title="Next Year" /></td>';
		calendarHTML += '			</tr>';
		// build table using for loops...		
		calendarHTML += '			<tr>';
		calendarHTML += '				<th scope="col">&nbsp;</th>';
		calendarHTML += '				<th scope="col">M</th>';
		calendarHTML += '				<th scope="col">T</th>';
		calendarHTML += '				<th scope="col">W</th>';
		calendarHTML += '				<th scope="col">T</th>';
		calendarHTML += '				<th scope="col">F</th>';
		calendarHTML += '				<th scope="col">S</th>';
		calendarHTML += '				<th scope="col">S</th>';
		calendarHTML += '			</tr>';
		for (r=0;r<6;r++) {
			calendarHTML += '	<tr>';
			calendarHTML += '		<th scope="row" id="week' + r + '">00</th>';
				for (c=0;c<7;c++) {
					calendarHTML += '		<td><a href="#" id="cell'+ r + "" + c +'">00</a></td>';					
				}
		}
		calendarHTML += '	</tr>';
		calendarHTML += '</table>';
		// ... end 
		calendarHTML += '	</div>';
		calendarHTML += '	</form>';
		
		EZCalendarDIV.innerHTML = calendarHTML;
		EZcalendar = true;
		document.onmousedown = clickbg;
		updateCalendar();
	}

	/* Initialise the page by preparing the calendar when the page has loaded */
	document.onload = setTimeout("initCalendar()",500);