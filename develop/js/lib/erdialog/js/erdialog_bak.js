/******************************************************************/
/*                        ERDialog 0.0.1                          */
/* A modal box (inline popup), used to display remote content(now */
/* just for form submitting) loaded using AJAX, written for the   */
/* mootools framework (version 1.2 or newer )                     */
/* by broader.zhong@yahoo.com.cn                                  */
/* @Website                                                       */
/******************************************************************/
/*                                                                */
/* MIT style license:  
/* http://en.wikipedia.org/wiki/MIT_License                       */
/*                                                                */
/* mootools found at:                                             */
/* http://mootools.net/                                           */
/******************************************************************/
/* Original code based on "Moodiabox",which based on mootools     */
/* version 1.x and written by Razvan Brates, razvan [at] e-magine.ro*/
/* http://www.e-magine.ro/web-dev-and-design/36/moodalbox/        */
/******************************************************************/
/* Migrading from version 1.x to 1.2.x by the                     */
/* introduction:                                                  */
/* http://wiki.github.com/mootools/mootools-core/conversion-from-1-11-to-1-2*/
/******************************************************************/

// Constants defined here can be changed for easy config / translation
// (defined as vars, because of MSIE's lack of support for const)

// the error message displayed when the request has a problem
var _ERROR_MESSAGE = "Oops.. there was a problem with your request.<br /><br />" +
					"Please try again.<br /><br />" +
					"<em>Click anywhere to close.</em>"; 
// Duration of height and width resizing (ms)
var _RESIZE_DURATION = 400; 		// Initial width of the box (px)
var _INITIAL_WIDTH = 250;		// Initial height of the box (px)
var _INITIAL_HEIGHT = 250;		// Actual width of the box (px)
var _CONTENTS_WIDTH = 500;		// Actual height of the box (px)
var _CONTENTS_HEIGHT	= 400;// Default width of the box (px) - used for resetting when a different setting was used
var _DEF_CONTENTS_WIDTH	= 700;		// Default height of the box (px) - used for resetting when a different setting was used
var _DEF_CONTENTS_HEIGHT = 350;// Enable/Disable caption animation
var _ANIMATE_CAPTION	= true;		// Option to evaluate scripts in the response text
var _EVAL_SCRIPTS	= true;	// Option to evaluate the whole response text
var _EVAL_RESPONSE = true;	

