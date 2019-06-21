###### this script prepares a water mask to use incase we want to exlude the stable water in both LULC2015 and 2017 from sampling

### load the parameters
source('~/uga_activity_data/scripts/get_parameters.R')

### load data
## 2015 land cover map
lc2015_vector.tif <- paste0(lc15_dir,'LULC_2015_10052019.tif')

## 2017 land cover map
lc2017_vector.tif <- paste0(lc17_dir,'LULC_2017_10052019.tif')

##check the extents of the maps. these are supported to be aligned, otherwise run lines 17-33 to align the two maps
extent(raster(lc2017_vector.tif))
extent(raster(lc2015_vector.tif))

## assign a name to 2017 land cover map aligned with 2015 map that will be created
lc2017.aligned <- paste0(lc17_dir,'LC_2017_10052019_aligned.tif')
## match the extent of the 2 LC maps -- using the extent of 2015
bb<- extent(raster(lc2015_vector.tif))

##if the two rasters are not well aligned, then align one to match the other. 2017 to match 2015
if(!file.exists(lc2017.aligned)){
  system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
                 floor(bb@xmin),
                 ceiling(bb@ymax),
                 ceiling(bb@xmax),
                 floor(bb@ymin),
                 lc2017_vector.tif,
                 lc2017.aligned
  ))
}
extent(raster(lc2017.aligned))

# assign a name to output Water mask
water_mask <- paste0(lc_dir2,'water_mask_2015_2017.tif')

#################### reclassify LC map into  mask
if(!file.exists(water_mask)){
  system(sprintf("gdal_calc.py -A %s -B %s --type=Byte --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
                 lc2015_vector.tif,
                 lc2017_vector.tif,
                 water_mask,
                 paste0("((A==12)+(B==12))*1")
  ))
}

##plot the mask
plot(raster(water_mask))

#################### reproject mask to latlong WGS84
if(!file.exists(paste0(lc_dir2,"water_mask_2015_2017_proj.tif"))){
  system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
                 "EPSG:4326",
                 water_mask,
                 paste0(lc_dir2,"water_mask_2015_2017_proj.tif")
  ))
}
gdalinfo(water_mask,mm=T)


