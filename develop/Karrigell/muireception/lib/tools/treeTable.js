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
			alternaterows: true,	
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
		this.table = null;
		
		if (!this.container)
			return;
			
		this.draw();
		
		//this.reset();
		
		//this.loadData();
	},
	
	// ************************************************************************
	// ************************* Main draw function ***************************
	// ************************************************************************
	draw: function(){
		options = {
			properties: this.options['properties'],
			headers: this.options['headers']			
		};
		
		this.table = new HtmlTable({
		    properties: {
		        border: 1,
		        cellspacing: 3
		    },
		    headers: ['fruits', 'colors']		    
		});
		
		this.table.inject(this.container);
		rows = [
			['apple', 'red'],
		   ['lemon', 'yellow']
		];
		
		rows.each(
			function(row){
				this.tables.push(row);
			},
			this
		);		

	}
	
});


/*************************************************************/