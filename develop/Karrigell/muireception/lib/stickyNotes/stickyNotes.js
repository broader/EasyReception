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
		noteClass: "note", 		// the css class for the note
		handleClass: "handle", 		// the css class for the note
		needleClass: "needle", 		// the css class for the note
		closeBnClass: "closeNote", 	// the css class for the note
		layout: "cascade",		// the style for the layout of the sticky notes in the container
		indexLevel: 10000,		// the default z-index level value
		notesData: null		// the data holding the content for each note
	},
	
	initialize: function(options){	
		this.setOptions(options);
		this.layout = this.options.layout;
		var self = this;
		
		self.addNotes(self.options.notesData || []);		

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
		var el = new Element('div',{'class':'note','style':'margin-top:2em;margin-left:2em;'});

		// add title bar
		var titleDiv = new Element('div',{'class':'handle'});
				
		var closeBn = new Element('div', {'class':'closeNote'});
		closeBn.addEvent('click', function(e){
			new Event(e).stop();
			el.dispose();
			self.resetLayout(self.layout);
		});
		titleDiv.adopt( new Element('div', {'class':'needle'}),closeBn);
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
			//droppables: self.options.dropElements,
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

	// cascade notes
	cascade: function(xOffset, yOffset){
		xOffset = xOffset || 40;
		yOffset = yOffset || 40;
		var self = this,
		    containerTopOffset = 0, containerLeftOffset = 0;

		self.layout="cascade";
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
		centerX = centerX || 320;
		centerY = centerY || 270;
		radius = radius || 200;

		var self = this,
		    elements = self.getNotes(),
		    i = 1, sides = elements.length;

		self.layout="circle";

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
		columns = columns || 4;
		xOffset = xOffset || 180;
		yOffset = yOffset || 100;
		var self = this, 
		    containerTopOffset = 120,
		    containerLeftOffset = 150;
		var i = 1;
		self.getNotes().each(function(el){
			self.options.indexLevel++;
			el.setStyle('z-index', self.options.indexLevel);
			if(i>1 && i<= columns){
				containerLeftOffset += xOffset;
			}
			else if (i>1){
				containerLeftOffset = 150;
				containerTopOffset += yOffset;
				i = 1;
			}
			
			var notesMorph = new Fx.Morph(el, {
				'duration': 400
			});
			notesMorph.start({
				'top': containerTopOffset,
				'left': containerLeftOffset,
			});
			i++;
		});
	},

	// reset the layout of the sticky notes
	resetLayout: function(layouType){
		this.layout = layouType;
		if($defined(this[layouType])) this[layouType]();
	},
	
	// add a note
	addOne: function(title,content){
		
			
	}

});
