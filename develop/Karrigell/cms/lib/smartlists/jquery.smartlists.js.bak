
(function($){$.extend({currentPage:1,currentFlag:"smartlist-all",options:{},flagInfo:null,listItems:[],itemFlagIndexes:[],smartlist:function(opts)
{var options={baseName:"sl",itemClass:"item",showFlagCount:true,itemFlagClass:"flags",itemFlagSeparator:", ",itemChangeEffect:"Blind",itemChangeDuration:800,pageChangeEffect:"",pageChangeDuration:500,numItemsPerPage:10,paginationLeft:'\u00ab',paginationRight:"\u00bb",maxPaginationLinks:10,defaultDropdownOptText:"All items",optgroups:{}};jQuery.extend(options,opts);var listItems=$("#"+options.baseName+" ."+options.itemClass);var itemFlagIndexes=[];var flagInfo=[];var currFlagIndex=0;for(var i=0;i<listItems.length;i++)
{if(i<options.numItemsPerPage)
$(listItems[i]).show();else
$(listItems[i]).hide();var itemFlagNodes=$(listItems[i]).find("."+options.itemFlagClass);var currItemFlagIndexes=[];var linkNodes=[];for(var j=0;j<itemFlagNodes.length;j++)
{var currItemFlagStrings=$(itemFlagNodes[j]).html().split(/\s+/);var flagSpan=document.createElement("span");for(var k=0;k<currItemFlagStrings.length;k++)
{var currFlag=currItemFlagStrings[k].replace(/&nbsp;/g," ");flagIndex=currFlagIndex;var flagStringAlreadyLogged=false;for(var m=0;m<flagInfo.length;m++)
{if(flagInfo[m][0]==currFlag)
{flagInfo[m][2]++;flagIndex=flagInfo[m][1];flagStringAlreadyLogged=true;}}
if(!flagStringAlreadyLogged)
{flagInfo.push([currFlag,flagIndex,1]);currFlagIndex++;}
var a=document.createElement("a");a.setAttribute("href","#");a.setAttribute("class",options.baseName+"-flag"+flagIndex);a.setAttribute("className",options.baseName+"-flag"+flagIndex);a.appendChild(document.createTextNode(currFlag));flagSpan.appendChild(a);flagSpan.appendChild(document.createTextNode(options.itemFlagSeparator));currItemFlagIndexes.push(flagIndex);}
if(flagSpan.childNodes.length)
flagSpan.removeChild(flagSpan.childNodes[flagSpan.childNodes.length-1]);$(itemFlagNodes[j]).html(flagSpan);}
itemFlagIndexes[i]=currItemFlagIndexes;}
var sortedFlags=[];for(var i=0;i<flagInfo.length;i++)
sortedFlags.push(flagInfo[i][0]);sortedFlags.sort();var sortedFlagInfo=[];for(var i=0;i<sortedFlags.length;i++)
{var currFlag=sortedFlags[i];for(var j=0;j<flagInfo.length;j++)
{if(flagInfo[j][0]==currFlag)
sortedFlagInfo.push([currFlag,flagInfo[j][1],flagInfo[j][2]]);}}
this.options=options;this.flagInfo=sortedFlagInfo;this.listItems=listItems;this.itemFlagIndexes=itemFlagIndexes;this.createPagination("smartlist-all");this.addDropdown();$(options.baseName).show();},createPagination:function(flagIndex)
{var listItems=this.listItems;var options=this.options;var flagInfo=this.flagInfo;var numPages=0;if(flagIndex=="smartlist-all")
numPages=Math.ceil(listItems.length/options.numItemsPerPage);else
{var flagCount=this._getFlagCountFromFlagIndex(flagIndex);numPages=Math.ceil(flagCount/options.numItemsPerPage);}
$("#"+options.baseName+"-pagination").empty();if(numPages<=1)
return;var pagination=document.createElement("span");var previousSpan=document.createElement("span");previousSpan.setAttribute("id",options.baseName+"-pagination-previous");previousSpan.appendChild(document.createTextNode(this.options.paginationLeft));pagination.appendChild(previousSpan);var halfTotalNavPages=Math.floor(options.maxPaginationLinks/2);for(var i=1;i<=numPages;i++)
{var span=document.createElement("span");span.setAttribute("id",options.baseName+"-page"+i);if(i==1)
{span.setAttribute("class",options.baseName+"-pagination-selected");span.setAttribute("className",options.baseName+"-pagination-selected");}
if(i>halfTotalNavPages)
span.style.cssText="display:none";var a=document.createElement("a");a.setAttribute("href","#");var currSmartList=this;$(a).bind("click",{page:i},function(e){return currSmartList.changePage(e);});a.appendChild(document.createTextNode(i));span.appendChild(a);pagination.appendChild(span);}
var nextSpan=document.createElement("span");nextSpan.setAttribute("id",options.baseName+"-pagination-next");nextSpan.appendChild(this._getPaginationNextLinkNode());pagination.appendChild(nextSpan);$("#"+options.baseName+"-pagination").html(pagination);},addDropdown:function()
{var options=this.options;var flagInfo=this.flagInfo;var currSmartList=this;var s=document.createElement("select");$(s).bind("change",function(e){return currSmartList.filterByFlag(e)});var defaultOpt=document.createElement("option");defaultOpt.setAttribute("value","smartlist-all");defaultOpt.appendChild(document.createTextNode(options.defaultDropdownOptText));s.appendChild(defaultOpt);for(var i=0;i<flagInfo.length;i++)
{var flag=flagInfo[i][0];var index=flagInfo[i][1];var count=flagInfo[i][2];var opt=document.createElement("option");opt.setAttribute("value",index);var displayText=(options.showFlagCount)?flag+" ("+count+")":flag;opt.appendChild(document.createTextNode(displayText));s.appendChild(opt);$("."+options.baseName+"-flag"+index).bind('click',{flagIndex:index},function(e){return currSmartList.filterByFlag(e);});}
$("#"+options.baseName+"-flag-dropdown").html(s);},changePage:function(event)
{var options=this.options;var currentPage=this.currentPage;var page=event.data.page;if(page==currentPage)
return;if(page=="next")
page=currentPage+1;else if(page=="previous")
page=currentPage-1;$("#"+options.baseName+"-page"+currentPage).removeClass(options.baseName+"-pagination-selected");$("#"+options.baseName+"-page"+page).addClass(options.baseName+"-pagination-selected");var selectedFlagItems=(this.currentFlag=="smartlist-all")?this.listItems:this._getItemsByFlag(this.currentFlag);var firstItemToHide=(currentPage-1)*options.numItemsPerPage;var maxLastItem=firstItemToHide+options.numItemsPerPage;var lastItemToHide=(maxLastItem>selectedFlagItems.length)?selectedFlagItems.length:maxLastItem;var firstItemToShow=(page-1)*options.numItemsPerPage;var maxLastItem=firstItemToShow+options.numItemsPerPage;var lastItemToShow=(maxLastItem>selectedFlagItems.length)?selectedFlagItems.length:maxLastItem;for(var i=0;i<selectedFlagItems.length;i++)
{if(i>=firstItemToHide&&i<lastItemToHide)
{switch(options.pageChangeEffect)
{case"Blind":$(selectedFlagItems[i]).hide(options.pageChangeDuration);break;case"FadeAppear":$(selectedFlagItems[i]).fadeOut(options.pageChangeDuration);break;default:$(selectedFlagItems[i]).hide();break;}}
if(i>=firstItemToShow&&i<lastItemToShow)
{switch(options.pageChangeEffect)
{case"Blind":$(selectedFlagItems[i]).animate({opacity:options.pageChangeDuration}).show(options.pageChangeDuration);break;case"FadeAppear":$(selectedFlagItems[i]).animate({opacity:options.pageChangeDuration}).fadeIn(options.pageChangeDuration);break;default:$(selectedFlagItems[i]).show();break;}}}
var lastPage=Math.ceil(selectedFlagItems.length/options.numItemsPerPage);if(page==1)
$("#"+options.baseName+"-pagination-previous").html(options.paginationLeft);else
$("#"+options.baseName+"-pagination-previous").html(this._getPaginationPreviousLinkNode());if(page==lastPage)
$("#"+options.baseName+"-pagination-next").html(options.paginationRight);else
$("#"+options.baseName+"-pagination-next").html(this._getPaginationNextLinkNode());var totalVisible=0;var halfTotalNavPages=Math.floor(options.maxPaginationLinks/2);var firstVisiblePage=(page>halfTotalNavPages)?page-halfTotalNavPages:1;var lastVisiblePage=((page+halfTotalNavPages)<lastPage)?page+halfTotalNavPages:lastPage;for(var i=1;i<=lastPage;i++)
{if(i<firstVisiblePage)
$("#"+options.baseName+"-page"+i).hide();if(i>lastVisiblePage)
$("#"+options.baseName+"-page"+i).hide();if(i>=firstVisiblePage&&i<=lastVisiblePage)
$("#"+options.baseName+"-page"+i).show();}
this.currentPage=page;return false;},filterByFlag:function(event)
{var flagIndex=flagIndex;if(event.target.value=="smartlist-all")
flagIndex=event.target.value;else if(event.target.value!=undefined)
flagIndex=parseInt(event.target.value);if(event.data)
flagIndex=event.data.flagIndex;var listItems=this.listItems;var options=this.options;var itemFlagIndexes=this.itemFlagIndexes;var count=0;for(var i=0;i<listItems.length;i++)
{if(count>=options.numItemsPerPage)
{$(listItems[i]).hide();continue;}
if($.inArray(flagIndex,itemFlagIndexes[i])!=-1||flagIndex=="smartlist-all")
{if($(listItems[i]).css("display")=="none")
{switch(options.itemChangeEffect)
{case"Blind":$(listItems[i]).show(options.itemChangeDuration);break;case"FadeAppear":$(listItems[i]).fadeIn(options.itemChangeDuration);break;default:$(listItems[i]).show();break;}}
count++;}
else
{if($(listItems[i]).css("display")!="none")
{switch(options.itemChangeEffect)
{case"Blind":$(listItems[i]).hide(options.itemChangeDuration);break;case"FadeAppear":$(listItems[i]).fadeOut(options.itemChangeDuration);break;default:$(listItems[i]).hide();break;}}
else
$(listItems[i]).hide();}}
this._selectDropdownOption(flagIndex);this.createPagination(flagIndex);this.currentPage=1;this.currentFlag=flagIndex;return false;},_getFlagCountFromFlagIndex:function(flagIndex)
{var flagCount=null;for(var i=0;i<this.flagInfo.length;i++)
{if(this.flagInfo[i][1]==flagIndex)
flagCount=this.flagInfo[i][2];}
return flagCount;},_getPaginationNextLinkNode:function()
{var nextLink=document.createElement("a");nextLink.setAttribute("href","#");var currSmartList=this;$(nextLink).bind("click",{page:"next"},function(e){currSmartList.changePage(e)});nextLink.appendChild(document.createTextNode(this.options.paginationRight));return nextLink;},_getPaginationPreviousLinkNode:function()
{var previousLink=document.createElement("a");previousLink.setAttribute("href","#");var currSmartList=this;$(previousLink).bind("click",{page:"previous"},function(e){currSmartList.changePage(e)});var left=this.options.paginationLeft;previousLink.appendChild(document.createTextNode(left));return previousLink;},_selectDropdownOption:function(flagIndex)
{var options=this.options;var dd_els=$("#"+options.baseName+"-flag-dropdown").find("select");var dd=dd_els[0];for(var i=0;i<dd.options.length;i++)
{if(dd.options[i].value==flagIndex)
{dd.options[i].selected=true;break;}}},_getItemsByFlag:function(flagIndex)
{var nodes=[];for(var i=0;i<this.listItems.length;i++)
{if($.inArray(flagIndex,this.itemFlagIndexes[i])!=-1)
nodes.push(this.listItems[i]);}
return nodes;}});})(jQuery);