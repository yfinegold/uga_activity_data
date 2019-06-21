########################################
## Identifying patterns in BFAST output
########################################
## load parameters
source('~/uga_activity_data/scripts/get_parameters.R')

# input files
bfastout <-paste0(bfast_dir,'all_bfast.tif')
change.sieved <- paste0(ad_dir,"change_2015_2017_all_classes_04052019_sieve.tif")
# the legend is created in script ad2_analysis.R lines 125 to 145
lc_trans_legend <- paste0(ad_dir,'all_lc_transitions_legend.csv')

# output file names
bfast.mask <- paste0(thres_dir,'all_bfast_masked.tif')
forestmask <- paste0(lc_dir,'stableforest_mask.tif')
forestmask.clip <- paste0(lc_dir,'stableforest_mask_clipped.tif')
boundarymask <- paste0(lc_dir,'boundary_mask.tif')
boundary.clip <- paste0(lc_dir,'boundary_mask_clipped.tif')
outputfile   <- paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_threshold.tif')

## parameters
# factor to multiply standard deviation
mult_sd <- 2.5


#################### reclassify LC map into forestmask mask
lc_trans_legend <- read.csv(lc_trans_legend)
eq.reclass1 <- paste0('(A==',lc_trans_legend$id[(lc_trans_legend$map_lc2015%in%1:5|lc_trans_legend$map_lc2017%in%1:5)],') + ',collapse = '')
eq.reclass1 <- paste0('(',as.character(substr(eq.reclass1,1,nchar(eq.reclass1)-2)),')*1',collapse = '')
eq.reclass1



system(sprintf("gdal_calc.py -A %s --type=Byte --debug --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               change.sieved,
               forestmask,
               eq.reclass1
))
gdalinfo(change.sieved,mm=T)

gdalinfo(forestmask2,mm=T)
plot(raster(forestmask))

#################### reproject forest mask to latlong WGS84
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
               "EPSG:4326",
               forestmask,
               paste0(thres_dir,"tmp_proj.tif")
))

# clip bfast output to mask
system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -tr %s %s -co COMPRESS=LZW %s %s",
               extent(raster(bfastout))@xmin,
               extent(raster(bfastout))@ymax,
               extent(raster(bfastout))@xmax,
               extent(raster(bfastout))@ymin,
               res(raster(bfastout))[1],
               res(raster(bfastout))[2],
               paste0(thres_dir,"tmp_proj.tif"),
               forestmask.clip
))

## create a boundary mask
system(sprintf("gdal_calc.py -A %s --type=Byte --debug --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               change.sieved,
               boundarymask,
               paste0("(A==0)*1")
))
gdalinfo(boundarymask)
plot(raster(boundarymask))

system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
               "EPSG:4326",
               boundarymask,
               paste0(thres_dir,"tmp_proj.tif")
))

# clip bfast output to mask
system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -tr %s %s -co COMPRESS=LZW %s %s",
               extent(raster(bfastout))@xmin,
               extent(raster(bfastout))@ymax,
               extent(raster(bfastout))@xmax,
               extent(raster(bfastout))@ymin,
               res(raster(bfastout))[1],
               res(raster(bfastout))[2],
               paste0(thres_dir,"tmp_proj.tif"),
               boundary.clip
))
# apply mask
system(sprintf("gdal_calc.py -A %s -B %s --B_band=2 --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               forestmask.clip,
               bfastout,
               bfast.mask,
               paste0("A*B")
))
# plot(raster(forestmask.albertine))
# plot(raster(bfast.mask))

## Post-processing ####
# calculate the mean, standard deviation, minimum and maximum of the magnitude band
# reclass the image into 10 classes
# 0 = no data
# 1 = no change (mean +/- 1 standard deviation)
# 2 = negative small magnitude change      (mean - 2 standard deviations)
# 3 = negative medium magnitude change     (mean - 3 standard deviations)
# 4 = negative large magnitude change      (mean - 4 standard deviations)
# 5 = negative very large magnitude change (mean - 4+ standard deviations)
# 6 = postive small magnitude change       (mean + 2 standard deviations)
# 7 = postive medium magnitude change      (mean + 3 standard deviations)
# 8 = postive large magnitude change       (mean + 4 standard deviations)
# 9 = postive very large magnitude change  (mean + 4+ standard deviations)
#################### SET NODATA TO NONE IN THE TIME SERIES STACK

