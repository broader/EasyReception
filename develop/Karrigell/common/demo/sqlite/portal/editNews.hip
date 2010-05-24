# edits a news

Include ("header.hip")

table = Import("portalDb",REL=REL).table

so=Session()
news=table['news'][int(_id)]

print "<h3>%s</h3>" %_("Edit existing news")
Include("newsForm.pih",
    action="updateNews.py",
    news=news)
