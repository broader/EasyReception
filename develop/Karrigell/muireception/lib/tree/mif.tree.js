/*
---
 
name: Mif.Tree
description: Mif.Tree base Class
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: 
  - core:1.2.4:*
  - more:/Fx.Scroll
provides: Mif.Tree
 
...
*/

if(!Mif) var Mif = {};
if(!Mif.ids) Mif.ids = {};
if(!Mif.id) Mif.id = function(id){
	return Mif.ids[id];
}

Mif.Tree = new Class({
	
	version: '1.2.6',

	Implements: [new Events, new Options],
		
	options:{
		types: {},
		forest: false,
		animateScroll: true,
		height: 18,
		expandTo: true,
		selectable: ['input']
	},
	
	initialize: function(options){
		this.setOptions(options);
		$extend(this, {
			types: this.options.types,
			forest: this.options.forest,
			animateScroll: this.options.animateScroll,
			dfltType: this.options.dfltType,
			height: this.options.height,
			container: $(options.container),
			UID: ++Mif.Tree.UID,
			key: {},
			expanded: []
		});
		this.defaults = {
			name: '',
			cls: '',
			openIcon: 'mif-tree-empty-icon',
			closeIcon: 'mif-tree-empty-icon',
			loadable: false,
			hidden: false
		};
		this.dfltState = {
			open: false
		};
		this.$index = [];
		this.updateOpenState();
		if(this.options.expandTo) this.initExpandTo();
		this.DOMidPrefix='mif-tree-';
		this.wrapper = new Element('div').addClass('mif-tree-wrapper').injectInside(this.container);
		this.initEvents();
		this.initScroll();
		this.initSelection();
		this.initHover();
		this.addEvent('drawChildren', function(parent){
			var nodes = parent._toggle||[];
			for(var i = 0, l = nodes.length; i < l; i++){
				nodes[i].drawToggle();
			}
			parent._toggle = [];
		});
		var id = this.options.id;
		this.id = id;
		if(id != null) Mif.ids[id] = this;
		if (MooTools.version >= '1.2.2' && this.options.initialize) this.options.initialize.call(this);
	},
	
	initEvents: function(){
		this.wrapper.addEvents({
			mousemove: this.mouse.bindWithEvent(this),
			mouseover: this.mouse.bindWithEvent(this),
			mouseout: this.mouse.bindWithEvent(this),
			mouseleave: this.mouseleave.bind(this),
			mousedown: function(event){
				if(event.which != 1) return;
				this.fireEvent('mousedown');
				return this.stopSelection(event);
			}.bind(this),
			click: this.toggleClick.bindWithEvent(this),
			dblclick: this.toggleDblclick.bindWithEvent(this)
		});
		if(Browser.Engine.trident){
			this.wrapper.addEvent('selectstart', this.stopSelection.bind(this));
		}        
		this.container.addEvent('click', this.focus.bind(this));
		document.addEvent('click', this.blurOnClick.bind(this));
		document.addEvents({
			keydown: this.keyDown.bindWithEvent(this),
			keyup: this.keyUp.bindWithEvent(this)
		});
    },
	
	stopSelection: function(event){
		var target = $(event.target);
		var selectable = this.options.selectable;
		for(var i = 0, l = selectable.length; i < l; i++){
			if(target.match(selectable[i])) return true;
		}
		return false;
	},
    
	blurOnClick: function(event){
		var target = event.target;
		while(target){
			if(target == this.container) return;
			target = target.parentNode;
		}
		this.blur();
	},
    
	focus: function(){
		if(Mif.Focus && Mif.Focus == this) return this;
		if(Mif.Focus) Mif.Focus.blur();
		Mif.Focus = this;
		this.focused = true;
		this.container.addClass('mif-tree-focused');
		return this.fireEvent('focus');
	},
    
	blur: function(){
		Mif.Focus = null;
		if(!this.focused) return this;
		this.focused = false;
		this.container.removeClass('mif-tree-focused');
		return this.fireEvent('blur');
	},
	
	$getIndex: function(){//return array of visible nodes.
		this.$index = [];
		var node = this.forest ? this.root.getFirst() : this.root;
		var previous = node;
		while(node){
			if(!(previous.hidden && previous.contains(node))){
				if(!node.hidden) this.$index.push(node);
				previous = node;
			}
			node = node._getNextVisible();
		}
	},
	
	mouseleave: function(){
		this.mouse.coords = {x:null,y:null};
		this.mouse.target = false;
		this.mouse.node = false;
		if(this.hover) this.hover();
	},
	
	mouse: function(event){
		this.mouse.coords = this.getCoords(event);
		var target = this.getTarget(event);
		this.mouse.target = target.target;
		this.mouse.node	= target.node;
	},
	
	getTarget: function(event){
		var target = event.target, node;
		while(!/mif-tree/.test(target.className)){
			target = target.parentNode;
		}
		var test = target.className.match(/mif-tree-(gadjet)-[^n]|mif-tree-(icon)|mif-tree-(name)|mif-tree-(checkbox)/);
		if(!test){
			var y = this.mouse.coords.y;
			if(y == -1||!this.$index) {
				node = false;
			}else{
				node = this.$index[((y)/this.height).toInt()];
			}
			return {
				node: node,
				target: 'node'
			};
		}
		for(var i = 5; i > 0; i--){
			if(test[i]){
				var type = test[i];
				break;
			}
		}
		return {
			node: Mif.Tree.Nodes[target.getAttribute('uid')],
			target: type
		};
	},
	
	getCoords: function(event){
		var position = this.wrapper.getPosition();
		var x = event.page.x-position.x;
		var y = event.page.y-position.y;
		var wrapper = this.wrapper;
		if((y-wrapper.scrollTop > wrapper.clientHeight)||(x - wrapper.scrollLeft > wrapper.clientWidth)){//scroll line
			y = -1;
		};
		return {x: x, y: y};
	},
	
	keyDown: function(event){
		this.key = event;
		this.key.state = 'down';
		if(this.focused) this.fireEvent('keydown', [event]);
	},
	
	keyUp: function(event){
		this.key = {};
		this.key.state = 'up';
		if(this.focused) this.fireEvent('keyup', [event]);
	},
	
	toggleDblclick: function(event){
		var target = this.mouse.target;
		if(!(target == 'name'||target == 'icon')) return;
		this.mouse.node.toggle();
	},
	
	toggleClick: function(event){
		if(this.mouse.target != 'gadjet') return;
		this.mouse.node.toggle();
	},
	
	initScroll: function(){
		this.scroll = new Fx.Scroll(this.wrapper, {link: 'cancel'});
	},
	
	scrollTo: function(node){
		var position = node.getVisiblePosition();
		var top = position*this.height;
		var up = (top < this.wrapper.scrollTop);
		var down = (top > (this.wrapper.scrollTop+this.wrapper.clientHeight-this.height));
		if(position == -1 || ( !up && !down ) ) {
			this.scroll.fireEvent('complete');
			return false;
		}
		if(this.animateScroll){
			this.scroll.start(this.wrapper.scrollLeft, top - (down ? this.wrapper.clientHeight - this.height : this.height));
		}else{
			this.scroll.set(this.wrapper.scrollLeft, top - (down ? this.wrapper.clientHeight - this.height : this.height));
			this.scroll.fireEvent('complete');
		}
	},
	
	updateOpenState: function(){
		this.addEvents({
			'drawChildren': function(parent){
				var children = parent.children;
				for(var i = 0, l = children.length; i < l; i++){
					children[i].updateOpenState();
				}
			},
			'drawRoot': function(){
				this.root.updateOpenState();
			}
		});
	},
	
	expandTo: function(node){
		if (!node) return this;
		var path = [];
		while( !node.isRoot() && !(this.forest && node.getParent().isRoot()) ){
			node = node.getParent();
			if(!node) break;
			path.unshift(node);
		};
		path.each(function(el){
			el.toggle(true)
		});
		return this;
	},
	
	initExpandTo: function(){
		this.addEvent('loadChildren', function(parent){
			if(!parent) return;
			var children = parent.children;
			for( var i = children.length; i--; ){
				var child = children[i];
				if(child.expandTo) this.expanded.push(child);
			}
		});
		function expand(){
			this.expanded.each(function(node){
				this.expandTo(node);
			}, this);
			this.expanded = [];
		};
		this.addEvents({
			'load': expand.bind(this),
			'loadNode': expand.bind(this)
		});
	}
	
});
Mif.Tree.UID = 0;

