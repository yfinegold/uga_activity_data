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


mgmt.data <- readOGR(mgmt)

ce <- read.csv(cefile)
## explore data
head(ce)
plot(ce$location_x,ce$location_y)
table(ce$region)
table(ce$map_class_label)
table(ce$lulc_2015_class_label)
table(ce$lulc_2017_class_label)
table(ce$lulc_2015_class_label,ce$lulc_2017_class_label)
table(ce$ref_class_label)
table(ce$map_class_label,ce$ref_class_label)
table(ce$lulc_2015_class_label,ce$lulc_2017_class_label,ce$map_class_label)


## read CE data as spatial data
coord <- coordinates(cbind(ce$location_x,ce$location_y))
coord.sp <- SpatialPoints(coord)
coord.df <- as.data.frame(ce)
coord.spdf <- SpatialPointsDataFrame(coord.sp, coord.df)

#download province boundaries
adm <- getData ('GADM', country= countrycode, level=1)
#match the coordinate systems for the sample points and the boundaries
plot(adm)
proj4string(coord.spdf) <-proj4string(adm)
adm1 <- over(coord.spdf, adm)
head(adm1)
coord.spdf$adm1 <- adm1[,4]
table(coord.spdf$region,coord.spdf$adm1)

## reproject mgmt data into latlong
mgmt.data.proj <- spTransform(mgmt.data,crs(coord.spdf))
writeOGR(mgmt.data.proj,mgmtdir,'Protected_Areas_WGS84_dslv',driver = 'ESRI Shapefile')

crs(mgmt.data.proj)
head(mgmt.data.proj)
mgmt.1 <- over(coord.spdf, mgmt.data.proj)
head(mgmt.1)
mgmt.1$code[is.na(mgmt.1$code)] <- 1
coord.spdf$mgmt <- mgmt.1$code
mgmt.labels <-  as.data.frame(cbind(c(1,10,100), c('private', 'UWA', 'NFA')))
names(mgmt.labels) <- c('mgmt','mgmt_label')
coord.spdf <- merge(coord.spdf,mgmt.labels)

coord.spdf$yf_lc2015 <- extract(raster(lc2015p),coord.spdf)
table(coord.spdf$lulc_2015_class,coord.spdf$yf_lc2015)
table(coord.spdf$map_class_label,coord.spdf$yf_lc2015)
coord.spdf$yf_lc2017 <- extract(raster(lc2017p),coord.spdf)

lc.labels <-  as.data.frame(cbind(1:13, c('Broadleaved plantations', 'Coniferus plantations', 'THF high stocked', 'THF low stocked',  'Woodlands', 'Bushland', 'Grassland', 'Wetland', 'Subsistence farmland', 'Commercial farmland', 'Built up', 'Water bodies', 'Impediment')))
names(lc.labels) <- c('yf_lc2015','yf_lc2015_label')
coord.spdf <- merge(coord.spdf,lc.labels)
names(lc.labels) <- c('yf_lc2017','yf_lc2017_label')
coord.spdf <- merge(coord.spdf,lc.labels)
head(coord.spdf)
table(coord.spdf$map_class_label,coord.spdf$yf_lc2015_label)
table(coord.spdf$map_class_label,coord.spdf$yf_lc2017_label)

