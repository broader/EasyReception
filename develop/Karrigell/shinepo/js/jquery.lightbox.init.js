// Ativando o jQuery lightBox plugin
$(document).ready(function() {
	$('#gallery a').lightBox({
        	/*fixedNavigation:true,*/
        	txtImage: '图片',
		txtOf: '图片总计'
       	});
});