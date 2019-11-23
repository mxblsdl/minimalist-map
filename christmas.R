######  ##    ##  #######  ##      ## 
##    ## ###   ## ##     ## ##  ##  ## 
##       ####  ## ##     ## ##  ##  ## 
######  ## ## ## ##     ## ##  ##  ## 
## ##  #### ##     ## ##  ##  ## 
##    ## ##   ### ##     ## ##  ##  ## 
######  ##    ##  #######   ###  ###  


rm(list=ls())

## general setup
# install.packages(c("ggplot2", "gganimate", "extrafont", "showtext", "gifski", "png"))
library(ggplot2)
library(gganimate)
library(extrafont)
library(showtext)

# make font available ("The Perfect Christmas")
font_import(paths = getwd(), pattern="The Perfect Christmas", prompt = F) 
loadfonts()
font_import()
## flake setup
n <- 50                 # the number of flakes
twists <- 10            # how often a flake will change its direction on its way down
#speed <- .05            # how fast the flake hits the ground, measured in units decrease on [0,1] y-axis

## flake generation
snow_long <- NULL
for (i in 1:twists){
  
  if(i==1){
    
    # initialize first set of snow flakes
    snow_tmp <- data.frame(id=1:n, x=runif(n), y=runif(n), t=1)
    
  }else{                   
    
    # use most recent snowflakes
    snow_last <- snow_long[(nrow(snow_long)-n+1):nrow(snow_long),]
    
    # for all flakes outside the runif range [0,1] ...
    snow_last$id[snow_last$y < 0.05] <- snow_last$id[snow_last$y < 0.05] + n    #... assign a new flake ID
    snow_last$y[snow_last$y < 0.05]  <- snow_last$y[snow_last$y < 0.05] + 1     #... move them back up in the valid flake space [0,1]
    
    # make all the flakes go down
    snow_tmp <- data.frame(id=snow_last$id,
                           x=jitter(snow_last$x, amount=.05),   # jitter along the x-axis
                           y=snow_last$y-.05,                 # decrease y-position
                           t=i)
    
  }
  snow_long <- rbind.data.frame(snow_long, snow_tmp)
}
#snow_long

# make flake ID a factor so it'll know which flakes to connect
snow_long$id  <- as.factor(snow_long$id)
snow_long$rn <- runif(nrow(snow_long))

p <-
  ggplot(snow_long, aes(x,y,group=id)) + 
  geom_point(aes(alpha=rn), size=3, col="white", shape=8, show.legend = FALSE) +
  labs(x="", y="") +
  lims(x=c(0,1)) +
  theme(panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_rect(fill = "deepskyblue4"),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  annotate("text", x=.5, y=.5, col="white", size=10,
           label = "The weather outside is frightful\nbut it's snowing!!!",
           family = font[3])

font <- fonts()
# let it snow!
animate(p + transition_time(t), 
        nframes=100, 
        fps=100, 
        width = 600, 
        height = 600)
