/*******************************************************
A Class for  importing and removing mootools' Assets.
********************************************************/

var AssetsManager = new Class({
    
    initialize: function (){ 
    	this.imported = $H();    	
    },

    /********************************************************************
    Import a outside asset file such as css or js file.
    Do some prepare works before really importing this file, then call 
    this._importAsset to import this file.
    Parameters:
    	id: the Dom id for this imported tag
    	object: a javascript object, 
    			  {'app':..., 'lib':..., 'url':..., 'type':... }
    	options: the options or properties for mootoools.Assets import function
    *********************************************************************/
    //import: function(obj, options){ }
    _import: function(obj, options){
    	if(!$defined(options)) options={}; 
    	
    	var elId = options['id'];
    	    	
    	if(!$defined(elId)) 
			options['id'] = elId = obj['url'];    		 
    	
    	if(this.imported.getKeys().contains(elId)) return;
    	
    	// store the information of this file to be imported     	
		this.imported.set(elId, $H(obj));
		
    	// import this file 
    	this._importAsset(elId, options);
    },
    
    /**********************************************************************
    Inner import function which really imports a outside asset file, the 
    file maybe a css, js or image file.    
    parameters:
    	elId: the id of this imported tag;
    	options: a json object for mootools Assets module.
    **********************************************************************/
    _importAsset: function(elId, options){
    	var props = this.imported.get(elId);    	
    	// the type of this import file,it could be 'css','js' or 'image'
    	var fileType = props.get('type');    	
    	// the file name, including its path information
    	var name = props.get('url');  		

    	switch(fileType){
    	case 'css':
    		new Asset.css(name, options);
    		break;
    	case 'js':    		
    		new Asset.javascript(name, options);    			
    		break;
    	case 'image':
    		new Asset.image(name, options);
    		break; 
    	}
    	 		
    },
    
    /***********************************************************************
    Remove the imported tag by giving 'name' value.
    Parameters:
    	name: the value to search and the corresponding tag should be removed
    	type: the type of name, maybe 'id','app','lib','url' 
    ************************************************************************/
    remove: function(name, type){  	
    	
    	if(['app','lib'].contains(type)){
    		this._removeByTag(type,name,false);
    	}
    	else if (type=='id'){    		
    		if(this.imported.getKeys().contains(name)){
    			this._removeAsset(name);
    		}
    	}
    	else{	// type is 'url'
    		// filter the matched item 
	    	var toRemoved = this.imported.filter(function(item, index){
	    		return item.get(type)==name
	    	});
	    	
	    	toRemoved.each(function(value,key){	    		
	    		this._removeAsset(key);
	    	}, this );
    	};
    	
    },
    
    /*********************************************************************
    Private function
    Filter the target item from this.imported by giving tag and vlaue.
    Parameters:
    	tag: the target tag name of each item, maybe 'app','lib','url';
    	value: the target value of the tag in each item of this.imported;
    	inverse: a boolean value, 'false' means removed the item and 'true' 
    			   means a inverse action; 'true' option has been used in 
    			   this.filterApp function.
    			   default value is 'false'
    **********************************************************************/
    _removeByTag: function(tag,value, inverse){    	
    	this.imported.map(function(item, key){
    		var condition = (item.get(tag)==value); 
    		//alert('is tag? '+condition+',to be removed?' + (!inverse && condition));
 			if((!inverse && condition) || ( inverse && !condition)){ 				
 				this._removeAsset(key); 					
 			};
 		}, this);
    },
    
    _removeAsset: function(elId){
    	if($defined($(elId))){
    		//alert('asset to be removed,its id is'+id);
	    	$(elId).dispose();
	    	this.imported.erase(elId);
    	}
    },
    
    // remove all the imported assets 
    removeAll: function(){
    	this.imported.getKeys().each(function(key){
    		if($defined($(key))){    			    			
	    		$(key).dispose();
	    	};    		
    		this.imported.erase(key);
    	}.bind(this));
    },
    
    /***************************************************************
    Search the giving application name, only this application imported
	 files could be existed, ohters will be removed.
    Parameters:
    	name: the name of a application   
    ****************************************************************/
    filterApp: function(name){
    	this._removeByTag('app',name, true);
    }
});
