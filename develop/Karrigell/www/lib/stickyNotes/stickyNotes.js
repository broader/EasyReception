/*******************************************************************************************************************************
Author: Broader ZHONG 
Web: http://github.com/broader/EasyReception
Email: broader.zhong@yahoo.com.cn
Company: 
Licence: Creative Commons Attribution 3.0 Unported License, http://creativecommons.org/licenses/by/3.0/
If you copy, distribute or transmit the source code please retain the above copyright notice, author name and project URL. 
Required: Mootools 1.2 or newer 
*******************************************************************************************************************************/

var StickyNotes = new Class({
	version: '0.1',
	
	Implements: [Events,Options],
				  
	options: {
		dropElements: null,	// the elements where the dragged elements could be dropped	
		container: null,	// the container for the sticky notes
		noteClass: "stickyNote", 		// the css class for the note
		handleClass: "handle", 		// the css class for the note
		needleClass: "needle", 		// the css class for the note
		closeBnClass: "closeNote", 	// the css class for the note

		// the default setting for different styles' layout of the sticky notes in the container
		layout: {
			"default":"grid", 
			"grid":{"columns":4, "xOffset":180, "yOffset": 100, "containerTopOffset": 120, "containerLeftOffset": 150},
			"circle":{"centerX":320, "centerY": 270, "radius": 200},
			"cascade":{"xOffset":40, "yOffset": 40, "containerTopOffset": 10, "containerLeftOffset": 10}
		},
		
		indexLevel: 1000,		// the default z-index level value
		notesData: null,		// the data holding the content for each note
		notesDataUrl: null		// the url which will return a json object as notesData
	},
	
	initialize: function(options){	
		this.setOptions(options);
		this.layout = this.options.layout.default;
		var self = this;
		var data = null;
		if(self.options.notesDataUrl){
			new Request.JSON({
				url:self.options.notesDataUrl, 
				async: false, 
				onSuccess: function(json){
					data = json;
				}
			}).get();
		}
		else{
			data = self.options.notesData || [];
		};
		
		self.addNotes(data);		

	},
	
	/*
	 add notes
	 @para data, a json object which format is [{'title':..., 'content':...},...]
	*/
	addNotes: function(data){
		var self = this;
		
		$(self.options.container).adopt(
			data.map(self.addNote.bind(self))
		);
		self[self.layout]();	
	},
	
	// initialize the layout of one note
	addNote: function(item){
		var self = this;
		var el = new Element('div',{'class':self.options.noteClass});
		
		// add title bar
		var titleDiv = new Element('div',{'class': self.options.handleClass});
				
		var closeBn = new Element('div', {'class':self.options.closeBnClass});
		// add the callback function to the close button
		closeBn.addEvent('click', function(e){
			new Event(e).stop();
			el.dispose();
			self.resetLayout(self.layout);
		});
		titleDiv.adopt( new Element('div', {'class':self.options.needleClass}),closeBn);
		el.adopt(titleDiv);

		// add content to the note
		el.adopt(
			new Element('h3', {html: item.title}), 
			new Element('p', {html: item.content})
		);
		
		el.addEvent('click', function(e){
			self.options.indexLevel++;
			e.target.setStyle('z-index', self.options.indexLevel);
		});

		var draggableOptions = {
			droppables: self.options.dropElements,
			container: $(self.options.container),
			onStart: function(el,dr){
				self.options.indexLevel++;
				el.setStyle('z-index', self.options.indexLevel);
				el.setStyle('opacity', '0.5');
			},
			
			onComplete: function(el, dr){
				el.setStyle('opacity', '1');
			},
			onDrop: function(el, dr){
				if(!dr) return;
				dr.highlight('#667CA4');
				
			},
			onEnter: function(el, dr){
				if(!dr) return;
				dr.highlight('#FB911C');

			},
			onLeave: function(el,dr){
				if(!dr) return;
				dr.highlight('#FB911C');
			}
		};
		el.makeDraggable(draggableOptions);

		var rotate = new Fx.Rotate(el);
		rotate.start(0, -0.00019);
		
		return el
	},

	// get all the notes elements
	getNotes: function(){
		return $$('.'+this.options.noteClass)
	},

	// delete all the notes
	closeAll: function(){
		this.getNotes().each(function(item){
			item.dispose();
		});
	},

	// cascade layout 
	cascade: function(xOffset, yOffset){
		var self = this;
		xOffset = xOffset || this.options.layout.cascade.xOffset ;
		yOffset = yOffset || this.options.layout.cascade.yOffset ;
		var containerTopOffset = self.options.layout.cascade.containerTopOffset,
		    containerLeftOffset = self.options.layout.cascade.containerLeftOffset;

		self.layout = "cascade";
		self.getNotes().each(function(el){
			self.options.indexLevel++;
			el.setStyle('z-index', self.options.indexLevel);
			containerTopOffset += yOffset;
			containerLeftOffset += xOffset;
			var noteMorph = new Fx.Morph(el, {
				'duration': 400
			});
			noteMorph.start({
				'top': containerTopOffset,
				'left': containerLeftOffset
			});
		});
	},
	
	// circle layout
	circle: function(centerX, centerY, radius){
		var self = this;	
		centerX = centerX || this.options.layout.circle.centerX ;
		centerY = centerY || this.options.layout.circle.centerY ;
		radius = radius || this.options.layout.circle.radius;

		var elements = self.getNotes(),
		    i = 1, sides = elements.length;

		self.layout = "circle";

		elements.each(function(el){
			self.options.indexLevel++;
			el.setStyle('z-index', self.options.indexLevel);
			var pointRatio = i/sides;
			var xSteps = Math.cos(pointRatio*2*Math.PI);
			var ySteps = Math.sin(pointRatio*2*Math.PI);
			var pointX = centerX + xSteps * radius;
			var pointY = centerY + ySteps * radius;
			var notesMorph = new Fx.Morph(el,{'duration':400});
			notesMorph.start({ 'top': pointY, 'left': pointX});
			i++;
		});
	},
	
	// grid layout
	grid: function(columns, xOffset, yOffset){
		var self = this;
		columns = columns || self.options.layout.grid.columns;
		xOffset = xOffset || self.options.layout.grid.xOffset ;
		yOffset = yOffset || self.options.layout.grid.yOffset;
		    
		var containerTopOffset = self.options.layout.grid.containerTopOffset,
		    containerLeftOffset = self.options.layout.grid.containerLeftOffset,
		    i = 1;
		
		self.layout = "grid" ;	
		self.getNotes().each(function(el){
			self.options.indexLevel++;
			el.setStyle('z-index', self.options.indexLevel);
			if(i>1 && i<= columns){	containerLeftOffset += xOffset;	}
			else if (i>1){
				containerLeftOffset = 150;
				containerTopOffset += yOffset;
				i = 1;
			}
			
			var notesMorph = new Fx.Morph(el, {'duration': 400});
			notesMorph.start({
				'top': containerTopOffset,
				'left': containerLeftOffset,
			});
			i++;
		});
	},

	// reset the layout of the sticky notes
	resetLayout: function(layouType){
		this.layout.default = layouType;
		if($defined(this[layouType])) this[layouType]();
	}
	
});
