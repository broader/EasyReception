var euro = {
		src: '/_common/swf/eurostyle.swf'
	};

	sIFR.activate(euro);
	
	/*sIFR.replace(euro, {
		selector: 'h1',
		css: {
			'.sIFR-root': { 
		  		'color': '#354158', 
		  		'letter-spacing': 0,
				'background-color': '#FFFFFF'
			}
		},
		wmode: 'transparent'
	});*/
	
	
	sIFR.replace(euro, {
		selector: 'h2',
		css: {
			'.sIFR-root': { 
		  		'color': '#354158', 
		  		'letter-spacing': 0,
				'background-color': '#FFFFFF'
			}
		},
		wmode: 'transparent'
	});
	
	
	
	sIFR.replace(euro, {
		selector: 'h3',
		css: {
			'.sIFR-root': { 
		  		'color': '#607293', 
		  		'letter-spacing': 0,
				'background-color': '#FFFFFF'
			}
		},
		wmode: 'transparent'
	});
	
	sIFR.replace(euro, {
		selector: '.home dt',
		css: {
			'.sIFR-root': { 
		  		'color': '#607293', 
		  		'letter-spacing': 0,
				'background-color': '#FFFFFF',
				'display': 'block'
			},
			'a': { 
				'text-decoration': 'none',
				'color': '#607293'
			},
      		'a:hover': { 
				'color': '#607293' 
			}
		},
		tuneHeight: -6,
		wmode: 'transparent'
	});