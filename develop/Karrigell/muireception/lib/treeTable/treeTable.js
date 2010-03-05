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
				  
	options: {
		columnsModel: null,	
		colsModelUrl: null,
		treeColumn: null,
		cssStyle: 'treeTable',
		dataUrl: null,
		data: null,
		
		// the properties need to show tree 
		parentPrefix: "parent-",
		depthPrefix: "depth-",
		depthPointer: 'expander',
		indent: 19,
		initialExpandedDepth: 1,
		initialState: "collapsed",
		expandedTag: "expanded",
		collapsedTag: "collapsed",
		
		// Events
		renderOver: null, 
		
	},
	
	initialize: function(container, options){					
		this.setOptions(options);		
		this.container = $(container);
		this.tableInstance = null;
		this.colsModel = this.options.columnsModel;
		this.hideColumns = [];
		
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
		this.tableInstance.element.addClass(this.options.cssStyle);
		
		this.setHeaders();
		
		this.tableInstance.inject(this.container,'top');

	},
	
	// get the index for the columns need to be hidden
	getHideColumns: function(){
		return this.colsModel.filter(function(column,index){
			return column.hide == '1'
		},this)
		.map(function(column,index){
			return index
		},this)
	},
	
	// set the css style for the header of tree table 
	setHeaders: function(){
		colsUrl = this.options.colsModelUrl; 
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
		else
			this.hideColumns = this.getHideColumns();
			
		var data = [];
		this.colsModel.each(function(column,index){
			var col = {'content':column.label,'properties':{}};
			
			if(column.property)
				col.properties = column.property;
			
			if(this.hideColumns.contains(index))
				col.properties['style'] = 'dipaly:none;';
				
			data.push(col);
		},this);
		
		this.tableInstance.setHeaders(data);
	},
	
	// load rows' data to table body 
	loadData: function(){
		rowUrl = this.options.dataUrl;
		if(!rowUrl)
			return;
			
		var request = new Request.JSON({			
			url: rowUrl,
			async: false,
			//onSuccess: function(data){this.setData(data);}.bind(this) 			
			onSuccess: function(data){
				this.options.data= data;
				this.setData();
				
			}.bind(this)
		});
		request.get();
	},
	
	// return the object which holds the data rendered in the table body 
	getData: function(){
		return this.options.data;
	},
	
	// render data to each row 
	setData: function(){
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
		var rows = this.options.data; 
		if(!rows)
			return;
		
		rows.each(this.setRowData,this);
		
		renderEnd = this.options.renderOver;		
		if(renderEnd){
			this.fireEvent('onRenderOver',renderEnd(this));
		};
							
	},
	
	// render data to each row
	setRowData: function(row){
		var data=row.data, depth=row.depth, rowId=row.id,
		parent=row.parent,								
		// empty column will be set to ''				
		interval = this.colsModel.length - data.length;				
		for (i=0;i<interval;i++){
			data.push('');
		};				
		
		// if hideColumn has value, hide td elements in these columns
		this.hideColumns.each(function(i){
			data[i] = {
				'content':data[i],
				'properties':{
					style: 'display:none;'
				}
			};
		});
		 
		var trRow = this.tableInstance.push(data);
		
		// add css class for tr element 
		var tr = trRow.tr;		
		tr.setProperties({'id': rowId});
		tr.addClass([this.options.parentPrefix,parent].join(''));
		tr.addClass([this.options.depthPrefix,depth].join(''));
		
		if(depth <= this.options.initialExpandedDepth)
			tr.addClass(this.options.expandedTag);
		else
			tr.addClass(this.options.collapsedTag);
		
		// set the td that holds collapsing status tag for tree 
		var treeColumn = this.options.treeColumn;		
		if($defined(treeColumn)){					
			// compute the left offset
			var offset= parseInt(this.options.indent)*(parseInt(depth)-1);
			var treeTag = new Element('span',{
				'class': this.options.depthPointer,
				'style': ['margin-left:',offset,'px',';'].join('')+'padding-right: 19px',
				'events': {
					'click': function(e){alert('tree tag clicked!');}
				}
			});			 
			//data[treeColumn] = {content: container.get('html')};
			treeTag.inject(trRow.tds[treeColumn],'top');
		};
	},	
	 
	// return all the tr elements in tbody 
	getTrs: function(){
		return this.tableInstance.element.getElements('tr').slice(1);
	}
	
	
});


/*************************************************************/