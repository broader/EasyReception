// Author: Broader ZHONG 
// Web: http://github.com/broader/EasyReception
// Email: broader.zhong@yahoo.com.cn
// Company: 
// Licence: Creative Commons Attribution 3.0 Unported License, http://creativecommons.org/licenses/by/3.0/
//			If you copy, distribute or transmit the source code please retain the above copyright notice, author name and project URL. 
// Required: Mootools 1.2 or newer 
// Version: treeTable 0.1 
// ****************************************************************************

var TreeTable = new Class({
	Implements: [Events,Options],
				  
	getOptions: function(){
		return {
			columnsModle: null,	
			cssStyle: 'treeTable',
			dataUrl: null,
			showHeader:true,
			sortHeader:false,
			resizeColumns:true,
			selectable:true,
			serverSort:true,
			sortOn: null,
			sortBy: 'ASC',
			filterHide: true,
			filterHideCls: 'hide',
			filterSelectedCls: 'filter',
			multipleSelection:true,
			// accordion
			accordion:false,
			accordionRenderer:null,
			autoSectionToggle:true, // if true just one section can be open/visible
			// pagination
			url:null,
			pagination:false,
			page:1,
			perPageOptions: [10, 20, 50, 100, 200],
			perPage:10
		};
	},
	
	initialize: function(container, options){				
		this.setOptions(this.getOptions(), options);
		this.container = $(container);
		this.tableInstance = null;
		this.colsModel = this.options['columnsModel'];
		
		if (!this.container)
			return;
			
		this.draw();
		this.loadData();
		
		//this.reset();
		
		//this.loadData();
	},
	
	// ************************************************************************
	// ************************* Main draw function ***************************
	// ************************************************************************
	draw: function(){		
		this.tableInstance = new HtmlTable();
		
		// set table css style 
		this.tableInstance.toElement().addClass(this.options['cssStyle']);
		
		this.setHeaders();
		
		this.tableInstance.inject(this.container);

	},
	
	// set the css style for the header of tree table 
	setHeaders: function(){
				
		if(!this.colsModel)
			return
		
		var data = [];
		this.colsModel.each(function(column){
			var col = {'content':column['label']};
			if(column['label'])
				col['property'] = column['property'];
				
			data.push(col);
		});
		
		this.tableInstance.setHeaders(data);
	},
	
	// load rows' data to table body 
	loadData: function(){
		url = this.options['dataUrl'];
		if(!url)
			return;
			
		var request = new Request.JSON({url:url});

		request.addEvent("complete", this.onLoadData.bind(this) ) ;

		request.send();
	},
	
	// load data successfully event handler
	onLoadData: function(data){
		this.setData(data);
	},
	
	// render data to each row 
	setData: function(rows){
		/*
		rows = [
			['apple', 'red'],
		   ['lemon', 'yellow']
		];
		
		rows.each(
			function(row){
				this.tableInstance.push(row);
			},
			this
		);	
		*/	
		
		rows.each(
			function(row){
				this.tableInstance.push(row);
			},
			this
		);
				
	}
	
});


/*************************************************************/