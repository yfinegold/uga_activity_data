########################################
## Identifying patterns in BFAST output
########################################
## load parameters
source('~/uga_activity_data/scripts/get_parameters.R')

# input files
bfastout <-paste0(bfast_dir,'bfast_westlbert_co.tif')
lc <- paste0(lc_dir,'Ug2017_CW_gEdits4_co.tif')

# output file names
result <- paste0(thres_dir,'bfast_westlbert_co_thf_mask.tif')
forestmask <- paste0(lc_dir,'THF_mask2017.tif')
forestmask.albertine <- paste0(lc_dir,'THF_mask2017_albertine.tif')

## parameters
# factor to divide standard deviation
divide_sd <- 4

#################### reclassify LC map into THF mask
system(sprintf("gdal_calc.py -A %s --type=Byte --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               lc,
               forestmask,
               paste0("((A==3)+(A==4))*1")
))
#################### reproject THF mask to latlong WGS84
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
               forestmask.albertine
))

# apply mask
system(sprintf("gdal_calc.py -A %s -B %s --B_band=2 --co COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               forestmask.albertine,
               bfastout,
               result,
               paste0("A*B")
))
# plot(raster(forestmask.albertine))
# plot(raster(result))

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
  
  outputfile   <- paste0(thres_dir,  substr(basename(bfastout), 1, nchar(basename(bfastout))-4),'_threshold.tif')
  # r <- raster(result)
  # NAvalue(r) <- 0
  means_b2 <- cellStats( raster(result) , na.rm=TRUE, "mean") 
  mins_b2 <- cellStats( raster(result) , na.rm=TRUE,"min")
  maxs_b2 <- cellStats(  raster(result) ,na.rm=TRUE, "max")
  stdevs_b2 <- cellStats(  raster(result) ,na.rm=TRUE, "sd")/divide_sd
  system(sprintf("gdal_calc.py -A %s --co=COMPRESS=LZW --type=Byte --outfile=%s --calc='%s'
                 ",
                 result,
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
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(thres_dir,"color_table.txt"),
               paste0(thres_dir,"tmp_threshold.tif"),
               paste0(thres_dir,"/","tmp_colortable.tif")
))
## Compress final result
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(thres_dir,"/","tmp_colortable.tif"),
               outputfile
))
# gdalinfo(outputfile,hist = T)
## Clean all
system(sprintf(paste0("rm ",thres_dir,"/","tmp*.tif")))

