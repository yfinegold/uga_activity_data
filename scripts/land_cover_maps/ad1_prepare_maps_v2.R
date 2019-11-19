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
change <- paste0(ad_dir,"change_2015_2017_04052019.tif")
change.sieved <- paste0(ad_dir,"change_2015_2017_04052019_sieve.tif")
lc_vector <- paste0(lc17_dir,'LULC_2017_as_at_10_May_2019_by_edward.shp')
lc2015_vector.tif <- paste0(lc15_dir,'LULC_2015_04052019.tif')
lc2017_vector.tif <- paste0(lc17_dir,'LULC_2017_04052019.tif')
lc2015_vector.tif.prj <- paste0(lc15_dir,'LULC_2015_04052019_proj.tif')
lc2017_vector.tif.prj <- paste0(lc17_dir,'LULC_2017_04052019_proj.tif')

change.all <- paste0(ad_dir,"change_2015_2017_all_classes_04052019.tif")
change.all.sieved <- paste0(ad_dir,"change_2015_2017_all_classes_04052019_sieve.tif")

###############################################################################
################### vector map to raster
###############################################################################
## 2015 map
if(!file.exists(lc2015_vector.tif)){
  system(sprintf("python %soft-rasterize_attr.py -v %s -i %s -o %s -a %s",
                 scriptdir,
                 lc_vector,
                 lc2015,
                 lc2015_vector.tif,
                 "e_15"
  ))
}
## view some metadata from the new raster file
gdalinfo(lc2015_vector.tif)

## 2017 map
if(!file.exists(lc2017_vector.tif)){
  system(sprintf("python %soft-rasterize_attr.py -v %s -i %s -o %s -a %s",
                 scriptdir,
                 lc_vector,
                 lc2015,
                 lc2017_vector.tif,
                 "e_17"
  ))
}
## view some metadata from the new raster file
gdalinfo(lc2017_vector.tif)
###############################################################################
################### REPROJECT IN latlong PROJECTION
###############################################################################
# 2015 LC map
if(!file.exists(lc2015_vector.tif.prj)){
  system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
                 proj,
                 lc2015_vector.tif,
                 lc2015_vector.tif.prj
  ))
}
# 2017 LC map
if(!file.exists(lc2017_vector.tif.prj)){
  system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
                 proj,
                 lc2017_vector.tif,
                 lc2017_vector.tif.prj
  ))
}

##### reproject mgmt data into latlong

mgmt.data <- readOGR(mgmt)
#download province boundaries
adm <- getData ('GADM', country= countrycode, level=1)
#match the coordinate systems for the sample points and the boundaries
mgmt.data.proj <- spTransform(mgmt.data,crs(adm))
writeOGR(mgmt.data.proj,mgmt_dir,'Protected_Areas_WGS84_dslv',driver = 'ESRI Shapefile')
##### rasterize mgmt map               paste0(thres_dir,"combined_test.tif"),

##### latlong forest management map 
if(!file.exists(mgmt.proj.tif)){
  system(sprintf("python %soft-rasterize_attr.py -v %s -i %s -o %s -a %s",
                 scriptdir,
                 mgmt.proj,
                 lc2015_vector.tif.prj,
                 mgmt.proj.tif,
                 "code"
  ))
}

##### utm forest management map 
if(!file.exists(mgmt.tif)){
  system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
                 scriptdir,
                 mgmt,
                 lc2015_vector.tif,
                 mgmt.tif,
                 "code"
  ))
}

###############################################################################
################### create change map for all map classes
###############################################################################
#################### COMBINATION INTO NATIONAL map comparision
# 1  = stable forest plantation 
# 2  = stable forest plantation 
# 3  = stable forest THF 
# 4  = stable forest THF
# 5  = stable forest WL 
# 6  = stable non-forest Bushland 
# 7  = stable non-forest grassland 
# 8  = stable non-forest wetlands
# 9  = stable non-forest cropland
# 10 = stable non-forest cropland
# 11 = stable non-forest settlement
# 12 = stable non-forest water
# 13 = stable non-forest impediments
# 14 = hard wood plantation to coniferous plantation 
# 15 = hard wood plantation to THF 
# 16 = hard wood plantation to THF 
# 17 = hard wood plantation to WL 
# 18 = hard wood plantation to Bushland
## ... classes in between
# 98 = wetlands to hard wood plantation
## ... more classes in between
# 169 impediments to water
if(!file.exists(change.all)){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
                 lc2015_vector.tif,
                 lc2017_vector.tif,
                 change.all,
                 sprintf(
                   "((A==B) * A) +  %s %s %s %s %s %s %s %s %s %s %s %s %s %s  " ,              ## stable classes 1 to 13
                   paste0('((A==1)  * (B == ',2:13,           ') *',14:25 ,')  + ',collapse=''), ## plantation hardwood to classes 2 to 13 with values 14 to 25
                   paste0('((A==2)  * (B == ',c(1,3:13),      ') *',26:37 ,')  + ',collapse=''),
                   paste0('((A==3)  * (B == ',c(1:2,4:13),    ') *',38:49 ,')  + ',collapse=''),
                   paste0('((A==4)  * (B == ',c(1:3,5:13),    ') *',50:61 ,')  + ',collapse=''),
                   paste0('((A==5)  * (B == ',c(1:4,6:13),    ') *',62:73 ,')  + ',collapse=''),
                   paste0('((A==6)  * (B == ',c(1:5,7:13),    ') *',74:85 ,')  + ',collapse=''),
                   paste0('((A==7)  * (B == ',c(1:6,8:13),    ') *',86:97 ,')  + ',collapse=''),
                   paste0('((A==8)  * (B == ',c(1:7,9:13),   ') *',98:109 ,')  + ',collapse=''),
                   paste0('((A==9)  * (B == ',c(1:8,10:13), ') *',110:121 ,')  + ',collapse=''),
                   paste0('((A==10) * (B == ',c(1:9,11:13), ') *',122:133 ,')  + ',collapse=''),
                   paste0('((A==11) * (B == ',c(1:10,12:13),') *',134:145 ,')  + ',collapse=''),
                   paste0('((A==12) * (B == ',c(1:11,13),   ') *',146:157 ,')  + ',collapse=''),
                   paste0('((A==13) * (B == ',c(1:11),      ') *',158:168 ,')  + ',collapse=''),
                   paste0('((A==13) * (B == ',c(12),        ') *',169 ,') '      ,collapse='')
                   
                 )
                 
  ))
}

