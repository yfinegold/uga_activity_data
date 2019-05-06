####################################################################################################
####################################################################################################
## Tiling of an AOI (shapefile defined)
## Contact remi.dannunzio@fao.org 
## 2019/03/11
####################################################################################################
####################################################################################################
### load the parameters
source('~/uga_activity_data/scripts/get_parameters.R')
usernamelist <- paste0(mgmt_dir,'usernames_uga.csv')


### GET COUNTRY BOUNDARIES FROM THE WWW.GADM.ORG DATASET
aoi   <- getData('GADM',
                 path=gadm_dir, 
                 country= countrycode, 
                 level=0)

(bb    <- extent(aoi))
 


### What grid size do we need ? 
grid_size <- 20000          ## in meters

### GENERATE A GRID
sqr_df <- generate_grid(aoi,grid_size/111320)

nrow(sqr_df)

### Select a vector from location of another vector
sqr_df_selected <- sqr_df[aoi,]
nrow(sqr_df_selected)

### Give the output a decent name, with unique ID
names(sqr_df_selected@data) <- "tileID" 
sqr_df_selected@data$tileID <- row(sqr_df_selected@data)[,1]

### Reproject in LAT LON
tiles   <- spTransform(sqr_df_selected,CRS("+init=epsg:4326"))
aoi_geo <- spTransform(aoi,CRS("+init=epsg:4326"))


### Plot the results
plot(tiles)
plot(aoi_geo,add=T,border="blue")


### check against forest nonforest mask
FNF_mask_proj <- paste0(lc_dir,"FNF_mask_2015_2017_proj.tif")
FNF_mask_proj.shp <- paste0(lc_dir,"FNF_mask_2015_2017_proj.shp")
plot(raster(FNF_mask_proj),add=T)
######################################
if(!file.exists(FNF_mask_proj.shp)){
system(sprintf("gdal_polygonize.py -mask %s %s -f 'ESRI Shapefile' %s  ",
                               FNF_mask_proj,
                               FNF_mask_proj,
                               FNF_mask_proj.shp
                               ))
}
shp_mask <- readOGR(FNF_mask_proj.shp)
# plot(shp_mask,add=T)
shp_mask <- spTransform(shp_mask,CRS("+init=epsg:4326"))

tiles@data$forest_mask <- over(tiles,shp_mask)
subtile <- tiles[tiles@data$forest_mask$DN %in% 1 ,]
subtile <- subtile[,"tileID"]
subtile
table(tiles$forest_mask)

subtile <- tiles[tiles@data$forest_mask$DN %in% 1 ,]
subtile <- subtile[,"tileID"]
# plot(shp_mask,border="green")
plot(subtile,add=T)

### Read the list of usernames
users     <- read.csv(usernamelist)

### Assign each tile with a username
df        <- data.frame(cbind(subtile@data[,"tileID"],users$Name))
names(df) <- c("tileID","username")
df$tileID <- as.numeric(df$tileID)
table(df$username)
subtile@data <- df


for(username in unique(df$username)){
  ### Create a final subset corresponding to your username
    my_tiles <- subtile[subtile$tileID %in% df[df$username == username,"tileID"],]
    # plot(my_tiles,add=T,col="black")
    length(my_tiles)
    
    ### Export the final subset
    export_name <- str_replace_all(paste0("national_scale_",length(my_tiles),"_tiles_",username), " ","_")
    
    
    writeOGR(obj=my_tiles,
        dsn=paste(tile_dir,export_name,".kml",sep=""),
        layer= export_name,
        driver = "KML",
        overwrite_layer = T)
    }
    
### Export ALL TILES as KML
export_name <- paste0("tiling_system_",countrycode)

writeOGR(obj=subtile,
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)
my_tiles <- tiles[tiles$tileID %in% df[df$username == username,"tileID"],]

plot(my_tiles,add=T,col="green")
length(my_tiles)

### Export the final subset
export_name <- paste0("charcoal_kilns_",length(my_tiles),"_tiles_",username)

writeOGR(obj=my_tiles,
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)

### Export the ONE TILE IN THE subset
export_name <- paste0("charcoal_kilns_one_tile_",username)

writeOGR(obj=my_tiles[1,],
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)
