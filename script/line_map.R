# About -------------------------------
# Script to produce minimalist line maps of raster data

# inspired by a post found while exploring the velox package (which is also great)
# http://philipphunziker.com/velox/extract.html

# The above link led me to this post:
# https://www.whackdata.com/2014/08/04/line-graphs-parallel-processing-r/
# which was also very helpful in getting this to work

# Currently written to download data based on the chosen country
# See ?getData() for more info on this

# Additional elevation data for the US
# Data comes from https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-density-rev11

# Library -------------------------------------

library(raster) # read raster data
library(ggplot2) # graphing 
library(sf) # read polygons
library(ggridges) # achieves ridges look to data
library(grid) # extra background plotting function

# Functions ----------------------

## Helper ----------------------
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

## Main functions -------------------------

# see getData('ISO3') for a list of all country codes
# tol is an arbitrary number to help refine the detail of the line map
prepare_poly_country <- function(country, tol, path = tempdir()) {
  # utilizes the getData function to download elevation data for any country
  # many other options exist for this function
  # Default downloads to a temp folder
  r_sub <- getData(name = 'alt', country = country, path = path)
  
  # added as USA is a list
  if(class(r_sub) == "list") {
    r_sub <- r_sub[[1]]
    warning("country downloaded as list")
    }
  
  while(length(r_sub) > tol * 10000) { # some arbitrary limit
    # averaging values to smooth graph
    # warning: if your datatable has too many rows you wont be able to plot
    # I'm not sure the limit, but around 70,000 rows makes a really detailed end plot
    # Anything more than this wont really look good
    # This all depends on the input raster
    r_sub <- aggregate(r_sub, fact = 2, fun = mean, na.rm = T)
  }  
  return(r_sub)
}

prepare_dt <- function(raster) {
  # This can be a very long process without the helper function
  r_dt <-
    as.data.table.raster(raster, xy = T, na.rm = F)
  
  # Name columns
  r_dt <- r_dt[,1:3]
  names(r_dt) <- c("x", "y", "value")  

  return(r_dt)
}

prepare_plot <- function(fill, line_col, dt, grad = F ) {
  g <- 
    ggplot(dt, aes(x = x, 
                   y = y,
                   group = y,
                   height = value)) +
    geom_density_ridges(stat = "identity", 
                        scale = 15, # intensity of spikes
                        fill = fill,
                        color = line_col) +
    theme_void() + # drop all axes, lines, etc...
    theme(panel.background = element_rect(fill= fill,
                                          colour= fill),
          plot.background = element_rect(fill = fill,
                                         colour = fill)) +
    coord_cartesian()
  
  if(grad) {
    g + annotation_custom(grad, xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf) 
  }
  
  return(g)
}

# Example --------------------------------------------

r <- prepare_poly_country("JPN", tol = 14)
r_dt <- prepare_dt(r)
prepare_plot(dt = r_dt, fill = "black", line_col = "grey20")

