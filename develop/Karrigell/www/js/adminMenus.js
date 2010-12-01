/*
**	Portal menu click function
*/
function adminProfile(event){
	new Event(event).stop();

	// the dom id for popup window
	var wid = event.target.retrieve("popupWindowId");
	if($(wid)) {
		MUI.Windows.instances.get(wid).restore();
		return;
	};

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
**
*/
function logout(event){
	MUI.logout(event);
};
