[]
from HTMLTags import *

PRINT( """
<link type="text/css" href="yaml/screen/forms.css" rel="stylesheet" />

<style type="text/css" title="currentStyle">
	@import "lib/dataTable/css/demo_table.css";
	@import "lib/treeTable/jquery.treeTable.css";
</style>
""")

# classes list Div component on the left of the page
js_1 = "$('#classes_list').hide().show('slow')"
style_1 = "width:auto;margin-left: 2em;"
menuId = 'classes_list'
d1 = {'id': menuId, 'class':'tablist', 'style' : style_1}

# below is top Div component which holds classes' edit menus
'''
<div class="subcolumns">
<div id="%s" class="tablist"  style="%s">
'''%(menuId, style_1)

# the classes list
Include('sysadmin.ks/index')

PRINT( '''
</div>
</div>
''')


# bottom Div component to show and edit class
showId = 'class_show'
style_2 = "width:auto;border:1px solid #8B8378;margin-left : 2em;margin-right:2em;"
d2 = {'id': showId, 'style': style_2}
bottom = DIV(DIV(**d2), **{'class' : 'subcolumns'})
PRINT( bottom)


PRINT( """
<script type="text/javascript">
	$.fn.waitingJFrame = function () {
          $(this).html('<img src="../images/ajax_loading.gif" alt="Loading......" />');
	};

	var menuId = "%s";
	var showId = "%s";

	function setMenu(link){
		if (typeof(link) == 'number'){
			// for jquery.each() call, replace 'link' to 'this'
			link = this;
		}
		$(link)
		.unbind("click")
		.click(function(){
			li = $(this).parent();

			// get actived menu and reset it to clickable menu
			active = $("#" + menuId + " .active");
			if (active.length == 1){
				lastActive = active[0];
				// remove 'active' class
				$(lastActive).removeAttr("class");
				// get <strong> tag
				label = $(lastActive).children()[0];
				// replace <strong> tag to <a> tage
				replace = "<a href='" + $(label).attr("href") + "' >" +$(label).text() + "</a>"
				$(lastActive).html(replace);
				menu = $(lastActive).children()[0];
				// add click callback function to <a> tag
				setMenu(menu);
			}

			var url = $(this).attr("href");
			$("#" + showId).load(url);
			$(li).attr("class", "active");
			var html = "<strong>" +$(this).text() + "</strong>"
			$(li).html(html);
			$($(li).children()[0]).attr("href", url);
			return false
		});
	};

	menus = $("#" + menuId + "> ul>li>a");
	menus.each(setMenu);
	$(menus[0]).trigger("click");
</script>
"""%(menuId, showId))

