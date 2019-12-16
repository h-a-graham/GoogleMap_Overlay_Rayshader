library(rayshader)
library(sf)
library(tidyverse)
library(ggmap)
library(raster)

# ------------ User Inputs ---------------------------------

# Googple maps API KEY
register_google(key = "[ENTER KEY HERE!!]") # Create your own key as shown in the ggmap documentation: https://github.com/dkahle/ggmap

#  WGS84 Long lat centroid location for your scene...
Loc_Coords <- c(6.265301,44.26526)  # Barre de Chine

# Enter the path to your DEM...
DEM_path <- './Raster_Path.tif'

# Enter a path for a temp output of the satellite overlay...
Save_Path <- "./Save_Folder_Path.jpg"  # must be a jpg for this workflow.

# Enter the output path for your scene...
fname = './Out_Folder_Path.png'  # save sat output (must be included at the moment.)

# ------ Get and project Raster ---------------

# ggmap works with WGS84 so need to set the raster crs to this.
newproj <- "+proj=longlat +datum=WGS84 +no_defs"

dem_ras <- raster::raster(DEM_path)
dem_ras <- projectRaster(dem_ras, crs = newproj)


# ------ Get Aerial image and extent. Then crop Raster ---------------

X = Loc_Coords[1]
Y = Loc_Coords[2]

amap = get_googlemap(center = c(lon = X , lat = Y),
                     zoom = 14, scale = 2,
                     maptype ='satellite',
                     color = 'color', size =c(640, 640)) 


bb <- attr(amap, "bb")
bbox <- as.numeric(unlist(bb2bbox(bb)))
bbox <- c(bbox[1], bbox[3], bbox[2], bbox[4])

basemap = ggmap(amap, extent = "device")
ggmap(amap)

dem_ras <- raster::crop(dem_ras, extent(bbox), snap = 'in')
# plot(dem_ras)

# ------------- Convert ggmap to png ---------------------


grDevices::png(filename = fname, width = 1280, height = 1280)
par(mar = c(0,0,0,0))
basemap
dev.off()
overlay_img = png::readPNG(fname)


# dim(dem_mat)
dim(overlay_img)
#aggregate raster to incrEASE RESOLUTION
dem_ras2 <- raster::disaggregate(dem_ras, fact = 7, method='bilinear')
#Convert raster to matrix
dem_mat2 <- raster_to_matrix(dem_ras2)
# dim(dem_mat2)

# ----------- Run Rayshader ---------------------

dem_mat2 %>%
  sphere_shade(sunangle = 35, texture = "imhof4") %>%
  add_overlay(overlay_img, alphalayer = 0.95) %>%
  add_shadow(ray_shade(dem_mat2, zscale = 1), 0.5) %>%
  add_shadow(ambient_shade(dem_mat2), 0.5) %>%
  
  plot_3d(dem_mat2, zscale = 3, fov = 0, theta = 20, zoom = 0.51, phi = 35, windowsize = c(1200, 1000), 
          solid = FALSE, baseshape = "rectangle")
Sys.sleep(0.2)


render_depth(focus = 0.6, focallength = 20)

jpeg(Save_Path, units="in", width=5, height=5, res=600)
render_depth(focus = 0.5, focallength = 15)
dev.off()



