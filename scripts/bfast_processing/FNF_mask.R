## prepare forest mask for BFAST
# land cover map

### load the parameters
source('~/uga_activity_data/scripts/get_parameters.R')

### load data
## 2015 land cover map
lc2015 <- paste0(lc15_dir,'sieved_LC_2015.tif')
## 2017 land cover map
lc2017 <- paste0(lc17_dir,'LC_2017_18012019.tif')
## 2017 land cover map aligned with 2015 map- this is from the ad1_prepare_maps script
lc2017.aligned <- paste0(lc17_dir,'LC_2017_18012019_aligned.tif')

# output mask for BFAST
FNF_mask <- paste0(lc_dir,'FNF_mask_2015_2017.tif')

## match the extent of the 2 LC maps -- using the extent of 2015
bb<- extent(raster(lc2015))
extent(raster(lc2017))
extent(raster(lc2015))
if(!file.exists(lc2017.aligned)){
system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
               floor(bb@xmin),
               ceiling(bb@ymax),
               ceiling(bb@xmax),
               floor(bb@ymin),
               lc2017,
               lc2017.aligned
))
}
extent(raster(lc2017.aligned))

#################### reclassify LC map into  mask
if(!file.exists(FNF_mask)){
system(sprintf("gdal_calc.py -A %s -B %s --type=Byte --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               lc2015,
               lc2017.aligned,
               FNF_mask,
               paste0("((A<6)+(B<6))*1")
))
}

#################### reproject mask to latlong WGS84
if(!file.exists(paste0(lc_dir,"FNF_mask_2015_2017_proj.tif"))){
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
               "EPSG:4326",
               FNF_mask,
               paste0(lc_dir,"FNF_mask_2015_2017_proj.tif")
))
}
gdalinfo(FNF_mask,mm=T)
plot(raster(FNF_mask))

