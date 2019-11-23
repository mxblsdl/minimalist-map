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
library(ggridges) # achieves ridges look to data
library(grid) # extra background plotting function
library(RColorBrewer) # not needed but nice to play with 

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

# background gridient function
# From: https://stackoverflow.com/questions/30136725/plot-background-colour-in-gradient
make_gradient <- function(deg = 45, n = 100, cols = blues9) {
  cols <- colorRampPalette(cols)(n + 1)
  rad <- deg / (180 / pi)
  mat <- matrix(
    data = rep(seq(0, 1, length.out = n) * cos(rad), n),
    byrow = TRUE,
    ncol = n
  ) +
    matrix(
      data = rep(seq(0, 1, length.out = n) * sin(rad), n),
      byrow = FALSE,
      ncol = n
    )
  mat <- mat - min(mat)
  mat <- mat / max(mat)
  mat <- 1 + mat * n
  mat <- matrix(data = cols[round(mat)], ncol = n)
  grid::rasterGrob(
    image = mat,
    width = unit(1, "npc"),
    height = unit(1, "npc"), 
    interpolate = TRUE
  )
}
### Set output name
# name = "Oregon"
name = "India"

# load raster from given directory
# Data comes from https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-density-rev11
r <- dir("data", full.names = T, pattern = ".tif$")

# list available data
r

# I have multiple tif files in my data directory
# select correct one
r <-
  raster(r[2])

# various permutations
# elevation
# r <- raster("../../Fun_work/elevation_maps/raster_data/elevation_wgs.tif")

# select shapefile to clip data to
# STATES
# poly <-
#    read_sf("data/states_21basic/states.shp") %>%
#     filter(STATE_NAME == name)
# 
# # OR COUNTIES
# urban <-
#   read_sf("../../GIS data/or_counties/counties.shp") %>%
#   dplyr::filter(COUNTY == '051')
# 
# # Portland city limits
# poly <-
#   read_sf("../../GIS data/pdx_City_Boundaries/City_Boundaries.shp") %>%
#   filter(CITYNAME == "Portland")

# India
poly <-
  read_sf("../../GIS data/India_SHP/INDIA.shp")

# raster data can be in any projection for this process
# project shapefile to raster, much faster than projecting the raster
poly <-
  st_transform(poly, crs = crs(r))

# crop and mask to area of interest
r <- crop(r, poly)
r <- mask(r, poly)

# This step will vary depending on the size of the project and resolution of the input data
while(length(r) > 100000) { # some arbitrary limit
  # averaging values to smooth graph

  # warning: if your datatable has too many rows you wont be able to plot
  # I'm not sure the limit, but around 70,000 rows makes a really detailed end plot
  # Anything more than this wont really look good
  # This all depends on the input raster
    r <- aggregate(r, fact = 2, fun = mean, na.rm = T)
}

# to data.table format
# This can be a very long process without the helper function
r_dt <-
  as.data.table.raster(r, xy = T, na.rm = F)


# Name columns
r_dt <- r_dt[,1:3]
names(r_dt) <- c("x", "y", "value")

# optionally set the highest points a different color
high_points <- copy(r_dt)
high_points[, value := ifelse(value > 6200, value, NaN)]

# create a background color scheme to match the flag of India
g <- make_gradient(
  deg = 90, n = 1000, cols = c("#ff9b30", "white", "#0a8902")
)

#### ggridges method
fill = "#F8F8FF" # background color
line_col = "#333230" # color of ridge lines

ggplot(r_dt, aes(x = x, 
                 y = y,
                 group = y,
                 height = value)) +
  # add in the background colors
  annotation_custom(g, xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf) + 
    geom_density_ridges(stat = "identity", 
                      scale = 25, # intensity of spikes
                      fill = fill,
                      color = line_col) +
  # Secondary highlights disabled for now
  # geom_density_ridges(data = high_points, aes(x = x, 
  #                                             y = y,
  #                                             group = y,
  #                                             height = value),
  #                     stat = "identity",
  #                     color = c("#FFF68F"),
  #                     fill = NA,
  #                     scale = 15,
  #                     lwd = 1) +
  theme_void() + # drop all axes, lines, etc...
  theme(panel.background = element_rect(fill= fill,
                                        colour= fill),
        plot.background = element_rect(fill = fill,
                                       colour = fill)) +
  coord_cartesian()
 

## output file
ggsave(paste0(name, ".png"),
     dpi = 600, # always keep a high dots per inch
    height = 6, # may need to change based on image
   width = 8)