tryCatch({
  # NAvalue(r) <- 0
  means_b2 <- pixel_mean(bfast.mask) 
  mins_b2 <- pixel_min(bfast.mask) 
  maxs_b2 <- pixel_max(bfast.mask) 
  stdevs_b2 <- pixel_sd(bfast.mask) 
  stdevs_b2 <- stdevs_b2 * mult_sd
  stdevs_b2 *3
  num_class <-9
  paste0('(A<=',(maxs_b2),")*", '(A>',(means_b2+(stdevs_b2*floor(num_class/2))),")*",num_class,"+" ,
          paste( 
            " ( A >",(means_b2+(stdevs_b2*1:(floor(num_class/2)-1))),") *",
            " ( A <=",(means_b2+(stdevs_b2*2:floor(num_class/2))),") *",
            (ceiling(num_class/2)+1):(num_class-1),"+",
             collapse = ""), 
         '(A<=',(means_b2+(stdevs_b2)),")*",
         '(A>', (means_b2-(stdevs_b2)),")*1+",
         '(A>=',(mins_b2),")*",
         '(A<', (means_b2-(stdevs_b2*4)),")*",ceiling(num_class/2),"+",
         paste( 
           " ( A <",(means_b2-(stdevs_b2*1:(floor(num_class/2)-1))),") *",
           " ( A >=",(means_b2-(stdevs_b2*2:floor(num_class/2))),") *",
           2:(ceiling(num_class/2)-1),"+",
           collapse = "")
         )
  
  paste( " ( A <=",(means_b2+(stdevs_b2*1:num_class)),") *", collapse = "")
  
  system(sprintf("gdal_calc.py -A %s --co=COMPRESS=LZW --type=Byte --outfile=%s --calc='%s'
                 ",
                 bfast.mask,
                 paste0(thres_dir,"tmp_threshold.tif"),
                 paste0('(A<=',(maxs_b2),")*",
                        '(A>',(means_b2+(stdevs_b2*4)),")*9+",
                        '(A<=',(means_b2+(stdevs_b2*4)),")*",
                        '(A>',(means_b2+(stdevs_b2*3)),")*8+",
                        '(A<=',(means_b2+(stdevs_b2*3)),")*",
                        '(A>', (means_b2+(stdevs_b2*2)),")*7+",
                        '(A<=',(means_b2+(stdevs_b2*2)),")*",
                        '(A>', (means_b2+(stdevs_b2)),")*6+",
                        '(A<=',(means_b2+(stdevs_b2)),")*",
                        '(A>', (means_b2-(stdevs_b2)),")*1+",
                        '(A>=',(mins_b2),")*",
                        '(A<', (means_b2-(stdevs_b2*4)),")*5+",
                        '(A>=',(means_b2-(stdevs_b2*4)),")*",
                        '(A<', (means_b2-(stdevs_b2*3)),")*4+",
                        '(A>=',(means_b2-(stdevs_b2*3)),")*",
                        '(A<', (means_b2-(stdevs_b2*2)),")*3+",
                        '(A>=',(means_b2-(stdevs_b2*2)),")*",
                        '(A<', (means_b2-(stdevs_b2)),")*2")
  ))
  
system(sprintf("gdal_calc.py -A %s --co=COMPRESS=LZW --type=Byte --outfile=%s --calc='%s'",
                 bfast.mask,
                 paste0(thres_dir,"tmp_threshold.tif"),
                 paste0('(A<=',(maxs_b2),")*", '(A>',(means_b2+(stdevs_b2*floor(num_class/2))),")*",num_class,"+" ,
                        paste( 
                          " ( A >",(means_b2+(stdevs_b2*1:(floor(num_class/2)-1))),") *",
                          " ( A <=",(means_b2+(stdevs_b2*2:floor(num_class/2))),") *",
                          (ceiling(num_class/2)+1):(num_class-1),"+",
                          collapse = ""), 
                        '(A<=',(means_b2+(stdevs_b2)),")*",
                        '(A>', (means_b2-(stdevs_b2)),")*1+",
                        '(A>=',(mins_b2),")*",
                        paste( 
                          " ( A <",(means_b2-(stdevs_b2*1:(floor(num_class/2)-1))),") *",
                          " ( A >=",(means_b2-(stdevs_b2*2:floor(num_class/2))),") *",
                          2:(ceiling(num_class/2)-1),"+",
                          collapse = "")
                 )
  ))
  
}, error=function(e){})

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("white","beige","yellow","orange","red","darkred","palegreen","green2","forestgreen",'darkgreen'))
pct <- data.frame(cbind(c(0:9),
                        cols[1,],
                        cols[2,],
                        cols[3,]
))

