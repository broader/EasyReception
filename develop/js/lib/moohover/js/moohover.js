/**
 * MooHover - Anchor and form input modification
 *
 * @version		1.0.1
 *
 * @license		MIT-style license
 * @author		Constantin Boiangiu <constantin [at] php-help.ro>
 * @copyright	Author
 */

var MooHover = new Class({
	Implements: [Options],
	options: {
		container: null,
		className: 'MooTrans',
		defaultClass: 'default',
		duration: 400,
		transition: Fx.Transitions.Sine.easeOut		
	},

	initialize: function(options) {
		this.setOptions(options);
		this.container = $(this.options.container) || document;
		this.start();		
	},
	
	start: function(){
		var buttons = this.container.
					  getElements('.'+this.options.className).
					  filter(function(elem,i){
							if(elem.rel!=='selected')
								return elem;							
					   }.bind(this));
		
		buttons.each(function(element,i){
			element.setStyles({'opacity':0.001,'position':'absolute','top':0,'left':0});
			
			new Element('div',{
				'class':this.options.defaultClass,
				'text':element.get('text')||element.get('value')
			}).injectBefore(element).adopt(element);
			
			var transEffect = new Fx.Morph(element, {duration: this.options.duration, transition: this.options.transition});
			
			element.addEvents({
				'mouseover':function(){
					transEffect.cancel();
					transEffect.start({opacity:1});
				},
				'mouseout':function(){
					transEffect.cancel();
					transEffect.start({opacity:0.001});
				}
			})			
		}.bind(this));
	}
});