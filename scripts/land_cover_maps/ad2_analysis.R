####################################################
## Uganda prepare data for activity data analysis ##
####################################################
## This script explores the data and does some analysis 
## of the reference data and map data
## contact : yelena.finegold@fao.org
## created : 09 April 2019
## modified: 24 April 2019
####################################################

### load the parameters
source('~/uga_activity_data/scripts/get_parameters.R')

## load data
## assign the file names to variables
cefile <- paste0(ref_dir,'ref_data_changes1517_080319.csv')
cefile1 <- paste0(ref_dir,'TOTAL_collectedData_earthuri_ce_changes1517_on_080319_151929_CSV.csv')

lc2015 <- paste0(lc15_dir,'sieved_LC_2015.tif')
lc2017 <- paste0(lc17_dir,'LC_2017_18012019.tif')
mgmt   <- paste0(mgmt_dir,'Protected_Areas_UTMWGS84_dslv.shp')
lc2015p <- paste0(lc2015,"sieved_LC_2015_proj.tif")
lc2017p <- paste0(lc2017,"LC_2017_18012019_proj.tif")
hansen <- paste0(gfc_dir,"gfc_UGA_lossyear.tif")

## read the data into R
## load the forest management data in R
mgmt.data <- readOGR(mgmt)

## load the reference data in R
ce <- read.csv(cefile)


###############################################################################
################### EXPLORING THE REFERENCE DATA
###############################################################################

## visualize the first 6 lines of the reference data database
head(ce)

## plot the reference data
plot(ce$location_x,ce$location_y)

#download province boundaries
adm <- getData ('GADM', country= countrycode, level=1)

## plot administrative boundaries on top of the points
plot(adm, add=T)

### some guiding questions
## how are the samples distributed by region?
table(ce$region)

## how many samples where distributed by map class?
table(ce$map_class_label)

## how are samples distributed for 2015 land cover?
table(ce$lulc_2015_class_label)

## how are samples distributed for 2017 land cover?
table(ce$lulc_2017_class_label)

## what is the agreement and disagreement between 2015 and 2017 land cover as classified by the reference data? 
table(ce$lulc_2015_class_label,ce$lulc_2017_class_label)

## what are the change class labels?
table(ce$ref_class_label)

## what is the agreement and disagreement between change classes in the reference data and map? 
table(ce$map_class_label,ce$ref_class_label)

## By map class what is the agreement and disagreement between 2015 and 2017 land cover as classified by the reference data? 
table(ce$lulc_2015_class_label,ce$lulc_2017_class_label,ce$map_class_label)


###############################################################################
################### READ THE SPATIAL DATA
###############################################################################

## read the reference data as spatial data
coord <- coordinates(cbind(ce$location_x,ce$location_y))
coord.sp <- SpatialPoints(coord)
coord.df <- as.data.frame(ce)
coord.spdf <- SpatialPointsDataFrame(coord.sp, coord.df)

## match the coordinate systems for the sample points and the boundaries
proj4string(coord.spdf) <-proj4string(adm)

## reproject mgmt data into latlong
mgmt.data.proj <- spTransform(mgmt.data,crs(coord.spdf))
crs(mgmt.data.proj)
## visualize the first 6 lines of the forest management data database
head(mgmt.data.proj)

###############################################################################
################### EXTRACT DATA OVER REFERENCE DATA SAMPLES
###############################################################################

## extract the forest management data for each sample in the reference data
mgmt.1 <- over(coord.spdf, mgmt.data.proj)
head(mgmt.1)

## if the value is NA is private lands, reassign privates to the value 1
mgmt.1$code[is.na(mgmt.1$code)] <- 1

## add the forest management information as a column in the reference data
coord.spdf$mgmt <- mgmt.1$code

## create labels for the forest management classes
mgmt.labels <-  as.data.frame(cbind(c(1,10,100), c('private', 'UWA', 'NFA')))
names(mgmt.labels) <- c('mgmt','mgmt_label')
coord.spdf <- merge(coord.spdf,mgmt.labels)

