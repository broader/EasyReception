
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
    spinner4content.show();

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


// constructs mianmenu and submenu
function iniMenu(menus){
    var lis = menus.map(function(navMenu,index){
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
	
function renderContent(conf){
    
    document.title = conf['title'][lang];
    $('logo').getChildren('p')[0].set('text', conf['header'][lang]);
    
    iniMenu(conf['menus'][lang]);

    // set language flags
    $('languageOption').getChildren('a').each(function(item){
	var href = $(item).getProperty('href');
	if(href.split('=')[1] == lang){
	    $(item).addClass('activeLanguage');
	};
    });

    // set the spinner for 'sidebar' element
    spinner4sidebar.show();
    $('sidebar').load(conf['sidebar'][lang]);   
};

var lang;
function setLanguage(){
    // if user has clicked the language flag on the top right corner of the home page,
    // then use user selected language.
    lang = location.href.toURI().getData('lang');
    if(!lang)
	lang = (MooTools.lang.getCurrentLanguage().toLowerCase().contains('en','-')) ? 'en':'cn';

};
	
function languageJudge(){
    var currentLanguage = navigator.language || navigator.browserLanguage || navigator.userLanguage || navigator.systemLanguage;
    if(currentLanguage){
	MooTools.lang.addLanguage(currentLanguage);
	MooTools.lang.setLanguage(currentLanguage);
    }
    
    setLanguage();
};	

// the global variables
var spinner4content, spinner4sidebar; 

window.addEvent('load', function(){
   
    languageJudge();

    /*
    spinner4content = new Spinner('content');
    spinner4sidebar = new Spinner('sidebar');

    $('content').set('load', {
	evalScripts: true,
	onComplete: function(){
	    spinner4content.hide(); 
	}
    });

    // set content spinner
    spinner4content.show();

    if(href) $('content').load(href);
    */

    $H(['content','sidebar'].associate(['spinner4content', 'spinner4sidebar']))
    .each(function(value,key){
	window[key] = new Spinner(value);
	$(value).set('load', {
	    evalScripts: true,
	    onComplete: function(){
		window[key].hide(); 
	    }
	});
	
    });
     
    

    // get menu data in json format	
    var req = new Request.JSON({
	url:'config.json', 
	async:false, 
	onComplete: renderContent
    });
    req.get();
});
