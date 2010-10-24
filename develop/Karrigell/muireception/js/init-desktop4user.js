/* 

	In this file we setup our Windows, Columns and Panels,
	and then inititialize MUI.
	
	At the bottom of Core.js you can setup lazy loading for your
	own plugins.

*/

initializeWindows = function(){

	MUI.clockWindow = function(){	
		new MUI.Window({
			id: 'clock',
			title: 'Canvas Clock',
			addClass: 'transparent',
			loadMethod: 'xhr',
			contentURL: '../plugins/coolclock/index.html',
			shape: 'gauge',
			headerHeight: 30,
			width: 160, height: 160,
			x: 1170, y: 82,
			padding: { top: 0, right: 0, bottom: 0, left: 0 },
			require: {			
				js: ['../plugins/' + 'coolclock/scripts/coolclock.js'],
				onload: function(){
					if (CoolClock) new CoolClock();
				}	
			}			
		});	
	};	

	// Deactivate menu header links
	$$('a.returnFalse').each(function(el){
		el.addEvent('click', function(e){
			new Event(e).stop();
		});
	});

	// Build windows onLoad
	MUI.clockWindow();

	// application windows
	var res = new Request.JSON();
	// set some options for Request.JSON instance
	res.setOptions({
		url: '../desktop_demo.ks/page_windowsConfig',
		onSuccess: function(json){
			if(json.length == 0 ) return;
			json.each(function(option,index){
				if( option.shape == 'gauge'){
					new MUI.GaugeWindow(option);	
				}
				else new MUI.Window(option);
			});
		}
	});
    
	res.get();
	//reservationWindow();
	
	MUI.myChain.callChain();
	
}

// Initialize MochaUI when the DOM is ready
window.addEvent('load', function(){

	MUI.myChain = new Chain();
	MUI.myChain.chain(
		function(){MUI.Desktop.initialize();},
		function(){MUI.Dock.initialize();},
		function(){initializeWindows();}		
	).callChain();
	
	// This is just for the demo. Running it onload gives pngFix time to replace the pngs in IE6.
	$$('.desktopIcon').addEvent('click', function(){
		MUI.notification('Do Something');
	});	

});

window.addEvent('unload', function(){
	// This runs when a user leaves your page.	
});
