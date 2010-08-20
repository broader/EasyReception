/*
**	Portal menu click function
*/
function adminProfile(event){
	new Event(event).stop();

	// the dom id for popup window
	var wid = "adminProfileWindow";
	if($(wid)) return;

	var url = "portfolio/portfolio.ks/page_showAccount?windowId={wid}".substitute({'wid':wid});
	//new MUI.Modal({
	new MUI.Window({
		id: wid,
         	width:400, height:350,
         	contentURL: url,
         	//title: "Your Profile",
         	title: "Your Profile"
         	//modalOverlayClose: false
         });

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
