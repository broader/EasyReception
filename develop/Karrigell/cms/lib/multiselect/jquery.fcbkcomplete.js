/*

 FCBKcomplete 2.5

 - Jquery version required: 1.2.x, 1.3.x

 

 Changelog:

 

 - 2.00	new version of fcbkcomplete

 

 - 2.01 fixed bugs & added features

 		fixed filter bug for preadded items

 		focus on the input after selecting tag

 		the element removed pressing backspace when the element is selected

 		input tag in the control has a border in IE7

 		added iterate over each match and apply the plugin separately

 		set focus on the input after selecting tag

 

 - 2.02 fixed fist element selected bug

 		fixed defaultfilter error bug

 

 - 2.5 	removed selected="selected" attribute due ie bug

 		element search algorithm changed

 		better performance fix added

 		fixed many small bugs

 		onselect event added

 		onremove event added

 */

/* Coded by: emposha <admin@emposha.com> */

/* Copyright: Emposha.com <http://www.emposha.com/> - Distributed under MIT - Keep this message! */

/*

 * json_url         - url to fetch json object

 * json_cache       - use cache for json

 * height           - maximum number of element shown before scroll will apear

 * newel            - show typed text like a element

 * filter_case      - case sensitive filter

 * filter_selected  - filter selected items from list

 * complete_text    - text for complete page

 * maxshownitems	- maximum numbers that will be shown at dropdown list (less better performance)

 * onselect			- fire event on item select

 * onremove			- fire event on item remove

 */

