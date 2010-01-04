/******************************************************************/
/*                        ERTabs 0.0.1                            */
/* A Notebook( or named "Tabs") widget, used to display remote    */ 
/* content(now just for form submitting) loaded using AJAX,       */
/* written for the mootools framework (version 1.2 or newer )     */
/* by broader.zhong@yahoo.com.cn                                  */
/* @Website                                                       */
/******************************************************************/
/*                                                                */
/* MIT style license:                                             */
/* http://en.wikipedia.org/wiki/MIT_License                       */
/*                                                                */
/* mootools found at:                                             */
/* http://mootools.net/                                           */
/******************************************************************/
/* This widget is inspired by "tabs-1-2",                         */
/* http://http://jonplante.com/demo/tabs-1-2                      */
/******************************************************************/

var ERTabs = new Class({      
    Implements: [Options],
    options: {
        tabs: ".ertabs_title li",        
        panelTag: "div",
        selectedClass: "active",        
        activateOnLoad: 0,        
        ajaxOptions: { 
           method:'get',           
           noCache: true,           
           evalScripts: true, 
           useSpinner:true,           
           spinnerOptions: {fxOptions:{duration:'long'}}
        }        
    },
    
    /* 
    Parameters:
       e, the 'id' of a 'div' element which holds a ul element and a div element.
       o, a object that is  the options of this class. 
    */
    initialize: function (e, o) {        
        this.setOptions(o);
        var e = $(e) 
        this.contentPanel = e.getElements(this.options.panelTag);
        this.tabs = e.getElements(this.options.tabs);
        // record the tabs that could be selected 
        this.activeTabs = [];
        
        // add 'click' function to each tab 
        if(this.tabs){  
           this.enableTabs(this.tabsIndexArray());
        }   
        
        this.showTab(this.options.activateOnLoad);        
    },
    
    // get all a index array  according to the tabs' number
    tabsIndexArray: function(){
       var a = [];
       if(this.tabs){
          (this.tabs.length).times(function(i){a.push(i)},a);
       }
       return a
    },
     
    // add click callback function to each tab label 
    elementClick: function (e, element){      
       var event = new Event(e).stop();
       this.tabs.each(function(i) {
          i.removeClass('active');
       });
       element.addClass(this.options.selectedClass);
       
       // config for content updating       
       var options = this.options.ajaxOptions;       
       this.contentPanel
       .set('load',options)
       .load($(element.getElements('a')[0]).getAttribute('ref'));       
    },
    
    // show the content of a tab linked
    showTab: function (index){         
       // maybe this tab has been diabled, so enables it first
       if(!this.activeTabs.contains(index)){ 
          this.enableTabs([index]); 
       };
           
       var element = this.tabs[index]; 
       element.fireEvent('click', element);
    }, 
    
    // get current showing tab
    currentTab: function(){
       // get the index of current tab by 'active' class
       var active = this.options.selectedClass;  
       
       var li = this.tabs.filter(function(item, index){          
          if( item.getAttribute('class') == active){
             return true
          }
          else{
             return false
          }
       });
       index = this.tabs.indexOf(li[0]);
       return index
    },
    
    // show the next tab, if current tab is the last tab, then the first tab will be shown 
    nextTab: function(){       
       index = this.currentTab();
       // calculate the next tab's index
       if(this.tabs.length == (index+1)){
          index=0;
       }
       else{
          index += 1;
       }
       // show that tab 
       this.showTab(index);             
    },
    
    // enabled a tab to be shown  
    enableTabs: function (tabs){
       /* Parameters:
          tabs : a array holds the index numbers of the tabs to be enabled
       */
       tabs.each(function(index){
          if(this.activeTabs.contains(index)){ return };
          this.activeTabs.push(index);
          var tab = this.tabs[index]; 
          tab.addEvent('click',this.elementClick.bindWithEvent(this,tab));          
       }, this);
    },
    
    // diabled a tab to be shown
    disableTabs: function (tabs){
       /* Parameters:
          tabs : a array holds the index numbers of the tabs to be disabled
       */
       tabs.each(function(index){
          if(!this.activeTabs.contains(index)){ return };
          var tab = this.tabs[index];
          tab.removeEvents();  
          this.activeTabs.erase(index);        
       }, this);
    },
    
    // toggle tabs showing by the gived index 
    toggleTabs: function (index){
    	// diable action must be done first before switching to other tab
      this.disableTabs([this.currentTab()]);
		this.showTab(index);
    }
    
});
      