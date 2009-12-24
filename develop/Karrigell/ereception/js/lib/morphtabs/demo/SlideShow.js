
var SlideShow = new Class({
	start: function() {
		this.slideShow = this.next.periodical(this.options.slideShowDelay * 1000, this);
	},
	stop: function() {
		this.clearChain();
		$clear(this.slideShow);
	}
});
