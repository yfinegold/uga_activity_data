##############################################################
# 
#This Script was written for remote sensing image classification based on polygon training locations.
# It was first tested on Sentinel 2A imagery downoanloaded from GEE.
#The training polygons are generated and stored in ESRI shapefile OGR format.
# Script was written in May 2019 
#                      
# Joseph Mutyaba
# joseph.mutyaba@fao.org
# mutyabajoekk@gmail.com
# last version 20190715
###############################################################

#load  packages

library(RStoolbox)
library(raster)
library(maptools)
library(rgdal)

# Start processing
startTime <- Sys.time()
cat("Start time", format(startTime),"\n")

#setting working directory for the classification process and other working files
#setwd("Set the location of the working directory here. Edit the example provided to suit your working location")
setwd("D:/NFMS_NFA_FAO_WB2018_9/March2019/S2A_Mosaics2019")

# Input shapefiles with training data
#shapefileDSN <- 'Navigate or paste the path of the shapefile with training data here. Edit the example provided to suit your working location'
shapefileDSN <- 'D:/NFMS_NFA_FAO_WB2018_9/March2019/S2A_Mosaics2019/triain.shp'
# Read the Shapefile
?readOGR
?rgdal::readOGR
vec1 <- readOGR(shapefileDSN, )

#Input image to be classified
#image <- stack("Path to input image to be classified". Edit the example provided to suit your working location)
image <- stack("D:/NFMS_NFA_FAO_WB2018_9/March2019/S2A_Mosaics2019/Uganda0_0.tif")

# Test plotting
plotRGB(image, r=1, g=2, b=3) # use raster function to plot RGB image
ggRGB(image, r=1, g=2, b=3, stretch='hist', maxpixels=500000) # use RStoolbox function to plot RGB image

# plot(vec1, add=T, col=2)  #Overlay training data

# Simple supervised classification using random forest and Write out image to disk

#outImage1 <- superClass(image, vec1, responseCol="Id", nSamples=50, model="rf", verbose=TRUE, mode="classification")

outImage1 <- superClass(image, vec1, valData = NULL, responseCol = "ID",
                                  nSamples = 25, polygonBasedCV = FALSE, trainPartition = NULL,
                                   model = "rf", tuneLength = 3, kfold = 5, minDist = 2,
                                   mode = "classification", predict = TRUE, predType = "raw",
                                  filename = "OutputFileName.tif", verbose=TRUE, overwrite = TRUE)

# Look at the structure of an output image then plot
str(outImage1)
plot(outImage1$map)
print(outImage1$model)
print(outImage1$classMapping)



# Calculate processing time
timeDiff <- Sys.time() - startTime
cat("\nProcessing time", format(timeDiff), "\n")
