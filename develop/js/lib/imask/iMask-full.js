/* ************************************************************************************* *\
 * The MIT License
 * Copyright (c) 2007 Fabio Zendhi Nagao - http://zend.lojcomm.com.br
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies
 * or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
\* ************************************************************************************* */

var iMask = new Class({
	options: {
		targetClass: ".iMask",
		maskEmptyChr: '_',

		validNumbers: "1234567890",
		validAlphas: "abcdefghijklmnopqrstuvwxyz",
		validAlphaNums: "abcdefghijklmnopqrstuvwxyz1234567890",

		onFocus: Class.empty,
		onBlur: Class.empty,
		onValid: Class.empty,
		onInvalid: Class.empty,
		onKeyDown: Class.empty
	},

	initialize: function(options) {
		this.setOptions(options);

		var fields = $$(this.options.targetClass);
		fields.each(function(obj, i) {
			obj.options = Json.evaluate(obj.alt);
			if(obj.options.type == "number") obj.setStyle("text-align", "right");
			obj.addEvent("mousedown", function(event) {
				event = new Event(event);
				event.stop();
			});
			obj.addEvent("mouseup", function(event) {
				event = new Event(event);
				event.stop();
				this._onMouseUp(event, obj);
			}.bind(this));
			obj.addEvent("click", function(event) {
				event = new Event(event);
				event.stop();
			});
			obj.addEvent("keydown", function(event) {
				event = new Event(event);
				this._onKeyDown(event, obj);
				this.fireEvent("onKeyDown", obj, 20);
			}.bind(this));
			obj.addEvent("keypress", function(event) {
				event = new Event(event);
				this._onKeyPress(event, obj);
			}.bind(this));
			obj.addEvent("focus", function(event) {
				event = new Event(event);
				event.stop();
				this._onFocus(event, obj);
				this.fireEvent("onFocus", obj, 20);
			}.bind(this));
			obj.addEvent("blur", function(event) {
				event = new Event(event);
				event.stop();
				this._onBlur(event, obj);
				this.fireEvent("onBlur", obj, 20);
			}.bind(this));
		}.bind(this));
	},

	_onMouseUp: function(event, obj) {
		if(obj.options.type == "fixed") {
			var p = this._getSelectionStart(obj);
			this._setSelection(obj, p, (p + 1));
		} else if(obj.options.type == "number") {
			this._setEnd(obj);
		}
	},

	_onKeyDown: function(event, obj) {
		if(event.code == 13) { // enter
			obj.blur();
			this._submitForm(obj);
		} else if(!(event.code == 9)) {
			event.stop();
			if(obj.options.type == "fixed") {
				var p = this._getSelectionStart(obj);
				switch(event.code) {
					case 8: // Backspace
						this._selectPrevious(obj);
						break;
					case 36: // Home
						this._selectFirst(obj);
						break;
					case 35: // End
						this._selectLast(obj);
						break;
					case 37: // Left
					case 38: // Up
						this._selectPrevious(obj);
						break;
					case 39: // Right
					case 40: // Down
						this._selectNext(obj);
						break;
					case 46: // Delete
						this._updSelection(obj, p, this.options.maskEmptyChr);
						break;
					default:
						var chr = this._chrFromEvent(event);
						if(this._isViableInput(obj, p, chr)) {
							if(event.shift)
								{this._updSelection(obj, p, chr.toUpperCase());}
							else
								{this._updSelection(obj, p, chr);}
							this.fireEvent("onValid", [event, obj], 20);
							this._selectNext(obj);
						} else {
							this.fireEvent("onInvalid", [event, obj], 20);
						}
						break;
				}
			} else if(obj.options.type == "number") {
				switch(event.code) {
					case 8: // backspace
					case 46: // delete
						this._popNumber(obj);
						break;
					default:
						var chr = this._chrFromEvent(event);
						if(this.options.validNumbers.indexOf(chr) >= 0) {
							this._pushNumber(obj, chr);
							this.fireEvent("onValid", [event, obj], 20);
						} else {
							this.fireEvent("onInvalid", [event, obj], 20);
						}
						break;
				}
			}
		}
	},

	_onKeyPress: function(event, obj) {
		if(
			   !(event.code == 9) // tab
			&& !(event.shift && event.code == 9) // shift + tab
			&& !(event.code == 13) // enter
			&& !(event.ctrl && event.code == 67) // ctrl + c
			&& !(event.ctrl && event.code == 86) // ctrl + v
			&& !(event.ctrl && event.code == 88) // ctrl + x
		) {
			event.stop();
		}
	},

	_onFocus: function(event, obj) {
		if(obj.options.stripMask) obj.value = this._wearMask(obj, obj.value);
		if(obj.options.type == "fixed")
			{this._selectFirst.delay(20, this, obj);}
		else
			{this._setEnd.delay(20, this, obj);}
	},

	_onBlur: function(event, obj) {
		if(obj.options.stripMask)
			obj.value = this._stripMask(obj);
	},

	_selectAll: function(obj) {
		this._setSelection(obj, 0, obj.value.length);
	},

	_selectFirst: function(obj) {
		for(var i = 0, len = obj.options.mask.length; i < len; i++) {
			if(this._isInputPosition(obj, i)) {
				this._setSelection(obj, i, (i + 1));
				return;
			}
		}
	},

	_selectLast: function(obj) {
		for(var i = (obj.options.mask.length - 1); i >= 0; i--) {
			if(this._isInputPosition(obj, i)) {
				this._setSelection(obj, i, (i + 1));
				return;
			}
		}
	},

	_selectPrevious: function(obj, p) {
		if(!$chk(p))p = this._getSelectionStart(obj);
		if(p <= 0) {
			this._selectFirst(obj);
		} else {
			if(this._isInputPosition(obj, (p - 1))) {
				this._setSelection(obj, (p - 1), p);
			} else {
				this._selectPrevious(obj, (p - 1));
			}
		}
	},

	_selectNext: function(obj, p) {
		if(!$chk(p))p = this._getSelectionEnd(obj);
		if(p >= obj.options.mask.length) {
			this._selectLast(obj);
		} else {
			if(this._isInputPosition(obj, p)) {
				this._setSelection(obj, p, (p + 1));
			} else {
				this._selectNext(obj, (p + 1));
			}
		}
	},

	_setSelection: function(obj, a, b) {
		if(obj.setSelectionRange) {
			obj.focus();
			obj.setSelectionRange(a, b);
		} else if(obj.createTextRange) {
			var r = obj.createTextRange();
			r.collapse();
			r.moveStart("character", a);
			r.moveEnd("character", (b - a));
			r.select();
		}
	},

	_updSelection: function(obj, p, chr) {
		var value = obj.value;
		var output = "";
		output += value.substring(0, p);
		output += chr;
		output += value.substr(p + 1);
		obj.value = output;
		this._setSelection(obj, p, (p + 1));
	},

 	_setEnd: function(obj) {
		var len = obj.value.length;
		this._setSelection(obj, len, len);
	},

	_getSelectionStart: function(obj) {
		var p = 0;
		if(obj.selectionStart) {
			if($type(obj.selectionStart) == "number") p = obj.selectionStart;
		} else if(document.selection) {
			var r = document.selection.createRange().duplicate();
			r.moveEnd("character", obj.value.length);
			p = obj.value.lastIndexOf(r.text);
			if(r.text == "") p = obj.value.length;
		}
		return p;
	},

	_getSelectionEnd: function(obj) {
		var p = 0;
		if(obj.selectionEnd) {
			if($type(obj.selectionEnd) == "number")
				{p = obj.selectionEnd;}
		} else if(document.selection) {
			var r = document.selection.createRange().duplicate();
			r.moveStart("character", -obj.value.length);
			p = r.text.length;
		}
		return p;
	},

	_isInputPosition: function(obj, p) {
		var mask = obj.options.mask.toLowerCase();
		var chr = mask.charAt(p);
		if("9ax".indexOf(chr) >= 0)
			return true;
		return false;
	},

	_isViableInput: function(obj, p, chr) {
		var mask = obj.options.mask.toLowerCase();
		var chMask = mask.charAt(p);
		switch(chMask) {
			case '9':
				if(this.options.validNumbers.indexOf(chr) >= 0) return true;
				break;
			case 'a':
				if(this.options.validAlphas.indexOf(chr) >= 0) return true;
				break;
			case 'x':
				if(this.options.validAlphaNums.indexOf(chr) >= 0) return true;
				break;
			default:
				return false;
				break;
		}
	},

	_wearMask: function(obj, str) {
		var mask = obj.options.mask.toLowerCase();
		var output = "";
		for(var i = 0, u = 0, len = mask.length; i < len; i++) {
			switch(mask.charAt(i)) {
				case '9':
					if(this.options.validNumbers.indexOf(str.charAt(u).toLowerCase()) >= 0) {
						if(str.charAt(u) == "") {output += this.options.maskEmptyChr;}
						else {output += str.charAt(u++);}
					} else {
						output += this.options.maskEmptyChr;
					}
					break;
				case 'a':
					if(this.options.validAlphas.indexOf(str.charAt(u).toLowerCase()) >= 0) {
						if(str.charAt(u) == "") {output += this.options.maskEmptyChr;}
						else {output += str.charAt(u++);}
					} else {
						output += this.options.maskEmptyChr;
					}
					break;
				case 'x':
					if(this.options.validAlphaNums.indexOf(str.charAt(u).toLowerCase()) >= 0) {
						if(str.charAt(u) == "") {output += this.options.maskEmptyChr;}
						else {output += str.charAt(u++);}
					} else {
						output += this.options.maskEmptyChr;
					}
					break;
				default:
					output += mask.charAt(i);
					break
			}
		}
		return output;
	},

	_stripMask: function(obj) {
		var value = obj.value;
		if("" == value) return "";
		var output = "";
		if(obj.options.type == "fixed") {
			for(var i = 0, len = value.length; i < len; i++) {
				if((value.charAt(i) != this.options.maskEmptyChr) && (this._isInputPosition(obj, i)))
					{output += value.charAt(i);}
			}
		} else if(obj.options.type == "number") {
			for(var i = 0, len = value.length; i < len; i++) {
				if(this.options.validNumbers.indexOf(value.charAt(i)) >= 0)
					{output += value.charAt(i);}
			}
		}
		return output;
	},

	_chrFromEvent: function(event) {
		var chr = '';
		switch(event.code) {
			case 48: case 96: // 0 and numpad 0
				chr = '0';
				break;
			case 49: case 97: // 1 and numpad 1
				chr = '1';
				break;
			case 50: case 98: // 2 and numpad 2
				chr = '2';
				break;
			case 51: case 99: // 3 and numpad 3
				chr = '3';
				break;
			case 52: case 100: // 4 and numpad 4
				chr = '4';
				break;
			case 53: case 101: // 5 and numpad 5
				chr = '5';
				break;
			case 54: case 102: // 6 and numpad 6
				chr = '6';
				break;
			case 55: case 103: // 7 and numpad 7
				chr = '7';
				break;
			case 56: case 104: // 8 and numpad 8
				chr = '8';
				break;
			case 57: case 105: // 9 and numpad 9
				chr = '9';
				break;
			default:
				chr = event.key; // key pressed as a lowercase string
				break;
		}
		return chr;
	},

	_pushNumber: function(obj, chr) {
		obj.value = obj.value + chr;
		this._formatNumber(obj);
	},

	_popNumber: function(obj) {
		obj.value = obj.value.substring(0, (obj.value.length - 1));
		this._formatNumber(obj);
	},

	_formatNumber: function(obj) {
		// stripLeadingZeros
		var str2 = this._stripMask(obj);
		var str1 = "";
		for(var i = 0, len = str2.length; i < len; i++) {
			if('0' != str2.charAt(i)) {
				str1 = str2.substr(i);
				break;
			}
		}

		// wearLeadingZeros
		str2 = str1;
		str1 = "";
		for(var len = str2.length, i = obj.options.decDigits; len <= i; len++) {
			str1 += "0";
		}
		str1 += str2;

		// decimalSymbol
		str2 = str1.substr(str1.length - obj.options.decDigits)
		str1 = str1.substring(0, (str1.length - obj.options.decDigits))

		// groupSymbols
		var re = new RegExp("(\\d+)(\\d{"+ obj.options.groupDigits +"})");
		while(re.test(str1)) {
			str1 = str1.replace(re, "$1"+ obj.options.groupSymbol +"$2");
		}

		obj.value = str1 + obj.options.decSymbol + str2;
	},

	_getObjForm: function(obj) {
		var parent = obj.getParent();
		if(parent.getTag() == "form") {
			return parent;
		} else {
			return this._getObjForm(parent);
		}
	},

	_submitForm: function(obj) {
		var form = this._getObjForm(obj);
		form.submit();
	}
});
iMask.implement(new Events); // Implements addEvent(type, fn), fireEvent(type, [args], delay) and removeEvent(type, fn)
iMask.implement(new Options);// Implements setOptions(defaults, options)