write.table(pct,paste0(thres_dir,"color_table.txt"),row.names = F,col.names = F,quote = F)


################################################################################
## Add pseudo color table to bfast.mask
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(thres_dir,"color_table.txt"),
               paste0(thres_dir,"tmp_threshold.tif"),
               paste0(thres_dir,"/","tmp_colortable.tif")
))
## Compress final bfast.mask
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(thres_dir,"/","tmp_colortable.tif"),
               outputfile
))

################################################################################
######## post post processing 
################################################################################
######## DEFORESTATION
#################### reclass only high magnitude loss mask
system(sprintf("gdal_calc.py -A %s --type=Byte --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               outputfile,
               paste0(thres_dir,"/","tmp_hi_mag_loss.tif"),
               paste0("(A==5)")
))

#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(thres_dir,"/","tmp_hi_mag_loss.tif"),
               paste0(thres_dir,  "tmp_",substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_loss_threshold_sieve.tif')
               
))
## Compress sieved
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(thres_dir,  "tmp_",substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_loss_threshold_sieve.tif'),
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_loss_threshold_sieve.tif')
               
))
#################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(thres_dir,"/","tmp_hi_mag_loss.tif"),
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_loss_threshold_sieve.tif'),
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_loss_threshold_sieve_inf.tif'),
               paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
))

################################################################################
######## REFORESTATION
#################### reclass only high magnitude gain mask
system(sprintf("gdal_calc.py -A %s --type=Byte --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               outputfile,
               paste0(thres_dir,"/","tmp_hi_mag_gain.tif"),
               paste0("(A==9)")
))

#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               mmu,
               paste0(thres_dir,"/","tmp_hi_mag_gain.tif"),
               paste0(thres_dir,  "tmp_",substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_gain_threshold_sieve.tif')
               
))

## Compress sieved
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(thres_dir,  "tmp_",substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_gain_threshold_sieve.tif'),
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_gain_threshold_sieve.tif')
               
))

# #################### DIFFERENCE BETWEEN SIEVED AND ORIGINAL
# system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(thres_dir,"/","tmp_hi_mag_gain.tif"),
#                paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_gain_threshold_sieve.tif'),
#                paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_gain_threshold_sieve_inf.tif'),
#                paste0("(A>0)*(A-B)+(A==0)*(B==1)*0")
# ))


################################################################################
######## DEGRADATION
### what about sieving another magnitude class? should degradation have some MMU?
#################### reclass only medium magnitude loss mask
system(sprintf("gdal_calc.py -A %s --type=Byte --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               outputfile,
               paste0(thres_dir,"/","tmp_med_mag_loss.tif"),
               paste0("(A==4)")
))
#################### SIEVE TO THE MMU
system(sprintf("gdal_sieve.py -st %s %s %s ",
               2,
               paste0(thres_dir,"/","tmp_med_mag_loss.tif"),
               paste0(thres_dir,  "tmp_",substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_deg_threshold_sieve.tif')
               
))

## Compress sieved
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(thres_dir,  "tmp_",substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_deg_threshold_sieve.tif'),
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_deg_threshold_sieve.tif')
               
))
plot(raster(forestmask.clip))
system(sprintf("gdal_calc.py -A %s -B %s -C %s -D %s -E %s -F %s  --overwrite --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               forestmask.clip,
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_loss_threshold_sieve.tif'),
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_loss_threshold_sieve_inf.tif'),
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_gain_threshold_sieve.tif'),
               paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_deg_threshold_sieve.tif'),
               boundary.clip,
               paste0(thres_dir,"tmp_BFAST_change_2015_2017.tif"),
               paste0(
                 "(F==1)*0+",
                 "((A==1)*(B<1)*(C<1)*(D<1)*(E<1)*(F<1))*1+",
                 "((A==0)*(B<1)*(C<1)*(D<1)*(E<1)*(F<1))*2+",
                 "(B==1)*3+",
                 "(((E==1)*(B<1))+(C==1))*4+",
                 "(D==1)*5"
                 ## need to add a mask layer for 0
                 ,collapse = "")
))
# plot(raster(forestmask.clip))
gdalinfo(paste0(thres_dir,"tmp_BFAST_change_2015_2017.tif"),mm=T)
gdalinfo(paste0(thres_dir,"tmp_BFAST_change_2015_2017.tif"),hist=T)

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c('white','forestgreen','gray100',"red","yellow","darkblue"))
pct <- data.frame(cbind(c(0:6),
                        cols[1,],
                        cols[2,],
                        cols[3,]
))