Array.implement({
	
	inject: function(added, current, where){//inject added after or before current;
		var pos = this.indexOf(current)+(where=='before' ? 0 : 1);
		for(var i = this.length-1; i >= pos; i--){
			this[i+1] = this[i];
		}
		this[pos] = added;
		return this;
	}
	
});


/*
---
 
name: Mif.Tree.Node
description: Mif.Tree.Node
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: Mif.Tree
provides: Mif.Tree.Node
 
...
*/

Mif.Tree.Node = new Class({

	Implements: [Events],
	
	initialize: function(structure, options) {
		$extend(this, structure);
		this.children = [];
		this.type = options.type || this.tree.dfltType;
		this.property = options.property || {};
		this.data = options.data;
		this.state = $extend($unlink(this.tree.dfltState), options.state);
		this.$calculate();
		this.UID = Mif.Tree.Node.UID++;
		Mif.Tree.Nodes[this.UID] = this;
		var id = this.id;
		if(id != null) Mif.ids[id] = this;
		this.tree.fireEvent('nodeCreate', [this]);
		this._property = ['id', 'name', 'cls', 'openIcon', 'closeIcon', 'openIconUrl', 'closeIconUrl', 'hidden'];
	},
	
	$calculate: function(){
		$extend(this, $unlink(this.tree.defaults));
		this.type = $splat(this.type);
		this.type.each(function(type){
			var props = this.tree.types[type];
			if(props) $extend(this, props);
		}, this);
		$extend(this, this.property);
		return this;
	},
	
	getDOM: function(what){
		var node = $(this.tree.DOMidPrefix+this.UID);
		if(what == 'node') return node;
		var wrapper = node.getFirst();
		if(what == 'wrapper') return wrapper;
		if(what == 'children') return wrapper.getNext();
		return wrapper.getElement('.mif-tree-'+what);
	},
	
	getGadjetType: function(){
		return (this.loadable && !this.isLoaded()) ? 'plus' : (this.hasVisibleChildren() ? (this.isOpen() ? 'minus' : 'plus') : 'none');
	},
	
	toggle: function(state) {
		if(this.state.open == state || this.$loading || this.$toggling) return this;
		var parent = this.getParent();
		function toggle(type){
			this.state.open = !this.state.open;
			if(type == 'drawed'){
				this.drawToggle();
			}else{
				parent._toggle = (parent._toggle||[])[this.state.open ? 'include' : 'erase'](this)
			}
			this.fireEvent('toggle', [this.state.open]);
			this.tree.fireEvent('toggle', [this, this.state.open]);
			return this;
		}
		if(parent && !parent.$draw){
			return toggle.apply(this, []);
		}
		if(this.loadable && !this.state.loaded) {
            if(!this.load_event){
                this.load_event = true;
                this.addEvent('load',function(){
                    this.toggle();
                }.bind(this));
            }
            return this.load();
        }
		if(!this.hasChildren()) return this;
		return toggle.apply(this, ['drawed']);
	},
	
	drawToggle: function(){
		this.tree.$getIndex();
		Mif.Tree.Draw.update(this);
	},
	
	recursive: function(fn, args){
		args=$splat(args);
		if(fn.apply(this, args) !== false){
			this.children.each(function(node){
				if(node.recursive(fn, args) === false){
					return false;
				}
			});
		}
		return this;
	},
	
	isOpen: function(){
		return this.state.open;
	},
	
	isLoaded: function(){
		return this.state.loaded;
	},
	
	isLast: function(){
		if(this.parentNode == null || this.parentNode.children.getLast() == this) return true;
		return false;
	},
	
	isFirst: function(){
		if(this.parentNode == null || this.parentNode.children[0] == this) return true;
		return false;
	},
	
	isRoot: function(){
		return this.parentNode == null ? true : false;
	},
	
	getChildren: function(){
		return this.children;
	},
	
	hasChildren: function(){
		return this.children.length ? true : false;
	},
	
	index: function(){
		if( this.isRoot() ) return 0;
		return this.parentNode.children.indexOf(this);
	},
	
	getNext: function(){
		if(this.isLast()) return null;
		return this.parentNode.children[this.index()+1];
	},
	
	getPrevious: function(){
		if( this.isFirst() ) return null;
		return this.parentNode.children[this.index()-1];
	},
	
	getFirst: function(){
		if(!this.hasChildren()) return null;
		return this.children[0];
	},
	
	getLast: function(){
		if(!this.hasChildren()) return null;
		return this.children.getLast();		
	},
	
	getParent: function(){
		return this.parentNode;
	},
	
	_getNextVisible: function(){
		var current=this;
		if(current.isRoot()){
			if(!current.isOpen() || !current.hasChildren(true)) return false;
			return current.getFirst(true);
		}else{
			if(current.isOpen() && current.getFirst(true)){
				return current.getFirst(true);
			}else{
				var parent = current;
				do{
					current = parent.getNext(true);
					if(current) return current;
				}while( parent = parent.parentNode );
				return false;
			}
		}
	},
	
	getPreviousVisible: function(){
		var index = this.tree.$index.indexOf(this);
		return index == 0 ? null : this.tree.$index[index-1];
	},
	
	getNextVisible: function(){
		var index = this.tree.$index.indexOf(this);
		return index < this.tree.$index.length-1 ? this.tree.$index[index+1] : null;
	},
	
	getVisiblePosition: function(){
		return this.tree.$index.indexOf(this);
	},
	
	hasVisibleChildren: function(){
		if(!this.hasChildren()) return false;
		if(this.isOpen()){
			var next = this.getNextVisible();
			if(!next) return false;
			if(next.parentNode != this) return false;
			return true;
		}else{
			var child = this.getFirst();
			while(child){
				if(!child.hidden) return true;
				child = child.getNext();
			}
			return false;
		}
	},
	
	isLastVisible: function(){
		var next = this.getNext();
		while(next){
			if(!next.hidden) return false;
			next = next.getNext();
		};
		return true;
	},
		
	contains: function(node){
		while(node){
			if(node == this) return true;
			node = node.parentNode;
		};
		return false;
	},

	addType: function(type){
		return this.processType(type, 'add');
	},

	removeType: function(type){
		return this.processType(type, 'remove');
	},
	
	setType: function(type){
		return this.processType(type, 'set');
	},
	
	processType: function(type, action){
		switch(action){
			case 'add': this.type.include(type); break;
			case 'remove': this.type.erase(type); break;
			case 'set': this.type = type; break;
		}
		var current = {};
		this._property.each(function(p){
			current[p] = this[p];
		}, this);
		this.$calculate();
		this._property.each(function(p){
			this.updateProperty(p, current[p], this[p]);
		}, this);
		return this;
	},
	
	set: function(obj){
		this.tree.fireEvent('beforeSet', [this, obj]);
		var property = obj.property||obj||{};
		for(var p in property){
			var nv = property[p];
			var cv = this[p];
			this.updateProperty(p, cv, nv);
			this[p] = this.property[p] = nv;
		}
		this.tree.fireEvent('set', [this, obj]);
		return this;
	},
	
	updateProperty: function(p, cv, nv){
		if(nv == cv) return this;
		if(p == 'id'){
			delete Mif.ids[cv];
			if(nv) Mif.ids[nv]=this;
			return this;
		}
		if(!Mif.Tree.Draw.isUpdatable(this)) return this;
		switch(p){
			case 'name':
				this.getDOM('name').set('html', nv);
				return this;
			case 'cls':
				this.getDOM('wrapper').removeClass(cv).addClass(nv);
				return this;
			case 'openIcon':
			case 'closeIcon':
				this.getDOM('icon').removeClass(cv).addClass(nv);
				return this;
			case 'openIconUrl':
			case 'closeIconUrl':
				var icon = this.getDOM('icon');
				icon.setStyle('background-image', 'none');
				if(nv) icon.setStyle('background-image', 'url('+nv+')');
				return this;
			case 'hidden':
				this.getDOM('node').setStyle('display', nv ? 'none' : 'block');
				var _previous = this.getPreviousVisible();
				var _next = this.getNextVisible();
				var parent = this.getParent();
				this[p] = this.property[p]=nv;
				this.tree.$getIndex();
				var previous = this.getPreviousVisible();
				var next = this.getNextVisible();
				[_previous, _next, previous, next, parent, this].each(function(node){
					Mif.Tree.Draw.update(node);
				});
				return this;
		}
	},
	
	updateOpenState: function(){
		if(this.state.open){
			this.state.open = false;
			this.toggle();
		}
	}
	
});

