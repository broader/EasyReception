par(mar=rep(0,4))
dat = read.csv(textConnection("city,jd,wd
    北京,116.4666667,39.9
    上海,121.4833333,31.23333333
    天津,117.1833333,39.15
    济南,117,36.63333333
    南京,118.8333333,32.03333333
    成都,104.0833333,30.65
    贵阳,106.7,26.58333333
    广州,113.25,23.13333333
    海口,110.3333333,20.03333333
    南宁,108.3333333,22.8"))
library(maps)
library(mapdata)
#library(maptools)

map("china", col = "darkgray", ylim = c(18, 54), panel.first = grid())
points(dat$jd, dat$wd, pch = 19, col = rgb(1, 0, 0, 1))
#pointLabel(dat$jd, dat$wd, as.character("*"))

text(dat$jd, dat$wd, dat[, 1], cex = 0.8, col = rgb(0,
    0, 0, 0.9), pos = c(3, 3.5, 2, 2, 3, 2, 2, 3, 2, 2 ))
axis(1, lwd = 0); axis(2, lwd = 0); axis(3, lwd = 0); axis(4, lwd = 0)
