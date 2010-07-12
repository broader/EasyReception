/*
---
description: Simple overlay class for MooTools.

license: MIT-style

authors:
- Christopher Pitt

requires:
- core/1.2.4: Class.Extras
- core/1.2.4: Fx.Morph

provides: [Overlay]

...
*/

var Overlay = new Class({
    'Implements': [Options, Events],

    'options': {    
        /*
        'onLoad': $empty,
        'onPosition': $empty,
        'onShow': $empty,
        'onHide': $empty,
        'onClick': $empty,
        */        
        'color': '#000',
        'opacity': 0.7,
        'z-index': 1,
        'container': document.body,
        'duration': 100
    },
    
    'initialize': function(options)
    {
        this.setOptions(options);
        
        var self = this,
            container = document.id(self.options['container']),
            
            wrapper = new Element('div', {
                'styles': {
                    'position': 'absolute',
                    'left': 0,
                    'top': 0,
                    'visibility': 'hidden',
                    'overflow': 'hidden',
                    'z-index': self.options['z-index'] + 1
                },
                'events': {
                    'click': function(e)
                    {
                        self.fireEvent('onClick', [e]);
                    }
                }
            }).inject(container),
            
            iframe = new Element('iframe', {
                'src': 'about:blank',
                'frameborder': 1,
                'scrolling': 'no',
                'styles': {
                    'position': 'absolute',
                    'top': 0,
                    'left': 0,
                    'width': '100%',
                    'height': '100%',
                    'filter': 'progid:DXImageTransform.Microsoft.Alpha(style=0,opacity=0)',
                    'opacity': 0,
                    'z-index': self.options['z-index'] + 2
                }
            }).inject(wrapper),
            
            overlay = new Element('div', {
                'styles': {
                    'position': 'absolute',
                    'left': 0,
                    'top': 0,
                    'width': '100%',
                    'height': '100%',
                    'background-color': self.options['color'],
                    'z-index': self.options['z-index'] + 3
                }
            }).inject(wrapper),
            
            morph = new Fx.Morph(wrapper, {
                'duration': self.options['duration']
            });
            
        self.container = wrapper;
        self.wrapper = wrapper;
        self.iframe = iframe;
        self.overlay = overlay;
        self.morph = morph;
        
        container.addEvents({
            'resize': self.position.bind(self),
            'scroll': self.position.bind(self)
        });
        
        this.fireEvent('onLoad');
    },
	
    'position': function()
    {
        var self = this;        
        if(self.options.container == document.body)
        {
            var size = document.id(document.body).getScrollSize();
            
            self.wrapper.setStyles({
                'width': size.x,
                'height': size.y
            });
        }
        else
        {
            self.wrapper.setStyles(self.container.getCoordinates());
        }
        
        self.fireEvent('onPosition');
    },
    
    'show': function()
    {
        this.position();
        
        this.morph.start({
            'opacity': [0, this.options['opacity']]
        });
        
        this.fireEvent('onShow');
    },
	
    'hide': function()
    {      
        this.morph.start({
            'opacity': [this.options['opacity'], 0]
        });
        
        this.fireEvent('onHide');
    },

    // erase the overlay element, add by B.Z
    'close': function()
    {     
        this.morph.start({
            'opacity': [this.options['opacity'], 0]
        });
        
        this.wrapper.dispose();
    }
});

/*
---
description: Simple modal class (with overlay) for MooTools.

license: MIT-style

authors:
- Christopher Pitt

requires:
- Overlay (sixtyseconds)/0.1: Overlay

provides: [Modal]

...
*/

var Modal = new Class({
    'Implements': [Options, Events],

    'options': {    
        /*
        'onLoad': $empty,
        'onPosition': $empty,
        'onShow': $empty,
        'onHide': $empty,
        'onButton': $empty,
        */
        'z-index': 1,
        'buttons': 'ok|cancel',
        'container': document.body,
        'duration': 100,
        'color': '#000',
        'opacity': 0.7
    },
    
    'initialize': function(options)
    {
        this.setOptions(options);
	// in some conditions, after being set to document.body, it's still a null value. Add by B.Z
	if(this.options.container == null) this.options.container = document.body;
        
        var self = this,
            buttons = self.options.buttons.split('|'),
            
            overlay = new Overlay($extend(self.options, {
                'onPosition': self.position.bind(self)
            })),
            
            modalWindow = new Element('div', {
                'class': 'modal-window',
                'styles': {
                    'z-index': self.options['z-index'] + 10,
                    'position': 'absolute',
                    'display': 'none'
                }
            }).inject(document.body),
	    
	    closeBnContainer = new Element('div', {style:'height:20px'}), 
	    closeBnImg = new Element('a',{'class': 'modal-close', href: 'javascript:;'}),
            content = document.id(self.options['content']) || new Element('div', {'class': 'modal-content'});
        
	closeBnImg.addEvent('click', function(e){
		new Event(e).stop();
		self.close();
	});
 	               
	modalWindow.grab(closeBnContainer.grab(closeBnImg));

	content.setStyles({
		'z-index': self.options['z-index'] + 11
	}).inject(modalWindow);            
            
	Array.each(buttons, function(button) {
		new Element('a', {
			'class': 'button ' + button,
			'text': button,
			'href': '#',
			'events': {
				'click': function(e)
				{
					self.fireEvent('onButton', [e, button]);
				}
			}
		}).inject(modalWindow);
	});
            
        self.overlay = overlay;
	// when overlay being clicked, close popup dialog, add by B.Z
	self.overlay.wrapper.addEvent('click', function(e){
		new Event(e).stop();
		self.close();
	});

        self.window = modalWindow;
        self.content = content;
        
        this.fireEvent('onLoad');
    },
    
    'show': function()
    {
        this.overlay.show();
        this.window.setStyle('display', 'block');
        this.fireEvent('onShow');
    },
    
    'hide': function()
    {
        this.overlay.hide();
        this.window.setStyle('display', 'none');
        this.fireEvent('onHide');
    },
	
    'close': function()
    {
        this.overlay.close();
        this.window.setStyle('display', 'none');
	this.window.dispose();
    },
    
    'position': function()
    {
        var self = this,
            size = window.getSize(),
            coords = self.window.setStyle('display', 'block').getCoordinates();
        
        self.window.setStyles({
            //'top': Math.floor((size.y - coords.height) / 2),
	    // changed for adjust the window to be on the center of the scroll window, by B.Z
            'top': Math.floor((size.y - coords.height) / 2 + document.body.getScroll().y),
            'left': Math.floor((size.x - coords.width) / 2)
        });
        
        self.fireEvent('onPosition');
    },

    'setBackground': function(style)
    {
	alert('test');
	this.window.setStyle('background',style);
    }

});
