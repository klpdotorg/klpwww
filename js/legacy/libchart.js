//google.load("visualization", "1", {packages:["corechart","table"]});

var levels=[],langs=[],borrows=[];
var options={
          title: 'Based On Level',
	  pointSize: 5,
	  vAxis:{title:'Avg no of transactions per student', viewWindowMode: 'explicit',viewWindow: {min: 0}},
	  hAxis:{title:'Month'},
	  smoothLine: 'true',
	  animation:{
        	duration: 1000,
        	easing: 'out'
      		},
	  height:400,
	  width:950,
	  legend:{position:'none'},
	  backgroundColor: 'transparent'
        };

var levelimage=document.getElementById('levelimage');

var cssClassNames = {
    'headerRow': 'header-row-libchart center-text-libchart',
    'tableRow': 'background-libchart center-text-libchart',
    'oddTableRow': 'background-libchart center-text-libchart',
    'selectedTableRow': 'background-libchart center-text-libchart',
    'hoverTableRow': 'background-libchart center-text-libchart',
    'headerCell': 'background-libchart center-text-libchart',
    'tableCell': 'background-libchart center-text-libchart'
};

function libchartload(){/*
	document.getElementById('aggchart').style.display='block';
	document.getElementById('borrowchart').style.display='none';*/
	var clas=document.getElementById("clas");
	var year=document.getElementById("acyear");
	for(var i=1;i<=classes.length;i++)
		clas.options[i]=new Option(classes[i-1],classes[i-1]);
	for(var i=0;i<years.length;i++)
		acyear.options[i]=new Option(years[i],years[i]);
	charttable('2011-2012','0');
	draw_chart(levels,1);
}

function display(value,type){
	var type=document.getElementById('change').value;
	var levelimage=document.getElementById('levelimage');
	var data;
	if(value=="agg"){
		options['title']='Total transaction';
		options['legend']={position:'none'};
		levelimage.style.display='none';
		data=borrows;
	}
	else if(value=="blevel"){
		options['title']='Based On Level';
		options['legend']={position:'none'};
		levelimage.style.display='block';
		data=levels
	}
	else if(value=="blang"){
		options['title']='Based On Language';
		options['legend']={position:'right'};
		levelimage.style.display='none';
		data=langs;		
	}
	if(type=="Change to Table View")
		draw_chart(data,1);
	else{
		draw_chart(data,2);
                levelimage.style.display='none';
	}
}

function charttable(year,clas){
	var i,j,k,temp;
	var total=0;
	var totalstudent=0;
	temp=new Array();
	if(clas==0){
		for(i=1;i<totals.length;i++){
			if(totals[i][2]==year)
				total=parseInt(total)+parseInt(totals[i][1]);
		}
	}
	else{
		for(i=1;i<totals.length;i++){
			if(totals[i][0]==parseInt(clas) && totals[i][2]==year){
				total=parseInt(total)+parseInt(totals[i][1]);
			}
		}
	}        
	totalstudent=total;
	if(total==0)
		total=1;
//	alert(total);
	var mon=['Jun','Jul','Aug','Sep','Nov','Dec','Jan','Feb','Mar','Apr','May'];
	levels = new google.visualization.DataTable();
	levels.addColumn('string','Month');
	levels.addColumn('number','GREEN');
	levels.addColumn('number','RED');
	levels.addColumn('number','ORANGE');
	levels.addColumn('number','WHITE');
	levels.addColumn('number','BLUE');
	levels.addColumn('number','YELLOW');
	langs = new google.visualization.DataTable();
	langs.addColumn('string','Month');
	langs.addColumn('number','KANNADA');
	langs.addColumn('number','URDU');
	langs.addColumn('number','HINDI');
	langs.addColumn('number','ENGLISH');
	langs.addColumn('number','E/H');
	langs.addColumn('number','E/K');
	langs.addColumn('number','TAMIL');
	langs.addColumn('number','TELUGU');
	borrows = new google.visualization.DataTable();
	borrows.addColumn('string','Month');
	borrows.addColumn('number','Count');
	for(i=0;i<=mon.length-1;i++){
		temp=[mon[i],0,0,0,0,0,0];
		for(j=1;j<level.length-1;j++){
			if(level[j][2].toString()==mon[i]){
				if(clas=='0'){
					if(level[j][0].toString()==year){
						temp[1]=parseInt(temp[1])+parseInt(level[j][3]);
						temp[2]=parseInt(temp[2])+parseInt(level[j][4]);
						temp[3]=parseInt(temp[3])+parseInt(level[j][5]);
						temp[4]=parseInt(temp[4])+parseInt(level[j][6]);
						temp[5]=parseInt(temp[5])+parseInt(level[j][7]);
						temp[6]=parseInt(temp[6])+parseInt(level[j][8]);						
					}						
				}
				else{
					if(level[j][0].toString()==year && level[j][1]==clas){
						temp[1]=parseInt(temp[1])+parseInt(level[j][3]);
						temp[2]=parseInt(temp[2])+parseInt(level[j][4]);
						temp[3]=parseInt(temp[3])+parseInt(level[j][5]);
						temp[4]=parseInt(temp[4])+parseInt(level[j][6]);
						temp[5]=parseInt(temp[5])+parseInt(level[j][7]);
						temp[6]=parseInt(temp[6])+parseInt(level[j][8]);						
					}
				}
			}
		}
		for(k=1;k<temp.length;k++){
			temp[k]=(parseInt(temp[k])/parseInt(total));
			if(temp[k]>0)
				temp[k]=temp[k].toFixed(2)*1;
		}
		//alert(temp);
		levels.addRow(temp);
		temp=[mon[i],0,0,0,0,0,0,0,0];
		for(j=1;j<lang.length;j++){
			if(lang[j][2].toString()==mon[i]){
				if(clas=='0'){
					if(lang[j][0]==year){
						temp[1]=parseInt(temp[1])+parseInt(lang[j][3]);
						temp[2]=parseInt(temp[2])+parseInt(lang[j][4]);
						temp[3]=parseInt(temp[3])+parseInt(lang[j][5]);
						temp[4]=parseInt(temp[4])+parseInt(lang[j][6]);
						temp[5]=parseInt(temp[5])+parseInt(lang[j][7]);
						temp[6]=parseInt(temp[6])+parseInt(lang[j][8]);						
						temp[7]=parseInt(temp[7])+parseInt(lang[j][9]);
						temp[8]=parseInt(temp[8])+parseInt(lang[j][10]);
					}						
				}
				else{
					if(lang[j][0]==year && lang[j][1]==clas){
						temp[1]=parseInt(temp[1])+parseInt(lang[j][3]);
						temp[2]=parseInt(temp[2])+parseInt(lang[j][4]);
						temp[3]=parseInt(temp[3])+parseInt(lang[j][5]);
						temp[4]=parseInt(temp[4])+parseInt(lang[j][6]);
						temp[5]=parseInt(temp[5])+parseInt(lang[j][7]);
						temp[6]=parseInt(temp[6])+parseInt(lang[j][8]);						
						temp[7]=parseInt(temp[7])+parseInt(lang[j][9]);
						temp[8]=parseInt(temp[8])+parseInt(lang[j][10]);						
					}
				}
			}
		}
		for(k=1;k<temp.length;k++){
			temp[k]=parseInt(temp[k])/parseInt(total);
			if(temp[k]>0)
                		temp[k]=temp[k].toFixed(2)*1;
		}
		langs.addRow(temp);
		temp=[mon[i],0];
		for(j=1;j<borrow.length;j++){
			if(borrow[j][2]==mon[i]){
				if(clas=='0'){
					if(borrow[j][0]==year){
						temp[1]=parseInt(temp[1])+parseInt(borrow[j][4]);						
					}						
				}
				else{
					if(borrow[j][0]==year && borrow[j][1]==clas){
						temp[1]=parseInt(temp[1])+parseInt(borrow[j][4]);						
					}
				}
			}
		}
		for(k=1;k<temp.length;k++){
			temp[k]=parseInt(temp[k])/parseInt(total);
                        if(temp[k]>0)
                                temp[k]=temp[k].toFixed(2)*1;
		}
		borrows.addRow(temp);
	}
	document.getElementById('students').innerHTML="Total Number of Students : "+totalstudent;
}

