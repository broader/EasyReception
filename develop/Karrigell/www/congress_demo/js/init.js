/*************************************************************************
Some initialization functions.
**************************************************************************/
window.addEvent('domready', function(){
	// add login functions 
	var loginBn = $('loginPanel'),
	    style = $H({'background-color':'#212F8A','color':'white','height':'165px'}); 

	if(Browser.Engine.trident) style.set('width','300px');
	var toSet = [];
	style.each(function(value,key){
	    toSet.push([key,value].join(':'));
	});
	toSet = toSet.join(';');

	loginBn.addEvent('click', function(e){
	    var slideEl = new Element('div', {
		style: toSet
	    });
	    slideEl.inject(loginBn.getParent(),'bottom');
	    
	    // hide login button
	    loginBn.getPrevious().hide();
	    loginBn.hide().store('form', slideEl);

	    slideEl.set('load', {
		    async: false, 
		    //evalScripts:true, evalResponse:true,
		    onComplete: function(){}
	    });
	    slideEl.load("congress_demo/loginFn.ks/page_loginForm");
	    

	});

	// add menu clickable function
	var navbar =$('navigation'),
		 homeLi = navbar.getChildren('ul')[0].getChildren('li')[0],
		 content = $('contents');
	
	navbar.getChildren('ul')[0]
	.getChildren('li').each(function(li,index){
		li.addEvent('click',function(e){
			new Event(e).stop();
			var currentActiveLi = navbar.getElements('li.active')[0]; 
			if(li == currentActiveLi) return;
			else {
				currentActiveLi.removeClass('active');
			};
			
			li.addClass('active');				
			content.load(li.getChildren('a')[0].get('href'));
		});
	});
	
	homeLi.addClass('active');
	content.load(homeLi.getChildren('a')[0].get('href'));
});
