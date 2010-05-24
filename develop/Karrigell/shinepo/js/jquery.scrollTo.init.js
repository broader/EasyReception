jQuery(function( $ ){
	/**
	 * THIS BLOCK IS SPECIFICALLY FOR THE DEMO
	 * Binding of the section links, to load other sections inside the content div
	 */
	var $sections = $('#menu a'),// Links on the left
		last = null;// Last section
	
	$sections.click(function(){
		if( last != this ){ // let's avoid needless requests			
			//var url = 'html/' + this.hash.slice(1) + '.html';
			var url = this.hash.slice(1);			
			//alert(url);
			$('#main').html( '<p class="loading">内容载入中，请稍候......</p>' ).load( url, function(){
				this.scrollLeft = 0;//scroll back to the left
			});
		}
		last = this;
		this.blur(); // Remove the awful outline
		return false;
	});
	
	$sections.eq(0).click(); // Load the first section
	
	/**
	 * Actual call to jQuery.localScroll.
	 * Most jQuery.LocalScroll's defaults, belong to jQuery.ScrollTo, check it's demo for an example of each option.
	 * @see http://flesler.demos.com/jquery/scrollTo/
	 */
	
	//$('#content').localScroll({// Only the links inside that jquery object will be affected
		//lazy: true, // This is the KEY setting here, makes the links work even after an Ajax load.
		//target: '#main', // The element that gets scrolled
		//axis:'x', // Horizontal scrolling
		//duration:500,
		//onBefore:function( e, subsec, $cont ){//'this' is the clicked link
			//if( this.blur )
				//this.blur(); // Remove the awful outline
		//}
	//});
});
