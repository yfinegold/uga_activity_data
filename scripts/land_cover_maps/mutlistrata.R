## combine all lc maps
### load the parameters
source('~/uga_activity_data/scripts/get_parameters.R')
library(gdalUtils)
library(raster)

## load the land cover maps
lc2000 <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2000.tif')
lc2000.prj <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2000_proj.tif')
lc2000.prj.align <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2000_proj_align.tif')

lc2005 <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2005.tif')
lc2005.prj <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2005_proj.tif')
lc2005.prj.align <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2005_proj_align.tif')

lc2010 <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2010.tif')
lc2010.prj <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2010_proj.tif')
lc2010.prj.align <- ('/home/finegold/uganda/sieved_maps/sieved_LC_2010_proj_align.tif')

## 2015 land cover map
lc2015 <- (paste0(lc15_dir,'LULC_2015_10052019_proj.tif'))
## 2017 land cover map
lc2017 <- (paste0(lc17_dir,'LULC_2017_10052019_proj.tif'))
lc2017.align <- (paste0(lc17_dir,'LULC_2017_10052019_proj_align.tif'))

## forest management areas
mgmt   <- paste0(mgmt_dir,'Protected_Areas_UTMWGS84_dslv.shp')

## Latlong projection used to reproject data
proj <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"

mgmt.proj <- paste0(mgmt_dir,'Protected_Areas_WGS84_dslv.shp')
mgmt.proj.tif <- paste0(mgmt_dir,"Protected_Areas_WGS84_dslv.tif")
mgmt.tif <- paste0(mgmt_dir,"Protected_Areas_UTM_dslv.tif")

bfast<-'/home/finegold/uga_activity_data/data/bfast/threshold/BFAST_change_2015_2017.tif'
bfast.align<-'/home/finegold/uga_activity_data/data/bfast/threshold/BFAST_change_2015_2017_align_updated.tif'
lc2000.2015.2017 <- '/home/finegold/uga_activity_data/data/sieved_maps/lc_2000_2015_2017.tif'
lc2000.2015.2017.bfast.utm<- "/home/finegold/uga_activity_data/data/sieved_maps/lc_2000_2015_2017_bfast_utm36n.tif"
lc2000.2015.2017.bfast <- '/home/finegold/uga_activity_data/data/sieved_maps/lc_2000_2015_2017_bfast.tif'
refdata <- read.csv('/home/finegold/uga_activity_data/data/reference_data/reference_collectedData_earthlulc_aa_2015_2017_uganda_on_230719_095540_CSV_with-forest-rechecked.csv')

areas.strata<- read.csv('/home/finegold/uga_activity_data/data/sieved_maps/lc2000_2015_2017_bfast_utm_UPDATED.csv')
table(refdata$change_class10_label)
table(refdata$lulc_2015_class_label,refdata$lulc_2017_class_label)
table(refdata$stratification_map)

### calc extent
refimg<-lc2015
reso <- strsplit(gdalinfo(refimg)[14],"[, ()]+")[[1]][4]
xmin <- strsplit(gdalinfo(refimg)[21],"[, ()]+")[[1]][3]
ymax <- strsplit(gdalinfo(refimg)[21],"[, ()]+")[[1]][4]
xmax <- strsplit(gdalinfo(refimg)[24],"[, ()]+")[[1]][3]
ymin <- strsplit(gdalinfo(refimg)[24],"[, ()]+")[[1]][4]
outsizex <- strsplit(gdalinfo(refimg)[3],"[, ()]+")[[1]][3]
outsizey <- strsplit(gdalinfo(refimg)[3],"[, ()]+")[[1]][4]

# reproject to latlong
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               lc2000,
               lc2000.prj
))
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               lc2005,
               lc2005.prj
))
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -multi -co COMPRESS=LZW %s %s",
               proj,
               lc2010,
               lc2010.prj
))


## match the extent of the 2 LC maps -- using the extent of 2015
## 2000 lc map
system(sprintf("gdalwarp -ot Byte -tr %s %s  -te %s %s %s %s -overwrite -co COMPRESS=LZW %s %s",
               reso,
               reso,
               xmin,
               ymin,
               xmax,
               ymax,
               lc2000.prj,
               lc2000.prj.align
))

## 2005 land cover map
system(sprintf("gdal_translate -ot Byte -outsize %s %s  -a_ullr %s %s %s %s -overwrite -co COMPRESS=LZW %s %s",
               outsizex,
               outsizey,
               xmin,
               ymax,
               xmax,
               ymin,
               lc2005.prj,
               lc2005.prj.align
))

## 2010 land cover
system(sprintf("gdal_translate -ot Byte -outsize %s %s  -a_ullr %s %s %s %s -co COMPRESS=LZW %s %s",
               outsizex,
               outsizey,
               xmin,
               ymax,
               xmax,
               ymin,
               lc2010.prj,
               lc2010.prj.align
))

