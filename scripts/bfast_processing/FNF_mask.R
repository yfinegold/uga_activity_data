## prepare forest mask for BFAST
# land cover map

### load the parameters
source('~/uga_activity_data/scripts/get_parameters.R')

### load data
## 2015 land cover map
lc2015 <- paste0(lc15_dir,'sieved_LC_2015.tif')
## 2017 land cover map
lc2017 <- paste0(lc17_dir,'LC_2017_18012019.tif')
## 2017 land cover map aligned with 2015 map- this is from the ad2_analysis script
lc2017.aligned <- paste0(lc17_dir,'LC_2017_18012019_aligned.tif')

# output mask for BFAST
FNF_mask <- paste0(lc_dir,'FNF_mask_2015_2017.tif')
#################### reclassify LC map into THF mask
system(sprintf("gdal_calc.py -A %s -B %s --type=Byte --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               lc2015,
               lc2017.aligned,
               FNF_mask,
               paste0("((A<6)+(B<6))*1")
))

#################### reproject THF mask to latlong WGS84
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
               "EPSG:4326",
               FNF_mask,
               paste0(lc_dir,"FNF_mask_2015_2017_proj.tif")
))
gdalinfo(FNF_mask,mm=T)
plot(raster(FNF_mask))