## extract the 2015 and 2017 land cover map value for each sample in the reference data
coord.spdf$map_lc2015 <- extract(raster(lc2015p),coord.spdf)
coord.spdf$map_lc2017 <- extract(raster(lc2017p),coord.spdf)

## create labels for the land cover classes
lc.labels <-  as.data.frame(cbind(1:13, c('Broadleaved plantations', 'Coniferus plantations', 'THF high stocked', 'THF low stocked',  'Woodlands', 'Bushland', 'Grassland', 'Wetland', 'Subsistence farmland', 'Commercial farmland', 'Built up', 'Water bodies', 'Impediment')))
names(lc.labels) <- c('map_lc2015','map_lc2015_label')
coord.spdf <- merge(coord.spdf,lc.labels)
names(lc.labels) <- c('map_lc2017','map_lc2017_label')
coord.spdf <- merge(coord.spdf,lc.labels)

## check the change map classes and the land cover maps
## there are issues with the change map that was used, it does not consistent with the 2015 and 2017 LC maps
head(coord.spdf)
table(coord.spdf$map_class_label,coord.spdf$map_lc2015_label)
table(coord.spdf$map_class_label,coord.spdf$map_lc2017_label)

## since the column in the reference data labeled 'map class label' is not consistent with the land cover classes although it should be derived from these maps
## the 'map class label' should not be used. let's create a new column with derived change from the LC maps

## create change classes: level 0
change0.labels <-  as.data.frame(cbind(1:4, c('stable forest', 'stable non-forest', 'forest loss', 'forest gain')))
names(change0.labels) <- c('map_change_0','map_change_0_label')
# 1 = stable forest
# 2 = stable non-forest
# 3 = forest loss
# 4 = forest gain
coord.spdf$map_change_0 <- 0
coord.spdf$map_change_0[coord.spdf$map_lc2015 %in% c(1:5) & coord.spdf$map_lc2017 %in% c(1:5)] <- 1 #stable forest
coord.spdf$map_change_0[coord.spdf$map_lc2015 %in% c(6:13) & coord.spdf$map_lc2017 %in% c(6:13)] <- 2 #stable nonforest
coord.spdf$map_change_0[coord.spdf$map_lc2015 %in% c(1:5) & coord.spdf$map_lc2017 %in% c(6:13)] <- 3 #forest loss
coord.spdf$map_change_0[coord.spdf$map_lc2015 %in% c(6:13) & coord.spdf$map_lc2017 %in% c(1:5)] <- 4 #forest gain
coord.spdf <- merge(coord.spdf,change0.labels)

## number of map change classes in the sample data
table(coord.spdf$map_change_0_label)
## change between 2015-2017 by the derived change classes. this is to make sure the map change 0 classes are consistent
table(coord.spdf$map_lc2017_label,coord.spdf$map_lc2015_label,coord.spdf$map_change_0_label)

## create change classes: level 1
## derrive change from land cover maps
change1.labels <-  as.data.frame(cbind(1:8, c('stable forest', 'stable non-forest', 'forest loss plantations','forest loss THF','forest loss woodlands', 'forest gain plantations','forest gain THF','forest gain woodlands')))
names(change1.labels) <- c('map_change_1','map_change_1_label')
# 1  = stable forest 
# 2  = stable non-forest
# 3  = forest loss plantations
# 4  = forest loss THF
# 5  = forest loss woodlands
# 6  = forest gain plantations
# 7  = forest gain THF
# 8 = forest gain woodlands
coord.spdf$map_change_1 <- 0
coord.spdf$map_change_1[coord.spdf$map_lc2015 %in% c(1:5) & coord.spdf$map_lc2017 %in% c(1:5)] <- 1 #stable forest
coord.spdf$map_change_1[coord.spdf$map_lc2015 %in% c(6:13) & coord.spdf$map_lc2017 %in% c(6:13)] <- 2 #stable nonforest
coord.spdf$map_change_1[coord.spdf$map_lc2015 %in% c(1:2) & coord.spdf$map_lc2017 %in% c(6:13)] <- 3 #forest loss plantations
coord.spdf$map_change_1[coord.spdf$map_lc2015 %in% c(3:4) & coord.spdf$map_lc2017 %in% c(6:13)] <- 4 #forest loss THF
coord.spdf$map_change_1[coord.spdf$map_lc2015 %in% c(5) & coord.spdf$map_lc2017 %in% c(6:13)] <- 5 #forest loss woodlands
coord.spdf$map_change_1[coord.spdf$map_lc2015 %in% c(6:13) & coord.spdf$map_lc2017 %in% c(1:2)] <- 6 #forest gain plantations
coord.spdf$map_change_1[coord.spdf$map_lc2015 %in% c(6:13) & coord.spdf$map_lc2017 %in% c(3:4)] <- 7 #forest gain THF
coord.spdf$map_change_1[coord.spdf$map_lc2015 %in% c(6:13) & coord.spdf$map_lc2017 %in% c(5)] <- 8 #forest gain woodlands
coord.spdf <- merge(coord.spdf,change1.labels)