Mif.Tree.Node.UID = 0;
Mif.Tree.Nodes = {};

/*
---
 
name: Mif.Tree.Draw
description: convert javascript tree object to html
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: Mif.Tree
provides: Mif.Tree.Draw
 
...
*/

Mif.Tree.Draw = {

	getHTML: function(node,html){
		var prefix = node.tree.DOMidPrefix;
		if($defined(node.state.checked)){
			if(!node.hasCheckbox) node.state.checked='nochecked';
			var checkbox = '<span class="mif-tree-checkbox mif-tree-node-'+node.state.checked+'" uid="'+node.UID+'">'+Mif.Tree.Draw.zeroSpace+'</span>';
		}else{
			var checkbox = '';
		}
		html = html||[];
		html.push(
		'<div class="mif-tree-node ',(node.isLast() ? 'mif-tree-node-last' : ''),'"'+(node.hidden ? ' style="display:none"' : '')+' id="',prefix,node.UID,'">',
			'<span class="mif-tree-node-wrapper ',node.cls,(node.state.selected ? ' mif-tree-node-selected' : ''),'" uid="',node.UID,'">',
				'<span class="mif-tree-gadjet mif-tree-gadjet-',node.getGadjetType(),'" uid="',node.UID,'">',Mif.Tree.Draw.zeroSpace,'</span>',
				checkbox,
				'<span class="mif-tree-icon ',(node.closeIconUrl?'" style="background-image: url('+node.closeIconUrl+')" ': node.closeIcon+'"'),' uid="',node.UID,'">',Mif.Tree.Draw.zeroSpace,'</span>',
				'<span class="mif-tree-name" uid="',node.UID,'">',node.name,'</span>',
			'</span>',
			'<div class="mif-tree-children" style="display:none"></div>',
		'</div>'
		);
		return html;
	},
	
	children: function(parent, container){
		parent.open = true;
		parent.$draw = true;
		var html = [];
		var children = parent.children;
		for(var i = 0, l = children.length; i < l; i++){
			this.getHTML(children[i], html);
		}
		container = container || parent.getDOM('children');
		container.set('html', html.join(''));
		parent.tree.fireEvent('drawChildren',[parent]);
	},
	
	root: function(tree){
		var domRoot = this.node(tree.root);
		domRoot.inject(tree.wrapper);
		tree.$draw = true;
		tree.fireEvent('drawRoot');
	},
	
	forestRoot: function(tree){
		var container = new Element('div').addClass('mif-tree-children-root').injectInside(tree.wrapper);
		Mif.Tree.Draw.children(tree.root, container);
	},
	
	node: function(node){
		return new Element('div').set('html', this.getHTML(node).join('')).getFirst();
	},
	
	isUpdatable: function(node){
		if(
			(!node||!node.tree) ||
			(node.getParent() && !node.getParent().$draw) || 
			(node.isRoot() && (!node.tree.$draw||node.tree.forest)) 
		) return false;
		return true;
	},
	
	update: function(node){
		if(!this.isUpdatable(node)) return;
		if(!node.hasChildren()) node.state.open=false;
		node.getDOM('gadjet').className = 'mif-tree-gadjet mif-tree-gadjet-'+node.getGadjetType();
		if (node.closeIconUrl) {
			node.getDOM('icon').setStyle('background-image', 'url('+(node.isOpen() ? node.openIconUrl : node.closeIconUrl)+')');
		} else {
			node.getDOM('icon').className='mif-tree-icon '+node[node.isOpen() ? 'openIcon' : 'closeIcon'];
		}
		node.getDOM('node')[(node.isLastVisible() ?'add' : 'remove')+'Class']('mif-tree-node-last');
		if(node.$loading) return;
		var children = node.getDOM('children');
		if(node.isOpen()){
			if(!node.$draw) Mif.Tree.Draw.children(node);
			children.style.display = 'block';
		}else{
			children.style.display = 'none';
		}
		node.tree.fireEvent('updateNode', node);
		return node;
	},
	
	inject: function(node, element){
		if(!this.isUpdatable(node)) return;
		element = element || node.getDOM('node') || this.node(node);
		var previous = node.getPrevious();
		if(previous){
			element.injectAfter(previous.getDOM('node'));
			return;
		}
		var container;
		if(node.tree.forest && node.parentNode.isRoot()){
			container = node.tree.wrapper.getElement('.mif-tree-children-root');
		}else if(node.tree.root == node){
			container = node.tree.wrapper;
		}else{
			container = node.parentNode.getDOM('children');
		}
		element.inject(container, 'top');
	}
	
};

