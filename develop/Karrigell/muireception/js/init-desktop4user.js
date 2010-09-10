/* 

	In this file we setup our Windows, Columns and Panels,
	and then inititialize MUI.
	
	At the bottom of Core.js you can setup lazy loading for your
	own plugins.

*/

/*
  
INITIALIZE WINDOWS

	1. Define windows
	
		var myWindow = function(){ 
			new MUI.Window({
				id: 'mywindow',
				title: 'My Window',
				contentURL: 'pages/lipsum.html',
				width: 340,
				height: 150
			});
		}

	2. Build windows on onDomReady
	
		myWindow();
	
	3. Add link events to build future windows
	
		if ($('myWindowLink')){
			$('myWindowLink').addEvent('click', function(e) {
				new Event(e).stop();
				jsonWindows();
			});
		}

		Note: If your link is in the top menu, it opens only a single window, and you would
		like a check mark next to it when it's window is open, format the link name as follows:

		window.id + LinkCheck, e.g., mywindowLinkCheck

		Otherwise it is suggested you just use mywindowLink

	Associated HTML for link event above:

		<a id="myWindowLink" href="pages/lipsum.html">My Window</a>	


	Notes:
		If you need to add link events to links within windows you are creating, do
		it in the onContentLoaded function of the new window. 
 
-------------------------------------------------------------------- */

// reserved service dashboard
function reservationWindow(){
	new MUI.Window({
			id: 'reservationDashboard',
			title: 'Your Reservations',
			loadMethod: 'xhr',
			contentURL: '../pages/lipsum.html',
			//addClass: 'transparent',
			shape: 'gauge',
			width: 250,
			height: 150,
			x: 50, y: 100
		});
};

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
			width: 160,
			height: 160,
			x: 570,
			y: 152,
			padding: { top: 0, right: 0, bottom: 0, left: 0 },
			require: {			
				//js: [MUI.path.plugins + 'coolclock/scripts/coolclock.js'],
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

	reservationWindow();
	
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