coord.spdf$yf_change_0 <- 0
change0.labels <-  as.data.frame(cbind(1:4, c('stable forest', 'stable non-forest', 'forest loss', 'forest gain')))
## create change classes: level 0
change0.labels <-  as.data.frame(cbind(1:4, c('stable forest', 'stable non-forest', 'forest loss', 'forest gain')))
names(change0.labels) <- c('yf_change_0','yf_change_0_label')
# 1 = stable forest
# 2 = stable non-forest
# 3 = forest loss
# 4 = forest gain
coord.spdf$yf_change_0 <- 0
coord.spdf$yf_change_0[coord.spdf$yf_lc2015 %in% c(1:5) & coord.spdf$yf_lc2017 %in% c(1:5)] <- 1 #stable forest
coord.spdf$yf_change_0[coord.spdf$yf_lc2015 %in% c(6:13) & coord.spdf$yf_lc2017 %in% c(6:13)] <- 2 #stable nonforest
coord.spdf$yf_change_0[coord.spdf$yf_lc2015 %in% c(1:5) & coord.spdf$yf_lc2017 %in% c(6:13)] <- 3 #forest loss
coord.spdf$yf_change_0[coord.spdf$yf_lc2015 %in% c(6:13) & coord.spdf$yf_lc2017 %in% c(1:5)] <- 4 #forest gain
coord.spdf <- merge(coord.spdf,change0.labels)


table(coord.spdf$yf_change_0_label)
table(coord.spdf$yf_lc2017_label,coord.spdf$yf_lc2015_label,coord.spdf$yf_change_0_label)
## create change classes: level 1
change1.labels <-  as.data.frame(cbind(1:8, c('stable forest', 'stable non-forest', 'forest loss plantations','forest loss THF','forest loss woodlands', 'forest gain plantations','forest gain THF','forest gain woodlands')))
names(change1.labels) <- c('yf_change_1','yf_change_1_label')
# 1  = stable forest 
# 2  = stable non-forest
# 3  = forest loss plantations
# 4  = forest loss THF
# 5  = forest loss woodlands
# 6  = forest gain plantations
# 7  = forest gain THF
# 8 = forest gain woodlands
coord.spdf$yf_change_1 <- 0
coord.spdf$yf_change_1[coord.spdf$yf_lc2015 %in% c(1:5) & coord.spdf$yf_lc2017 %in% c(1:5)] <- 1 #stable forest
coord.spdf$yf_change_1[coord.spdf$yf_lc2015 %in% c(6:13) & coord.spdf$yf_lc2017 %in% c(6:13)] <- 2 #stable nonforest
coord.spdf$yf_change_1[coord.spdf$yf_lc2015 %in% c(1:2) & coord.spdf$yf_lc2017 %in% c(6:13)] <- 3 #forest loss plantations
coord.spdf$yf_change_1[coord.spdf$yf_lc2015 %in% c(3:4) & coord.spdf$yf_lc2017 %in% c(6:13)] <- 4 #forest loss THF
coord.spdf$yf_change_1[coord.spdf$yf_lc2015 %in% c(5) & coord.spdf$yf_lc2017 %in% c(6:13)] <- 5 #forest loss woodlands
coord.spdf$yf_change_1[coord.spdf$yf_lc2015 %in% c(6:13) & coord.spdf$yf_lc2017 %in% c(1:2)] <- 6 #forest gain plantations
coord.spdf$yf_change_1[coord.spdf$yf_lc2015 %in% c(6:13) & coord.spdf$yf_lc2017 %in% c(3:4)] <- 7 #forest gain THF
coord.spdf$yf_change_1[coord.spdf$yf_lc2015 %in% c(6:13) & coord.spdf$yf_lc2017 %in% c(5)] <- 8 #forest gain woodlands
coord.spdf <- merge(coord.spdf,change1.labels)

table(coord.spdf$yf_change_1_label,coord.spdf$yf_change_0_label)
table(coord.spdf$yf_change_1_label,coord.spdf$yf_lc2017_label)
table(coord.spdf$yf_change_1_label,coord.spdf$mgmt_label)
table(coord.spdf$map_class_label)
table(coord.spdf$yf_change_1_label,coord.spdf$ref_class_label)
table(coord.spdf$yf_change_1_label,coord.spdf$ref_ref_class_label)
table(coord.spdf$ref_class_label,coord.spdf$ref_ref_class_label)
table(coord.spdf$ref_class_label,coord.spdf$confidence_label)



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

