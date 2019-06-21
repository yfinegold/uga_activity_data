####################################################
## Uganda prepare data for activity data analysis ##
####################################################
## This script reprojects the map data and combines 
## the maps 
## contact : yelena.finegold@fao.org
## created : 09 April 2019
## modified: 06 May 2019
####################################################

### load the parameters
source('~/uga_activity_data/scripts/get_parameters.R')

### load data
## 2015 land cover map
lc2015 <- paste0(lc15_dir,'sieved_LC_2015.tif')
## forest management areas
mgmt   <- paste0(mgmt_dir,'Protected_Areas_UTMWGS84_dslv.shp')

## Latlong projection used to reproject data
proj <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"

### assign names to data that will be created in this script
mgmt.proj <- paste0(mgmt_dir,'Protected_Areas_WGS84_dslv.shp')
mgmt.proj.tif <- paste0(mgmt_dir,"Protected_Areas_WGS84_dslv.tif")
mgmt.tif <- paste0(mgmt_dir,"Protected_Areas_UTM_dslv.tif")

## 
bfast_change <- paste0(thres_dir,'BFAST_change_2015_2017.tif')
bfast_change.utm <- paste0(thres_dir,'BFAST_change_2015_2017_UTM.tif')
bfast_change.utm.align <- paste0(thres_dir,'BFAST_change_2015_2017_aligned.tif')

plot(raster(bfast_change))
gdalinfo(mgmt.tif)
################### project to UTM
if(!file.exists(bfast_change.utm)){
  system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
                 "EPSG:32636",
                 bfast_change,
                 bfast_change.utm
  ))
}
# clip bfast output to mask
system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -tr %s %s -co COMPRESS=LZW %s %s",
               extent(raster(mgmt.tif))@xmin,
               extent(raster(mgmt.tif))@ymax,
               extent(raster(mgmt.tif))@xmax,
               extent(raster(mgmt.tif))@ymin,
               res(raster(mgmt.tif))[1],
               res(raster(mgmt.tif))[2],
               bfast_change.utm,
               bfast_change.utm.align
))
gdalinfo(bfast_change.utm.align)
###############################################################################
################### INCLUDE FOREST MANAGEMENT INFORMATION
###############################################################################

################### CREATE PRIVATE LANDS MASK
if(!file.exists(paste0(mgmt_dir,"private_lands_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 mgmt.tif,
                 paste0(mgmt_dir,"private_lands_UTM.tif"),
                 paste0("(A==0)*1"
                 )
  ))
}
################### CREATE UWA LANDS MASK
if(!file.exists(paste0(mgmt_dir,"UWA_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 mgmt.tif,
                 paste0(mgmt_dir,"UWA_UTM.tif"),
                 paste0("(A==10)*1"
                 )
  ))
}
################### CREATE NFA LANDS MASK
if(!file.exists(paste0(mgmt_dir,"NFA_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 mgmt.tif,
                 paste0(mgmt_dir,"NFA_UTM.tif"),
                 paste0("(A==100)*1"
                 )
  ))
}

################### CHANGE MAP ON PRIVATE LANDS
if(!file.exists(paste0(ad_dir,"BFAST_change_2015_2017_06062019_private_lands_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 bfast_change.utm.align,
                 paste0(mgmt_dir,"private_lands_UTM.tif"),
                 paste0(ad_dir,"BFAST_change_2015_2017_06062019_private_lands_UTM.tif"),
                 paste0("(A*B)+(B<1)*0"
                 )
  ))
}
plot(raster(bfast_change.utm.align))

plot(raster(paste0(mgmt_dir,"private_lands_UTM.tif")))
plot(raster(paste0(ad_dir,"BFAST_change_2015_2017_06062019_private_lands_UTM.tif")))

################### CHANGE MAP ON UWA LANDS
if(!file.exists(paste0(ad_dir,"BFAST_change_2015_2017_06062019_UWA_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 bfast_change.utm.align,
                 paste0(mgmt_dir,"UWA_UTM.tif"),
                 paste0(ad_dir,"BFAST_change_2015_2017_06062019_UWA_UTM.tif"),
                 paste0("(A*B)"
                 )
  ))
}

################### CHANGE MAP ON NFA LANDS
if(!file.exists(paste0(ad_dir,"BFAST_change_2015_2017_06062019_NFA_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 bfast_change.utm.align,
                 paste0(mgmt_dir,"NFA_UTM.tif"),
                 paste0(ad_dir,"BFAST_change_2015_2017_06062019_NFA_UTM.tif"),
                 paste0("(A*B)+(A==0)*0"
                 )
  ))
}