Mif.Tree.Draw.zeroSpace = Browser.Engine.trident ? '&shy;' : (Browser.Engine.webkit ? '&#8203' : '');



/*
---
 
name: Mif.Tree.Selection
description: tree nodes selection
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: Mif.Tree
provides: Mif.Tree.Selection
 
...
*/

Mif.Tree.implement({
	
	initSelection: function(){
		this.defaults.selectClass = '';
		this.wrapper.addEvent('mousedown', this.attachSelect.bindWithEvent(this));
	},
	
	attachSelect: function(event){
		if(!['icon', 'name', 'node'].contains(this.mouse.target)) return;
		var node = this.mouse.node;
		if(!node) return;
		this.select(node);
	},
	
	select: function(node) {
		if(!node) return this;
		var current = this.selected;
		if (current == node) return this;
		if (current) {
			current.select(false);
			this.fireEvent('unSelect', [current]).fireEvent('selectChange', [current, false]);
		}
		this.selected = node;
		node.select(true);
		this.fireEvent('select', [node]).fireEvent('selectChange', [node, true]);
		return this;
	},
	
	unselect: function(){
		var current = this.selected;
		if(!current) return this;
		this.selected = false;
		current.select(false);
		this.fireEvent('unSelect', [current]).fireEvent('selectChange', [current, false]);
		return this;
	},
	
	getSelected: function(){
		return this.selected;
	},
	
	isSelected: function(node){
		return node.isSelected();
	}
	
});

