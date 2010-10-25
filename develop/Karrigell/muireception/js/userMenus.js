/*
**	Quit system
*/
function logout(event){
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

/*
**	Change the layout of the sticky notes	
*/
function setNotesLayout(event){
	new Event(event).stop();
	$("pageWrapper")
	.retrieve("notesWidget")
	.resetLayout(event.target.getProperty('id'));
};
