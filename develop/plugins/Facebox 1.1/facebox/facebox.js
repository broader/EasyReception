	/*
		Facebox for MooTools is a mootools port
		from the original Facebox, which was written for jQuery
		and which was inspired by the Facebook pop-up messages.
		
		Facebox is very extensible, and can be used to display
		normal html, images, text fetched with ajax, etc etc.
		
		More info and license can be found on http://bertramakers.com/labs/
	*/
	
	var Facebox = function(_options) {		
		var options = $extend({
			message: 'Message not specified.',
			url: false,
			ajaxErrorMessage: '<h3>Error 404</h3><p>The requested file could not be found.</p>',
			ajaxDelay: 800,
			width: 370,
			height: 'auto',
			title: false,
			draggable: true,
			submitValue: false,
			submitFunction: false,
			submitFocus: false,
			cancelValue: 'Cancel',
			cancelFunction: false,
			loadIcon: 'facebox/images/loading.gif',
			fadeOpacity: .75
		}, _options || {});
		
		var box = $(document.createElement("table"));
		box.className = 'facebox';
		var mbox;
		var instance = this;
		
		this.show = function() {
			for (var i = 0; i < 3; i++) {
				var row = box.insertRow(i);
				for (var a = 0; a < 3; a++) {
					var cell = row.insertCell(a);
					var cellClass = '';
					if (i == 0)
						cellClass = 'top';
					else if (i == 1)
						cellClass = 'center';
					else if (i == 2)
						cellClass = 'bottom';
					if (a == 0)
						cellClass += 'Left';
					else if (a == 1)
						cellClass += 'Center';
					else if (a == 2)
						cellClass += 'Right';
					if (cellClass == "centerCenter") {
						cell.style.width = options.width + "px";
						cell.style.height = "auto";
						mbox = document.createElement("div");
						mbox.className = 'faceboxContent';
						mbox.style.position = "relative";
						cell.appendChild(mbox);
					}
					cell.className = cellClass;
				}
			}
			box.style.position = "absolute";
			var boxLeft = (window.getSize().x / 2) + window.getScroll().x;
			var boxTop = (window.getSize().y / 2) + window.getScroll().y;
			box.style.left = boxLeft + "px";
			box.style.top = boxTop + "px";
			$$('body')[0].appendChild(box);
			var boxMLeft = (box.offsetWidth / 2) * (-1); // box.getSize().x
			box.style.marginLeft = boxMLeft + "px";
			var boxMTop = (box.offsetHeight / 2) * (-1); // box.getSize().y
			box.style.marginTop = boxMTop + "px";
			
			if (options.url != false) {
				var loading = document.createElement("img");
				loading.src = options.loadIcon;
				loading.className = 'loading';
				mbox.appendChild(loading);
				if ((options.url != false) && (options.url.toLowerCase().indexOf(".png") == -1) && (options.url.toLowerCase().indexOf(".jpg") == -1) && (options.url.toLowerCase().indexOf(".gif") == -1)) {
					var ajax = new Request({
						url: options.url,
						onComplete: function() {
							window.setTimeout(function() {
								mbox.removeChild(loading);	
								insertMessage();
							}, options.ajaxDelay);
						},
						onSuccess: function(html) {
							options.message = html;
						},
						onFailure: function(html) {
							options.message = options.ajaxErrorMessage;
						}
					});
					ajax.send();
				} else {
					var img = document.createElement("img");
					img.src = options.url;
					img.style.visibility = "hidden";
					img.style.position = "absolute";
					img.style.left = "0px";
					img.style.top = "0px";
					mbox.appendChild(img);
					window.setTimeout(function() {
						faceboxLoadImage(img, loading);
					}, options.ajaxDelay);
				}
			} else {
				insertMessage();
			}
		}
		
		var faceboxLoadImage = function(img, loading) {
			if ((img.width != null) && (img.width != undefined) && (img.width != "")) {
				options.width = img.width;
				options.height = img.height;
				if ((options.title != "") && (options.title != false))
					var imgAlt = options.title;
				else
					var imgAlt = img.src;
				options.message = '<img src="' + img.src + '" alt="' + imgAlt + '" />';
				mbox.removeChild(img);
				mbox.removeChild(loading);
				insertMessage();
			} else {
				faceboxLoadImage(img, loading);
			}
		}
			
		var insertMessage = function() {
			var title = false;
			if ((options.title != null) && (options.title != false) && (options.title != "")) {
				title = document.createElement("h2");
				title.innerHTML = options.title;
				title.className = 'faceboxTitle';
				mbox.appendChild(title);
			}
			
			var faceboxMessage = document.createElement("div");
			faceboxMessage.className = "faceboxMessage";
			if (options.height != "auto")
				faceboxMessage.style.height = options.height + "px";
			mbox.appendChild(faceboxMessage);
			faceboxMessage.style.width = options.width + "px";
			if (options.height != "auto")
				faceboxMessage.style.height = options.height + "px";
		
			var content = options.message;
			faceboxMessage.innerHTML = content;
			
			if ((options.url != false) && ((options.url.toLowerCase().indexOf(".png") != -1) || (options.url.toLowerCase().indexOf(".jpg") != -1) || (options.url.toLowerCase().indexOf(".gif") != -1)) && ((title == false) || (title == "")) && (options.submitValue == false) && (options.cancelValue == "Cancel") && (options.submitFunction == false)) {
				var img = faceboxMessage.getElementsByTagName("img");
				if (img.length > 0) {
					img[0].style.cursor = "pointer";
					if (window.attachEvent) {
						img[0].attachEvent("onclick", function() {
							var fx = new Fx.Morph(box, {duration: 300});
							fx.start({opacity: 0}).chain(function() { $$('body')[0].removeChild(box); });
						});						
					} else {
						img[0].addEvent("click", function() {
							var fx = new Fx.Morph(box, {duration: 300});
							fx.start({opacity: 0}).chain(function() { $$('body')[0].removeChild(box); });
						});
					}
				}
			} else {
				var faceboxFooter = document.createElement("div");
				faceboxFooter.className = "faceboxFooter";
				mbox.appendChild(faceboxFooter);
				
				if ((options.submitValue != false) && (options.submitValue != null) && (options.submitValue != "")) {
					var submitButton = document.createElement("input");
					submitButton.setAttribute("type", "button");
					submitButton.className = 'faceboxSubmit';
					submitButton.setAttribute("value", options.submitValue);
					if (window.attachEvent)
						submitButton.attachEvent("onclick", options.submitFunction);
					else
						submitButton.addEvent("click", options.submitFunction);
					faceboxFooter.appendChild(submitButton);
					if (options.submitFocus == true)
						submitButton.focus();
				}
				var cancelButton = document.createElement("input");
				cancelButton.setAttribute("type", "button");
				cancelButton.setAttribute("value", options.cancelValue);
				if (options.cancelFunction == false) {
					if (window.attachEvent) {
						cancelButton.attachEvent("onclick", function() {
							instance.close();				
						});
					} else {
						cancelButton.addEvent("click", function() {
							instance.close();
						});
					}
				} else {
					if (window.attachEvent)
						cancelButton.attachEvent("onclick", options.cancelFunction);
					else	
						cancelButton.addEvent("click", options.cancelFunction);
				}
				faceboxFooter.appendChild(cancelButton);
			}
			
			if ((options.draggable == true) && (title != false))
				var dragging = new Drag.Move(box, {handle: title});
				
			var boxMTop = (box.getSize().y / 2) * (-1);
			box.style.marginTop = boxMTop + "px";
		}
		
		this.close = function() {
			var fx = new Fx.Morph(box, {duration: 300});
			fx.start({
				opacity: 0
			}).chain(function() {
				$$('body')[0].removeChild(box);
			});
		}
		
		this.fastclose = function() {
			$$('body')[0].removeChild(box);
		}
		
		this.returnMessageBox = function() {
			var messageBox = box.getElements(".faceboxMessage")[0];
			return messageBox;
		}
		
		this.fade = function() {
			var overlayW = mbox.offsetWidth; // mbox.getSize().x
			var overlayH = mbox.offsetHeight; // mbox.getSize().y
			var overlay = document.createElement("div");
			overlay.style.width = overlayW + "px";
			overlay.style.height = overlayH + "px";
			overlay.style.position = "absolute";
			overlay.style.left = "-1px";
			overlay.style.top = "-1px";
			overlay.className = 'faceboxOverlay';
			overlay.style.backgroundColor = "#fff";
			var hide = new Fx.Morph(overlay, {duration: 400});
			hide.set({
				opacity: options.fadeOpacity
			});
			mbox.appendChild(overlay);
		}
		
		this.unfade = function() {
			mbox.setAttribute("id", "tmpMBoxId");
			var overlay = $$('#tmpMBoxId .faceboxOverlay'); // mbox.getElements('.faceboxOverlay');
			mbox.setAttribute("id", "");
			if (overlay.length > 0)
				mbox.removeChild(overlay[0]);
			var fx = new Fx.Morph(box);
			fx.set({opacity: 1});
		}
	}