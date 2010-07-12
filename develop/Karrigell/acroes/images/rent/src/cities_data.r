par(mar=rep(0,4))
dat = read.csv(textConnection("City,jd,wd
    Beijing,116.4666667,39.9
    Shanghai,121.4833333,31.23333333
    Tianjin,117.1833333,39.15
    Chongqing,106.5333333,29.53333333"))
library(maps)
library(mapdata)
map("china", col = "darkgray", ylim = c(18, 54), panel.first = grid())
points(dat$jd, dat$wd, pch = 19, col = rgb(0, 0, 0, 0.5))
text(dat$jd, dat$wd, dat[, 1], cex = 0.9, col = rgb(0,
    0, 0, 0.7), pos = c(2, 4, 4, 4, 3, 4, 2, 3, 4, 2, 4, 2, 2,
    4, 3, 2, 1, 3, 1, 1, 2, 3, 2, 2, 1, 2, 4, 3, 1, 2, 2, 4, 4, 2))
axis(1, lwd = 0); axis(2, lwd = 0); axis(3, lwd = 0); axis(4, lwd = 0)
