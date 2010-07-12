function elementCenter(target, container){

	if($(container)){
		container = $(container);
	}else{
		container = window;
	};

	var windSize = container.getSize();
	var elSize = $(target).getSize();

	var top,left,marginTop,marginLeft;
	if(windSize.x < elSize.x){
		left = 0;
		marginLeft = 0;
	}else{
		left = '50%';
		marginLeft = -(elSize.x/2).toInt();
	};

	if(windSize.y < elSize.y ) {
		top = 0;
		marginTop = 0;
	}else{
		top = '50%';
		marginTop = -(elSize.y/2).toInt();
		marginTop = -(elSize.y/2).toInt();
	};

	if(container != window && container.getStyle('position')=='static'){
		container.setStyle('position','relative');
	};

	target.setStyles({
		position:'absolute',
		top:top,
		left:left,
		marginLeft:marginLeft,
		marginTop:marginTop
	}).inject((container==window?$(document.body):container));

	return target;
};