gdalinfo(change.all, mm=T)
################### SIEVE TO THE MMU
if(!file.exists(change.all.sieved)){
  system(sprintf("gdal_sieve.py -st %s %s %s ",
                 mmu,
                 change.all,
                 paste0(ad_dir,"tmp_change_2015_2017_sieve.tif")
  ))
  
  
  ################### COMPRESS
  system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
                 paste0(ad_dir,"tmp_change_2015_2017_sieve.tif"),
                 change.all.sieved
  ))
  
  ################### REMOVE UNCOMPRESSED FILE
  system(sprintf("rm %s ",
                 paste0(ad_dir,"tmp_change_2015_2017_sieve.tif")
  ))
}

###############################################################################
################### create change map
###############################################################################
#################### COMBINATION INTO NATIONAL AD SCALE MAP
# 1  = stable forest plantation to plantation
# 2  = stable forest THF to plantation
# 3  = stable forest THF to THF
# 4  = stable forest THF to WL
# 5  = stable forest WL to plantation
# 6  = stable forest WL to WL
# 7  = forest loss plantations
# 8  = forest loss THF
# 9 = forest loss woodlands
# 10 = forest gain plantations
# 11 = forest gain THF
# 12 = forest gain woodlands
# 13 = stable non-forest
if(!file.exists(change)){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
                 lc2015_vector.tif,
                 lc2017_vector.tif,
                 change,
                 paste0("(A>0)*(A<3) * (B>0)*(B<3) * 1+", ### stable forest plantation to plantation
                        "(A>2)*(A<5) * (B>0)*(B<3) * 2+", ### stable forest THF to plantation
                        "(A>2)*(A<5) * (B>2)*(B<5) * 3+", ### stable forest THF to THF
                        "(A>2)*(A<5) * (B==5)      * 4+", ### stable forest THF to woodlands
                        "(A==5) * (B==5)           * 5+", ### stable forest woodlands to woodlands
                        "(A==5) * (B>0)*(B<3)      * 6+", ### stable forest woodlands to plantation
                        "(A>0)*(A<3) * (B>5)       * 7+", ### forest loss plantation
                        "(A>2)*(A<5) * (B>5)       * 8+", ### forest loss THF
                        "(A==5) * (B>5)            * 9+", ### forest loss woodlands
                        "(A>5) * (B>0)*(B<3)       * 10+",### forest gain plantation
                        "(A>5) * (B>2)*(B<5)       * 11+",### forest gain THF
                        "(A>5) * (B==5)            * 12+",### forest gain woodlands
                        "(A>5) * (B>5)             * 13"  ### stable non-forest
                 )
  ))
}
plot(raster(change))
################### SIEVE TO THE MMU
if(!file.exists(change.sieved)){
  system(sprintf("gdal_sieve.py -st %s %s %s ",
                 mmu,
                 change,
                 paste0(ad_dir,"tmp_change_2015_2017_sieve.tif")
  ))
  
  
  ################### COMPRESS
  system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
                 paste0(ad_dir,"tmp_change_2015_2017_sieve.tif"),
                 change.sieved
  ))
  
  ################### REMOVE UNCOMPRESSED FILE
  system(sprintf("rm %s ",
                 paste0(ad_dir,"tmp_change_2015_2017_sieve.tif")
  ))
}
plot(raster(change.sieved))

################### project to latlong
if(!file.exists(paste0(ad_dir,"change_2015_2017_sieve_wgs84.tif"))){
  system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
                 proj,
                 change.sieved,
                 paste0(ad_dir,"change_2015_2017_04052019_sieve_wgs84.tif")
  ))
}

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
if(!file.exists(paste0(ad_dir,"change_2015_2017_private_lands_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 change.sieved,
                 paste0(mgmt_dir,"private_lands_UTM.tif"),
                 paste0(ad_dir,"change_2015_2017_04052019_private_lands_UTM.tif"),
                 paste0("(A*B)"
                 )
  ))
}

################### CHANGE MAP ON UWA LANDS
if(!file.exists(paste0(ad_dir,"change_2015_2017_UWA_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 change.sieved,
                 paste0(mgmt_dir,"UWA_UTM.tif"),
                 paste0(ad_dir,"change_2015_2017_04052019_UWA_UTM.tif"),
                 paste0("(A*B)"
                 )
  ))
}

################### CHANGE MAP ON NFA LANDS
if(!file.exists(paste0(ad_dir,"change_2015_2017_NFA_UTM.tif"))){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
                 change.sieved,
                 paste0(mgmt_dir,"NFA_UTM.tif"),
                 paste0(ad_dir,"change_2015_2017_04052019_NFA_UTM.tif"),
                 paste0("(A*B)"
                 )
  ))
}

