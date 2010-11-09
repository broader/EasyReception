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
			if(config.onContentLoaded){
				config.onContentLoaded = eval(config.onContentLoaded);
				//alert(config.onContentLoaded);
			};

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
	
	// change the selected tag
	$$(".noteWidget").each(function(aLink){
		var checkTag = aLink.getChildren('div')[0];
		if(aLink == event.target){
			if(checkTag.getStyle('display')=='none')
			   checkTag.setStyle('display', 'block');
		}
		else{
			if(checkTag.getStyle('display')=='block')
			   checkTag.setStyle('display', 'none');		
		};		  
	});

	$("pageWrapper").retrieve("notesWidget")
	.resetLayout(event.target.getProperty('id'));
};

/* 
** onContentLoad function for user hotle map view
*/
function userHotelMapView(){
	
		
	new MUI.Column({
		container: 'hotelMap_contentWrapper',
		id: 'hotelMap_mainColumn',
		placement: 'main',
		//width: 100,
		resizeLimit: [100, 300]
	});
			
	new MUI.Column({
		container: 'hotelMap_contentWrapper',
		id: 'hotelMap_sideColumn',
		placement: 'right',
		//width: null,
		width: 300,
		resizeLimit: [100, 300]
	});
			
	new MUI.Panel({
		header: false,
		id: 'hotelMap_panel2',
		addClass: 'panelAlt',					
		contentURL: 'accomodation/maps/userMapView.ks/page_map',
		column: 'hotelMap_mainColumn'					
	});
			
	new MUI.Panel({
		id: 'hotelMap_reservation',					
		contentURL: 'license.html',
		column: 'hotelMap_sideColumn',
		height: 200,
		panelBackground: '#fff'
	});

	new MUI.Panel({
		id: 'hotelMap_hoteList',					
		contentURL: 'license.html',
		column: 'hotelMap_sideColumn',
		height: 300, panelBackground: '#fff'
	});

	new MUI.Panel({
		id: 'hotelMap_thumbnail',					
		contentURL: 'accomodation/maps/userMapView.ks/page_thumbnail',
		column: 'hotelMap_sideColumn',
		height: 250, 
		panelBackground: '#fff'
	});
	
	var c = Asset.css('lib/imageZoom/imageZoom.css');
	var imageZoomJs = Asset.javascript('lib/imageZoom/imageZoom.js', {
		onload: function(){
			MUI.notification('China');
			//alert("China");
		}
	});

};
