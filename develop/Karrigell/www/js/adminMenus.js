/*
**	Portal menu click function
*/
function adminProfile(event){
    new Event(event).stop();

    // the dom id for popup window
    var wid = event.target.retrieve("popupWindowId");

    //new MUI.Modal({
    new MUI.Window({
	id: wid,
	width:400, height:350,
	contentURL: "portfolio/portfolio.ks/page_showAccount",
	//title: "Your Profile",
	title: "Your Profile"
	//modalOverlayClose: false
    });

};

/*
**  Online Translation
Tanslates some i18n strings in source files.
*/
function translation(event){
    new Event(event).stop();
    // the dom id for popup window
    var wid = event.target.retrieve("popupWindowId");

    new MUI.Window({
	id: wid,
	width:700, height:350,
	title: "Online Translation",
	onContentLoaded: function(){
	    new MUI.Column({
		container: wid+'_contentWrapper',
		id: 'translationWindow_leftColumn',
		placement: 'left',
		width: 170,
		resizeLimit: [100, 300]
	    });
	    new MUI.Column({
		container: wid+'_contentWrapper',
		id: 'translationWindow_mainColumn',
		placement: 'main',
		width: null,
		resizeLimit: [100, 300]
	    });
		
	    // file list
	    new MUI.Panel({
		header: false,
		id: 'translationWindow_panel1',
		contentURL: 'sysadmin/translation.ks/page_fileList',
		column: 'translationWindow_leftColumn',
		panelBackground: '#fff'
	    });
	    
	    new MUI.Panel({
		header: false,
		id: 'translationWindow_panel1',
		contentURL: 'sysadmin/translation.ks/page_translating',
		column: 'translationWindow_mainColumn'
	    });
	}

     });
};

/*
**
*/
function logout(event){
    MUI.logout(event);
};
