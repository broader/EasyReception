
Fx.MorphElement = new Class({
	
	Extends: Fx.Morph,
	
	options: {
		wrap: true,
		wrapClass: 'morphElementWrap',
		FxTransition : $empty,
		hideOnInitialize: true
	},
	
	initialize: function(el, options) {
		this.setOptions(options);
		this.parent(el, options);
		
		if (this.options.wrap) this.setup();
		
		if (this.options.hideOnInitialize) {
			this.element.store('fxEffect:flag', 'hide');
			this.getFx('fade');
		}
	},
	
	setup: function() {
		var wrap = new Element('div', {
			'id': this.element.get('id') + '_wrap',
			'class': this.options.wrapClass,
			'styles': {
				'height': this.options.height,
				'width': this.options.width,
				'overflow': 'hidden'
			}
		}).wraps(this.element);
	},
	
	getFx: function(fx) {
		
		var flag = this.element.retrieve('fxEffect:flag', 'show');
		
		var styles = {
			'margin-top': [0, 0],
			'margin-left': [0, 0],
			'width': [this.options.width, this.options.width],
			'height': [this.options.height, this.options.height],
			'opacity': [1, 1]
		};
		
		fxEffect = this.element.get('morph', this.options.FxTransition);
		
		fx = fx.split(':');
		
		if (fx.length > 1) {
			fx = Fx.MorphElement.Effects[fx[0]][fx[1]][flag];
		} else {
			fx = Fx.MorphElement.Effects[fx[0]][flag];
		}
		
		$H(fx).each(function(hash, hashIndex){
			hash.each(function(item, index){
				if ($type(item) == 'string') {
					hash[index] = item.substitute({'width': this.options.width, 'height': this.options.height});
				}
			}.bind(this));
			styles[hashIndex] = hash
		}.bind(this));
		
		styles = fxEffect.start(styles);
		
		this.element.store('fxEffect:flag', (flag == 'hide') ? 'show' : 'hide');
		
		return styles;
	}
});

Element.Properties.morphElement = {

	set: function(options){
		var morphElement = this.retrieve('morphElement');
		if (morphElement) morphElement.cancel();
		return this.eliminate('morphElement').store('morphElement:options', $extend({link: 'cancel'}, options));
	},

	get: function(options){
		if (options || !this.retrieve('morphElement')){
			if (options || !this.retrieve('morphElement:options')) this.set('morphElement', options);
			this.store('morphElement', new Fx.MorphElement(this, this.retrieve('morphElement:options')));
		}
		return this.retrieve('morphElement');
	}

};

Element.implement({

	morphElement: function(props){
		this.get('morphElement').getFx(props);
		return this;
	}

});

Fx.MorphElement.Effects = $H({
	blind: {
		up: {
			hide: {
				'height': ['{height}', 0]
			},
			show: {
				'margin-top': ['{height}', 0],
				'height': [0, '{height}']
			}
		},
		down: {
			hide: {
				'margin-top': ['{height}'],
				'height': [0]
			},
			show: {
				'height': [0, '{height}']
			}
		},
		left: {
			hide: {
				'width': ['{width}', 0]
			},
			show: {
				'margin-left': ['{width}', 0],
				'width': [0, '{width}']
			}
		},
		right: {
			hide: {
				'margin-left': ['{width}'],
				'width': [0]
			},
			show: {
				'width': [0, '{width}']
			}
		}
	},
	slide: {
		up: {
			hide: {
				'margin-top': [0, '-{height}'],
				'width': ['{width}'],
				'height': ['{height}']
			},
			show: {
				'margin-top': ['{height}', 0]
			}
		},
		down: {
			hide: {
				'margin-top': [0, '{height}'],
				'width': ['{width}'],
				'height': ['{height}']
			},
			show: {
				'margin-top': ['-{height}', 0]
			}
		},
		left: {
			hide: {
				'margin-left': [0, '-{width}'],
				'width': ['{width}'],
				'height': ['{height}']
			},
			show: {
				'margin-left': ['{width}', 0]
			}
		},
		right: {
			hide: {
				'margin-left': [0, '{width}'],
				'width': ['{width}'],
				'height': ['{height}']
			},
			show: {
				'margin-left': ['-{width}', 0]
			}
		}
	},
	fade: {
		hide: {
			'opacity': [1, 0]
		},
		show: {
			'opacity': [0, 1]
		}
	}
});

