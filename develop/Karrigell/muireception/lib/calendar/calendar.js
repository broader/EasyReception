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
		cssStyle: 'calendarTable',
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
		if (!this.container)
			return;
		
		//this.colsModel = this.options.columnsModel;
		//this.treeColumn = this.options.treeColumn;
		//this.fireRenderOver = this.options.fireRenderOver; 
		
		this.htmlTable=null;
		this.draw();		
		//this.loadData();
	},
	
	/*
	Draw the layout of the table, such as table headers. 
	*/
	draw: function(){		
		this.htmlTable = new HtmlTable();
		
		// set table css style 
		this.htmlTable.element.addClass(this.options.cssStyle);
		
		// add caption for the table
		this.setCaption();
		
		// set the table headers 
		this.setHeader();
		
		this.htmlTable.inject(this.container,'top');

	},
	
	/*
	Add the year and moth information to the calendar table.
	*/
	setCaption: function(){
		var caption = new Element('caption');
		caption.grab( new Element('span', {html: 'China'}));
		this.htmlTable.grab(caption);
	},
	
	/*
	Set the header of the calendar table.
	*/
	setHeader: function(){
	}
	
});
