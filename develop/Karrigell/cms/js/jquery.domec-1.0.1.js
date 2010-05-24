/**
 * jQuery DOMEC (DOM Elements Creator) 1.0.1
 * http://code.google.com/p/jquery-domec
 *
 * Copyright (c) 2008-2009 Lukasz Rajchel (lukasz@rajchel.pl | http://lukasz.rajchel.pl)
 * Dual licensed under the MIT (http://www.opensource.org/licenses/mit-license.php)
 * and GPL (http://www.opensource.org/licenses/gpl-license.php) licenses.
 *
 * Documentation	:	http://code.google.com/p/jquery-domec/wiki/Documentation
 * Changelog		:	http://code.google.com/p/jquery-domec/wiki/Changelog
 */

/*global document, jQuery*/
/*members DOMEC, addAttributes, addChildren, append, attr, create, createElement , extend,
length, propertyIsEnumerable, splice, text, toString*/
(function ($) {

	// DOMEC Core class
	$.DOMEC = (function () {
		// variables declaration
		var typeOf, Element;

		// returns type of value
		typeOf = function (value) {
			var type = typeof value;
			if (type === 'object') {
				if (value === null) {
					type = 'null';
				} else if (typeof value.length === 'number' &&
					typeof value.splice === 'function' &&
					!(value.propertyIsEnumerable('length'))) {
					type = 'array';
				}

			}
			return type;
		};

		// DOM element
		Element = (function () {
			return {
				// create element
				create: function (name, root) {
					// set default root if undefined
					if (root === undefined || root === null) {
						root = document;
					}

					if (typeOf(root) === 'object' && typeOf(name) === 'string') {
						return $(root.createElement(name));
					}

					return undefined;
				},
				// add attributes
				addAttributes: function (elem, attributes) {
					if (typeOf(attributes) === 'object') {
						for (var key in attributes) {
							if (typeOf(attributes[key]) === 'string' || 
								typeOf(attributes[key]) === 'number') {
								elem.attr(key, attributes[key]);
							}
						}
					}
				},
				// add child elements
				addChildren: function (elem, children) {
					if (children !== undefined && children !== null) {
						if (typeOf(children) === 'array') {
							for (var i = 0; i < children.length; i += 1) {
								elem.append(children[i]);
							}
						} else if (typeOf(children) === 'object') {
							elem.append(children);
						} else {
							elem.text(children.toString());
						}
					}
				}
			};
		}());

		// DOMEC public members
		return {
			create: function (name, attributes, children, root) {
				var elem = Element.create(name, root);

				if (elem !== undefined) {
					Element.addAttributes(elem, attributes);
					Element.addChildren(elem, children);
				}

				return elem;
			}
		};
	}());

 	// register jQuery extension
	$.extend({
		create: $.DOMEC.create
	});

}(jQuery));