var SlideShow = new Class({
	start: function() {
		this.slideShow = this.next.periodical(this.options.slideShowDelay * 1000, this);
	},
	stop: function() {
		this.clearChain();
		$clear(this.slideShow);
	}
});

var Tabs = new Class({
	Implements: [Options, Events, SlideShow],
	
	options: {
		tabs: '.morphtabs_title li',
		panels: '.morphtabs_panel',
		panelClass: 'morphtabs_panel',
		selectedClass: 'active',
		mouseOverClass: 'over',
		activateOnLoad: 'first',
		slideShow: false,
		slideShowDelay: 3,
		ajaxOptions: {},
		onShow: $empty
	},
	
	initialize: function(element, options) {
		
		this.setOptions(options);
		this.el = document.id(element);
		this.elid = element;
		 
		this.tabs = $$(this.options.tabs);
		
		this.panels = $$(this.options.panels);
		
		this.attach(this.tabs);
		
		if(this.options.activateOnLoad != 'none') {
			if(this.options.activateOnLoad == 'first') {
				this.activate(this.tabs[0]);
			} else {
				this.activate(this.options.activateOnLoad);
			}
		}
		
		if (this.options.slideShow) this.start();
	},
	
	attach: function(elements) {
		$$(elements).each(function(element) {
			var enter = element.retrieve('tab:enter', this.elementEnter.bindWithEvent(this, element));
			var leave = element.retrieve('tab:leave', this.elementLeave.bindWithEvent(this, element));
			var mouseclick = element.retrieve('tab:click', this.elementClick.bindWithEvent(this, element));
			element.addEvents({
				mouseenter: enter,
				mouseleave: leave,
				click: mouseclick
			});
		}, this);
		return this;
	},
	
	detach: function(elements) {
		$$(elements).each(function(element){
			element.removeEvent('mouseenter', element.retrieve('tab:enter') || $empty);
			element.removeEvent('mouseleave', element.retrieve('tab:leave') || $empty);
			element.removeEvent('mouseclick', element.retrieve('tab:click') || $empty);
			element.eliminate('tab:enter').eliminate('tab:leave').eliminate('tab:click');
			var newTab = element.getProperty('title');
			var panelDispose = this.panels.filter('[id='+newTab+']')[0].dispose();
			var elementDispose = element.dispose();
		});
		return this;
	},
	
	activate: function(tab) {
		tab = this.getTab(tab)
		if($type(tab) == 'element') {
			var newTab = this.showTab(tab);
			this.fireEvent('onShow', [newTab]);
		}
	},
	
	showTab: function(tab) {
		var newTab = tab.getProperty('title');
		this.panels.removeClass(this.options.selectedClass);
		this.activePanel = this.panels.filter('[id='+newTab+']')[0];
		this.activePanel.addClass(this.options.selectedClass);
		this.tabs.removeClass(this.options.selectedClass);
		tab.addClass(this.options.selectedClass);
		this.activeTitle = tab;
		if (tab.getElement('a')) this.getContent();
		return newTab;
	},
	
	getTab: function(tab) {
		if($type(tab) == 'string') {
			myTab = $$(this.options.tabs).filter('[title=' + tab + ']')[0];
			tab = myTab;
		}
		return tab;
	},
	
	getContent: function() {
		this.activePanel.set('load', this.options.ajaxOptions);
		this.activePanel.load(this.activeTitle.getElement('a').get('href'));
	},
	
	elementEnter: function(event, element) {
		if(element != this.activeTitle) {
			element.addClass(this.options.mouseOverClass);
		}
	},
 
	elementLeave: function(event, element) {
		if(element != this.activeTitle) {
			element.removeClass(this.options.mouseOverClass);
		}
	},
	
	elementClick: function(event, element) {
		event.stop();
		if(element != this.activeTitle) {
			element.removeClass(this.options.mouseOverClass);
			this.activate(element);
		}
		
		if (this.slideShow) {
			this.setOptions(this.slideShow, false);
			this.stop();
		}
	},
	
	addTab: function(title, label, content) {
		
		var newTitle = new Element('li', {
			'title': title,
			'html': label
		});
		
		this.tabs.include(newTitle);
		
		$$(this.options.tabs).getParent().adopt(newTitle);
		
		var newPanel = new Element('div', {
			'id': title,
			'class': this.options.panelClass,
			'html': content
		});
		
		this.panels.include(newPanel);
		this.el.adopt(newPanel);
		this.attach(newTitle);
		return newTitle;
	},
 
	removeTab: function(title){
		if (this.activeTitle.title == title) this.activate(this.tabs[0]);
		var tab = $$(this.options.tabs).filter('[title=' + title + ']')[0];
		this.detach(tab);
	},
	
	next: function() {
		var nextTab = this.activeTitle.getNext();
		if (!nextTab) nextTab = this.tabs[0];
		this.activate(nextTab);
	},
 
	previous: function() {
		var previousTab = this.activeTitle.getPrevious();
		if (!previousTab) previousTab = this.tabs[this.tabs.length - 1];
		this.activate(previousTab);
	}
	
});
var MorphTabs = new Class({	Extends: Tabs, 	options: {		panelWrapClass: 'morphtabs_panelwrap',		TransitionFx: {			transition: 'linear',			duration: 'long'		},		panelStartFx: 'blind:left',		panelEndFx: 'blind:right'	}, 	initialize: function(element, options) {				this.firstRun = true;				this.parent(element, options);				this.wrap = new Element('div', {			'id': element + '_panelwrap',			'class': this.options.panelWrapClass		}).inject(document.id(element));				this.addToWrap(this.tabs);			}, 	attach: function(elements) {		$$(elements).each(function(element) {			this.parent(element);			element.store('tab:effect', document.id(element.title).get('morphElement', {				wrap: false,				width: this.el.getWidth(),				height: document.id(element.title).getStyle('height'),				FxTransition: this.options.TransitionFx			}));		}, this);		return this;	},		addToWrap: function(elements) {		$$(elements).each(function(element){			this.wrap.adopt(document.id(element.title));		},this);	}, 	activate: function(tab) {				tab = this.getTab(tab);				if($type(tab) == 'element') {						// panel fx here..			switch (this.firstRun) {				case true:					var newTab = this.showTab(tab);					break;				default:					this.effect = this.activeTitle.retrieve('tab:effect');					this.activePanel.setStyle('overflow', 'hidden');					this.effect.getFx(this.options.panelStartFx).chain(						function() {							var newTab = this.showTab(tab);						}.bind(this)					);					break;			}						if (this.firstRun) this.firstRun = false;						this.fireEvent('onShow', [newTab]);		}			},		showTab: function(tab) {		var newTab = this.parent(tab);		this.activePanel.setStyle('overflow', 'hidden');		this.effect = tab.retrieve('tab:effect');		this.showTabFx();		return newTab;	},		showTabFx: function() {		this.effect.getFx(this.options.panelEndFx).chain(			function() {				this.activePanel.setStyle('overflow', 'auto');			}.bind(this)		);	},		changeFx: function(elements, fx) {		if (elements == 'all') elements = this.tabs;		fx = {FxTransition:fx};		$$(elements).each(function(el) {			var morphElement = document.id(el.title).retrieve('morphElement');			morphElement.setOptions(fx);			el.eliminate('tab:effect').store('tab:effect', morphElement);		}.bind(this));	}, 	elementClick: function(event, element) {		this.parent(event, element);		if (this.slideShow) this.activePanel.store('fxEffect:flag', 'show');	},		addTab: function(title, label, content) {		var newTitle = this.parent(title, label, content);		this.addToWrap(newTitle);	}});