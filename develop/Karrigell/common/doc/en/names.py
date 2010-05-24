TITLE = 'Karrigell manual'
RELEASE = "Release"

CONTENT_PAGE_HEADER = """
    <table id="header">
        <tr>
        <td id="headercontent">
            <h1>Karrigell<sup>%(version)s</sup></h1>
            <h2>A pythonic web framework</h2>
        </td>

        <td id="section">
            <h1>Reference Manual</h1>

        </td>

    </table>
        <div id="menu">
            <ul>
                <li><a href="../index.py">Documentation</a></li>
                <li><a href="http://sourceforge.net/project/showfiles.php?group_id=67940">Downloads</a></li>
                <li><a href="/doc/en/tour/tour.pih">Getting Started</a></li>
                <li><a href="" class="active">Reference</a></li>
                <li><a href="http://groups.google.com/group/karrigell">Community</a></li>
            </ul>
        </div>
        <div id="menubottom"></div>

"""

PAGE_HEADER = """
    <table id="header">
        <tr>
        <td id="headercontent">
            <h1>Karrigell<sup>%(version)s</sup></h1>
            <h2>A pythonic web framework</h2>
        </td>

        <td id="section">
            <h1>Reference Manual</h1>

        </td>

    </table>

"""

previous = """<img src='../images/previous.png'  border='0' height='32'  
    alt='Previous Page.0' width='32' />"""
previous1 = '<li><a rel="prev" title="%s" href="%s">'

up = """<img src='../images/up.png' border='0' height='32'  
    alt='Upper level' width='32' />"""
up1 = '<li><a rel="up" title="%s" href="%s">'

next = """<img src='../images/next.png'
  border='0' height='32'  alt='Next Page' width='32' />"""
next1 = '<li><a rel="next" title="%s" href="%s">'

previous2 = '<b class="navlabel">Previous:</b>'
previous2 += '<a class="sectref" rel="prev" href="%s">'
previous2 += '%s. %s</A>'

up2 = '<b class="navlabel">Up:</b>'
up2 += '<a class="sectref" rel="parent" href="../reference.ks">Contents</A>'

next2 = '<b class="navlabel">Next:</b>'
next2 += '<a class="sectref" rel="next" href="%s">'
next2 += '%s. %s</A>'
