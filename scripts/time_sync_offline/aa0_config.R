####################################################################################################
####################################################################################################
## Configure the AA scripts
## Contact remi.dannunzio@fao.org
## 2018/08/31
####################################################################################################
####################################################################################################

the_map    <- paste0(thres_dir,'BFAST_change_2015_2017.tif')
sae_dir <- ref_dir
# sae_dir    <- paste0(dirname(the_map),"/","sae_design_",substr(basename(the_map),1,nchar(basename(the_map))-4),"/")
point_file <- paste0(ref_dir,"collectearth_20170526_new.csv")

####################################################################################################
options(stringsAsFactors=FALSE)

library(Hmisc)
library(sp)
library(rgdal)
library(raster)
library(plyr)
library(foreign)
library(dplyr)
library(rgeos)

