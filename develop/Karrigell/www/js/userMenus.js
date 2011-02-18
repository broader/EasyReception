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
		// run the function after content loaded
		config.onContentLoaded = eval(config.onContentLoaded);
	    };

	    // if 'width','height' are float number and no more than 1,
	    // then set them to relative value to window.screen value
	    ['width', 'height'].each(function(prop){
		var initData = config[prop].toFloat();
		if(initData < 1){
		    config[prop] = (window.screen[prop]*initData).toInt();
		}
	    });

	    if( config.shape == 'gauge'){
		new MUI.GaugeWindow(config);	
	    }
	    else if(config.type=='modal'){
		new MUI.Modal(config);
	    }
	    else  new MUI.Window(config);
	}
    });
    
    res.get();
};


/*
**	Change the layout of the sticky notes	
*/
function setNotesLayout(event){
    new Event(event).stop();
	
    // change the selected layout style tag
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
	
    //change the layout style, now it's between 'grid', 'circle' and 'cascade'
    $("pageWrapper").retrieve("notesWidget")
    .resetLayout(event.target.getProperty('id'));
};


/* 
** onContentLoad function for user hotle map view
*/
function userHotelMapView(){
    // load initial data for render map widget	
    new Request.JSON({
	url: 'accomodation/maps/userMapView.ks/page_initData',
	async: false, 
	onSuccess: function(json){ 
	    var titles = json.panelTitles,
		mapData = json; 
	    
	    // left column
	    new MUI.Column({
		container: 'hotelMap_contentWrapper',
		id: 'hotelMap_leftColumn',
		placement: 'left',
		width: 620,
		resizeLimit: [550, 620]
	    });
	
	    // right column	
	    new MUI.Column({
		container: 'hotelMap_contentWrapper',
		id: 'hotelMap_mainColumn',
		placement: 'main'
	    });
	
	    var mapDiv = "hotelBigMap";		
	    new MUI.Panel({
		header: false,
		id: 'hotelMap_panel2',
		content: new Element('div', {id: mapDiv}),				
		column: 'hotelMap_leftColumn'					
	    });
	
	    var containerId = 'hotelMap_reservation',
		url = [
		    'service/userHotelsView.ks/page_roomReservation', 
		    ['panelId',containerId].join('=')
		].join('?');		

	    new MUI.Panel({
		id:containerId ,					
		title: titles.reservations,
		contentURL: url,
		column: 'hotelMap_mainColumn',
		height: 180
	    });

	    new MUI.Panel({
		id: 'hotelMap_hoteList',					
		title: titles.hoteList,
		contentURL: 'service/userHotelsView.ks/page_hotelNameList',
		column: 'hotelMap_mainColumn',
		height: 220
	    });

	    var thumbDiv = "hotelThumbMap";
	    new MUI.Panel({
		id: 'hotelMap_thumbnail',					
		title: titles.thumbNail,
		content: new Element('div', {id:thumbDiv}),
		column: 'hotelMap_mainColumn'
	    });
		    
	    var hotelData = $H(mapData.hotelData).getValues().map(function(item){ return item.dimention; });
	    var iconStyle = mapData.hotelIconCss;

	    // set the callback function for dragging big hotel map
	    var showDimention = function(pos){
		$(mapDiv).getChildren('span').each(function(item){
		    item.dispose();
		});
	
		hotelData.each(function(dim){
		    if(
			dim.x >= pos.xrange[0] 
			&& dim.x <= pos.xrange[1]
			&& dim.y >= pos.yrange[0]
			&& dim.y <= pos.yrange[1]
		    ){	// add the hotel label
			iconStyle['margin-left'] = dim.x-pos.xrange[0]+'px';
			iconStyle['margin-top'] = dim.y-pos.yrange[0]+'px';
			var alink = new Element('span');
			alink.setStyles(iconStyle);
			$(mapDiv).adopt(alink);
		    };
				
		});

	    };
		    
	    MUI.imageZoom('', {onload: function(){
		new ImageZoom({
		    zoomerImageContainer: mapDiv,
		    zoomerImageUrl: mapData.zoomImage.zoomerImageUrl,
		    thumbUrl: mapData.zoomImage.thumbUrl,		
		    thumbContainer: thumbDiv,
		    zoomSize:6, initFn: showDimention, dragFn: showDimention
		});
		
		[mapDiv, thumbDiv].each(function(el){
		    $(el).getParent().getParent().setStyle('background-color','#000');
		});

	    }});

	}// onSuccess options definiation end

    }).get();

};
