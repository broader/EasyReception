/*******************************************************
A Class for  importing and removing mootools' Assets.
********************************************************/

var AssetsManager = new Class({
    
    initialize: function (){ 
    	this.imported = new Hash({});
    	alert('AssetsManger library initialized');
    },
    
    /********************************************************************
    Import a outside asset file such as css or js file.
    Do some prepare works before really importing this file, then call 
    this._importAsset to import this file.
    Parameters:
    	id: the Dom id for this imported tag
    	object: a javascript object, 
    			  {'app':..., 'lib':..., 'name':..., 'type':... }
    	options: the options or properties for mootoools.Assets import function
    *********************************************************************/
    import: function(id, object, options){
    	// store the information of this file to be imported     	
		this.imported.set(id, $H(object));    	
    	// import this file 
    	this._importAsset(id, options);
    },
    
    /**********************************************************************
    Inner import function which really imports a outside asset file, the 
    file maybe a css, js or image file.    
    parameters:
    	id: the id of this imported tag;
    	options: a json object for mootools Assets module.
    **********************************************************************/
    _importAsset: function(id, options){
    	var props = this.imported.get(id); 
    	
    	// the type of this import file,it could be 'css','js' or 'image'
    	var filetype = props.get('type');
    	
    	// the file name, including its path information
    	var name = props.get('name'); 
 		
    	switch(fileType){
    		case 'css':
    			new Asset.css(name, options);
    			break
    		case 'js':
    			new Asset.javascript(name, options);    			
    			break
    		case 'image':
    			new Asset.image(name, options);
    			break 
    		default:;	
    	}   		
    },
    
    /***********************************************************************
    Remove the imported tag by giving 'name' value.
    Parameters:
    	name: the value to search and the corresponding tag should be removed
    	type: the type of name, maybe 'id','app','lib','filePath' 
    ************************************************************************/
    remove: function(name, type){
    	
    	if(['app','lib'].contains(type)){
    		this._removeByTag(type,name,true);
    	}
    	else if (type=='id'){
    		if(this.imported.contains(name)){
    			this._removeAsset(name);
    		}
    	}
    	else{	// type is 'filePath'
    		// filter the matched item 
	    	var toRemoved = this.imported.filter(function(item, index){
	    		return item.get(type)==name
	    	});
	    	toRemoved.each(function(item,index){
	    		this._removeAsset(name);
	    	});
    	}
    	
    },
    
    /*********************************************************************
    Private function
    Filter the target item from this.imported by giving tag and vlaue.
    Parameters:
    	tag: the target tag name of each item, maybe 'app','lib','filePath';
    	value: the target value of the tag in each item of this.imported;
    	inverse: a boolean value, 'false' means removed the item and 'true' 
    			   means a inverse action; 'true' option has been used in 
    			   this.filterApp function.
    			   default value is 'false'
    **********************************************************************/
    _removeByTag: function(tag,value, inverse){
    	this.imported.map(function(item, key){
    		var condition = (item.get(tag)==value); 
 			if((!inverse && condition) || ( inverse && !condition){
 				this._removeAsset(key); 					
 			};
 		}, this)
    },
    
    _removeAsset: function(id){
    	if($defined($(id))){
	    	$(id).dispose();
	    	this.imported.erase(key);
    	}
    },
    
    /***************************************************************
    Search the giving application name, only this application imported
	 files could be existed, ohters will be removed.
    Parameters:
    	name: the name of a application   
    ****************************************************************/
    filterApp: function(name){
    	this._removeByTag('app',name, true)
    }
    
});