###############################################################################
################### Clean data
###############################################################################
###############################################################################
##quality check using the reference data 2015 land cover  2017 land cover and change classification
# eliminate reference samples labeled 'potential'

coord.spdf$lulc_2015_class_simp[coord.spdf$lulc_2015_class %in% 1:5] <- 'forest'
coord.spdf$lulc_2015_class_simp[coord.spdf$lulc_2015_class %in% 6:13] <- 'nonforest'
coord.spdf$lulc_2017_class_simp[coord.spdf$lulc_2017_class %in% 1:5] <- 'forest'
coord.spdf$lulc_2017_class_simp[coord.spdf$lulc_2017_class %in% 6:13] <- 'nonforest'
table(coord.spdf$number_trees_after_def_plant_wl_label)
table(coord.spdf$ref_class_label,coord.spdf$ref_class)
recheck <- coord.spdf[!coord.spdf$lulc_2015_class_simp == coord.spdf$lulc_2017_class_simp & coord.spdf$ref_class %in% c(11,99) 
                      |
                        coord.spdf$lulc_2015_class_simp == coord.spdf$lulc_2017_class_simp & coord.spdf$ref_class %in% c(19,39,59,91)
                      |
                        coord.spdf$ref_class_label %in% c('Potential deforestation in plantations','Potential deforestation in THF',
                                                          'Potential deforestation in woodlands','Potential forest gain', '' )
                      |
                        coord.spdf$confidence_label %in% c('Low')
                      ,]


coord.spdf <- coord.spdf[!coord.spdf$id %in% recheck$id,
                         ]
nrow(recheck@data)


###############################################################################
################### COMPUTE AREAS
###############################################################################
####################################################################################################
################# PIXEL COUNT FUNCTION
pixel_count <- function(x){
  info    <- gdalinfo(x,hist=T)
  buckets <- unlist(str_split(info[grep("bucket",info)+1]," "))
  buckets <- as.numeric(buckets[!(buckets == "")])
  hist    <- data.frame(cbind(0:(length(buckets)-1),buckets))
  hist    <- hist[hist[,2]>0,]
}

hist <- pixel_count(paste0(ad_dir,"change_2015_2017_private_lands_UTM.tif"))
pixel     <- res(raster(paste0(ad_dir,"change_2015_2017_private_lands_UTM.tif")))[1]
names(hist) <- c("change_2015_2017","pixels")
hist$area_ha <- floor(hist$pixels*pixel*pixel/10000)
hist <- merge(hist,change.labels)
hist$mgmt_label <- 'private'
write.csv(hist,paste0(ad_dir,"change_2015_2017_private_lands.csv"),row.names = F)


hist <- pixel_count(paste0(ad_dir,"change_2015_2017_UWA_UTM.tif"))
pixel     <- res(raster(paste0(ad_dir,"change_2015_2017_UWA_UTM.tif")))[1]
names(hist) <- c("change_2015_2017","pixels")
hist$area_ha <- floor(hist$pixels*pixel*pixel/10000)
hist <- merge(hist,change.labels)
hist$mgmt_label <- 'UWA'
write.csv(hist,paste0(ad_dir,"change_2015_2017_UWA.csv"),row.names = F)

hist <- pixel_count(paste0(ad_dir,"change_2015_2017_NFA_UTM.tif"))
pixel     <- res(raster(paste0(ad_dir,"change_2015_2017_NFA_UTM.tif")))[1]
names(hist) <- c("change_2015_2017","pixels")
hist$area_ha <- floor(hist$pixels*pixel*pixel/10000)
hist <- merge(hist,change.labels)
hist$mgmt_label <- 'NFA'
hist
write.csv(hist,paste0(ad_dir,"change_2015_2017_NFA.csv"),row.names = F)
areas <- rbind(read.csv(paste0(ad_dir,"change_2015_2017_private_lands.csv")),read.csv(paste0(ad_dir,"change_2015_2017_UWA.csv")),read.csv(paste0(ad_dir,"change_2015_2017_NFA.csv")))
areas
totalarea <- floor(sum(areas$area_ha))