## 2017 land cover map
system(sprintf("gdal_translate -ot Byte -outsize %s %s  -a_ullr %s %s %s %s -co COMPRESS=LZW %s %s",
               outsizex,
               outsizey,
               xmin,
               ymax,
               xmax,
               ymin,
               lc2017,
               lc2017.align
))

## bfast map
system(sprintf("gdalwarp -ot UInt16 -tr %s %s  -te %s %s %s %s -overwrite -co COMPRESS=LZW %s %s",
               reso,
               reso,
               xmin,
               ymin,
               xmax,
               ymax,
               bfast,
               bfast.align
))

###############################################################################
################### create change map
###############################################################################
#################### COMBINATION INTO NATIONAL strata

##### ********* NOTE: INSTEAD OF COMBINING 3 AT ONCE,          ********* #####  
##### ********* FIRST COMBINE 2000 AND 2015 THEN SIVE TO 2 HA  ********* ##### 
##### ********* THEN DO THE ESTIMATE WITH THE 2000-2015 DATA   ********* ##### 

## create formula to combine 3 land cover maps at the same time
c1<-c(rep("(A>0)*(A<3)",16),rep("(A>2)*(A<5)",16),rep("(A==5)",16),rep("(A>5)",16))
c2<-rep(c(rep("(B>0)*(B<3)",4),rep("(B>2)*(B<5)",4),rep("(B==5)",4),rep("(B>5)",4)),4)
c3<-rep(c("(C>0)*(C<3)","(C>2)*(C<5)","(C==5)","(C>5)"),16)
fm<-paste0(c1,'*',c2,'*',c3,'*',1:64,'+',collapse = " ")

## combine 3 land cover maps, there will be values from 1 to 64
system(sprintf("gdal_calc.py -A %s -B %s  -C %s --co COMPRESS=LZW --type=UInt16 --outfile=%s --calc=\"%s\"",
                 lc2000.prj.align,
                 lc2015,
                 lc2017.align,
                 lc2000.2015.2017,
                 substr(fm,1,nchar(fm)-1)
))

## combine 3 land cover maps with bfast map. bfast map has values 3 (deforestation) 4 (degradation) and 5 (gain) which are
## multiplied by 100 and added to the combined 2000-2015-2017 land cover maps
system(sprintf("gdal_calc.py -A %s -B %s  --type=UInt16 --outfile=%s --calc=\"%s\"",
                 lc2000.2015.2017,
                 bfast.align,
                 lc2000.2015.2017.bfast,
                 "A+(B*100)"
               ))

## reproject into UTM, this file is used for area calculation in QGIS
system(sprintf("gdalwarp -t_srs \"%s\" -ot UInt16 -co COMPRESS=LZW -overwrite %s %s",
               "EPSG:32636",
               lc2000.2015.2017.bfast,
               lc2000.2015.2017.bfast.utm
               ))

gdalinfo(lc2000.2015.2017.bfast.utm,mm=T)  

###############################################################################
################### ANAYLSIS OF REFERENCE DATA
###############################################################################
#################### READ THE REFERENCE DATA
coord <- coordinates(cbind(refdata$location_x,refdata$location_y))
coord.sp <- SpatialPoints(coord)
coord.df <- as.data.frame(refdata)
coord.spdf <- SpatialPointsDataFrame(coord.sp, coord.df)

## match the coordinate systems for the sample points and the boundaries
proj4string(coord.spdf) <- proj
## extract the values of the change map
coord.spdf$combined_strata <- raster::extract(raster(lc2000.2015.2017.bfast),coord.spdf)
table(coord.spdf$change_class10_label,coord.spdf$combined_strata)
table(coord.spdf$change_class10_label)

## areas.strata is the csv file from QGIS with the pixel counts and areas of the map classes from combined change map
## create a column with hectares
areas.strata$ha <- areas.strata$m2/10000
## calculate the total area
total.area<-sum(areas.strata$m2[areas.strata$value >0])/10000
head(areas.strata)

## areas for only land change classes
## calculate strata weights
areas.strata$map_weights<-areas.strata$ha/total.area
## merge the reference data with the areas
df <- merge(coord.spdf,areas.strata, by.x=c('combined_strata'),by.y=c('value'))
head(df)
table(df$change_class_label,df$degraded)
table(df$change_class_label,df$confidence_label)
df$total_area <- total.area

