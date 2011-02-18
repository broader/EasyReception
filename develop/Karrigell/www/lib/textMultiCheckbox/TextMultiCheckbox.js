/*
---
description:     
  - textMultiSelect is a MooTools plugin that turns your checkbox set into one single multi-select dropdown menu. MultiSelect is also completely CSS skinnable.
  - this plugin is inspired by another plugin "MultiSelect" whose author is Blaž Maležič (http://twitter.com/blazmalezic)
authors:
  - Broader ZHONG (http://broader.github.com)

version:
  - 0.1

license:
  - MIT-style license

requires:
  Mootools/core/1.2.1:   '*'
...
*/
var TextMultiCheckbox = new Class({
	
	Implements: [Options], 
	
	options: {
		data: null,			// initial options' data to construct each elements of this widget

		monitorText: ' selected',	// monitor text (localization)
		containerClass: 'TextMultiSelect', 	// element container CSS class
		monitorClass: 'monitor',	// monitor CSS class
		monitorActiveClass: 'active',	// monitor open CSS class
 
		// the suffix for the class of the element to show monitor text
		monitorTextClass: 'text',
		prompText: 'Please select...',	// the prompt in the monitor elemnent
		promptWrapper: 'span',
		promptClass: 'prompText',	// the css class for prompt text
		textSeperator: ',',		// the seperator of the showing text in monitor
		monitorFieldType: 'input',	// container holds the selected text

		menusContainer: 'ul',		// container hold menus
		boxWrapper: 'li',		// container for each text item
		box: 'span',			// the element hold the text to be selected
		boxStyle: 'padding-left:20px;',	// the css style for the text 
		itemSelectedClass: 'selected',	// list item selected CSS class
		
		// list item hover CSS class - usually we would use CSS :hover pseudo class, but we need this for keyboard navigation functionality
		itemHoverClass: 'hover'	
	}, 
	
	/*
	Paramerters:
	containerId - the id or a element instance in document body
	options - initalization options
	*/
	initialize: function(containerId, options) {
		// set options
		this.setOptions(options);
		
		// set global action variables
		this.active = false;
		
		this.monitorTextClass = [this.options.monitorClass, this.options.monitorTextClass].join('-');

		// if options.data is not null, render each elements of this widget
		if(this.options.data){ 
			this.render(containerId);
		}
		else{
			// add css style to this widget container
			this.container = $(containerId);
			this.container.addClass(this.options.containerClass);

		};

		// add event handler to monitor element
		if(!$defined(this.monitor)){
			this.monitor = this.container.getElement('.'+this.options.monitorClass);
		};	
		this.monitor.addEvent('click', function(e){
			new Event(e).stop();
			this.menusShowToggle();
		}.bind(this));
		
		if(!$defined(this.monitorTextElement)){
			this.monitorTextElement = this.monitor.getElement('.'+this.monitorTextClass);
		};
		
		// render new prompt Element
		this.prompt = new Element(
			this.options.promptWrapper,
			{'html': this.options.prompText, 'class': this.options.promptClass}
		);

		if(this.monitorTextElement.get('text') == '') {
			this.monitorTextElement.grab(this.prompt);};

		if(!$defined(this.formField)){
			this.formField = this.monitor.getElement(this.options.monitorFieldType);
		};
	
		// add css style to menus' container
		if(!$defined(this.menusContainer)){
			this.menusContainer = this.container.getElement(this.options.menusContainer);
		};
		this.menusContainer.setStyle('display','none');

		this.initSelectMenu();

	},

	/*
	render each element of this widget
	*/
	render: function(containerId){
		// widget container
		this.container = new Element('div', {
			'id':containerId, 
			'class':this.options.containerClass}
		);

		// add monitor elements
		// a wrapper for monitor Element that makes its looking nicely
		var monitorWrapper = new Element('div', {'class':this.options.monitorClass});

		this.monitor = new Element('div');
		this.monitorTextElement = new Element('div', {'class':this.monitorTextClass});
 		this.formField = new Element(this.options.monitorFieldType, {'name': containerId,'type':'hidden'});
		this.monitor.adopt([this.monitorTextElement,this.formField]);
		monitorWrapper.adopt(this.monitor);

		// add multiselect menus
		this.menusContainer = new Element(this.options.menusContainer);
		this.options.data.each(function(option){
			var text = new Element('span',{html:option});
			var li = new Element('li');
			li.grab(text);
			this.menusContainer.adopt(li);
		}.bind(this));

		this.container.adopt([monitorWrapper,this.menusContainer]);
	},

	/*
	*/
	initSelectMenu: function(){
		// var element = this.container;
		
		// create 'self' variable point to 'this' TextMultiSelect instance
		var self = this;
		document.addEvents({
			//'mouseup': function() { self.active = false; },
			'click': function() {
				if (self.active) {
					self.menusShowToggle();
				}
			},
			'keydown': function(e) {
				if (e.key == 'esc') {
					self.menusShowToggle();					
				}
			}
		});

		self.menusContainer.addEvents({
			'mouseenter': function() { self.action = 'open'; }, 
			'mouseleave': function() { 
				self.action = 'close';
			}
		});
		
		
		self.menusContainer.getElements(self.options.boxWrapper)
		.each(function(boxWrapper){
			boxWrapper.addEvent('click',function(e){
				new Event(e).stop();
				var toSet = (e.target.get('tag') == self.options.box) ? e.target.getParent(self.options.boxWrapper): e.target
				self.itemStatusToggle(toSet);
			});
			
			var el = boxWrapper.getElement(self.options.box);
			el.setProperty('style', self.options.boxStyle);
		
			var text = el.get('html');
		});
	
	},

	menusShowToggle: function(){
		if(this.active){
			this.active = false;
			this.menusContainer.setStyle('display','none');
		}
		else{
			this.active = true;
			this.menusContainer.setStyle('display','block');	

		};
	},
	
	itemStatusToggle: function(el){
		el.toggleClass(this.options.itemSelectedClass);	
		// get text in action target element
		var text = el.getElement(this.options.box).get('html');
		var oldText = this.getMonitorText();
		var newText = '';

		// judge action type- 'select' or 'unselect'
		if(el.hasClass(this.options.itemSelectedClass)){
			// 'select' action
			if(!oldText) {newText=text;}
			else if(!oldText.contains(text,this.options.textSeperator)){
				newText = oldText.split(this.options.textSeperator).include(text).join(this.options.textSeperator);
			};
			if(newText) this.setMonitorText(newText);						
		}
		else{
			// 'unselect' action
			if(oldText.contains(text,this.options.textSeperator)){
				newText = oldText.split(this.options.textSeperator).erase(text).join(this.options.textSeperator);
				this.setMonitorText(newText);
			};
			
		};
	},
	
	getMonitorText: function(){
		if(this.monitorTextElement.hasChild(this.prompt)) this.prompt=this.prompt.dispose();
		return this.monitorTextElement.get('text').trim()
	},
	
	setMonitorText: function(text){
		// change the text in monitor, including shown text and hidden 'input'
		this.monitorTextElement.set('html',text);
		if(!text) this.prompt.inject(this.monitorTextElement,'top');
		this.formField.setProperty('value',text);
	}

});
	
