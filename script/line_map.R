# Script to produce minimalist line maps of raster data

# inspired by a post found while exploring the velox package (which is also great)
# http://philipphunziker.com/velox/extract.html

# The above link led me to this post:
# https://www.whackdata.com/2014/08/04/line-graphs-parallel-processing-r/
# which was also very helpful in getting this to work

library(dplyr) # data manipulation
library(raster) # read raster data
library(ggplot2) # graphing 
library(sf) # read polygons

# Stop numbers from rendering as scientific notation
options(scipen = 10)

# helper functions
# get a percentage range of vector
range <- function(x) {
  (x - min(x)) / (max(x) - min(x))
  }

# faster raster to dt function
# Comes from https://gist.github.com/etiennebr/9515738
as.data.table.raster <- function(x, row.names = NULL, optional = FALSE, xy=FALSE, inmem = canProcessInMemory(x, 2), ...) {
  stopifnot(require("data.table"))
  if(inmem) {
    v <- as.data.table(as.data.frame(x, row.names=row.names, optional=optional, xy=xy, ...))
  } else {
    tr <- blockSize(x, n=2)
    l <- lapply(1:tr$n, function(i) 
      as.data.table(as.data.frame(getValues(x, 
                                            row=tr$row[i], 
                                            nrows=tr$nrows[i]), 
                                  row.names=row.names, optional=optional, xy=xy, ...)))
    v <- rbindlist(l)
  }
  coln <- names(x)
  if(xy) coln <- c("x", "y", coln)
  setnames(v, coln)
  v
}

# load raster from given directory
r <- dir("data", full.names = T, pattern = ".tif$")

# I have multiple tif files in my data directory
r <-
  raster(r[2])

# set a descriptive file name for output
output_name <- "ca_population"

# I made a shp file of CA without the Santa Cruz islands
# Islands cause problems with these plots
poly <-
  read_sf("data/ca/ca_no_islands.shp")

# project state to raster
# raster data can be in any projection for this process
poly <-
  st_transform(poly, crs = crs(r))

# crop and mask to area of interest
r <-
  crop(r, poly)
r <- 
  mask(r, poly)

# averaging values to smooth graph
# important for large rasters as the next step is memory heavy
r <-
  aggregate(r, fact = 8, fun = mean, na.rm = T)

# to data.table format
# This can be a very long process without the helper function
r_dt <-
  as.data.table.raster(r, xy = T, na.rm = T)

# WARNING: if your datatable has too many rows you wont be able to plot
# I'm not sure the limit, but around 70,000 rows makes a really detailed end plot
# Anything more than this wont really look good
# This all depends on the input raster

# Name columns
names(r_dt) <- c("x", "y", "value")

# Rescale the values and calculate the x/y ranges 
# This is to ensure that you can see the variation in the data
r_dt$value_st<-range(r_dt$value) * 0.1 # play with this number if you want
r_dt$x_st<-range(r_dt$x)
r_dt$y_st<-range(r_dt$y)

# create graphing object
values_s <- r_dt

# get values to run loop over
k <-
  unique(values_s$y_st)

# High values on the edges of the raster can cause odd polygon rendering 
# This step fixes a lot of headaches and abnormalities at the cost of some data
# zero out the edges
values_s <-
  values_s %>%
  group_by(y_st) %>%
  mutate(value_st = if_else(row_number() == 1, 0, value_st), # set first and last of each row to zero
         value_st = if_else(row_number() == n(), 0, value_st))

# call an empty ggplot
p <- ggplot()

# loop over each line of latitude adding a white polygon based on population
for(i in k) {
    p <- p + geom_polygon(data = values_s[values_s$y_st == i,],
                        aes(x_st, value_st + y_st, group = y_st),
                        size = 0.1,
                        fill = "white", # these are the base colors
                         col = "white"
                        ) + 
      # trace each polygon with a line that shows the changes in value
      geom_path(data = values_s[values_s$y_st == i,],
                aes(x_st, value_st + y_st, group = y_st),
                size = .3,
                lineend = "round",
                linejoin = "round")
    # different colors can be used here
}

#Switch off various ggplot things
quiet <- list(scale_x_continuous("", breaks = NULL),
              scale_y_continuous("", breaks = NULL))

# plot with plain white background
# worth plotting without theme to understand what is happening with the graphics
p + theme(panel.background = element_rect(fill='white',
                                          colour='white')) + quiet


# save outptu
# ggsave(filename = paste0(output_name, ".png"), 
#        dpi = 500, # keep high quality dpi
#        height = 12,# may have to change to get proportions correct
#        width = 10)