Mif.Tree.Node.implement({
		
	select: function(state) {
		this.state.selected = state;
		if(!Mif.Tree.Draw.isUpdatable(this)) return;
		var wrapper=this.getDOM('wrapper');
		wrapper[(state ? 'add' : 'remove')+'Class'](this.selectClass||'mif-tree-node-selected');
	},
	
	isSelected: function(){
		return this.state.selected;
	}
	
});


/*
---
 
name: Mif.Tree.Hover
description: hover(mouseover/mouseout) events/effects
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: Mif.Tree
provides: Mif.Tree.Hover
 
...
*/

Mif.Tree.implement({
	
	initHover: function(){
		this.defaults.hoverClass = '';
		this.wrapper.addEvent('mousemove', this.hover.bind(this));
		this.wrapper.addEvent('mouseout', this.hover.bind(this));
		this.defaultHoverState = {
			gadjet: false,
			checkbox: false,
			icon: false,
			name: false,
			node: false
		};
		this.hoverState = $unlink(this.defaultHoverState);
	},
	
	hover: function(){
		var cnode = this.mouse.node;
		var ctarget = this.mouse.target;
		$each(this.hoverState, function(node, target, state){
			if(node == cnode && (target == 'node'||target==ctarget)) return;
			if(node) {
				Mif.Tree.Hover.out(node, target);
				state[target] = false;
				this.fireEvent('hover', [node, target, 'out']);
			}
			if(cnode && (target == 'node'||target == ctarget)) {
				Mif.Tree.Hover.over(cnode, target);
				state[target] = cnode;
				this.fireEvent('hover', [cnode, target, 'over']);
			}else{
				state[target] = false;
			}
		}, this);
	},
	
	updateHover: function(){
		this.hoverState = $unlink(this.defaultHoverState);
		this.hover();
	}
	
});

