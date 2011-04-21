// the global variables
var spinner4page;

window.addEvent('load', function(){
    spinner4page = new Spinner('content',{message:"Please wait a minute..."});
    $('content').set('load', {
	evalScripts: true,
	onComplete: function(){
	    spinner4page.hide(); 
	}
    });

    // get menu data in json format	
    var req = new Request.JSON({
	url:'config.json', 
	async:false, 
	onComplete:renderMenu
    });
    req.get();
});
	
function renderMenu(conf){
    // constructs mianmenu and submenu
    var lis = conf["menus"].map(function(navMenu,index){
	var alink = new Element('a',{html:navMenu.label, href:'javascript:;'});
	alink.store('level',0);
	if($type(navMenu.submenu)==$type('')){
	    alink.setProperty('ref', navMenu.submenu);
	    alink.addEvent('click', loadPage);
	}
	else{	// add submenu
	    // save the data object of submenu to this tag
	    alink.store('subMenu', navMenu.submenu);
	    alink.addClass('hasMenu');
	    alink.addEvent('click', addSubMenu);
	};

	var li = new Element('li');
	if(index==0) {
	    li.addClass('active');
	    // load the default site home page, that usually means the 'home' page
	    $('content').load(navMenu.submenu);
	};

	li.grab(alink);
	return li;
    });

    var ul = new Element('ul');
    $('menu').grab(ul.adopt(lis), 'top');
};
		
// add sub menus to clicked main menu item
function addSubMenu(event){
    new Event(event).stop();
    var alink = $(event.target);
    setActive(alink);
};


// load page to 'content' container	
function loadPage(event){
    new Event(event).stop();
    
    // set content spinner
    spinner4page.show();

    var alink = $(event.target);
    setActive(alink);
    var href = alink.getProperty('ref');
    if(href) $('content').load(href);
		
};
		
// toggle 'active' css class for clicked menu
function setActive(alink){
    $$('#menu ul li').map(function(li){
	if(li.hasChild(alink) && !li.hasClass('active')){
	    li.addClass('active');
	}
	else if(li.hasClass('active')){
	    li.removeClass('active');
	};
    });
};

