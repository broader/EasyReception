//<![CDATA[
 
/**
 * @class MavDialog
 * @abstract MooTools class for customized dialog window boxes
 * @version 0.1.1
 *
 * @license MIT-style license
 * @author Dustin C Hansen <dustin [at] maveno.us>
 * @copyright Copyright (c) 2008 [Dustin Hansen](http://maveno.us, http://fuzecore.com).
 */

var MavDialog = new Class({
	Implements: [Options, Events],
	options: {
		'autoShow': true,
		'buttons': null,
		'cancel': null,
		'cancelClass': 'cancel-button',
		'cancelText': 'Cancel',
		'cancelDestroy': true,
		'callback': null,
		'center': true,
		'dialogClass': 'mav-dialog',
		'draggable': false,
		'fxOptions': {},
		'footer': null,
		'footerClass': 'mav-dialog-footer',
		'force': false,
		'height': 'auto',
		'loadingMessage': 'loading...',
		'message': null,
		'messageAreaClass': 'mav-dialog-message',
		'messageBoxClass': 'mid-float-box',
		'noTitleClass': 'mav-no-title',
		'noFooterClass': 'mav-no-footer',
		'ok': null,
		'okClass': 'ok-button',
		'okText': 'OK',
		'okDestroy': true,
		'parent': null,
		'shadeClass': 'mavdialog-shade',
		'styles': {},
		'title': null,
		'titleBarClass': 'mav-dialog-title',
		'titleClose': true,
		'titleCloseClass': 'icon-button md-closer',
		'titleCloseTitle': 'Close Dialog',
		'titleTextClass': 'md-title-text',
		'url': null,
		'useFx': true,
		'width': '400',
		'removeShade':false,

		'onComplete': $empty(),
		'onClose': $empty(),
		'onHide': $empty(),
		'onRequest': $empty(),
		'onShow': $empty()
	},

	'delayedShow': false,
	'dialog': null,
	'drag': null,
	'footer': null,
	'fx': null,
	'grabbed': null,
	'message': null,
	'parent': null,
	'request': null,
	'titlebar': null,

	initialize: function(_opts) {
		this.setOptions(_opts);
		if ($(this.options.id + '_dialog')) { return null; }

		this.request = new Request({
			'url': '',
			'onSuccess': this.urlRequest.bind(this),
			'onFailure': this.errorMessage.bind(this)
		});

		this.dialogId = 'mavd' + Math.ceil(Math.random() * 100000) + '_dialog';
		this.parent = $((this.options.parent || document.body));
		var dialog_styles = $merge({'display':'none', 'width':this.options.width.toInt()+'px'}, this.options.styles);

		this.dialog = new Element('div', {
			'id': this.dialogId, 
			'class': this.options.dialogClass,
			'opacity': (this.options.useFx ? 0 : 1),
			'styles': dialog_styles
		}).inject(this.parent);

		this.fx = this.options.useFx ? new Fx.Tween(this.dialog, $merge({
			'duration': '300'
		}, this.options.fxOptions)) : null;

		// dialog box sections and borders
		var db_message = new Element('div', {
			'class': this.options.messageBoxClass
		}).inject(this.dialog);
		
		// dialog box title
		if (this.options.title !== false) {
			this.titlebar = new Element('div', {
				'id': this.options.id + '_title',
				'class': this.options.titleBarClass
			}).inject(db_message);
			
			new Element('span', {'class':this.options.titleTextClass, 'html': this.options.title}).inject(this.titlebar);

			if (this.options.titleClose != false) {
				new Element('span', {
					'id':this.options.id + '_closer',
					'class': this.options.titleCloseClass,
					'title': this.options.titleCloseTitle
				}).inject(this.titlebar).addEvent('click', this.close.bind(this));
			}
		}

		// dialog box message
		this.message = new Element('div', {
			'id': this.options.id + '_message', 
			'class': this.options.messageAreaClass + (this.options.title === false ? ' ' + this.options.noTitleClass : '') + (this.options.footer === false ? ' ' + this.options.noFooterClass : '')
		}).inject(db_message).setStyle('height', (this.options.height=='auto'?'auto':this.options.height.toInt()+'px'));

		if ($defined(this.options.url)) {
			this.request.options.url = this.options.url;
			this.request.send();
			this.setMessage(this.options.loadingMessage);
			
			if (this.options.autoShow) { this.delayedShow = true; }
			
		} else if ($defined(this.options.message)){
			this.setMessage(this.options.message);
		}

		// dialog footer
		if (this.options.footer !== false) {
			this.footer = new Element('div', {
				'id': this.options.id + '_footer',
				'class': this.options.footerClass
			}).inject(db_message);

			new Element('div', {'class': 'foot-wrap'}).inject(this.footer);

			if (this.options.ok !== false) {
				(this.createButton(this.options.id, this.options.okText, this.options.okClass, this.options.ok, this.options.okDestroy)).inject(this.footer.firstChild, 'top');
			}
			if (this.options.cancel !== false) {
				(this.createButton(this.options.id, this.options.cancelText, this.options.cancelClass, this.options.cancel, this.options.cancelDestroy)).inject(this.footer.firstChild, 'top');
			}

			if ($type(this.options.buttons) == 'object') {
				for(var btn in this.options.buttons) {
					btn = this.options.buttons[btn];
					(this.createButton(this.options.id, btn.text, btn.class_name, btn.action, !(btn.auto_close), ($defined(btn.tabindex) ? btn.tabindex : null))).inject(this.footer.firstChild, 'top');
				}
			}
		}

		// set dialog to draggable
		if (this.options.draggable && this.titlebar) {
			this.drag = new Drag.Move(this.dialog, {handle: this.titlebar});
		}

		this.fireEvent('complete');

		// execute onComplete function, if present.
		if (this.options.autoShow && !this.request.running) { this.show(); }
	},

	setMessage: function(_message) {
		var message = ($type(_message) == 'function' ? _message() : _message);

		if ($type(message) == 'element') {
			this.grabbed = message.getParent();
			if (this.grabbed != null) {
				message.removeClass('none');
				this.message.grab(message);
			} else {
				message.inject(this.message);
			}
		} else {
			this.message.set('html', message);
		}
		
		if (this.delayedShow) { 
			this.delayedShow = false;
			this.show();
		}
	},
	errorMessage: function(_error) {
		
	},
	
	urlRequest: function(_response) {
		this.setMessage(_response);
		this.fireEvent('request');
	},

	createButton: function(_id, _text, _class, _action, _unforce, _tabindex) {
		var self = this;
		var bid = _id + '_' + (_text.toLowerCase()).replace(/\W/g, '');
		var db_button = new Element('div', { 'class': 'goright image-button ' + _class });
		var db_link = new Element('a', {
			'id': bid,
			'href':'javascript:void(0)', 
			'tabindex': ($defined(_tabindex) ? _tabindex : (++this.tab_index)), 
			'html': _text
		}).inject(db_button);

		if (_action && _action instanceof Function) { db_link.addEvent('click', _action); }
		if (!_unforce || _unforce !== false) { db_link.addEvent('click', this.close.bind(this)); }

		return db_button;
	},

	toggleShade: function(_show) {
		if (!$('mavdialog_shade')) { new Element('div', {'id':'mavdialog_shade', 'class':this.options.shadeClass}).inject(document.body); }

		$('mavdialog_shade').setStyle('display', (_show === true ? 'block' : 'none'));
	},

	show: function() {
		if (this.options.force) {
			var shade_requests = ($(document.body).retrieve('shade_requests') || 0).toInt();
			$(document.body).store('shade_requests', (++shade_requests));
			this.toggleShade(this.options.force);
		}

		this.dialog.setStyle('display', '');
		if (this.options.center !== false) { this.screen_center(); }
		this.fireEvent('show');

		if (this.options.useFx) {
			this.fx.start('opacity', 0, 1);
		}
	},

	hide: function() {
		this.dialog.setStyle('display', 'none');
		this.fireEvent('hide');
	},

	close: function() {
		if (this.options.useFx) {
			this.fx.start('opacity', 1, 0).chain(this.finishClose.bind(this));
		} else { this.finishClose(); }
	},

	finishClose: function() {
		if ($(this.dialog)) {
			if (this.options.force) {
				var shade_requests = ($(document.body).retrieve('shade_requests')).toInt();
				$(document.body).store('shade_requests', (--shade_requests));
			}

			if ($defined(this.grabbed)) {
				this.grabbed.grab(this.message.firstChild);
			}

			this.dialog.dispose();
			
			// add a judge to remove 'mavdialog_shade' element, added by ZG
			if (this.options.force) {
				if(this.options.removeShade){
					$('mavdialog_shade').dispose();
				}
				else if(shade_requests == 0){this.toggleShade();}				 
			}

			this.fireEvent('close');
		}		
	},

	screen_center: function() {
		var parXY = this.parent.getCoordinates();
		var parScroll = this.parent.getScroll();
		var elmXY = this.dialog.getCoordinates();
		var elmWH = this.dialog.getSize();

		if (this.options.center !== 'y') { this.dialog.setStyle('left', ((parXY.width - elmWH.x) / 2) + 'px'); }
		if (this.options.center !== 'x') { this.dialog.setStyle('top', (((parXY.height - elmWH.y) / 2) + parScroll.y) + 'px'); }
	}
});


