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
		// table layout 
		columnsModel: null,	
		colsModelUrl: null,
		treeColumn: 0,
		cssStyle: 'treeTable',
		dataUrl: null,
		data: null,
		
		// settings for buttons in each row
		bnTag: 'button',
		bnFunctions: $H(), 
		
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
		this.treeColumn = this.options.treeColumn;
		this.hideColumns = [];
		
		if (!this.container)
			return;
			
		this.draw();
		
		this.loadData();
		
		//this.reset();
		
		//this.loadData();
	},
	
	/*
	Main draw function 
	*/
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
		.map(function(column){
			return this.colsModel.indexOf(column);
		},this)
	},
	
	// get the index for the column that show tree collapsed status tag 
	setTreeColumn: function(){
		columns = this.colsModel.filter(function(column,index){
			return column.treeColumn == '1'
		},this);
		
		if (columns.length > 0)
			this.treeColumn = this.colsModel.indexOf(columns[0]);	// the number of tree column should be only one 
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
			this.setTreeColumn();
		
		var data = [];
		this.colsModel.each(function(column,index){
			//alert(column.label);
			column.label = column.label || '/';
			var col = {'content':column['label'],'properties':{}};
			
			if(column.property)
				col.properties = column.property;
			
			if(this.hideColumns.contains(index))
				col.properties['style'] = 'display:none;';
				
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
		if(interval > 0 ){				
			for (i=0;i<interval;i++){
				data.push('');
			};
		};
						
		
		// each item in the columns of each row will be transformed to a 'span' Element 
		data = data.map(function(item,index){	
			// constructed the elemnt contained by td element first		
			
			// get current column model 
			var colModel = this.colsModel[index]  
			// judge whether it's a buttn type 
			isButton = (colModel.dataType == this.options.bnTag) ; 
			
			// set the elemnet to be inserted to the TD Element 
			el = {properties:{
				align: (index==this.treeColumn || !isButton )?'left':'center'
			}};
			
			if ( isButton ){				
				// For button, insert a <IMG> Element
				toInsert = new Element('img',{src: colModel.imgUrl});				  
				
				// maybe it has a callback function for click event
				if( this.options.bnFunctions.getKeys().contains[colModel.dataIndex]){ 
					fn = this.options.bnFunctions[colModel.dataIndex];
					toInsert.addEvent('click', fn.bind(this));
					
				};
				
				el.content = toInsert;
			}
			else{
				// for none button type, insert a <SPAN> Element 
				el.content = new Element('span',{html: item});				
			};
			
			/*
			el = {
				content: new Element('span',{html: item}),
				properties: {
					align: (index==this.treeColumn)?'left':'center'
				}
			};
			*/
			
			// hide td element has been set to hidden in this.colsModel 
			if(this.hideColumns.contains(index)){				
				el.properties.style = 'display:none;';
			};
			return el;
		},this);
		 
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
		var treeColumn = this.treeColumn;		
		if($defined(treeColumn)){					
			// compute the left offset
			var offset= parseInt(this.options.indent)*(parseInt(depth)-1);
			var treeTag = new Element('span',{
				'class': this.options.depthPointer,
				'style': ['margin-left:',offset,'px',';'].join('')+'padding-right: 19px',
				'events': {
					'click': function(e){alert('tree collaped action tag clicked!');}
				}
			});			 
			
			treeTag.inject(trRow.tds[treeColumn],'top');
		};
		
	},	
	
	/*
	Return the propnames for columns' headers
	*/
	getHeaderProps: function(){
		return this.colsModel.map(
			function(column){
				return column.dataIndex; 
			}
		);
	},
	
	/*
	Return each data item in eahc column of one row
	*/
	getRowData: function(rowEl){		
		return rowEl.getElements('td').map(function(td){			
			spans = td.getElements('span').filter(function(span){
				return !span.hasClass(this.options.depthPointer);
			}.bind(this));
			
			if(spans){				
				values = spans.map(function(i){
					return i.get('text');
				}).join('');
			}
			else{	values = ''; }
			
			return values;
				
		},this);
	},
	
	/* 
	Return a row of data with their column property name 
	Parameters:
		rowEl - HtmlTableRow Element 
	*/
	getRowDataWithProps: function(rowEl){
		// get the names of columns' properties
		props = this.getHeaderProps();
		
		// get each data item in eahc column of this row
		values = this.getRowData(rowEl);
		
		return $H(values.associate(props));
	},
	 
	// return all the tr elements in tbody 
	getTrs: function(){
		return this.tableInstance.element.getElements('tr').slice(1);
	}
	
	
});


/*************************************************************/