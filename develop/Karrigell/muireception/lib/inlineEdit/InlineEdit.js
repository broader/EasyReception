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
		'triggerEventName': 'click',	// the name for Event that trigger the inline edit action
		'emptyClass': 'editable-empty',		// if nothing input, special css to show it

		'waitEditResult': true,		// is it need to wait the editting result from server side?
		'responseTag': 'ok',		// the response field name according which we judge the edit action is successful
		'responseSuccessTag': '1',	// the successful tag 	
		'errorHandler': null,		// the handle function when change content fail in server side

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
		// set options
		this.setOptions(options);
		
		// add closure variable to 'this'
		var self = this;

		self.input = null;
		self.element = $(element);
		if(!self.element) return;
		
		self.element.addEvent(self.options.triggerEventName, function(e){
			new Event(e).stop();
			self.setInput();
		});
		
	},
	
	
	setInput: function(){
		alert('setInput function');
		
		// add closure variable to 'this'
		var self = this;

		// get old value in the Element
		var oldValue = self.element.get('html').trim();

		// errase current
		self.element.set('html','');

		// clear old value in input of the instance
		if(self.input) {self.input.set('value','');}		
		else{
			alert('setInput, input type is '+self.options.inpuType);
			switch(self.options.inpuType){
				case 'input':
					self.input = new Element('input', {'class': 'box', 'text': oldValue});
					// blur input when key 'Enter' is pressed
					self.input.addEvent('keydown',function(e){
						if(e.key == 'enter') this.fireEvent('blur');
					});
					break;
				case 'textarea':
					self.input = new Element('textarea', {'class': 'box', 'text': oldValue});
					break;
				default:
					// add 'blur' event to input
					self.input.addEvent('blur',function(e){
						// self.submit();
					});
					break;
			};
		};

		// inject input Element to this.element body
		self.input.inject(self.element).select();
		
	}
	
	/*
	submit: function(){
		var data = {this.options.editFieldName: this.input.get('value').trim()};
		var options = {url: editUrl, method:'post'};
		
		if(this.options.waitEditResult){
			options['onComplete'] = function(json){
				if(json[this.options.responseTag]==this.options.responseSuccessTag){
					// change the content in this.element
					this.changeContent();
				}
				else{
					if(this.options.errorHandler) this.options.errorHandler();
				};
			};
			var request = new Request.JSON(options).get(data);
		}
		else{
			// send request
			var request = new Request.JSON(options).get(data);
			// change the content in this.element
			this.changeContent();
		};
	},

	changeContent: function(){
		// get input value and set it to this.element
		var newValue = this.get('value').trim();
		self.element.set('text',newValue).addClass(newValue==''? '' : self.options.emptyClass);
	}
	*/

});


	
	
