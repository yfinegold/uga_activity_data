####################################################################################################
####################################################################################################
## Set environment variables
## Contact yelena.finegold@fao.org 
## 2019/02/26
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

## Packages for data table handling
packages(xtable)
packages(DT)
packages(dismo)
packages(stringr)
packages(plyr)

## Packages for graphics and interactive maps
packages(ggplot2)

## Set the working directory
rootdir       <- "~/uga_degradation/"

## Set the country code
countrycode <- "UGA"

## Go to the root directory
setwd(rootdir)
rootdir <- paste0(getwd(),"/")

scriptdir<- paste0(rootdir,"scripts/")
data_dir <- paste0(rootdir,"data/")
bfast_dir<- paste0(rootdir,"data/bfast/")
thres_dir<- paste0(bfast_dir,"threshold/")
lc_dir   <- paste0(rootdir,"data/forest_mask/")
nfi_dir  <- paste0(rootdir,"data/nfi/")
mgmt_dir <- paste0(rootdir,"data/forest_management/")
ref_dir  <- paste0(rootdir,"data/reference_data/")
coll_dir <- paste0(ref_dir,'collected_samples/')
ana_dir  <- paste0(ref_dir,'analysis/')


dir.create(data_dir,showWarnings = F)
dir.create(bfast_dir,showWarnings = F)
dir.create(thres_dir,showWarnings = F)
dir.create(lc_dir,showWarnings = F)
dir.create(nfi_dir,showWarnings = F)
dir.create(mgmt_dir,showWarnings = F)
dir.create(ref_dir,showWarnings = F)
dir.create(ana_dir,showWarnings = F)
