window.addEvent('domready', function(){
	$('content').set('load', {evalScripts: true});
	// get menu data in json format	
	var req = new Request.JSON({
		url:'menus.json', 
		async:false, 
		onComplete:renderMenu
	});
	req.get();
});
	
function renderMenu(menus){
	// constructs mianmenu and submenu
	var lis = menus.map(function(menu,index){
		var alink = new Element('a',{html:menu.label, href:'javascript:;'});
		alink.store('level',0);
		if($type(menu.submenu)==$type('')){
			alink.setProperty('ref', menu.submenu);
			alink.addEvent('click', loadPage);
		}
		else{
			alink.store('subMenu', menu.submenu);
			alink.addClass('hasMenu');
			alink.addEvent('click', addSubMenu);
		};

		var li = new Element('li');
		if(index==0) {
			li.addClass('active');
			// load the default site home page, that usually means the 'home' page
			$('content').load('home.html');
		};

		li.grab(alink);
			return li
	});

	var ul = new Element('ul');
	$('mainmenu').grab(ul.adopt(lis));
};
		
// add sub menus to clicked main menu item
function addSubMenu(event){
	new Event(event).stop();
	var alink = $(event.target);
	setActive(alink);
	// change 'menus' container css style to 'hasSubMenu'
	$('menus').addClass('hasSubMenu');
	
	// clear submenu contianer first
	$('submenu').empty();
	var lis = alink.retrieve('subMenu').map(function(menu){
		var a = new Element('a',{html:menu.label, href:'javascript:;'});
		a.setProperty('ref', menu.ref);
		a.addEvent('click', loadPage);
		var li = new Element('li');
		li.grab(a);
		return li
	});

	var ul = new Element('ul');
	$('submenu').grab(ul.adopt(lis));
			
	// show the content of the first submenu
	$('content').load(alink.retrieve('subMenu')[0]['ref']);
};
		
// load page to 'content' container	
function loadPage(event){
	new Event(event).stop();
	var alink = $(event.target);

	// for the highest level menu, toggle css style for 'menus' container
	if(alink.retrieve('level')==0){
		if(alink.retrieve('subMenu')==null && $('menus').hasClass('hasSubMenu')){
			// clear 'submenu' content
			$('submenu').empty();
			$('menus').removeClass('hasSubMenu');
		};
		setActive(alink);
	};

	var href = alink.getProperty('ref');	
	$('content').load(href);		
};
		
// toggle 'active' css class for clicked menu
function setActive(alink){
	$$('#mainmenu ul li').map(function(li){
		if(li.hasChild(alink) && !li.hasClass('active')){
			li.addClass('active');
		}
		else if(li.hasClass('active')){
			li.removeClass('active');
		};
	});
};