#### COMBINE STRATA WITH LESS THAN 2 SAMPLES PER STRATUM
## samples with less than 2 samples per strata
df$ha[df$combined_strata %in% names(which((table(df$combined_strata)<2)==TRUE))]
df_combinedsmallstrata <- df
df_combinedsmallstrata$ha[df_combinedsmallstrata$combined_strata %in% names(which((table(df_combinedsmallstrata$combined_strata)<2)==TRUE))]<-  sum(df$ha[df$combined_strata %in% names(which((table(df$combined_strata)<2)==TRUE))])
df_combinedsmallstrata$map_weights[df_combinedsmallstrata$combined_strata %in% names(which((table(df_combinedsmallstrata$combined_strata)<2)==TRUE))]<-  sum(df$map_weights[df$combined_strata %in% names(which((table(df$combined_strata)<2)==TRUE))])
df_combinedsmallstrata$combined_strata[df_combinedsmallstrata$combined_strata %in% names(which((table(df_combinedsmallstrata$combined_strata)<2)==TRUE))] <- 1111
table(df_combinedsmallstrata$combined_strata)
df_combinedsmallstrata<- df_combinedsmallstrata[!is.na(df_combinedsmallstrata$map_weights),]

head(df_combinedsmallstrata) 

## eliminate samples without a map weight
df<- df[!is.na(df$map_weights),]
df_combinedsmallstrata<- df_combinedsmallstrata[!is.na(df_combinedsmallstrata$map_weights),]

## this one eliminates strata with less than 2 samples per stratum
df.morethan1<- df[!df$combined_strata %in% names(which((table(df$combined_strata)<2)==TRUE)),]
nrow(df.morethan1)
nrow(df)

###############################################################################
################### COMPUTE STATISTICS USING STRATIFIED RANDOM ESTIMATOR
###############################################################################
###############################################################################
## SURVEY DESIGN AS STRATIFIED RANDOM
# options("survey.lonely.psu") <- "average"
table(df_combinedsmallstrata$change_class_label,df_combinedsmallstrata$change_class10_label)
table(df_combinedsmallstrata$change_class10_label)
strat_srs_design <- svydesign(ids=~1,  strata=~combined_strata,
                              fpc=~ha, weights=~map_weights, data=df_combinedsmallstrata)
#df$change_class_label
?svyCprod
# ci<-1.96
ci<-1.645

# FOREST TYPES - 10 CLASSES
# calculate area and CI per class (for STRATIFIED random sampling design)
df.results.strat_srs_design <- as.data.frame(svymean(~change_class10_label,strat_srs_design))
df.results.strat_srs_design$class <- substring(row.names(df.results.strat_srs_design),21 )
df.results.strat_srs_design$area_ha <-round(df.results.strat_srs_design$mean * total.area)
df.results.strat_srs_design$CI_90 <- df.results.strat_srs_design$SE * ci
df.results.strat_srs_design$CI_ha <-round(df.results.strat_srs_design$SE * ci  * total.area)
df.results.strat_srs_design$CI_percent <- round(df.results.strat_srs_design$CI_ha/df.results.strat_srs_design$area_ha,digits = 3)*100
# df.results.strat_srs_design$forest_mgmt <- str_sub(df.results.strat_srs_design$class,-1,-1 )
# df.results.strat_srs_design$change <- str_sub(df.results.strat_srs_design$class,1,-2 )

as.data.frame(svytotal(~change_class10_label,strat_srs_design))
samplesize <- table(df$change_class10_label)
melted_samplesize <- melt(samplesize)
names(melted_samplesize) <- c('class','samplesize')
df.results.strat_srs_design <- merge(df.results.strat_srs_design,melted_samplesize,by='class')
df.results.strat_srs_design
## write the output to a CSV
write.csv(df.results.strat_srs_design,paste0(ad_dir,'multistrata_national_analysis_foresttypes_20191118.csv'),row.names = F)


# AGGREGATED CLASSES - 4 CLASSES
# calculate area and CI per class (for STRATIFIED random sampling design)
df.results.strat_srs_design <- as.data.frame(svymean(~change_class_label,strat_srs_design))
df.results.strat_srs_design$class <- substring(row.names(df.results.strat_srs_design),19 )
df.results.strat_srs_design$area_ha <-round(df.results.strat_srs_design$mean * total.area)
df.results.strat_srs_design$CI_90 <- df.results.strat_srs_design$SE * ci
df.results.strat_srs_design$CI_ha <-round(df.results.strat_srs_design$SE * ci  * total.area)
df.results.strat_srs_design$CI_percent <- round(df.results.strat_srs_design$CI_ha/df.results.strat_srs_design$area_ha,digits = 3)*100
# df.results.strat_srs_design$forest_mgmt <- str_sub(df.results.strat_srs_design$class,-1,-1 )
# df.results.strat_srs_design$change <- str_sub(df.results.strat_srs_design$class,1,-2 )

as.data.frame(svytotal(~change_class_label,strat_srs_design))
samplesize <- table(df$change_class_label)
melted_samplesize <- melt(samplesize)
names(melted_samplesize) <- c('class','samplesize')
df.results.strat_srs_design <- merge(df.results.strat_srs_design,melted_samplesize,by='class')
df.results.strat_srs_design
## write the output to a CSV
write.csv(df.results.strat_srs_design,paste0(ad_dir,'multistrata_national_analysis_20191118.csv'),row.names = F)

