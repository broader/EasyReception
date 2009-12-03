
window.addEvent('domready', function(){   
	$('tabs-nav').getElements('li').each(function(i) {	         	
		i.addEvent('click', function(event){
			event.stop();			
			Tab(i.get('id'));
		});
	});
});

function Tab(key){
	$('tabs-nav').getElements('li').each(function(i) {
		i.removeClass('active');
	})
	$(key).addClass('active');
	link = $($(key).getElements('a')[0]).getAttribute('ref');
	
	var req = new Request({		
		url: link,
		method: 'get',
		onRequest: function() {
			$(key + '-loading').set('html', '<img src=\'js/lib/tabs/images/ajax-loader.gif\' width=\'16\' height=\'16\' alt=\'Loading\' />');
		},
		onSuccess: function(responseText) {
			$(key + '-loading').set('html','');
			$('tabs-content').set('html',responseText);
		}
	}).send();
}
