/*
**	Portal menu click function
*/
function test(event){
	new Event(event).stop();
	//MUI.notification('Portal menu clicked!');
	alert('menu clicked');	
};

/*
**
*/
function logout(event){
	//new Event(event).stop();
	//MUI.notification('Really log out?');
	// remove menus in menu bar
	// reset the top navigation info
	//topNavSwitch(false);
	MUI.logout(event);
};

/*
**	Pop up a window by given window's id
*/
function popupWindow(wid){

	var res = new Request.JSON();
	// set some options for Request.JSON instance
	res.setOptions({
		url: 'portaLayout.ks/page_windowsConfig?wid='+wid,
		onSuccess: function(config){
			if( config.shape == 'gauge'){
				new MUI.GaugeWindow(config);	
			}
			else if(config.type=='modal'){
				new MUI.Modal(config);
			}
			else new MUI.Window(config);
		}
	});
    
	res.get();
};
