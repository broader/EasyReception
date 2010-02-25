// Author: Broader ZHONG 
// Web: http://github.com/broader/EasyReception
// Email: broader.zhong@yahoo.com.cn
// Company: 
// Licence: Creative Commons Attribution 3.0 Unported License, http://creativecommons.org/licenses/by/3.0/
//			If you copy, distribute or transmit the source code please retain the above copyright notice, author name and project URL. 
// Required: Mootools 1.2 or newer 
// ****************************************************************************

var TreeTable = new Class({
	version: '0.1',
	
	Implements: [Events,Options],
				  
	getOptions: function(){
		return {
			columnsModle: null,	
			colsModelUrl: null,
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
		
		this.tableInstance.inject(this.container,'top');

	},
	
	// set the css style for the header of tree table 
	setHeaders: function(){
		colsUrl = this.options['colsModelUrl']; 
		if(colsUrl){			
			var request = new Request.JSON({
				url: colsUrl,
				async: false,
				onSuccess: function(cols){this.colsModel = cols;}.bind(this)
			});			
			request.get();		
		};
		
		if(!this.colsModel)
			return;
			
		var data = [];
		this.colsModel.each(function(column){
			var col = {'content':column['label']};
			
			if(column['property'])
				col['property'] = column['property'];
				
			data.push(col);
		});
		
		this.tableInstance.setHeaders(data);
	},
	
	// load rows' data to table body 
	loadData: function(){
		rowUrl = this.options['dataUrl'];
		if(!rowUrl)
			return;
			
		var request = new Request.JSON({
			url: rowUrl,
			onSuccess: function(data){this.setData(data);}.bind(this) 			
		});
		request.get();
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