jQuery(

function($)

{

    $.fn.fcbkcomplete = function(opt)

    {

        return this.each(function()

        {

            function init()

            {

                createFCBK();

                preSet();

                addInput(0);

            }

            function createFCBK()

            {

                element.hide();

                element.attr("multiple", "multiple");

                if (element.attr("name").indexOf("[]") == -1)

                {

                    element.attr("name", element.attr("name") + "[]");

                }

                holder = $(document.createElement("ul"));

                holder.attr("class", "holder");

                element.after(holder);

                complete = $(document.createElement("div"));

                complete.addClass("facebook-auto");

                complete.append('<div class="default">' + options.complete_text + "</div>");

                feed = $(document.createElement("ul"));

                feed.attr("id", elemid + "_feed");

                complete.prepend(feed);

                holder.after(complete);

            }

            function preSet()

            {

                element.children("option").each(

                function(i, option)

                {

                    option = $(option);

                    if (option.hasClass("selected"))

                    {

                        addItem(option.text(), option.val(), true);

                        option.attr("selected", "selected");

                    }

                    else

                    {

                        option.removeAttr("selected");

                    }

                    cache.push({

                        caption: option.text(),

                        value: option.val()

                    });

                    search_string += "" + (cache.length - 1) + ":" + option.text() + ";";

                }

                );

            }

            function addItem(title, value, preadded)
            {  var li = document.createElement("li");
                var txt = document.createTextNode(title);
                var aclose = document.createElement("a");
                
                $(li).attr({
                    "class": "bit-box",
                    "rel": value
                });

                $(li).prepend(txt);

                $(aclose).attr({
                    "class": "closebutton",
                    "href": "#"
                });

                li.appendChild(aclose);

                holder.append(li);

                $(aclose).click(

                function() {

                    $(this).parent("li").fadeOut("fast",

                    function() {

                        removeItem($(this));

                    }

                    );

                    return false;

                }

                );

                if (!preadded)

                {

                    $("#" + elemid + "_annoninput").remove();

                    var _item;

                    addInput(1);

                    if (element.children("option[value=" + value + "]").length)

                    {

                        _item = element.children("option[value=" + value + "]");

                        _item.get(0).setAttribute("selected", "selected");

                        if (!_item.hasClass("selected"))

                        {

                            _item.addClass("selected");

                        }

                    }

                    else

                    {

                        var _item = $(document.createElement("option"));

                        _item.attr("value", value).get(0).setAttribute("selected", "selected");

                        _item.attr("value", value).addClass("selected");

                        _item.text(title);

                        element.append(_item);

                    }

                    if (options.onselect.length)

                    {

                        funCall(options.onselect, _item)

                    }

                }

                holder.children("li.bit-box.deleted").removeClass("deleted");
                feed.hide();          	
            }

            function removeItem(item)
            {    
		/*  Old codes -------------------------------------
                j = element.children("option[value=" + item.attr("rel") + "]");
                alert(j.length);
                j.removeAttr("selected");
                alert('removeItem, L295, the item to be removed value is ' + item.attr("rel"));        
                i = element.children("option[value=" + item.attr("rel") + "]");                
		alert('removeItem, L303, element is ' + element.toString() + 'options are ' + i.length);                
                i.removeClass("selected");  */                
                
                // New------------------------------------------
                ops = element.children();
                $.each(ops, function(){
                	if ($(this).attr("value") == item.attr("rel")){
                		if ($(this).attr("selected") != "undefined"){
					$(this).removeAttr("selected");
				}
				$(this).removeClass("selected");                	
                	}
                });
                //---------------------------------------------
                        
                
                item.remove();                

                if (options.onremove.length)
                {
                    funCall(options.onremove, item)
                }           
            }	    
	    
            function addInput(focusme){
		var li = $(document.createElement("li"));
                var input = $(document.createElement("input"));
                li.attr({
                    "class": "bit-input",
                    "id": elemid + "_annoninput"
                });

                input.attr({
                    "type": "text",
                    "class": "maininput"
                });

                holder.append(li.append(input));

                input.focus(function(){
			complete.fadeIn("fast");
                });

                input.blur( function(){
			complete.fadeOut("fast");
                });

                holder.click( function(){
                	input.focus();
                    	if (feed.length && input.val().length){
				feed.show();}
			else {
				feed.hide();
                        	complete.children(".default").show();}
                });

		// Add by ZG, to control the 'Enter' key action to no response		
		input.keypress(function(event){			
			if (event.keyCode == 13){							
				return false;
			}			
		});				
		                
                input.keyup( function(event){
					
			var etext = input.val();			
			
	                if (event.keyCode == 8 && etext.length == 0){
				feed.hide();
	                        if (holder.children("li.bit-box.deleted").length == 0) {
					holder.children("li.bit-box:last").addClass("deleted");
					return false;}
	                        else{
					holder
					.children("li.bit-box.deleted")
					.fadeOut("fast", function(){
		                                removeItem($(this));
						return false;});
                        	}
			}
			
			if (event.keyCode != 40 && event.keyCode != 38 && etext.length != 0){
				counter = 0;
	                        addTextItem(etext);
	                        if (options.json_url) {
					if (options.json_cache && json_cache){
						addMemebers(etext);
		                                bindEvents(); 
		                        }
					else{						
						url = options.json_url + "?tag=" + etext + "&filter=" + search_string;		                 
		                                $.getJSON( url,
		                                		    null,
                                				    function(data){
									addMemebers(etext, data);
									json_cache = true;
									bindEvents(); 
								    });
					}
                        	}
                        	else{
                            		addMemebers(etext);
					bindEvents();
				}
	
	                        complete.children(".default").hide();
	                        feed.show();
                    	}
		});
		       
                if (focusme) {
			setTimeout(function() {
                        				input.focus();
                        				complete.children(".default").show();
                        		      }, 1);
                }
            }
            
	    function itemInCache(val){
	    	
	    }
	    
            function addMemebers(etext, data) {
		feed.html('');				
                if (data != null && data.length) {
			$.each( data, 
				     function(i, val) {
				     	// Add by ZG, to judge whether this value has been saved in cache. 
				     	var bValueInCache = false;
				     	$.each(cache, function(j, o){				     		
	    					if(o.caption == val.caption){
	    						bValueInCache = true;
	    						return false
	    					}
	    				});    				
	    				
	    				if( bValueInCache ){
	    					// This value has been saved in cache, so do nothing.
	    				}
	    				else{
				     		cache.push(
							{ caption: val.caption,
						   	   value: val.value
							}
						);
						search_string += "" + (cache.length - 1) + ":" + val.caption + ";";
					}						
                    		    }
                    	);
                }
		
                var maximum = options.maxshownitems < cache.length ? options.maxshownitems: cache.length;
                var filter = "i";

                if (options.filter_case) {
			filter = "";
                }

                var myregexp = eval('/(?:^|;)\\s*(\\d+)\\s*:[^;]*?' + etext + '[^;]*/g' + filter);                
                var match = myregexp.exec(search_string);
                var content = '';	
		
                while (match != null && maximum > 0) {
			var id = match[1];
			var object = cache[id];
			
			// judge whether this value has been set in options 
			ops = element.children("option");
			var j = false ;
			if (ops.length != 0 ){
				$.each(ops, function(){
					if($(this).attr("value") == object.value && $(this).hasClass("selected"))
					{
						j = true ;
						return false;
					}
				});
			};			
			
			/*
			if ( options.filter_selected 
			        && element.children("option[value=" + object.value + "]").hasClass("selected"))
			{
				//nothing here...
			}
			*/
			
			if ( options.filter_selected && j)
			{
				//nothing here...
			}
			else{
				content += '<li rel="' + object.value + '">' + itemIllumination(object.caption, etext) + '</li>';
				counter++;
				maximum--;
			}
                    	match = myregexp.exec(search_string);
                }

                feed.append(content);
                if (counter > options.height){
			feed.css(
				{"height": (options.height * 24) + "px",
                        	  "overflow": "auto"
                    		}
                    	);
                }
                else{
			feed.css("height", "auto");
                }
            
            }

            function itemIllumination(text, etext)

            {

                if (options.filter_case)

                {

                    eval("var text = text.replace(/(.*)(" + etext + ")(.*)/gi,'$1<em>$2</em>$3');");

                }

                else

                {

                    eval("var text = text.replace(/(.*)(" + etext.toLowerCase() + ")(.*)/gi,'$1<em>$2</em>$3');");

                }

                return text;

            }

            function bindFeedEvent()

            {

                feed.children("li").mouseover(

                function()

                {

                    feed.children("li").removeClass("auto-focus");

                    $(this).addClass("auto-focus");

                    focuson = $(this);

                }

                );

                feed.children("li").mouseout(

                function()

                {

                    $(this).removeClass("auto-focus");

                    focuson = null;

                }

                );

            }

            function removeFeedEvent()

            {

                feed.children("li").unbind("mouseover");

                feed.children("li").unbind("mouseout");

                feed.mousemove(

                function()

                {

                    bindFeedEvent();

                    feed.unbind("mousemove");

                }

                );

            }

            function bindEvents()

            {

                var maininput = $("#" + elemid + "_annoninput").children(".maininput");

                bindFeedEvent();

                feed.children("li").unbind("click");

                feed.children("li").click(

                function()

                {

                    var option = $(this);

                    addItem(option.text(), option.attr("rel"));

                    feed.hide();

                    complete.hide();

                }

                );                

                maininput.unbind("keydown");

                maininput.keydown(

                function(event)

                {		
			
                    if (event.keyCode != 8)

                    {

                        holder.children("li.bit-box.deleted").removeClass("deleted");

                    }

                    if (event.keyCode == 13 && focuson != null)

                    {

                        var option = focuson;

                        addItem(option.text(), option.attr("rel"));

                        complete.hide();

                        event.preventDefault();

                        focuson = null;

                        return false;

                    }

                    if (event.keyCode == 13 && focuson == null)

                    {                    	
                    	
                        if (options.newel)

                        {
			    
                            var value = $(this).val();

                            addItem(value, value);

                            complete.hide();

                            event.preventDefault();

                            focuson = null;

                        }

                        return false;         

                    }

                    if (event.keyCode == 40)

                    {

                        removeFeedEvent();

                        if (focuson == null || focuson.length == 0)

                        {

                            focuson = feed.children("li:visible:first");

                            feed.get(0).scrollTop = 0;

                        }

                        else

                        {

                            focuson.removeClass("auto-focus");

                            focuson = focuson.nextAll("li:visible:first");

                            var prev = parseInt(focuson.prevAll("li:visible").length, 10);

                            var next = parseInt(focuson.nextAll("li:visible").length, 10);

                            if ((prev > Math.round(options.height / 2) || next <= Math.round(options.height / 2)) && typeof(focuson.get(0)) != "undefined")

                            {

                                feed.get(0).scrollTop = parseInt(focuson.get(0).scrollHeight, 10) * (prev - Math.round(options.height / 2));

                            }

                        }

                        feed.children("li").removeClass("auto-focus");

                        focuson.addClass("auto-focus");

                    }

                    if (event.keyCode == 38)

                    {

                        removeFeedEvent();

                        if (focuson == null || focuson.length == 0)

                        {

                            focuson = feed.children("li:visible:last");

                            feed.get(0).scrollTop = parseInt(focuson.get(0).scrollHeight, 10) * (parseInt(feed.children("li:visible").length, 10) - Math.round(options.height / 2));

                        }

                        else

                        {

                            focuson.removeClass("auto-focus");

                            focuson = focuson.prevAll("li:visible:first");

                            var prev = parseInt(focuson.prevAll("li:visible").length, 10);

                            var next = parseInt(focuson.nextAll("li:visible").length, 10);

                            if ((next > Math.round(options.height / 2) || prev <= Math.round(options.height / 2)) && typeof(focuson.get(0)) != "undefined")

                            {

                                feed.get(0).scrollTop = parseInt(focuson.get(0).scrollHeight, 10) * (prev - Math.round(options.height / 2));

                            }

                        }

                        feed.children("li").removeClass("auto-focus");

                        focuson.addClass("auto-focus");

                    }

                }

                );           
                
            }

            function addTextItem(value)

            {

                if (options.newel)

                {

                    feed.children("li[fckb=1]").remove();

                    if (value.length == 0)

                    {

                        return;

                    }

                    var li = $(document.createElement("li"));

                    li.attr({
                        "rel": value,
                        "fckb": "1"
                    }).html(value);

                    feed.prepend(li);

                    counter++;

                } else {

                    return;

                }

            }

            function funCall(func, item)

            {

                var _object = "";

                for (i = 0; i < item.get(0).attributes.length; i++)

                {

                    if (item.get(0).attributes[i].nodeValue != null)

                    {

                        _object += "\"_" + item.get(0).attributes[i].nodeName + "\": \"" + item.get(0).attributes[i].nodeValue + "\",";

                    }

                }

                _object = "{" + _object + " notinuse: 0}";

                eval(func + "(" + _object + ")");

            }

            var options = $.extend({

                json_url: null,

                json_cache: false,

                height: "10",

                newel: false,

                filter_case: false,

                filter_hide: false,

                complete_text: "Start to type...",

                maxshownitems: 30,

                onselect: "",

                onremove: ""

            },
            opt);

            //system variables
            var holder = null;

            var feed = null;

            var complete = null;

            var counter = 0;

            var cache = new Array();

            var json_cache = false;

            var search_string = "";

            var focuson = null;

            var element = $(this);

            var elemid = element.attr("id");

            init();

            return this;

        });

    };

}

);