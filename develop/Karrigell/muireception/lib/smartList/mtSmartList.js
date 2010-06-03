// Author: Broader ZHONG 
// Web: http://github.com/broader/EasyReception
// Email: broader.zhong@yahoo.com.cn
// Company: 
// Licence: Creative Commons Attribution 3.0 Unported License, http://creativecommons.org/licenses/by/3.0/
//	If you copy, distribute or transmit the source code please retain the above copyright notice, author name and project URL. 
// Required: Mootools 1.2 or newer 
// ****************************************************************************

var SmartList = new Class({
	version: '0.1',
	
	Implements: [Events,Options],

	Binds: ['reset', 'onPageDrag'],
				  
	options: {
		container: null,	// the container for this widget
		dataUrl: null,		// the data url for the li elements shown in this widget
		liRender: null,		// the render function for each li element
		
		contentClass: 'mtSmartListContent',	// the css class for li content

		// filter options
		filterBoxPosition: 'top',	// the position of filter box which holds a input element and a slider for pagination
		filterField: 'search',	// the filed name of filter value that will be send to server side 
		filterBnLabel: 'filter',	// the label for the filter button
		
		// paginator options
		itemsPerPage: 3,	// the number of showing items in one page
		paginatorPosition: 'top',	// the position of the paginator on widget container

		// slider options
		sliderClass: 'mtSmartListSlider',
		knobClass: 'mtSmartListKnob',
		pageInfoTmpls: {
			'total': 'Total {total} items', 
			'page': "Page <span class='{pageInfoClass}'>{currentPage}</span> of {pageNumber}"
		},
		pageInfoClass: 'currentPage'

	},
	
	initialize: function(container, options){		
		this.setOptions(options);	
		// pagination data
		this.pageData = $H({total: null, currentPage: 1, data: [], itemsPerPage: this.options.itemsPerPage});
		this.urlQuery = {'currentPage':1};
		// load data first
		this.load();
		// widget layout initialization	
		this.container = $(container);

		// add filterBox element which hlods the filter and pagination elements
		filterBox = new Element('div');

		// add filter input element and button
		var input = new Element('input',{value:'test', style: 'width:120px;'});
		var button = new Element('button',{html: this.options.filterBnLabel});
		button.store('input', input);
		button.addEvent('click', function(e){
			new Event(e).stop();
			// add input value to url query object
			this.urlQuery[this.options.filterField] = e.target.retrieve('input').getProperty('value');
			this.reset();
		}.bind(this));

		var span = new Element('span');
		span.adopt(input, button);
		filterBox.grab(span);
		
		// add the container to hold a slider for pagination
		this.paginator = new Element('div', {style:'line-height: 23px; font-size: 12px;'});
		//filterBox.grab(this.paginator);
		
		// add the container to hold li elements
		this.content = new Element('div', {'class': this.options.contentClass});
		this.container.adopt(new Element('br'), this.content);

		// inject the filter box to the container
		this.paginator.inject(this.container, this.options.paginatorPosition);
		filterBox.inject(this.container, this.options.filterBoxPosition);

		this.setPaginator();	
		// At end, render lists to content
		this.renderContent();
	},
	
	// for page changing
	renderContent: function(){
		// clear content
		this.content.set('html', '');

		var data = this.pageData.data;
		if($type(data) != $type([])){
			alert('Please return array object');
			return;
		};
		data.each(function(item){
			this.content.grab(this.options.liRender(item));
		}.bind(this));
	},
	
	// constructs the paginator layout, including a slider and a page information elements
	setPaginator: function(){
		// clear the cotent in paginator first
		this.paginator.empty();
		if(!this.pageData.total){
			this.paginator.set('text', 'No page data load!');
			this.content.set('text', 'No data!');
			return;
		};
		var pageNumber = this.pageData.pageNumber.toInt();
		
		// add paging info element
		pageInfo = new Element('span', {style:'float:left; width:100%;'});
		pageInfo.set('text', this.options.pageInfoTmpls.total.substitute({'total': this.pageData.total}));
		this.paginator.grab(pageInfo);

		// add slider element for pagination
		var slider = new Element('div', {'class': this.options.sliderClass});
		var knob = new Element('div', {'class': this.options.knobClass});
		slider.grab(knob);
		this.paginator.grab(slider);
		
		var templ = this.options.pageInfoTmpls.page.substitute({
			pageInfoClass: this.options.pageInfoClass, 
			currentPage: 1, 
			pageNumber: this.pageData.pageNumber
		});
		slider.grab( new Element('span', {html: templ, style:'float:right;'}));
	
		var sliderInstance = new Slider(slider,knob, {
			steps: 20, range:[1, pageNumber], //wheel: true, 
			onChange: function(value){	// page dragging
				this.onPageDrag(value);
			}.bind(this)	
		});

	},
	
	setInfo: function(){
		
	},

	onPageDrag: function(value){
		//alert('page drag value is '+value);
		this.paginator.getElement('.'+this.options.pageInfoClass).set('text', value);
		/*
		// set page information first
		templ = this.options.pageInfo.substitute(
			{total: this.pageData.total, pageNumber: this.pageData.pageNumber, currentPage: value}
		);
		this.paginator.retrieve('pageInfo').set('html', templ);
		*/

		// refresh content
		this.urlQuery['currentPage'] = value;
		this.load();
		this.renderContent();
	},
	
	// for filter event
	reset: function(){
		//alert(this.urlQuery.search);
		this.urlQuery['currentPage'] = 1;
		this.load();	// load data
		this.setPaginator();	// reset paginator
		this.renderContent();	// refresh content
	},

	load: function(){
		var dataUrl = this.options.dataUrl;
		if(!dataUrl){
			alert('Please set data url link first!');
			return;
		};
		
		var lisData = null;	
		var request = new Request.JSON({			
			url: dataUrl,
			async: false,
			onSuccess: function(data){
				lisData= data;
			}
		});
		this.urlQuery['itemsPerPage'] = this.pageData['itemsPerPage'];
		//this.urlQuery['currentPage'] = this.pageData['currentPage'];
		request.get(this.urlQuery);
		if(!lisData){
			alert('No data returned from the data url!');
			return;
		}
		this.pageData.extend(lisData);
	}
					
});
