/*************************************************************************
Some initialization functions.
**************************************************************************/
window.addEvent('domready', function(){
	var slideEl = $('loginPanel').getNext(),
	    slide = new Fx.Slide(slideEl);

	slide.hide();
	$('loginPanel').store('slide', {'element': slideEl, 'instance':slide});

	$('loginPanel').addEvent('click', function(e){
		if(slideEl.getChildren().length == 1 ){
			slideEl.empty();
			slide.toggle();
		}
		else{ 
			slideEl.set('load', {
				async: false,
				onComplete: function(){
					slide.toggle();
				}
			});

			slideEl.load("loginFn.ks/page_loginForm");

		}

	});

	/*	
	slideEl.addEvent('mouseleave', function(e){
		slide.toggle();
	});
	*/

});
