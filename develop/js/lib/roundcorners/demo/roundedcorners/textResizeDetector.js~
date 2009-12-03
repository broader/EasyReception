

/**************************************************************

	Script		: Text Resize Detector
	Version		: 1.0
	Authors		: Samuel birch
	Desc		: Captures when the text is resized.
	Licence		: Open Source MIT Licence

**************************************************************/

var TextResizeDetector = new Class({
	getOptions: function(){
		return {
			delay: 200,
			onChange: Class.empty
		};
	},
	
	initialize: function(options){
		this.setOptions(this.getOptions(), options);
		
		this.element = new Element('span').setProperty('id','textResizeControl').setStyles({position: 'absolute', left: '-9999px'}).setHTML('&nbsp;').injectInside(document.body);
		this.oldSize = this.element.getStyle('height').toInt();
		this.start();
	},
	
	check: function(){
		if(this.oldSize != this.element.getStyle('height').toInt()){
			this.oldSize = this.element.getStyle('height').toInt();
			this.options.onChange();
		}
	},
	
	start: function(){
		this.timer = this.check.periodical(this.options.delay, this);
	},
	
	stop: function(){
		$clear(this.timer);
	}
});
TextResizeDetector.implement(new Events);
TextResizeDetector.implement(new Options);

/*************************************************************/