## explore the data
table(coord.spdf$map_change_1_label,coord.spdf$map_change_0_label)
table(coord.spdf$map_change_1_label,coord.spdf$map_lc2017_label)
table(coord.spdf$map_change_1_label,coord.spdf$mgmt_label)
table(coord.spdf$map_class_label)
table(coord.spdf$map_change_1_label,coord.spdf$ref_class_label)
table(coord.spdf$map_change_1_label,coord.spdf$ref_ref_class_label)
table(coord.spdf$ref_class_label,coord.spdf$ref_ref_class_label)
table(coord.spdf$ref_class_label,coord.spdf$confidence_label)

## create change classes: level 2
## this is derived from the sieved map from the ad1_prepare_maps script
coord.spdf$change_2015_2017 <- extract(raster(paste0(ad_dir,"change_2015_2017_sieve_wgs84.tif")),coord.spdf)
## create change labels
change.labels <-  as.data.frame(cbind(1:13, c('stable forest PL to PL', 'stable forest THF to PL',
                                              'stable forest THF to THF','stable forest THF to WL',
                                              'stable forest WL to WL','stable forest WL to PL',
                                              'forest loss plantations','forest loss THF',
                                              'forest loss woodlands', 'forest gain plantations',
                                              'forest gain THF','forest gain woodlands',
                                              'stable non-forest')))
names(change.labels) <- c('change_2015_2017','change_2015_2017_label')
coord.spdf <- merge(coord.spdf,change.labels)

## create change classes: level 3
## this is converts the land use classes into IPCC classes
coord.spdf$lulc_2015_class_IPCC <- 0
coord.spdf$lulc_2017_class_IPCC <- 0
coord.spdf$map_lc2015_IPCC <- 0
coord.spdf$map_lc2017_IPCC <- 0
## reference data 2015 and 2017
coord.spdf$lulc_2015_class_IPCC[coord.spdf$lulc_2015_class %in% c(1:5) ] <- 1 #forest
coord.spdf$lulc_2015_class_IPCC[coord.spdf$lulc_2015_class %in% c(9:10)] <- 2 #cropland
coord.spdf$lulc_2015_class_IPCC[coord.spdf$lulc_2015_class %in% c(6:7) ] <- 3 #grassland
coord.spdf$lulc_2015_class_IPCC[coord.spdf$lulc_2015_class %in% c(8,12)] <- 4 #wetlands
coord.spdf$lulc_2015_class_IPCC[coord.spdf$lulc_2015_class %in% c(11)  ] <- 5 #settlements
coord.spdf$lulc_2015_class_IPCC[coord.spdf$lulc_2015_class %in% c(13)  ] <- 6 #otherland

coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(1:5) ] <- 1 #forest
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(9:10)] <- 2 #cropland
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(6:7) ] <- 3 #grassland
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(8,12)] <- 4 #wetlands
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(11)  ] <- 5 #settlements
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(13)  ] <- 6 #otherland
## map data 2015 and 2017
table(coord.spdf$map_lc2015)
coord.spdf$map_lc2015_IPCC[coord.spdf$map_lc2015 %in% c(1:5) ] <- 1 #forest
coord.spdf$map_lc2015_IPCC[coord.spdf$map_lc2015 %in% c(9:10)] <- 2 #cropland
coord.spdf$map_lc2015_IPCC[coord.spdf$map_lc2015 %in% c(6:7) ] <- 3 #grassland
coord.spdf$map_lc2015_IPCC[coord.spdf$map_lc2015 %in% c(8,12)] <- 4 #wetlands
coord.spdf$map_lc2015_IPCC[coord.spdf$map_lc2015 %in% c(11)  ] <- 5 #settlements
coord.spdf$map_lc2015_IPCC[coord.spdf$map_lc2015 %in% c(13)  ] <- 6 #otherland

coord.spdf$map_lc2017_IPCC[coord.spdf$map_lc2017 %in% c(1:5) ] <- 1 #forest
coord.spdf$map_lc2017_IPCC[coord.spdf$map_lc2017 %in% c(9:10)] <- 2 #cropland
coord.spdf$map_lc2017_IPCC[coord.spdf$map_lc2017 %in% c(6:7) ] <- 3 #grassland
coord.spdf$map_lc2017_IPCC[coord.spdf$map_lc2017 %in% c(8,12)] <- 4 #wetlands
coord.spdf$map_lc2017_IPCC[coord.spdf$map_lc2017 %in% c(11)  ] <- 5 #settlements
coord.spdf$map_lc2017_IPCC[coord.spdf$map_lc2017 %in% c(13)  ] <- 6 #otherland

coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(1:5) ] <- 1 #forest
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(9:10)] <- 2 #cropland
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(6:7) ] <- 3 #grassland
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(8,12)] <- 4 #wetlands
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(11)  ] <- 5 #settlements
coord.spdf$lulc_2017_class_IPCC[coord.spdf$lulc_2017_class %in% c(13)  ] <- 6 #otherland
## create IPCC labels
IPCC.labels <-  as.data.frame(cbind(1:6, c('forest',
                                           'cropland',
                                           'grassland',
                                           'wetlands',
                                           'settlements',
                                           'otherland')))

names(IPCC.labels) <- c('map_lc2015_IPCC','map_lc2015_IPCC_label')
coord.spdf <- merge(coord.spdf,IPCC.labels)
names(IPCC.labels) <- c('map_lc2017_IPCC','map_lc2017_IPCC_label')
coord.spdf <- merge(coord.spdf,IPCC.labels)
names(IPCC.labels) <- c('lulc_2015_class_IPCC','lulc_2015_class_IPCC_label')
coord.spdf <- merge(coord.spdf,IPCC.labels)
names(IPCC.labels) <- c('lulc_2017_class_IPCC','lulc_2017_class_IPCC_label')
coord.spdf <- merge(coord.spdf,IPCC.labels)


## create change classes: level 4
## this is derived from the Hansen Global Forest Change data
coord.spdf$gfc_lossyear <- extract(raster(hansen),coord.spdf)
table(coord.spdf$gfc_lossyear)
table(coord.spdf$gfc_lossyear,coord.spdf$ref_class_label)
table(coord.spdf$gfc_lossyear,coord.spdf$change_2015_2017_label)



###############################################################################
################### QUALITY CHECK AND CLEAN DATA
###############################################################################
table(coord.spdf$lulc_2015_class)
## first create a simplied forest/nonforest classification for the land cover map classes
coord.spdf$lulc_2015_class_simp[coord.spdf$lulc_2015_class %in% 1:5] <- 'forest'
coord.spdf$lulc_2015_class_simp[coord.spdf$lulc_2015_class %in% 6:13] <- 'nonforest'
coord.spdf$lulc_2017_class_simp[coord.spdf$lulc_2017_class %in% 1:5] <- 'forest'
coord.spdf$lulc_2017_class_simp[coord.spdf$lulc_2017_class %in% 6:13] <- 'nonforest'

