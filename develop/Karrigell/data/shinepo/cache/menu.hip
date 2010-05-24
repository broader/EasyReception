[]
PRINT( '<div id="topnav">')
PRINT( '<!-- start: skip link navigation -->')
PRINT( '<a class="skip" title="skip link" href="#navigation">Skip to the navigation</a><span class="hideme">.</span>')
PRINT( '<a class="skip" title="skip link" href="#content">Skip to the content</a><span class="hideme">.</span>')
PRINT( '<!-- end: skip link navigation -->')
PRINT( '<span style="color:#ffffff">')
PRINT( '<a href="http://www.digitalpoint.com/tools/geovisitors/" target="Geo Visitors Statistics">')
PRINT( '炫点访问统计<img src="http://geo.digitalpoint.com/a.png" alt="Geo Visitors Map" style="border:0">')
PRINT( '</a>')
PRINT( '</span>')
PRINT( '</div><!-- topnav end -->')

PRINT( '<div id="header" >')
PRINT( '<h1><span ></span></h1>')
PRINT( '</div><!-- header end -->')
PRINT( '<!-- skiplink anchor: navigation -->')
PRINT( '<a id="navigation" name="navigation"></a>')
PRINT( '<div id="nav_main" style="background:#000000 url(images/bg_hnav1.gif) repeat-x scroll left top;float:center;line-height:0; width:auto; margin-bottom:2px;border-top:1px solid #DDDDDD; border-bottom:1px solid #DDDDDD;">')
PRINT( '<ul class="lavaLampWithImage" id="menu" >')
#-_selected : the selected item, if specified
links = ('#home.pih', '#course.pih', '#certification.pih', '#others.pih', '#stage.pih', '#teacher.pih', '#', '#faq.pih', '#introduction.pih')
labels = ('首页', '舞蹈课程', '认证课程', '其他培训', '演艺制作', '教师风采', '会展服务', '热点话题',  '关于炫点')
for i, link in enumerate(links):
	if page == i:
		PRINT( '<li class="current"><a  href="%s" >%s</a></li>' %(link,labels[i]))
	else:
		PRINT( '<li><a href="%s" >%s</a></li>' %(link, labels[i]))
PRINT( '</ul>')
PRINT( '</div><!-- end of nav_main -->')