Mif.Tree.Hover = {
	
	over: function(node, target){
		var wrapper = node.getDOM('wrapper');
		wrapper.addClass((node.hoverClass||'mif-tree-hover')+'-'+target);
		if(node.state.selected) wrapper.addClass((node.hoverClass||'mif-tree-hover')+'-selected-'+target);
	},
	
	out: function(node, target){
		var wrapper = node.getDOM('wrapper');
		wrapper.removeClass((node.hoverClass||'mif-tree-hover')+'-'+target).removeClass((node.hoverClass||'mif-tree-hover')+'-selected-'+target);
	}
	
};


/*
---
 
name: Mif.Tree.Load
description: load tree from json
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: Mif.Tree
provides: Mif.Tree.Load
 
...
*/

Mif.Tree.Load = {
		
	children: function(children, parent, tree){
		for( var i = children.length; i--; ){
			var child = children[i];
			var subChildren = child.children;
			var node = new Mif.Tree.Node({
				tree: tree,
				parentNode: parent||undefined
			}, child);
			if( tree.forest || parent != undefined){
				parent.children.unshift(node);
			}else{
				tree.root = node;
			}
			if(subChildren && subChildren.length){
				arguments.callee(subChildren, node, tree);
			}
		}
		if(parent) parent.state.loaded = true;
		tree.fireEvent('loadChildren', parent);
	}
	
};