// Now the ERDialog define                                           
var ERDialog = new Class({

    Implements: [Options, Events],
    
    options: {
       resizeDuration: 	   _RESIZE_DURATION,
		 initialWidth: 		_INITIAL_WIDTH,	
		 initialHeight: 		_INITIAL_HEIGHT,
		 contentsWidth: 		_CONTENTS_WIDTH,
		 contentsHeight: 	   _CONTENTS_HEIGHT,
		 defContentsWidth: 	_DEF_CONTENTS_WIDTH,
		 defContentsHeight: 	_DEF_CONTENTS_HEIGHT,
		 animateCaption: 	   _ANIMATE_CAPTION,
		 evalScripts: 		   _EVAL_SCRIPTS,
		 evalResponse: 		_EVAL_RESPONSE
    },    
    
    initialize: function(options){
       // init default options
       this.setOptions(options);
		 
		 // add event listeners
		 this.eventKeyDown = this.keyboardListener.bindWithEvent(this);
		 this.eventPosition = this.position.bind(this);
		
		 // init the HTML elements
		 // the overlay (clickable to close)       //this.overlay = new Element('div').setProperty('id', 'mb_overlay').injectInside(document.body);
		 this.overlay = new Element('div',{'id':'mb_overlay'}).inject(document.body);
		
		 // the center element
		 this.center = new Element('div',
          {
             'id':'mb_center',
             'styles':{
             'width': this.options.initialWidth+'px', 
             'height': this.options.initialHeight+'px', 
             'marginLeft': '-'+(this.options.initialWidth/2)+'px', 
             'display': 'none'
             }		                      
          }
       ).inject(document.body);
		 
		 // the actual page contents
		 this.contents = new Element('div',{'id':'mb_contents'}).inject(this.center);

		 // the bottom part (close button)       this.bottom = new Element('div',
          {  
             'id':'mb_bottom',
             'styles':{'display':'block'}       
          }
       ).inject(this.contents,'before');       
		 
		 this.closelink = new Element('a',
		    { 'id':'mb_close_link','href': '#'}
		 ).inject(this.bottom);		 
				
		 this.error = new Element('div',{'id':'mb_error','class':'warning'}).set('html',_ERROR_MESSAGE);
		
		 // attach the close event to the close button / the overlay  		 //this.closelink.onclick = this.overlay.onclick = this.close.bind(this);
  		 this.closelink.onclick = this.close.bind(this);
		
		 // init the effects       var nextEffect = this.nextEffect.bind(this);
		 this.fx = {		    
          overlay:   this.overlay.get('tween', {property: 'opacity', duration: 500}),			 
			 resize: 	new Fx.Morph(this.center, { duration: this.options.resizeDuration, onComplete: nextEffect }),
			 contents: 	this.contents.get('tween',{property:'opacity', duration: 500, onComplete: nextEffect }),
			 bottom: 	new Fx.Morph(this.bottom, { duration: 400})
		 };
		
		 this.ajaxRequest = $empty;
		 
       // Open erdialog
       // When call this object instance,
       // options.url must be defined, options.dim is optional.        
       if(!$type(this.options.dim)){this.options.dim = '';};
       this.open(this.options.url, this.options.dim);   
    },
    
    open: function(sUrl, sDim) {
       this.href = sUrl;
   	 this.rel = sDim;
   	 
   	 this.position();
   	 this.setup(true);
   	 this.top = Window.getScrollTop() + (Window.getHeight() / 15);
   	 this.center.setStyles({top: this.top+'px', display: ''});   	 
   	 
   	 //this.fx.overlay.custom(0.8);
   	 this.fx.overlay.start(0.8);
   	 
   	 return this.loadContents(sUrl);
    },
    
    setup: function(open) {
       /*
       var elements = $A($$('object'));
		 elements.extend($$(window.ActiveXObject ? 'select' : 'embed'));
		 elements.each(function(el){ el.style.visibility = open ? 'hidden' : ''; });
		 */
		 var fn = open ? 'addEvent' : 'removeEvent';
		 window[fn]('scroll', this.eventPosition)[fn]('resize', this.eventPosition);
		 document[fn]('keydown', this.eventKeyDown);
		 this.step = 0;
	 },
	
    position: function() {
       this.overlay.setStyles(
          {
          top: Window.getScrollTop()+'px', 
          height: Window.getHeight()+'px'
          }
       );
	 },
    
    loadContents: function() {	
       if(this.step) return false;
		 this.step = 1;
		
		 // check to see if there are specified dimensions
		 // if not, fall back to default values
		 var aDim = this.rel.match(/[0-9]+/g);
		 this.options.contentsWidth = (aDim && (aDim[0] > 0)) ? aDim[0] : this.options.defContentsWidth;
		 this.options.contentsHeight = (aDim && (aDim[1] > 0)) ? aDim[1] : this.options.defContentsHeight;		 
		 //this.bottom.setStyles({opacity: '0', height: '0px', display: 'none'});
		 //this.bottom.setStyles({opacity: '0', height: '0px', display: 'block'});
		 //this.bottom.setStyles({opacity: '0', display: 'block'});
		 this.center.className = 'mb_loading';
				 
		 //this.fx.contents.hide();
		 //this.contents.fade('hide');
		
		 // AJAX call here
		 var nextEffect = this.nextEffect.bind(this);
		 var ajaxFailure = this.ajaxFailure.bind(this);
		 
		 var ajaxOptions = {
		    url:          this.href,
		    method: 		'get',
			 update: 		this.contents, 
			 evalScripts: 	this.options.evalScripts,
			 evalResponse: this.options.evalResponse,			  
			 onSuccess:    nextEffect,
			 onFailure: 	ajaxFailure
		 };
		 this.ajaxRequest = new Request.HTML(ajaxOptions).send();
				
		 return false;
	 },
	
	 ajaxFailure: function (){	    
	    this.contents.set('html','');	     
		 this.error.clone().injectInside(this.contents);		 
		 this.nextEffect();
		 this.center.setStyle('cursor', 'pointer');		 
		 this.center.onclick = this.bottom.onclick = this.close.bind(this);		
	 },
	
    nextEffect: function() {
       switch(this.step++) {
          case 1:
			   // remove previous styling from the elements    			// (e.g. styling applied in case of an error)            
   			this.center.className = '';
   			this.center.setStyle('cursor', 'default');   			
   			this.center.onclick = this.bottom.onclick = '';
   			
   			this.contents.set({
   			   'styles':
   			      {
   			         'width': this.options.contentsWidth + "px", 
   			         'height': this.options.contentsHeight + "px"
   			      }
   		   });
            
            /*
   			height = this.top + this.contents.scrollHeight;
   			if(this.center.clientHeight != this.contents.scrollHeight){
   				this.fx.resize.start({'height': [this.center.clientHeight, height]});   				
   				break;
   			}
   			*/			
   			this.step++;
					
		case 2:		      	   
		   this.center.setStyle(
			   'background','#D8D8D8 url(js/lib/erdialog/img/fancy_block_background.gif) repeat-y scroll bottom'
		   );		     
		   
		   if(this.center.clientHeight != this.contents.offsetHeight) {				
				alert('this.center.clientHeight is '+this.center.clientHeight+',this.contents.scrollHeight is ' + this.contents.scrollHeight);
				height = this.top + this.contents.scrollHeight;
				//this.center.setStyle('height', this.center.clientHeight);
				this.center.setStyle('height', height);
   		};
   		
   		
			if(this.center.clientWidth != this.contents.offsetWidth) {			   
				this.fx.resize.start({
				   'width': [this.center.clientWidth, this.contents.offsetWidth],				   
				   'marginLeft': [-this.center.clientWidth/2, -this.contents.offsetWidth/2]				   
				});			
				break;
			};
			this.step++;
		
		case 3:		
		   
			this.bottom.setStyles(
			   {
			      //top: (this.top + this.contents.clientHeight)+'px',
			      //top: this.center.clientHeight + 'px',			      
			      //top: this.contents.clientHeight+'px',			      
			      width: this.contents.style.width, 
			      marginLeft: this.center.style.marginLeft			      
			   }
			);			
			this.fx.contents.start(0,1);
			break;
		
		case 4:
			if(this.options.animateCaption) {				
				this.fx.bottom.start({
				   'opacity': [0, 1],
				   'height': [0, this.bottom.scrollHeight]				   
				});				
				break;
			}
			this.bottom.setStyles({opacity: '1', height: this.bottom.scrollHeight+'px'});			

		case 5:
			this.step = 0;
		}
	},    
    
    keyboardListener: function(event) {
       // close the MOOdalBox when the user presses CTRL + W, CTRL + X, ESC 		 if ((event.control && event.key == 'w') || (event.control && event.key == 'x') || (event.key == 'esc'))
 		 {
 		    this.close();
			 event.stop();
		 }		
	 },
	
	 close: function() {
	    if(this.step < 0) return;
		 this.step = -1;
		 this.overlay.dispose();
		 this.center.dispose()		 
		 return false;
	 }
});
