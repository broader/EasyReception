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
				  
	options: {
		container: null,	// the container for this widget
		dataUrl: null,		// the data url for the li elements shown in this widget
		filterBoxPosition: 'top',	// the position of filter box which holds a input element and a slider for pagination
		liRender: null,		// the render function for each li element
		
		// slider options
		sliderClass: 'mtSmartListSlider',
		knobClass: 'mtSmartListKnob',
	},
	
	initialize: function(container, options){		
					
		this.setOptions(options);		
		this.container = $(container);
		
		// add filterBox element
		this.filterBox = new Element('div');
		// add filter input element
		this.filterInput = new Element('input',{html:'test'});
		this.filterInput.addEvent('change', this.filter.bind(this));
	
		// add slider element for pagination
		var slider = new Element('div', {'class': this.options.sliderClass});
		var knob = new Element('div', {'class': this.options.knobClass});
		slider.grab(knob);
		this.slider = new Slider(slider,knob);
		// add filter input and slider to filterBox element
		this.filterBox.adopt(this.filterInput, this.slider);

		// add the container to hold li elements
		this.content = new Element('div');
		
		// pagination options
		this.pageData = { total: null, current: 1};
		this.load();
	},
	
	/*
	*/
	filter: function(event){
		new Event(event).stop();
		alert('serach text');
	},

	load: function(){
		alert('load data');
		dataUrl = this.options.dataUrl;
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
		request.get({'page':this.pageData.current});
		
		if(!lisData){
			alert('No data returned from the data url!');
			return;
		};
		
		this.refresh(data);
	},
	
	refresh: function(data){
		alert(data);
	}
});