df <- merge(coord.spdf,areas, by.x=c('change_2015_2017_label','mgmt_label'),by.y=c('change_2015_2017_label','mgmt_label'))
test <- df[!df %in% rechecek,]
tail(df,20)
df$strata <- paste0(df$change_2015_2017.x,'_',df$mgmt)
df$strata_label <- paste0(df$change_2015_2017_label,'- ',df$mgmt_label)
# calculate strata weights
df$map_weights<-df$area_ha/sum(unique(df$area_ha),na.rm = T)
df$total_area <- totalarea
str(unique(df$area_ha))
# write.csv(all_strata_areas,paste0(samp_dir,'all_strata_areas.csv'),row.names = F)
df<- df[!is.na(df$map_weights),]
df<- df[!df$strata %in% c('11_1','11_10','2_1','4_100'),]

# loss_area <- sum(hist[(hist$code > 7 & hist$code < 9),"pixels"]*pixel*pixel/10000)
sum(unique(df$map_weights))
table(df$strata)

table(df$ref_class_label)
nrow(df)
table(df$ref_class_label)
table(df$confidence_label)
table(df$change_2015_2017_label,df$ref_class_label,df$mgmt_label)
table(df$number_trees_2017_tof_label)
table(df$lulc_2015_class_label,df$lulc_2017_class_label,df$ref_class_label)
table(df$lulc_2015_class_label,df$lulc_2015_class)



###############################################################################
# stratified random survey
table(df$strata_label)
strat_srs_design <- svydesign(ids=~1,  strata=~mgmt_label,
                              fpc=~area_ha, weights=~map_weights, data=df)
# svyby(~strata_label, strat_srs_design, svymean,keep.var = T, vartype = 'ci')

svymean(~ref_class_label,strat_srs_design)
svyby(~ref_class_label,~mgmt, strat_srs_design, svymean)

svytotal(~ref_class_label ,strat_srs_design)
table(allref1$strata_label)
# calculate area and CI per class (for STRATIFIED random sampling design)
df.results.strat_srs_design <- as.data.frame(svymean(~ref_class_label,strat_srs_design))
df.results.strat_srs_design$class <- substring(row.names(df.results.strat_srs_design),16 )
df.results.strat_srs_design$area_ha <-round(df.results.strat_srs_design$mean * totalarea)
df.results.strat_srs_design$CI_95 <- df.results.strat_srs_design$SE * 1.96
df.results.strat_srs_design$CI_ha <-round(df.results.strat_srs_design$SE * 1.96  * totalarea)
df.results.strat_srs_design$CI_percent <- round(df.results.strat_srs_design$CI_ha/df.results.strat_srs_design$area_ha,digits = 3)*100
# df.results.strat_srs_design$prioritylandscape <- str_sub(df.results.strat_srs_design$class,-1,-1 )
# df.results.strat_srs_design$change <- str_sub(df.results.strat_srs_design$class,1,-2 )

as.data.frame(svytotal(~ref_class_label,strat_srs_design))
samplesize <- table(df$ref_class_label)
melted_samplesize <- melt(samplesize)
names(melted_samplesize) <- c('class','samplesize')
df.results.strat_srs_design <- merge(df.results.strat_srs_design,melted_samplesize,by='class')
df.results.strat_srs_design



table(coord.spdf$change_2015_2017_label,coord.spdf$ref_class_label)
table(coord.spdf$change_2015_2017_label,coord.spdf$ref_class_label,coord.spdf$mgmt_label)

table(coord.spdf$ref_class_label)
table(coord.spdf$confidence_label)


ggplot(data = df.results.strat_srs_design, aes(x = class, y = area_ha)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_text(aes(y = 0, label = n), position = position_dodge(width = 0.9), vjust = -1)
  

