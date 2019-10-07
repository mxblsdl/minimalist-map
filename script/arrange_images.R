# arrange plots of CA together


library(png)
library(grid)
library(gridExtra)

images <- 
  dir(pattern = ".png$")

plot1 <- readPNG(images[1])
plot2 <- readPNG(images[2])


grid.arrange(rasterGrob(plot1),rasterGrob(plot2),ncol = 2,
             top=textGrob("Tree Density Vs. Human Density",
                          gp=gpar(fontsize=20,font=3)))