Mif.Tree.implement({

	load: function(options){
		var tree = this;
		this.loadOptions = this.loadOptions||$lambda({});
		function success(json){
			if(tree.forest){
				tree.root = new Mif.Tree.Node({
					tree: tree,
					parentNode: null
				}, {});
				var parent = tree.root;
			}else{
				var parent = null;
			}
			Mif.Tree.Load.children(json, parent, tree);
			Mif.Tree.Draw[tree.forest ? 'forestRoot' : 'root'](tree);
			tree.$getIndex();
			tree.fireEvent('load');
			return tree;
		}
		options = $extend($extend({
			isSuccess: $lambda(true),
			secure: true,
			onSuccess: success,
			method: 'get'
		}, this.loadOptions()), options);
		if(options.json) return success(options.json);
		new Request.JSON(options).send();
		return this;
	}
	
});

Mif.Tree.Node.implement({
	
	load: function(options){
		this.$loading = true;
		options = options||{};
		this.addType('loader');
		var self = this;
		function success(json){
			Mif.Tree.Load.children(json, self, self.tree);
			delete self.$loading;
			self.state.loaded = true;
			self.removeType('loader');
			Mif.Tree.Draw.update(self);
			self.fireEvent('load');
			self.tree.fireEvent('loadNode', self);
			return self;
		}
		options=$extend($extend($extend({
			isSuccess: $lambda(true),
			secure: true,
			onSuccess: success,
			method: 'get'
		}, this.tree.loadOptions(this)), this.loadOptions), options);
		if(options.json) return success(options.json);
		new Request.JSON(options).send();
		return this;
	}
	
});


/*
---

name: Mif.Tree.Sort
description: Mif.Tree.Sort
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: Mif.Tree
provides: Mif.Tree.Sort

...
*/

Mif.Tree.implement({
	
	initSortable: function(sortFunction){
		this.sortable=true;
		this.sortFunction=sortFunction||function(node1, node2){
			if(node1.name>node2.name){
				return 1;
			}else if(node1.name<node2.name){
				return -1;
			}else{
				return 0;
			}
		};
		this.addEvent('loadChildren', function(parent){
			if(parent) parent.sort();
		});
		this.addEvent('structureChange', function(from, to, where, type){
			from.sort();
		});
		return this;
	}
	
});


Mif.Tree.Node.implement({

	sort: function(sortFunction){
		this.children.sort(sortFunction||this.tree.sortFunction);
		return this;
	}
	
});


/*
---
 
name: Mif.Tree.Checkbox
description: Mif.Tree.Checkbox
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: Mif.Tree
provides: Mif.Tree.Checkbox
 
...
*/

Mif.Tree.implement({

	initCheckbox: function(type){
		this.checkboxType=type||'simple';
		this.dfltState.checked='unchecked';
		this.defaults.hasCheckbox=true;
		this.wrapper.addEvent('click',this.checkboxClick.bind(this));
		if(this.checkboxType=='simple') return;
		this.addEvent('loadChildren', function(node){
			if(!node) return;
			if(node.state.checked=='checked'){
				node.recursive(function(){
					this.state.checked='checked';
				});
			}else{
				node.getFirst().setParentCheckbox(1)
			}
		});

	},
	
	checkboxClick: function(event){
		if(this.mouse.target!='checkbox') {return;}
		this.mouse.node['switch']();
	},
	
	getChecked: function(includePartially){
		var checked=[];
		this.root.recursive(function(){
			var condition = includePartially ? this.state.checked!=='unchecked' : this.state.checked=='checked';
			if(this.hasCheckbox && condition) checked.push(this);
		});
		return checked;
	}

});

