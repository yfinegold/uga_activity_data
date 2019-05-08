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
lc_vector <- paste0(lc17_dir,'LULC_2017_as_at_4_May_2019_by_edward.shp')
lc2015_vector.tif <- paste0(lc15_dir,'LULC_2015_04052019.tif')
lc2017_vector.tif <- paste0(lc17_dir,'LULC_2017_04052019.tif')
lc2015_vector.tif.prj <- paste0(lc15_dir,'LULC_2015_04052019_proj.tif')
lc2017_vector.tif.prj <- paste0(lc17_dir,'LULC_2017_04052019_proj.tif')

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
##### rasterize mgmt map
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

system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
               lc2015_vector.tif,
               lc2017_vector.tif,
               'delete.tif',
               sprintf(
                 "(A==B) * A + ((A==1) * ( %s %s )) + ((A==2) * ( %s %s )) + ((A==3) * ( %s %s )) + ((A==4) * ( %s %s )) + ((A==5) * ( %s %s )) + ((A==5) * ( %s %s )) + ((A==5) * ( %s %s )) 
                 + ((A==6) * ( %s %s ) + ((A==7) * ( %s %s )) + ((A==8) * ( %s %s )) + ((A==9) * ( %s %s ))
                  + ((A==10) * ( %s %s )) + ((A==11) * ( %s %s )) + ((A==12) * ( %s %s )) + ((A==13) * ( %s %s ))" , ### stable forest woodlands to woodlands
                 paste0('( (B == ',2:12,') *',14:24 ,' ) + ',collapse=''),
                 paste0('( (B == ',13,') *',25 ,' )',collapse=''),
                 paste0('( (B == ',14:24,') *',26:36 ,' ) + ',collapse=''),
                 paste0('( (B == ',25,') *',37 ,' )',collapse=''),
                 paste0('( (B == ',26:36,') *',38:48 ,' ) + ',collapse=''),
                 paste0('( (B == ',37,') *',49 ,' )',collapse=''),
                 paste0('( (B == ',38:48,') *',50:60 ,' ) + ',collapse=''),
                 paste0('( (B == ',49,') *',61 ,' )',collapse=''),
                 paste0('( (B == ',50:60,') *',62:72 ,' ) + ',collapse=''),
                 paste0('( (B == ',61,') *',73 ,' )',collapse=''),
                 paste0('( (B == ',62:72,') *',74:84 ,' ) + ',collapse=''),
                 paste0('( (B == ',73,') *',85 ,' )',collapse=''),
                 
                 paste0('( (B == ',62:72,') *',74:84 ,' ) + ',collapse=''),
                 paste0('( (B == ',73,') *',85 ,' )',collapse=''),
                 paste0('( (B == ',62:72,') *',74:84 ,' ) + ',collapse=''),
                 paste0('( (B == ',73,') *',85 ,' )',collapse=''),
                 paste0('( (B == ',62:72,') *',74:84 ,' ) + ',collapse=''),
                 paste0('( (B == ',73,') *',85 ,' )',collapse=''),
                 paste0('( (B == ',62:72,') *',74:84 ,' ) + ',collapse=''),
                 paste0('( (B == ',73,') *',85 ,' )',collapse=''),
               )
              ))

gdalinfo('delete.tif', mm=T)

sprintf(
  "(A==B) * A + ((A==1) * ( %s %s )) + ((A==2) * ( %s %s ))" , ### stable forest woodlands to woodlands
  paste0('( (B == ',2:12,') *',14:24 ,' ) + ',collapse=''),
  paste0('( (B == ',13,') *',25 ,' )',collapse=''),
  paste0('( (B == ',14:24,') *',26:36 ,' ) + ',collapse=''),
  paste0('( (B == ',25,') *',37 ,' )',collapse='')
  
)


if(!file.exists(change.allclasses)){
  system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
                 lc2015_vector.tif,
                 lc2017_vector.tif,
                 change.allclasses,
                 paste0(
                   "(A==B) * A +", ### stable forest woodlands to woodlands
                   "(A==1) * ( ((B==2) * 14) +", ### stable forest woodlands to woodlands
                   cat('(A==1) * (', 
                          paste0 ('( (B ==',2:13,') *',14:25, ),
                          ") +")
                   ,
                   "           ((B==3) * 15) +", ### stable forest woodlands to woodlands
                   "           ((B==4) * 16) +", ### stable forest woodlands to woodlands
                   "           ((B==5) * 17) +", ### stable forest woodlands to woodlands
                   "           ((B==6) * 18) +", ### stable forest woodlands to woodlands
                   "           ((B==7) * 19) +", ### stable forest woodlands to woodlands
                   "           ((B==8) * 20) +", ### stable forest woodlands to woodlands
                   "           ((B==9) * ) +", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   "(A==5) * (B==5) * 5+", ### stable forest woodlands to woodlands
                   
                 )
  ))
}


###############################################################################
################### create change map with FREL classes
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
                        "(A>0)*(A<5) * (B>2)*(B<5) * 3+", ### stable forest THF to THF
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