function draw_chart(data,type){
	var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
	var table = new google.visualization.Table(document.getElementById('table_div'));
	options['colors']=['Green', 'Red', 'Orange', '#DDD', 'Blue','Yellow','Gray','black'];
	if(type==1)
		chart.draw(data,options);
	else
		table.draw(data,{'allowHtml': true, 'cssClassNames': cssClassNames});
}

function changedata(){
	year=document.getElementById('acyear').value;
	clas=document.getElementById('clas').value;
	var levelimage=document.getElementById('levelimage');
	charttable(year,clas);
	var value=document.getElementById('change').value;
	var type=document.getElementById('type').value;
	var data;
	if(type=="blevel"){
		options['title']='Based On Level';
		options['legend']={position:'none'};
                levelimage.style.display='block';
		data=levels;
	}
	else if(type=="blang"){
		options['title']='Based On Language';
		options['legend']={position:'right'};
                levelimage.style.display='none';
		data=langs;
	}
	else {
		options['title']='Total transaction';
		options['legend']={position:'none'};
                levelimage.style.display='none';
		data=borrows;
	}
	if(value=="Change to Table View"){
		draw_chart(data,1);
	}
	else{
                levelimage.style.display='none';
		draw_chart(data,2);
	}
}

function changetype(value){
	if(value=="Switch to Language"){
		document.getElementById('switch').value='Switch to Level';
		if(document.getElementById('change').value=="Change to Table View")
			draw_chart(langs,1);
		else
			draw_chart(langs,2);		
	}
	else{
		document.getElementById('switch').value='Switch to Language';
		if(document.getElementById('change').value=="Change to Table View")
			draw_chart(levels,1);
		else
			draw_chart(levels,2);
	}
}

function changechart(value){
	var type=document.getElementById('type').value;
        var levelimage=document.getElementById('levelimage');	
	var data;
	if(type=="blevel"){
		options['title']='Based On Level';
		options['legend']={position:'none'};
                levelimage.style.display='block';
		data=levels;
	}
	else if(type=="blang"){
		options['title']='Based On Language';
		options['legend']={position:'right'};
                levelimage.style.display='none';
		data=langs;
	}
	else {
		options['title']='Total transaction';
		options['legend']={position:'none'};
                levelimage.style.display='none';
		data=borrows;
	}
	if(value=="Change to Table View"){
		document.getElementById('change').value="Change to Line Chart";
		document.getElementById('chart_div').style.display="none";
		document.getElementById('table_div').style.display="block";
                levelimage.style.display='none';
		draw_chart(data,2);
	}
	else{
		document.getElementById('change').value="Change to Table View";
		document.getElementById('chart_div').style.display="block";
		document.getElementById('table_div').style.display="none";
		draw_chart(data,1);
	}
}