write.table(pct,paste0(thres_dir,"color_table.txt"),row.names = F,col.names = F,quote = F)

################################################################################
## Add pseudo color table to bfast change
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(thres_dir,"color_table.txt"),
               paste0(thres_dir,"tmp_BFAST_change_2015_2017.tif"),
               paste0(thres_dir,"/","tmp_BFAST_change_2015_2017.tif")
))

## Compress final bfast.mask
system(sprintf("gdal_translate -a_nodata 255 -ot byte -co COMPRESS=LZW %s %s",
               paste0(thres_dir,"/","tmp_BFAST_change_2015_2017.tif"),
               paste0(thres_dir,"/","BFAST_change_2015_2017.tif")
               
))

plot(raster(paste0(thres_dir,"BFAST_change_2015_2017.tif")))

#################### reproject forest mask to latlong WGS84
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
               "EPSG:4326",
               change.sieved,
               paste0(thres_dir,"tmp_proj_change.tif")
))

# clip lc map to output
system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -tr %s %s -co COMPRESS=LZW %s %s",
               extent(raster(paste0(thres_dir,"tmp_proj_change.tif")))@xmin,
               extent(raster(paste0(thres_dir,"tmp_proj_change.tif")))@ymax,
               extent(raster(paste0(thres_dir,"tmp_proj_change.tif")))@xmax,
               extent(raster(paste0(thres_dir,"tmp_proj_change.tif")))@ymin,
               res(raster(paste0(thres_dir,"tmp_proj_change.tif")))[1],
               res(raster(paste0(thres_dir,"tmp_proj_change.tif")))[2],
               
               paste0(thres_dir,"/","BFAST_change_2015_2017.tif"),
               paste0(thres_dir,"/","BFAST_change_2015_2017_clipped.tif")
))

eq.reclass2 <- paste0(
  paste0('((A == 3)  * (B == ',1:169, ') * ',1:169   ,') + ',collapse=''), 
  paste0('((A == 4)  * (B == ',1:169, ') * ',170:338 ,') + ',collapse=''),
  paste0('((A == 5) * (B == ',1:169, ') * ',339:507 ,') + ',collapse='')
  ,collapse=''
)
eq.reclass2 <- as.character(substr(eq.reclass2,1,nchar(eq.reclass2)-2))
eq.reclass2
#### deforestation and lc transition matrix overlap
system(sprintf("gdal_calc.py -A %s -B %s  --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               paste0(thres_dir,"/","BFAST_change_2015_2017_clipped.tif"),
               paste0(thres_dir,"tmp_proj_change.tif"),
               paste0(thres_dir,"BFAST_deforestation_LC_classes.tif"),
               paste0('(A == 3)  * B')
              ))
32736
#################### reproject forest mask to UTM 36S
system(sprintf("gdalwarp -t_srs \"%s\" -overwrite -ot Byte -co COMPRESS=LZW %s %s",
               "EPSG:32736",
               paste0(thres_dir,"LC_combined_test.tif"),
               paste0(thres_dir,"tmp_proj.tif")
))
################# PIXEL COUNT OF DEFORESTATION ON LC MATRIX CLASSES
hist <- pixel_count(paste0(thres_dir,"tmp_proj.tif"))
pixel     <- res(raster(paste0(thres_dir,"tmp_proj.tif")))[1]
names(hist) <- c("id","pixels")
hist$area_ha <- floor(hist$pixels*pixel*pixel/10000)
hist <- merge(hist,lc_trans_legend )
head(hist)
hist$change_label <- 'deforestation'
write.csv(hist,paste0(ad_dir,"BFAST_change_2015_2017_deforestation.csv"),row.names = F)



paste0(thres_dir,"combined_test.tif")
gdalinfo(paste0(thres_dir,"BFAST_change_2015_2017_clipped.tif"),hist = T)
gdalinfo(paste0(thres_dir,"combined_test.tif"),hist = T)

gdalinfo(paste0(thres_dir,"tmp_proj_change.tif"),mm = T)

gdalinfo(paste0(thres_dir,"LC_combined_test.tif"),mm = T)
plot(raster(outputfile))
## Clean all
system(sprintf(paste0("rm ",thres_dir,"/","tmp*.tif")))

