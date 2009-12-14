/*******************************************************
A Class for  importing and removing mootools' Assets.
********************************************************/

var AssetsManager = new Class({
    
    initialize: function (){ 
    	this.imported = {};
    },
    
    /********************************************************************
    Import a outside asset file such as css or js file.
    Do some prepare works before really importing this file, then call 
    this._importAsset to import this file.
    Parameters:
    	object: a javascript object, 
    			  {'app':..., 'lib':..., 'id':..., 'name':..., 'type':..., 
    			   'options':...}
    *********************************************************************/
    import: function(object){    
     	var app=object['app'],lib=object['lib']; 
		var tagId=object['id'], name=object['name'];
		var fileType=object['type'], options=object['options'];     	
     	
     	// get the context of the file to be imported, the context
     	// means a pointer to this.imported[appName][libName] of this file 
    	lib = this.getContext(app,lib);
    	
    	this._importAsset(fileType, name, tagId, options);
    	
    	lib[tagId] = {'type':fileType, 'name':name};
    },
    
    /**********************************************************************
    Inner import function which really imports a outside asset file, the 
    file maybe a css, js or image file.    
    parameters:
    	type: the type of this import file,it could
    			be 'css','js' or 'image';
    	name: the file name, including its path 
    			information;
    	id: the id of this imported tag;
    	options: a json object for mootools Assets module.
    **********************************************************************/
    _importAsset: function(type, name, id, options){
    	if( !$defined(options['id']) ){
 			options['id'] = id;
 		};
 		
    	switch(type){
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
    
    getContext: function(app,lib){
    	if($defined(this.imported[app])){    		
			app = this.imported[app];			    		
    	}
    	else{
    		app = this.imported['anyapp'];
    	};
    	
    	if($defined(app[lib])){    		
			lib = app[lib];			    		
    	}
    	else{
    		lib = app['anylib'];
    	};
    	return lib
    },
    
    remove: function(name,type){
    	var app,lib,tagId;
    	    	
    	switch(type){
    	
    		case 'app':
    			for (lib in this.imported[name]){
    				for ( tagId in this.imported[name][lib] ){
    					this._rmeoveAsset(tagId);
    				}
    			}
    			this.imported[name] = null;
    			break
    			
    		case 'lib':
    			var libCheck = false;
    			
    			for app in this.imported){    			
    				for (lib in this.imported[app]){
    					if (lib == name){
    						libCheck = true;
    						for( tagId in this.imported[app][lib] ){this._removeAsset(tagId);};
    						this.imported[app][lib] = null;
    						break;
    					}
    				};
    				
    				if(libCheck){ break; };
    			}
    			
    			break
    			
    		case 'file':
    			var fileCheck = false;
    			for (app in this.imported){
    				for (lib in this.imported[app]){
    					for (tagId in this.imported[app][lib]){
    						if( tagId==name || this.imported[app][lib][tagId]['name']==name ){
    							fileCheck = true;
    							this._removeAsset(tagId);
    							this.imported[app][lib][tagId] = null;
    							break;
    						};    						
    					}
    					if(fileCheck){break;};
    				}
    				if(fileCheck){break;};
    			}
    			break
    			
    		default:;
    	}
    	
    },
    
    _removeAsset: function(id){
    	$(id).dispose();
    },
    
    filter: function(appName){
    	alert('This function has not been implemented!');
    }
    
});