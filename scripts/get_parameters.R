####################################################################################################
####################################################################################################
## Set environment variables
## Contact yelena.finegold@fao.org 
## 2019/05/29
####################################################################################################
####################################################################################################

####################################################################################################

### Read all external files with TEXT as TEXT
options(stringsAsFactors = FALSE)

### Create a function that checks if a package is installed and installs it otherwise
packages <- function(x){
  x <- as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}


### Load necessary packages
## Packages for geospatial data handling
packages(raster)
packages(rgeos)
packages(rgdal)
packages(Formula)
packages(gdalUtils)

## Packages for data table handling
packages(xtable)
packages(DT)
packages(dismo)
packages(stringr)
packages(plyr)
packages(Hmisc)
packages(survey)
packages(dplyr)
packages(reshape2)

## Packages for graphics and interactive maps
packages(ggplot2)

## Packages to download GFC data
packages(devtools)
install_github('yfinegold/gfcanalysis')
library(gfcanalysis)

## Set the working directory
rootdir       <- "~/uga_activity_data/"

## Set the country code
countrycode <- "UGA"

## Set MMU for filtering raster
mmu <- 11

## Go to the root directory
setwd(rootdir)
rootdir <- paste0(getwd(),"/")

scriptdir<- paste0(rootdir,"scripts/misc/")
data_dir <- paste0(rootdir,"data/")
bfast_dir<- paste0(rootdir,"data/bfast/")
thres_dir<- paste0(bfast_dir,"threshold/")
lc_dir   <- paste0(rootdir,"data/forest_mask/")
nfi_dir  <- paste0(rootdir,"data/nfi/")
mgmt_dir <- paste0(rootdir,"data/forest_management/")
mspa_dir <- paste0(rootdir,"data/MSPA/")

ad_dir   <- paste0(rootdir,"data/AD/")
ref_dir  <- paste0(ad_dir,"ref/")

lc15_dir <- paste0(data_dir,"lc_2015/")
lc17_dir <- paste0(data_dir,"lc_2017/")
gadm_dir <- paste0(data_dir,"gadm/")
gfc_dir  <- paste0(data_dir,'gfc/')

fld_dir  <- paste0(rootdir,"data/field_data/")
coll_dir <- paste0(fld_dir,'collected_samples/')
ana_dir  <- paste0(fld_dir,'analysis/')
plts_dir <- paste0(fld_dir,"bfast_plots/")
tile_dir <- paste0(bfast_dir,"tiles/")


dir.create(data_dir,showWarnings = F)
dir.create(bfast_dir,showWarnings = F)
dir.create(thres_dir,showWarnings = F)
dir.create(lc_dir,showWarnings = F)
dir.create(nfi_dir,showWarnings = F)
dir.create(mgmt_dir,showWarnings = F)
dir.create(ref_dir,showWarnings = F)
dir.create(ana_dir,showWarnings = F)
dir.create(mspa_dir,showWarnings = F)
dir.create(fld_dir,showWarnings = F)

dir.create(ad_dir,showWarnings = F)
dir.create(lc15_dir,showWarnings = F)
dir.create(lc17_dir,showWarnings = F)
dir.create(gadm_dir,showWarnings = F)
dir.create(tile_dir,showWarnings = F)
dir.create(gfc_dir,showWarnings = F)


############ CREATE A FUNCTION TO GENERATE REGULAR GRIDS
generate_grid <- function(aoi,size){
  ### Create a set of regular SpatialPoints on the extent of the created polygons  
  sqr <- SpatialPoints(makegrid(aoi,offset=c(-0.5,-0.5),cellsize = size))
  
  ### Convert points to a square grid
  grid <- points2grid(sqr)
  
  ### Convert the grid to SpatialPolygonDataFrame
  SpP_grd <- as.SpatialPolygons.GridTopology(grid)
  
  sqr_df <- SpatialPolygonsDataFrame(Sr=SpP_grd,
                                     data=data.frame(rep(1,length(SpP_grd))),
                                     match.ID=F)
  ### Assign the right projection
  proj4string(sqr_df) <- proj4string(aoi)
  sqr_df
}

################# PIXEL COUNT FUNCTION AND IMAGE STAT FUNCTIONS
pixel_count <- function(x){
  info    <- gdalinfo(x,hist=T)
  buckets <- unlist(str_split(info[grep("bucket",info)+1]," "))
  buckets <- as.numeric(buckets[!(buckets == "")])
  hist    <- data.frame(cbind(0:(length(buckets)-1),buckets))
  hist    <- hist[hist[,2]>0,]
}

pixel_mean <- function(x){
  info    <- gdalinfo(x)
  p.mean  <- as.numeric(unlist(str_split(info[grep("STATISTICS_MEAN=",info)],"="))[2])
}

pixel_min <- function(x){
  info    <- gdalinfo(x)
  p.min   <- as.numeric(unlist(str_split(info[grep("STATISTICS_MINIMUM=",info)],"="))[2])
}

pixel_max <- function(x){
  info    <- gdalinfo(x)
  p.max   <- as.numeric(unlist(str_split(info[grep("STATISTICS_MAXIMUM=",info)],"="))[2])
}

pixel_sd <- function(x){
  info    <- gdalinfo(x)
  p.sd    <- as.numeric(unlist(str_split(info[grep("STATISTICS_STDDEV=",info)],"="))[2])
}
