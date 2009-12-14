/*******************************************************
Some initial functions for application.
********************************************************/

var tools = $H();

alert('help tools imported');
// add a global object to manage mootools.Assets importing action 
tools.set('assetManager', new AssetsManager());