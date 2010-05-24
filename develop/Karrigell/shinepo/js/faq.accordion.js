$.accordian = function(items, first, options) {
	var active = first;
	var running = 0;
	var titles = options && options.titles || '.title';
	var contents = options && options.contents || '.content';
	var onClick = options && options.onClick || function(){};
	var onShow = options && options.onShow || function(){};
	var onHide = options && options.onHide || function(){};
	var showSpeed = options && options.showSpeed || 'slow';
	var hideSpeed = options && options.hideSpeed || 'fast';
	$(items).not(active).children(contents).hide();
	$(items).not(active).each(onHide);
	$(active).each(onShow);
	$(items).children(titles).click(function(e){
		var p = $(contents, this.parentNode);
		$(this.parentNode).each(onClick);
		if (running || !p.is(":hidden")) return false;
		running = 2;
		$(active).children(contents).not(':hidden').slideUp(hideSpeed, function(){--running;});
		p.slideDown(showSpeed, function(){--running;});
		$(active).each(onHide);
		active = '#' + $(this.parentNode)[0].id;
		$(active).each(onShow);
		return false;
	});
};
			
$(function(){
	$.accordian('#list1 > div', '#item11');			
});