### quality check using the reference data 2015 land cover  2017 land cover and change classification
## samples to recheck include: reference samples labeled 'potential'
## reference data with inconsistent land cover and change classfication- for example 2015=forest 2017=forest and change class= deforestation
## reference data labelled with low confidence
table(coord.spdf$number_trees_after_def_plant_wl_label)
table(coord.spdf$ref_class_label,coord.spdf$ref_class)
## create a dataset that needs to be rechecked using Collect Earth
recheck <- coord.spdf[!coord.spdf$lulc_2015_class_simp == coord.spdf$lulc_2017_class_simp & coord.spdf$ref_class %in% c(11,99) 
                      |
                        coord.spdf$lulc_2015_class_simp == coord.spdf$lulc_2017_class_simp & coord.spdf$ref_class %in% c(19,39,59,91)
                      |
                        coord.spdf$ref_class_label %in% c('Potential deforestation in plantations','Potential deforestation in THF',
                                                          'Potential deforestation in woodlands','Potential forest gain', '' )
                      |
                        coord.spdf$confidence_label %in% c('Low')
                      |
                        (!coord.spdf$ref_class_label %in% c("Deforestation in THF", "Deforestation in woodlands") & coord.spdf$gfc_lossyear %in% c(15:17) )
                      ,]
print(paste0('there are ', nrow(recheck),' samples to recheck'))

write.csv(recheck,paste0(ref_dir,'recheck_ref_data1.csv'),row.names = F)

## eliminate samples that need to be rechecked from the reference data that will be analyzed
coord.spdf <- coord.spdf[!coord.spdf$id %in% recheck$id,
                         ]

###############################################################################
################### COMPUTE AREAS IN EACH MANAGEMENT TYPE
###############################################################################
####################################################################################################


################# PIXEL COUNT OF PRIVATE LANDS
hist <- pixel_count(paste0(ad_dir,"change_2015_2017_private_lands_UTM.tif"))
pixel     <- res(raster(paste0(ad_dir,"change_2015_2017_private_lands_UTM.tif")))[1]
names(hist) <- c("change_2015_2017","pixels")
hist$area_ha <- floor(hist$pixels*pixel*pixel/10000)
hist <- merge(hist,change.labels)
hist$mgmt_label <- 'private'
write.csv(hist,paste0(ad_dir,"change_2015_2017_private_lands.csv"),row.names = F)

################# PIXEL COUNT OF UWA AREAS
hist <- pixel_count(paste0(ad_dir,"change_2015_2017_UWA_UTM.tif"))
pixel     <- res(raster(paste0(ad_dir,"change_2015_2017_UWA_UTM.tif")))[1]
names(hist) <- c("change_2015_2017","pixels")
hist$area_ha <- floor(hist$pixels*pixel*pixel/10000)
hist <- merge(hist,change.labels)
hist$mgmt_label <- 'UWA'
write.csv(hist,paste0(ad_dir,"change_2015_2017_UWA.csv"),row.names = F)

################# PIXEL COUNT OF NFA AREAS
hist <- pixel_count(paste0(ad_dir,"change_2015_2017_NFA_UTM.tif"))
pixel     <- res(raster(paste0(ad_dir,"change_2015_2017_NFA_UTM.tif")))[1]
names(hist) <- c("change_2015_2017","pixels")
hist$area_ha <- floor(hist$pixels*pixel*pixel/10000)
hist <- merge(hist,change.labels)
hist$mgmt_label <- 'NFA'
hist
write.csv(hist,paste0(ad_dir,"change_2015_2017_NFA.csv"),row.names = F)

################# COMBINE PIXEL COUNTS OF ALL MANAGEMENT AREAS
areas <- rbind(read.csv(paste0(ad_dir,"change_2015_2017_private_lands.csv")),read.csv(paste0(ad_dir,"change_2015_2017_UWA.csv")),read.csv(paste0(ad_dir,"change_2015_2017_NFA.csv")))
areas
## areas for only mgmt areas
for(strat in unique(areas$mgmt_label)){
  areas$mgmt_area_ha[areas$mgmt_label %in% strat] <- sum(areas$area_ha[areas$mgmt_label %in% strat])
}
## areas for only land change classes
for(strat in unique(areas$change_2015_2017_label)){
  areas$change_area_ha[areas$change_2015_2017_label %in% strat] <- sum(areas$area_ha[areas$change_2015_2017_label %in% strat])
}
totalarea <- floor(sum(areas$area_ha))
df <- merge(coord.spdf,areas, by.x=c('change_2015_2017_label','mgmt_label'),by.y=c('change_2015_2017_label','mgmt_label'))
df <- df[!df %in% recheck,]
tail(df)

