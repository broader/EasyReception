

/**************************************************************

	Script		: Rounded Corners
	Version		: 2.0
	Authors		: Samuel Birch
	Desc		: Image based rounded corners for divs and images
	Licence		: Open Source MIT Licence

**************************************************************/

var RoundedCorners = new Class({
							  
	getOptions: function(){
		return {
			radius: 20,
			cls: 'box',
			overlay: false
		};
	},

	initialize: function(className, options){
		this.setOptions(this.getOptions(), options);
		
		this.boxes = $$(className);
		
		this.boxes.each(function(el){
				this.setup(el);
		}, this);
		
	},
	
	setup: function(el){
		
		var container = new Element('div').setStyles({
			position: 'relative',
			width: el.getStyle('width').toInt()+el.getStyle('paddingLeft').toInt()+el.getStyle('paddingRight').toInt()+'px',
			height: el.getStyle('height').toInt()+el.getStyle('paddingTop').toInt()+el.getStyle('paddingBottom').toInt()+'px',
			margin: el.getStyle('margin')
		}).injectBefore(el).adopt(el);
		
		el.setStyles({
			position: 'absolute',
			top: '0px',
			left: '0px',
			margin: '0px',
			border: 'none',
			background: 'none',
			zIndex: 2
		});
		
		var cornerContainer = new Element('div').setStyles({
			position: 'absolute',
			top: '0px',
			left: '0px',
			zIndex: 1
		}).injectAfter(el);
		
		if(this.options.overlay){
			cornerContainer.setStyle('zIndex', 3);
		}
		
		var num = 0;
		
		//top
		var topLeft = new Element('div').addClass(this.options.cls+'TopLeft').addClass(this.options.cls+'Float').setStyles({
			width: this.options.radius+'px',
			height: this.options.radius+'px'
		}).injectInside(cornerContainer);
		
		var top = new Element('div').addClass(this.options.cls+'Top').addClass(this.options.cls+'Float').setStyles({
			width: container.getStyle('width').toInt()-(this.options.radius*2)+'px'
		}).injectInside(cornerContainer);
		top.setStyle('height', (this.options.radius-top.getStyle('borderTopWidth').toInt())+'px');
		
		var topRight = new Element('div').addClass(this.options.cls+'TopRight').addClass(this.options.cls+'Float').setStyles({
			width: this.options.radius+'px',
			height: this.options.radius+'px'
		}).injectInside(cornerContainer);
		
		//middle
		num = container.getStyle('height').toInt()-(this.options.radius*2);
		if(num < 0){num=0}
		
		var middleLeft = new Element('div').addClass(this.options.cls+'MiddleLeft').addClass(this.options.cls+'Float').setStyles({
			height: num+'px'
		}).injectInside(cornerContainer);
		middleLeft.setStyle('width', (this.options.radius-middleLeft.getStyle('borderLeftWidth').toInt())+'px');
		
		var middle = new Element('div').addClass(this.options.cls+'Middle').addClass(this.options.cls+'Float').setStyles({
			width: container.getStyle('width').toInt()-(this.options.radius*2)+'px',
			height: num+'px'
		}).injectInside(cornerContainer);
		
		var middleRight = new Element('div').addClass(this.options.cls+'MiddleRight').addClass(this.options.cls+'Float').setStyles({
			height: num+'px'
		}).injectInside(cornerContainer);
		middleRight.setStyle('width', (this.options.radius-middleRight.getStyle('borderRightWidth').toInt())+'px');
		
		//bottom
		var bottomLeft = new Element('div').addClass(this.options.cls+'BottomLeft').addClass(this.options.cls+'Float').setStyles({
			width: this.options.radius+'px',
			height: this.options.radius+'px'
		}).injectInside(cornerContainer);
		
		var bottom = new Element('div').addClass(this.options.cls+'Bottom').addClass(this.options.cls+'Float').setStyles({
			width: container.getStyle('width').toInt()-(this.options.radius*2)+'px'
		}).injectInside(cornerContainer);
		bottom.setStyle('height', (this.options.radius-bottom.getStyle('borderBottomWidth').toInt())+'px');
		
		var bottomRight = new Element('div').addClass(this.options.cls+'BottomRight').addClass(this.options.cls+'Float').setStyles({
			width: this.options.radius+'px',
			height: this.options.radius+'px'
		}).injectInside(cornerContainer);
		
	},
	
	resize: function(){
		
		this.boxes.each(function(el){
			var par = el.getParent();
			par.setStyle('height', el.getStyle('height').toInt()+el.getStyle('paddingTop').toInt()+el.getStyle('paddingBottom').toInt()+'px');
			
			var num = par.getStyle('height').toInt()-(this.options.radius*2);
			if(num < 0){num=0}
			
			var els = el.getNext().getElements('div');
			
			els[3].setStyle('height',num+'px');
			els[4].setStyle('height',num+'px');
			els[5].setStyle('height',num+'px');
		}, this);

	}

});

RoundedCorners.implement(new Events);
RoundedCorners.implement(new Options);

/*************************************************************/
