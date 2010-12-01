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
		lang: 'zh-CN',	// i18n 
		// table layout
		cssFile: null,	// the css file for this widget instance 
		containerClass: 'calendarTable',
		nextClass: 'next',
		prevClass: 'prev',
		outOfMonthClass: 'outOfMonth',
		selectedClass: 'selected'	// the css class for selected <td> element 
	},
	
	initialize: function(container, options){		
					
		this.setOptions(options);		
		
		// load css sytle
		if(this.options.cssFile) new Asset.css(this.options.cssFile);

		this.container = $(container);
		if(!this.container.hasClass(this.options.cssStyle)) this.container.addClass(this.options.containerClass);

		if (!this.container)
			return;
	
		// the MooTools Date instance
		this.selectDate = new Date();
		this.currentDate = this.selectDate.clone();
				
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
		this.setDays(this.firstDate(this.selectDate));
		
		this.htmlTable.inject(this.container,'top');

	},

	// calculate the first date for current this.selectDate
	firstDate: function(date){
		return date.clone().decrement('day', date.get('Date')-1);
	},
	
	/*
	Add the year and moth information to the calendar table.
	*/
	setCaption: function(){
		var caption = new Element('caption');
	
		var prevTag = new Element('a', {'class': this.options.nextClass, html: '<<'});
		prevTag.addEvent('click', function(e){
			date = this.currentDate.decrement('month', 1);
			this.setDays(this.firstDate(date));			
			this.refreshCaptionDate(date);
		}.bind(this));

		this.captionDate = new Element('span', {html: this.selectDate.format(Date.shortDate).split(' ')[0].slice(0,8)}); 
		
		var nexTag = new Element('a', {'class': this.options.prevClass, html: '>>'});
		nexTag.addEvent('click', function(e){
			date = this.currentDate.increment('month', 1);
			this.refreshCaptionDate(date);
			this.setDays(this.firstDate(date));			
		}.bind(this));

		caption.adopt( prevTag, this.captionDate, nexTag);
		this.htmlTable.grab(caption);
	},

	// refresh the date in the caption
	refreshCaptionDate: function(date){
		this.captionDate.set('html', date.format(Date.shortDate).split(' ')[0].slice(0,8));
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
	setDays: function(startDate){
		// clear the table's body first
		this.htmlTable.empty();

		var isLastDay=true;

		var startWeekDay = startDate.get('day'), 
		    endDay = startDate.getLastDayOfMonth(),
		    date = startDate.clone();
	
		// calculate whether the selected date in the same month with start date
		var selected = null;
		if( this.currentDate.format('%x') == this.selectDate.format('%x') ) selected = this.selectDate.get('date');
		
		while(isLastDay){
			var tr = [];
			
			if(date.get('date') <= startDate.clone().increment('day', 6-startDate.get('day')).get('date')){
				// decrement the date to the start date of this week which is not the date in this month
				date = date.decrement('day', startWeekDay);

				for(i=0;i<=6;i++){
					var number = date.get('date');
					if(i < startWeekDay){
						tr.push({'content': number, properties:{'class':this.options.outOfMonthClass}});
					}
					else{
						if( (!selected) || number != selected ){
							tr.push(number);
						}
						else{
							tr.push({'content': number, properties:{'class':this.options.selectedClass}});
						};
					};
					
					date.increment('day',1);
				}
			}
			else{
				var endMonth = false;
				for(i=0;i<=6;i++){
					var number = date.get('date');
					if(number == endDay) endMonth = true;

					if(!endMonth || number == endDay){
						if( (!selected) || number != selected ){
							tr.push(number);
						}
						else{
							tr.push({'content': number, properties:{'class':this.options.selectedClass}});
						};
					}
					else{
						tr.push({'content': number, properties:{'class':this.options.outOfMonthClass}});
					};

					if(number == endDay) {isLastDay=false;}
					date.increment('day',1);
				};
			};
		
	
			this.htmlTable.push(tr);

		};
		
		// add event to each td cell of this month
		this.htmlTable.element.getElements('tbody td[class!=outOfMonth]').map(function(td, index){
			td.addEvent('click', function(e){
				new Event(e).stop();
				alert('china');
			});
		});
		
	}
	
});
