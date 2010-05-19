_in = open("index.htm")
out = open("new_index.htm","w")
data = _in.read()
print data

data = data.replace('frame_tour_en.htm','tour_en.pih')
out.write(data)
out.close()

