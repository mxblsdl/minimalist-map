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
library(ggridges)

# Stop numbers from rendering as scientific notation
options(scipen = 10)

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
  #if(xy) coln <- c("x", "y", coln)
  #setnames(v, coln)
  v
}


### Set State Name
name = "Oregon"

# load raster from given directory
r <- dir("data", full.names = T, pattern = ".tif$")

# list available data
r

# I have multiple tif files in my data directory
r <-
  raster(r[2])

# elevation
r <- raster("../../Fun_work/elevation_maps/raster_data/elevation_wgs.tif")

# select shapefile to clip data to

# STATES
poly <-
   read_sf("data/states_21basic/states.shp") %>%
    filter(STATE_NAME == name)

# OR COUNTIES
urban <-
  read_sf("../../GIS data/or_counties/counties.shp") %>%
  dplyr::filter(COUNTY == '051')

# Portland city limits
poly <-
  read_sf("../../GIS data/pdx_City_Boundaries/City_Boundaries.shp") %>%
  filter(CITYNAME == "Portland")

# India
poly <-
  read_sf("../../GIS data/India_SHP/INDIA.shp")

# raster data can be in any projection for this process
poly <-
  st_transform(poly, crs = crs(r))

# poly <-
#   st_buffer(poly, dist = 0.001, endCapStyle = "FLAT")
plot(poly)
plot(r)
# crop and mask to area of interest
r <- crop(r, poly)
r <- mask(r, poly)

# levels(r)[[1]] <- NULL

if(length(r) > 100000) {
  # averaging values to smooth graph
  # important for large rasters as the next step is memory heavy
  r <- aggregate(r, fact = 2, fun = mean, na.rm = T)
}
if(length(r) > 100000) {r <- aggregate(r, fact = 2, fun = mean, na.rm = T)}
if(length(r) > 100000) {r <- aggregate(r, fact = 2, fun = mean, na.rm = T)}

# to data.table format
# This can be a very long process without the helper function
r_dt <-
  as.data.table.raster(r, xy = T, na.rm = F)

# warning: if your datatable has too many rows you wont be able to plot
# I'm not sure the limit, but around 70,000 rows makes a really detailed end plot
# Anything more than this wont really look good
# This all depends on the input raster

# Name columns
r_dt <- r_dt[,1:3]
names(r_dt) <- c("x", "y", "value")

summary(r_dt$value)

r_dt %>%
  filter(value > 6200) %>%
  nrow()

high_points <- copy(r_dt)

high_points[, value := ifelse(value > 6200, value, NaN)]

#### ggridges method testing
fill = "#8B8989"

fill = "#F8F8FF"
line_col = "#333230"

ggplot(r_dt, aes(x = x, 
                 y = y,
                 group = y,
                 height = value)) +
    geom_density_ridges(stat = "identity", 
                      scale = 25, # intensity of spikes
                      fill = fill,
                      color = line_col) +
  # geom_density_ridges(data = high_points, aes(x = x,
  #                                             y = y,
  #                                             group = y,
  #                                             height = value),
  #                     stat = "identity",
  #                     color = c("#FFF68F"),
  #                     fill = NA,
  #                     scale = 15,
  #                     lwd = 1) +
  theme_void() +
  theme(panel.background = element_rect(fill= fill,
                                        colour= fill),
        plot.background = element_rect(fill = fill,
                                       colour = fill)) +
  coord_cartesian(clip = "off")
 
name = "India"
ggsave(paste0(name, ".png"),
     dpi = 600,
    height = 6,
   width = 8)
