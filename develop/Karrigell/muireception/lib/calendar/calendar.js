/*******************************************************************************************************************************
Author: Broader ZHONG 
Web: http://github.com/broader/EasyReception
Email: broader.zhong@yahoo.com.cn
Company: 
Licence: Creative Commons Attribution 3.0 Unported License, http://creativecommons.org/licenses/by/3.0/
If you copy, distribute or transmit the source code please retain the above copyright notice, author name and project URL. 
Required: Mootools 1.2 or newer 
*******************************************************************************************************************************/

var CalendarTable = new Class({
	version: '0.1',
	
	Implements: [Events,Options],
				  
	options: {
		// table layout 
		//columnsModel: null,	
		//colsModelUrl: null,
		lang: 'zh-CN',	// i18n 
		tableClass: 'calendarTable',
		nextClass: 'next',
		prevClass: 'prev',
		outOfMonthClass: 'outOfMonth',
		dataUrl: null,
		//data: null,
		selectedClass: 'selected'	// the css class for selected <td> element 
		
		// setting for Events
		//fireRenderOver: true,
		//renderOver: null, 
		
	},
	
	initialize: function(container, options){		
					
		this.setOptions(options);		
		this.container = $(container);
		if(!this.container.hasClass(this.options.cssStyle)) this.container.addClass(this.options.tableClass);

		if (!this.container)
			return;
	
		// the MooTools Date instance
		this.date = new Date();
				
		this.htmlTable=null;
		this.draw();		
		//this.loadData();
	},
	
	/*
	Draw the layout of the table, such as table headers. 
	*/
	draw: function(){		
		this.htmlTable = new HtmlTable();
		
		// add caption for the table
		this.setCaption();
		
		// set the table headers 
		this.setHeader();

		// set the days of this month
		this.setDays();
		
		this.htmlTable.inject(this.container,'top');

	},
	
	/*
	Add the year and moth information to the calendar table.
	*/
	setCaption: function(){
		var caption = new Element('caption');
		
		caption.adopt(
			new Element('a', {'class': this.options.nextClass, html: '<<'}), 
			new Element('span', {html: this.date.format(Date.shortDate).split(' ')[0]}), 
			new Element('a', {'class': this.options.prevClass, html: '>>'}) 
		);
		this.htmlTable.grab(caption);
	},
	
	/*
	Set the date header of the calendar table.
	*/
	setHeader: function(){
		this.htmlTable.setHeaders(MooTools.lang.get('Date').days);
	},

	/*
	Set the days of current month to the calendar table.
	*/
	setDays: function(){
		var isLastDay=true,
		    date= this.date.clone();

		date.decrement('day', this.date.get('Date')-1);
		var startWeekDay=date.get('day'), 
		    startWeek = date.get('week'),
		    endDay= date.getLastDayOfMonth();

		while(isLastDay){
			var tr = [];

			if(date.get('week') == startWeek){
				date = date.decrement('day', startWeekDay);
				for(i=0;i<=6;i++){
					if(i < startWeekDay){
						tr.push({'content': date.get('date'), properties:{'class':this.options.outOfMonthClass}});
					}
					else{tr.push(date.get('date'));};
					
					date.increment('day',1);
				}
			}
			else{
				var endMonth = false;
				for(i=0;i<=6;i++){
					if(date.get('date') == endDay) endMonth = true;

					if(!endMonth || date.get('date') == endDay){
						tr.push(date.get('date'));
					}
					else{
						tr.push({'content': date.get('date'), properties:{'class':this.options.outOfMonthClass}});
					};

					if(date.get('date')==endDay) {isLastDay=false;}
					date.increment('day',1);
				};
			};
		
	
			this.htmlTable.push(tr);

		};
		
	}
	
});
