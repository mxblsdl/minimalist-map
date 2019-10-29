# Create Minimalist Line Maps
+ [Main Objective](#Purpose)
+ [Requirements](#Requirements:)
+ [Libraries](#Libraries-needed)
+ [Resources](#Resource)
+ [Known issues](#Issues)

![basal-area](images/ca_basal_area.png)
*Above Map Shows Biomass of CA*

## Purpose

To make sylistic maps from any raster data input in reproducable and understandable code

***
All work is done with R statistical software

### Requirements:
+ Raster data of something
+ Shapefile of area of interest
+ R software

***

### Libraries needed

    library(dplyr) # data manipulation
    library(raster) # read raster data
    library(sf) # read polygons
    library(ggplot2) # graphing 
    library(data.table) # for raster manipulation


This script can be used to make a map similar to the one above with any input raster. 

### Resources

This workflow is inspired by a blogs postsI found while researching the excellent [velox package](http://philipphunziker.com/velox/extract.html). 

This lead me to another [useful blog](https://www.whackdata.com/2014/08/04/line-graphs-parallel-processing-r/) post about line maps.

### Issues

There is a known issue that the maps come out odd when there are disconnected lines of latitude. Imagine Washington State with Puget Sound. This workflow would connect the Olympic Peninsula to the Seattle area and the water of Puget Sound would appear to be land with low values.

 California works well for these maps as it is a single block, similar to a rectangular column. 

I am currently working on this and if anyone finds a fix please share.