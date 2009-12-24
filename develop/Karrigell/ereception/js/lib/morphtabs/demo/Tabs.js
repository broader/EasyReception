
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
