/*
---
description:     
  - InlineEditElement is a MooTools style class to give a Element the capability to edit it's content inlinly.
  - this plugin is inspired by the article (http://davidwalsh.name/editable-content-mootools-php-mysql), which is on the blog of David Walsh.
authors:
  - Broader ZHONG (http://broader.github.com)

version:
  - 0.1

license:
  - MIT-style license

requires:
  core/1.2.1:   '*'
...
*/
var InlineEditElement = new Class({
	Implements: [Options], 
	
	options: {
		'triggerEventName': null,	// the name for Event that trigger the inline edit action
		'emptyClass': '',		// if nothing input, special css to show it

		'waitEditResult': true,		// is it need to wait the editting result from server side?
		'responseTag': null,		// the response field name according which we judge the edit action is successful
		'responseSuccessTag': null,	// the successful tag 	

		'inpuType': null,		// the type for the input Element
		'editUrl': null, 		// the url for the Request to server side to really acomplish the inline edit action 
		'editFieldName': null		// the filed name for the Element to be edit, which will be send to server side
	},

	/*
	Paramerters:
	element - the id or a element instance in document body, which will be inline edit
	options - initalization options
	*/
	initialize: function( element, options) {
		// add closure variable to 'this'
		var self = this;

		this.input = null;
		this.element = $(element);
		if(!this.element) return;
		
		this.element.addEvent(triggerEventName,	function(e){
			new Event(e).stop();
			self.setInput();
		});
		
	},

	setInput: function(){
		// get old value in the Element
		var oldValue = this.element.get('html').trim();

		// errase current
		this.element.set('html','');

		// inject new input Element to this.element body
		switch(this.options.inputType){
			case 'input':
				this.input = new Element('input', {'class': 'box', 'text': oldValue});
				// blur input when key 'Enter' is pressed
				this.input.addEvent('keydown',function(e){
					if(e.key == 'enter') this.fireEvent('blur');
				});
				break;
			case 'textarea':
				this.input = new Element('textarea', {'class': 'box', 'text': oldValue});
				break;
			default:
				// inject input to this.element
				this.input.inject(this.element).select();
				
				// add 'blur' event to input
				this.input.addEvent('blur',function(e){
					// get input value and set it to this.element
					var newValue = this.input.get('value').trim();
					this.element.set('text',newValue).addClass(newValue==''?'':this.options.emptyClass);
				}.bind(this));
				break;

		};	
	}

});

	
	