Mif.Tree.Node.implement({

	'switch' : function(state){
		if(this.state.checked==state||!this.hasCheckbox) return;
		var type=this.tree.checkboxType;
		var checked=(this.state.checked=='checked') ? 'unchecked' : 'checked';
		if(type=='simple'){
			this.setCheckboxState(checked);
			this.tree.fireEvent(checked=='checked' ? 'check' : 'unCheck', this);
			this.tree.fireEvent('switch', [this, (checked=='checked' ? true : false)]);
			return this;
		};
		this.recursive(function(){
			this.setCheckboxState(checked);
		});
		this.setParentCheckbox();
		this.tree.fireEvent(checked=='checked' ? 'check' : 'unCheck', this);
		this.tree.fireEvent('switch', [this, (checked=='checked' ? true : false)]);
		return this;
	},
	
	setCheckboxState: function(state){
		if(!this.hasCheckbox) return;
		var oldState=this.state.checked;
		this.state.checked=state;
		if((!this.parentNode&&this.tree.$draw) || (this.parentNode && this.parentNode.$draw)){
			this.getDOM('checkbox').removeClass('mif-tree-node-'+oldState).addClass('mif-tree-node-'+state);
		}
	},
	
	setParentCheckbox: function(s){
		if(!this.hasCheckbox || !this.parentNode || (this.tree.forest && !this.parentNode.parentNode)) return;
		var parent=this.parentNode;
		var state='';
		var children=parent.children;
		for(var i=children.length; i--; i>0){
			var child=children[i];
			if(!child.hasCheckbox) continue;
			var childState=child.state.checked;
			if(childState=='partially'){
				state='partially';
				break;
			}else if(childState=='checked'){
				if(state=='unchecked'){
					state='partially';
					break;
				}
				state='checked';
			}else{
				if(state=='checked'){
					state='partially';
					break;
				}else{
					state='unchecked';
				}
			}
		}
		if(parent.state.checked==state ||(s && state=='partially' && parent.state.checked=='checked')){return;};
		parent.setCheckboxState(state);
		parent.setParentCheckbox(s);
	}

});


/*
---
 
name: Mif.Tree.CookieStorage
description: Mif.Tree.Node
license: MIT-Style License (http://mifjs.net/license.txt)
copyright: Anton Samoylov (http://mifjs.net)
authors: Anton Samoylov (http://mifjs.net)
requires: Mif.Tree
provides: Mif.Tree.CookieStorage
 
...
*/

Mif.Tree.CookieStorage = new Class({

	Implements: [Options],
	
	options:{
		store: function(node){
			return node.property.id;
		},
		retrieve: function(value){
			return Mif.id(value);
		},
		event: 'toggle',
		action: 'toggle'
	},

	initialize: function(tree, options){
		this.setOptions(options);
		this.tree = tree;
		this.cookie = new Cookie('mif.tree:' + this.options.event + tree.id||'');
		this.nodes = [];
		this.initSave();
	},
	
	write: function(){
		this.cookie.write(JSON.encode(this.nodes));
	},
	
	read: function(){
		return JSON.decode(this.cookie.read()) || [];
	},
	
	restore: function(data){
		if(!data){
			this.restored = this.restored || this.read();
		}
		var restored = data || this.restored;
		for(var i = 0, l = restored.length; i < l; i++){
			var stored = restored[i];
			var node = this.options.retrieve(stored);
			if(node){
				node[this.options.action](true);
				restored.erase(stored);
				l--;
			}
		}
		return restored;
	},
	
	initSave: function(){
		this.tree.addEvent(this.options.event, function(node, state){
			var value = this.options.store(node);
			if(state){
				this.nodes.include(value);
			}else{
				this.nodes.erase(value);
			}
			this.write();
		}.bind(this));
	}

});


