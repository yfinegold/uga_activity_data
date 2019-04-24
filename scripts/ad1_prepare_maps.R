####################################################
## Uganda prepare data for activity data analysis ##
####################################################
## contact : yelena.finegold@fao.org
## created : 09 April 2019
## modified: 24 April 2019

## load data
cefile <- paste0(ref_dir,'TOTAL_collectedData_earthuri_ce_changes1517_on_080319_151929_CSV.csv')
lc2015 <- paste0(lc15_dir,'sieved_LC_2015.tif')
lc2017 <- paste0(lc17_dir,'LC_2017_18012019.tif')
mgmt   <- paste0(mgmt_dir,'Protected_Areas_UTMWGS84_dslv.shp')

proj <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"

lc2015p <- paste0(lc2015,"sieved_LC_2015_proj.tif")
lc2017p <- paste0(lc2017,"LC_2017_18012019_proj.tif")

###############################################################################
################### REPROJECT IN latlong PROJECTION
###############################################################################


system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               lc2015,
               lc2015p
))

system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               lc2017,
               lc2017p
))

#################################################
## create change map
#################################################
##### rasterize mgmt map
# ugdir <- '/home/finegold/uganda/ad/'
# mgmt_dir <- '/home/finegold/uganda/mgmt_areas/'

system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               ad_dir,
               paste0(mgmt_dir,'Protected_Areas_WGS84_dslv.shp'),
               lc2015p,
               paste0(mgmt_dir,"Protected_Areas_WGS84_dslv.tif"),
               "code"
))

system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               ad_dir,
               mgmt,
               lc2015,
               paste0(mgmt_dir,"Protected_Areas_UTM_dslv.tif"),
               "code"
))

## match the extent of the 2 LC maps -- using the extent of 2015
bb<- extent(raster(lc2015))
system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
               floor(bb@xmin),
               ceiling(bb@ymax),
               ceiling(bb@xmax),
               floor(bb@ymin),
               lc2017,
               paste0(lc17_dir,'LC_2017_18012019_aligned.tif')
))


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

system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --type=Byte --outfile=%s --calc=\"%s\"",
               lc2015,
               paste0(lc17_dir,'LC_2017_18012019_aligned.tif'),
               # paste0(mgmt_dir,"Protected_Areas_WGS84_dslv.tif"),
               paste0(ad_dir,"change_2015_2017.tif"),

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
################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(ad_dir,"change_2015_2017.tif"),
               paste0(ad_dir,"tmp_change_2015_2017_sieve.tif")
))
###############################################################################
################### COMPRESS
###############################################################################
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(ad_dir,"tmp_change_2015_2017_sieve.tif"),
               paste0(ad_dir,"change_2015_2017_sieve.tif")

))

## project to latlong
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               paste0(ad_dir,"change_2015_2017_sieve.tif"),
               paste0(ad_dir,"change_2015_2017_sieve_wgs84.tif")
))

system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               paste0(mgmt_dir,"Protected_Areas_UTM_dslv.tif"),
               paste0(mgmt_dir,"private_lands_UTM.tif"),
               paste0("(A==0)*1"
                      )
))
system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               paste0(mgmt_dir,"Protected_Areas_UTM_dslv.tif"),
               paste0(mgmt_dir,"UWA_UTM.tif"),
               paste0("(A==10)*1"
               )
))
system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               paste0(mgmt_dir,"Protected_Areas_UTM_dslv.tif"),
               paste0(mgmt_dir,"NFA_UTM.tif"),
               paste0("(A==100)*1"
               )
))

system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               paste0(ad_dir,"change_2015_2017_sieve.tif"),
               paste0(mgmt_dir,"private_lands_UTM.tif"),
               paste0(ad_dir,"change_2015_2017_private_lands_UTM.tif"),
               paste0("(A*B)"
               )
))
system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               paste0(ad_dir,"change_2015_2017_sieve.tif"),
               paste0(mgmt_dir,"UWA_UTM.tif"),
               paste0(ad_dir,"change_2015_2017_UWA_UTM.tif"),
               paste0("(A*B)"
               )
))
system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               paste0(ad_dir,"change_2015_2017_sieve.tif"),
               paste0(mgmt_dir,"NFA_UTM.tif"),
               paste0(ad_dir,"change_2015_2017_NFA_UTM.tif"),
               paste0("(A*B)"
               )
))
