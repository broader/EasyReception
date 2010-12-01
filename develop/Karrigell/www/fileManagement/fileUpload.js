//********************************************************************************************************************************
// Author: Broader ZHONG 
// Web: http://github.com/broader/EasyReception
// Email: broader.zhong@yahoo.com.cn
// Company: 
// Licence: Creative Commons Attribution 3.0 Unported License, http://creativecommons.org/licenses/by/3.0/
//	If you copy, distribute or transmit the source code please retain the above copyright notice, author name and project URL. 
// Required: Mootools core 1.2 or newer 
// *******************************************************************************************************************************

var FileUpload = new Class({
	version: '0.1',
	
	Implements: [Events,Options],
				  
	options: {
		container: null,
		
	},
	
	initialize: function(options){	
		this.setOptions(options);		
		this.container = $(this.options.container);
		if (!this.container)
			return;
	
		// layout initial
		this.input = new Element('h2', {html:'China'});
	
		this.container.grab(this.input);
	
					
	}
});