## STRATA AS CHANGE CLASS BY MANAMGEMENT TYPE
df$strata <- paste0(df$change_2015_2017.x,'_',df$mgmt)
df$strata_label <- paste0(df$change_2015_2017_label,'- ',df$mgmt_label)
## calculate strata weights
df$map_weights<-df$area_ha/sum(unique(df$area_ha),na.rm = T)
df$total_area <- totalarea
## ELIMINATE CLASSES WITH 0 OR 1 SAMPLES
names(which((table(df$strata_label)<2)==TRUE))
table(df$strata_label)
df<- df[!is.na(df$map_weights),]
df<- df[!df$strata_label %in% names(which((table(df$strata_label)<2)==TRUE)),]


################# EXPLORE THE DATA
# loss_area <- sum(hist[(hist$code > 7 & hist$code < 9),"pixels"]*pixel*pixel/10000)
sum(unique(df$map_weights))
table(df$strata)
sum(unique(df$area_ha))

table(df$ref_class_label)
nrow(df)
table(df$confidence_label)
table(df$change_2015_2017_label,df$ref_class_label,df$mgmt_label)
table(df$number_trees_2017_tof_label)
table(df$lulc_2015_class_label,df$lulc_2017_class_label,df$ref_class_label)
table(df$lulc_2015_class_label,df$lulc_2015_class)
table(df$mgmt_label)
table(df$area_ha,df$mgmt_label)
write.csv(df,paste0(ref_dir,'change_2015_2017_ref_data_1.csv'),row.names = F)

###############################################################################
################### COMPUTE STATISTICS USING STRATIFIED RANDOM ESTIMATOR
###############################################################################
###############################################################################
## SURVEY DESIGN AS STRATIFIED RANDOM
strat_srs_design <- svydesign(ids=~1,  strata=~mgmt_label,
                              fpc=~mgmt_area_ha, weights=~map_weights, data=df)
strat_srs_design <- svydesign(ids=~1,  strata=~strata_label,
                              fpc=~area_ha, weights=~map_weights, data=df)

# calculate area and CI per class (for STRATIFIED random sampling design)
df.results.strat_srs_design <- as.data.frame(svymean(~ref_class_label,strat_srs_design))
df.results.strat_srs_design$class <- substring(row.names(df.results.strat_srs_design),16 )
df.results.strat_srs_design$area_ha <-round(df.results.strat_srs_design$mean * totalarea)
df.results.strat_srs_design$CI_95 <- df.results.strat_srs_design$SE * 1.96
df.results.strat_srs_design$CI_ha <-round(df.results.strat_srs_design$SE * 1.96  * totalarea)
df.results.strat_srs_design$CI_percent <- round(df.results.strat_srs_design$CI_ha/df.results.strat_srs_design$area_ha,digits = 3)*100
# df.results.strat_srs_design$forest_mgmt <- str_sub(df.results.strat_srs_design$class,-1,-1 )
# df.results.strat_srs_design$change <- str_sub(df.results.strat_srs_design$class,1,-2 )

as.data.frame(svytotal(~ref_class_label,strat_srs_design))
samplesize <- table(df$ref_class_label)
melted_samplesize <- melt(samplesize)
names(melted_samplesize) <- c('class','samplesize')
df.results.strat_srs_design <- merge(df.results.strat_srs_design,melted_samplesize,by='class')
df.results.strat_srs_design
## write the output to a CSV
write.csv(df.results.strat_srs_design,paste0(ad_dir,'map_substraction_national_analysis_1.csv'),row.names = F)

## explore data
table(coord.spdf$change_2015_2017_label,coord.spdf$ref_class_label)
table(coord.spdf$change_2015_2017_label,coord.spdf$ref_class_label,coord.spdf$mgmt_label)
table(coord.spdf$ref_class_label)
table(coord.spdf$confidence_label)
