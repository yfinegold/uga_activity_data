####################################################
## Uganda prepare data for activity data analysis ##
####################################################
## This script reprojects the map data and combines 
## the maps 
## contact : yelena.finegold@fao.org
## created : 09 April 2019
## modified: 24 April 2019
####################################################

### load the parameters
source('~/uga_activity_data/scripts/get_parameters.R')

### load data
## reference data for changes
cefile <- paste0(ref_dir,'TOTAL_collectedData_earthuri_ce_changes1517_on_080319_151929_CSV.csv')
## 2015 land cover map
lc2015 <- paste0(lc15_dir,'sieved_LC_2015.tif')
## 2017 land cover map
lc2017 <- paste0(lc17_dir,'LC_2017_18012019.tif')
## forest management areas
mgmt   <- paste0(mgmt_dir,'Protected_Areas_UTMWGS84_dslv.shp')



## Latlong projection used to reproject data
proj <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"

### assign names to data that will be created in this script
lc2015.proj <- paste0(lc15_dir,"sieved_LC_2015_proj.tif")
lc2017.proj <- paste0(lc17_dir,"LC_2017_18012019_proj.tif")
mgmt.proj <- paste0(mgmt_dir,'Protected_Areas_WGS84_dslv.shp')
mgmt.proj.tif <- paste0(mgmt_dir,"Protected_Areas_WGS84_dslv.tif")
mgmt.tif <- paste0(mgmt_dir,"Protected_Areas_UTM_dslv.tif")
lc2017.aligned <- paste0(lc17_dir,'LC_2017_18012019_aligned.tif')
change <- paste0(ad_dir,"change_2015_2017.tif")
change.sieved <- paste0(ad_dir,"change_2015_2017_sieve.tif")


###############################################################################
################### REPROJECT IN latlong PROJECTION
###############################################################################

# 2015 LC map
if(!file.exists(lc2015.proj)){
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               lc2015,
               lc2015.proj
))
}
# 2017 LC map
if(!file.exists(lc2017.proj)){
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               lc2017,
               lc2017.proj
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
               lc2015.proj,
               mgmt.proj.tif,
               "code"
))
}

##### utm forest management map 
if(!file.exists(mgmt.tif)){
system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               scriptdir,
               mgmt,
               lc2015,
               mgmt.tif,
               "code"
))
}

## match the extent of the 2 LC maps -- using the extent of 2015
bb<- extent(raster(lc2015))
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
               lc2015,
               lc2017.aligned,
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
################### project to latlong
if(!file.exists(paste0(ad_dir,"change_2015_2017_sieve_wgs84.tif"))){
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               change.sieved,
               paste0(ad_dir,"change_2015_2017_sieve_wgs84.tif")
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
               paste0(ad_dir,"change_2015_2017_private_lands_UTM.tif"),
               paste0("(A*B)"
               )
))
}

################### CHANGE MAP ON UWA LANDS
if(!file.exists(paste0(ad_dir,"change_2015_2017_UWA_UTM.tif"))){
system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               change.sieved,
               paste0(mgmt_dir,"UWA_UTM.tif"),
               paste0(ad_dir,"change_2015_2017_UWA_UTM.tif"),
               paste0("(A*B)"
               )
))
}

################### CHANGE MAP ON NFA LANDS
if(!file.exists(paste0(ad_dir,"change_2015_2017_NFA_UTM.tif"))){
system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               change.sieved,
               paste0(mgmt_dir,"NFA_UTM.tif"),
               paste0(ad_dir,"change_2015_2017_NFA_UTM.tif"),
               paste0("(A*B)"
               )
))
}