MavDialog.Confirm = new Class({
	Extends: MavDialog,

	initialize: function(_opts) {
		var opts = $merge(_opts, {
			'cancel':false,
			'titleClose':false,
			'message': this.buildMessage.bind(this, _opts.message),
			'ok': this.closeAction.bind(this, true),
			'cancel': this.closeAction.bind(this, false)
		});
		this.parent(opts);
	},
	
	buildMessage: function(_msg) {
		var message_box = new Element('div');
		new Element('div', {'class':'icon-button confirm-icon goleft'}).inject(message_box);
		new Element('div', {'class':'mav-alert-msg goleft', 'html': _msg}).inject(message_box);
		new Element('div', {'class':'clear'}).inject(message_box);
		
		return message_box;
	},
	
	closeAction: function(_confirmed) {
		this.close();

		if (this.options.useFx && $defined(this.options.callback)) {
			// bah.
			this.fx.start('opacity', 1, 0).chain(this.finishClose.bind(this)).chain(this.options.callback(_confirmed));
		} else {
			this.finishClose();
			if ($defined(this.options.callback) && $type(this.options.callback) == 'function') {
				this.options.callback(_confirmed);
			}
		}
	}
});

MavDialog.Prompt = new Class({
	Extends: MavDialog,

	initialize: function(_opts) {
		var opts = $merge(_opts, {
			'cancel':false,
			'titleClose':false,
			'message': this.buildMessage.bind(this, _opts.message),
			'ok': this.closeAction.bind(this),
			'cancel': this.closeAction.bind(this, false),
			'onComplete': function() {
				var text_elem = this.dialogId + '_prompted';
				window.setTimeout(function() {
					$(text_elem).focus();
				}, 310);
			}
		});
		this.parent(opts);
	},

	buildMessage: function(_msg) {
		var message_box = new Element('div');
		new Element('div', {'class':'icon-button prompt-icon goleft'}).inject(message_box);
		var msg_display = new Element('div', {'class':'mav-alert-msg goleft'}).inject(message_box);

		new Element('div', {'html': _msg}).inject(msg_display);
		new Element('input', {
			'id': this.dialogId + '_prompted',
			'type':'text', 
			'class': 'mav-prompt-input'
		}).inject(msg_display);

		new Element('div', {'class':'clear'}).inject(message_box);

		return message_box;
	},
	
	closeAction: function(_canceled) {
		this.close();
		
		var prompt_value = (_canceled === false ? null : $(this.dialogId + '_prompted').get('value'));
		if (this.options.useFx && $defined(this.options.callback)) {
			// bah.
			this.fx.start('opacity', 1, 0).chain(this.finishClose.bind(this)).chain(this.options.callback(prompt_value));
		} else {
			this.finishClose();
			if ($defined(this.options.callback) && $type(this.options.callback) == 'function') {
				this.options.callback(prompt_value);
			}
		}
	}
});

MavDialog.Alert = new Class({
	Extends: MavDialog,

	initialize: function(_opts) {
		var opts = $merge(_opts, {
			'cancel':false,
			'titleClose':false,
			'message': this.buildMessage.bind(this, _opts.message)
		});
		this.parent(opts);
	},

	buildMessage: function(_msg) {
		var message_box = new Element('div');
		new Element('div', {'class':'icon-button alert-icon goleft'}).inject(message_box);
		new Element('div', {'class':'mav-alert-msg goleft', 'html': _msg}).inject(message_box);
		new Element('div', {'class':'clear'}).inject(message_box);
		
		return message_box;
	}
});


//]]>