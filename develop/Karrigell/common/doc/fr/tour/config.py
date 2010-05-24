for k in dir(CONFIG):
	if not k.startswith("_"):
		print k,":",getattr(CONFIG,	k),"<BR>"