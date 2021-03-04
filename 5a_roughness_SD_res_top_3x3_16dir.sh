# Computing DIRECTIONAL terrain roughness as standard deviation of the residual topography (grohnman 2011)
# Calculate SD of the residual topography in 16 directions along a predefined buffer area of the input polylines
# WINDOW SIZE: 3x3


# INPUT DATA:
# 1- Digital Surface Model
# 2- Polyline representing the channel (Polyline preprocessing: split it in segments (qgis tool named "explode"), calculate in the attribute table the azimuth of each segments in the field calculator in qgis (field_name "azimuth": degrees(azimuth(start_point($geometry), end_point($geometry)))
# 3- distance buffer: maximum lateral extension to compute the directional slope
# 4- resolution: matching the input raster resolution (to compute the distance used in the moving window)
# 5- working directory: path to the working directory for input and output files

# POSTPROCESSING
# select the layers for which the directional map is computed 
# 1- merge the maps in a final one (saga: mosaic raster layer - mean value method)
# 2- fill the values for which the directional slope is not computed due to the buffer mask (grass: r.fillnulls)

############################
g.remove -f type=raster pattern="*"
g.remove -f type=vector pattern="*"

# INPUT DATA

distance_buf="30"	#width of the buffer from the given polyline (area for which will be calculated the directional roughness) 
min_distance_buf="5"
#import the DSM and the lines for direction
working_directory="/home/tommaso/braema_directional_5a"
r.import -o --o input="$working_directory"/DSM_Braema_Duchli_20190617_1m_AOI.tif output=DSM
v.import --o -o input="$working_directory"/roughness_direction.shp output=direct_line


############################
window_size="31" #set the window size for the smooth surface

g.region -p -s raster=DSM

r.neighbors input=DSM size="$window_size" method=average output=reference_surface #create the reference surface
r.mapcalc "dif = DSM - reference_surface"

# classical method to compute SD of residual topography
r.neighbors input=dif size=3 method=stddev output=SD_res_top		#SD of the residual topography
r.out.gdal --o -c -m input=SD_res_t\op output="$working_directory"/SD_res_top_3x3.tif


v.extract --o input=direct_line output=direct_0     where="(azimuth >= 348.75) or (azimuth < 11.25)"
v.extract --o input=direct_line output=direct_22p5  where="(azimuth >= 11.25) and (azimuth < 33.75)"
v.extract --o input=direct_line output=direct_45    where="(azimuth >= 33.75) and (azimuth < 56.25)"
v.extract --o input=direct_line output=direct_67p5  where="(azimuth >= 56.25) and (azimuth < 78.75)"
v.extract --o input=direct_line output=direct_90    where="(azimuth >= 78.75) and (azimuth < 101.25)"
v.extract --o input=direct_line output=direct_112p5 where="(azimuth >= 101.25) and (azimuth < 123.75)"
v.extract --o input=direct_line output=direct_135   where="(azimuth >= 123.75) and (azimuth < 146.25)"
v.extract --o input=direct_line output=direct_157p5 where="(azimuth >= 146.25) and (azimuth < 168.75)"
v.extract --o input=direct_line output=direct_180   where="(azimuth >= 168.75) and (azimuth < 191.25)"
v.extract --o input=direct_line output=direct_202p5 where="(azimuth >= 191.25) and (azimuth < 213.75)"
v.extract --o input=direct_line output=direct_225   where="(azimuth >= 213.75) and (azimuth < 236.25)"
v.extract --o input=direct_line output=direct_247p5 where="(azimuth >= 236.25) and (azimuth < 258.75)"
v.extract --o input=direct_line output=direct_270   where="(azimuth >= 258.75) and (azimuth < 281.25)"
v.extract --o input=direct_line output=direct_292p5 where="(azimuth >= 281.25) and (azimuth < 303.75)"
v.extract --o input=direct_line output=direct_315   where="(azimuth >= 303.75) and (azimuth < 326.25)"
v.extract --o input=direct_line output=direct_337p5 where="(azimuth >= 326.75) and (azimuth < 348.75)"


v.buffer --o -s input=direct_0     output=buf_0     distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_22p5  output=buf_22p5  distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_45    output=buf_45    distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_67p5  output=buf_67p5  distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_90    output=buf_90    distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_112p5 output=buf_112p5 distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_135   output=buf_135   distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_157p5 output=buf_157p5 distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_180   output=buf_180   distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_202p5 output=buf_202p5 distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_225   output=buf_225   distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_247p5 output=buf_247p5 distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_270   output=buf_270   distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_292p5 output=buf_292p5 distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_315   output=buf_315   distance="$distance_buf" minordistance="$min_distance_buf"
v.buffer --o -s input=direct_337p5 output=buf_337p5 distance="$distance_buf" minordistance="$min_distance_buf"


r.mask --o vector=buf_0
r.mapcalc --o "mean_0 = (dif[1,-1] + dif[1,0] + dif[1,1] + dif[-1,-1] + dif[-1,0] + dif[-1,1]) / 6"
r.mapcalc --o "rough_0 = (((dif[1,-1]-mean_0)^2 + (dif[1,0]-mean_0)^2 + (dif[1,1]-mean_0)^2 + (dif[-1,-1]-mean_0)^2 + (dif[-1,0]-mean_0)^2 + (dif[-1,1]-mean_0)^2) / 6)^0.5"
r.mask -r

r.mask --o vector=buf_22p5
r.mapcalc --o "mean_22p5 = (dif[1,-1] + dif[1,0] + dif[-1,0] + dif[-1,1]) / 4"
r.mapcalc --o "rough_22p5 = (((dif[1,-1]-mean_22p5)^2 + (dif[1,0]-mean_22p5)^2 + (dif[-1,0]-mean_22p5)^2 + (dif[-1,1]-mean_22p5)^2) / 4)^0.5"
r.mask -r

r.mask --o vector=buf_45
r.mapcalc --o "mean_45 = (dif[0,-1] + dif[1,-1] + dif[1,0] + dif[-1,0] + dif[-1,1] + dif[0,1]) / 6"
r.mapcalc --o "rough_45 = (((dif[0,-1]-mean_45)^2 + (dif[1,-1]-mean_45)^2 + (dif[1,0]-mean_45)^2 + (dif[-1,0]-mean_45)^2 + (dif[-1,1]-mean_45)^2 + (dif[0,1]-mean_45)^2) / 6)^0.5"
r.mask -r

r.mask --o vector=buf_67p5
r.mapcalc --o "mean_67p5 = (dif[0,-1] + dif[1,-1] + dif[-1,1] + dif[0,1]) / 4"
r.mapcalc --o "rough_67p5 = (((dif[0,-1]-mean_67p5)^2 + (dif[1,-1]-mean_67p5)^2 + (dif[-1,1]-mean_67p5)^2 + (dif[0,1]-mean_67p5)^2) / 4)^0.5"
r.mask -r

r.mask --o vector=buf_90
r.mapcalc --o "mean_90 = (dif[-1,-1] + dif[0,-1] + dif[1,-1] + dif[-1,1] + dif[0,1] + dif[1,1]) / 6"
r.mapcalc --o "rough_90 = (((dif[-1,-1]-mean_90)^2 + (dif[0,-1]-mean_90)^2 + (dif[1,-1]-mean_90)^2 + (dif[-1,1]-mean_90)^2 + (dif[0,1]-mean_90)^2 + (dif[1,1]-mean_90)^2) / 6)^0.5"
r.mask -r

r.mask --o vector=buf_112p5
r.mapcalc --o "mean_112p5 = (dif[-1,-1] + dif[0,-1] + dif[0,1] + dif[1,1]) / 4"
r.mapcalc --o "rough_112p5 = (((dif[-1,-1]-mean_112p5)^2 + (dif[0,-1]-mean_112p5)^2 + (dif[0,1]-mean_112p5)^2 + (dif[1,1]-mean_112p5)^2) / 4)^0.5"
r.mask -r

r.mask --o vector=buf_135
r.mapcalc --o "mean_135 = (dif[-1,0] + dif[-1,-1] + dif[0,-1] + dif[0,1] + dif[1,1] + dif[1,0]) / 6"
r.mapcalc --o "rough_135 = (((dif[-1,0]-mean_135)^2 + (dif[-1,-1]-mean_135)^2 + (dif[0,-1]-mean_135)^2 + (dif[0,1]-mean_135)^2 + (dif[1,1]-mean_135)^2 + (dif[1,0]-mean_135)^2) / 6)^0.5"
r.mask -r

r.mask --o vector=buf_157p5
r.mapcalc --o "mean_157p5 = (dif[-1,-1] + dif[-1,0] + dif[1,1] + dif[1,0]) / 4"
r.mapcalc --o "rough_157p5 = (((dif[-1,-1]-mean_157p5)^2 + (dif[-1,0]-mean_157p5)^2 + (dif[1,1]-mean_157p5)^2 + (dif[1,0]-mean_157p5)^2) / 4)^0.5"
r.mask -r

r.mask --o vector=buf_180
r.mapcalc --o "mean_180 = (dif[-1,-1] + dif[-1,0] + dif[-1,1] + dif[1,-1] + dif[1,0] + dif[1,1]) / 6"
r.mapcalc --o "rough_180 = (((dif[-1,-1]-mean_180)^2 + (dif[-1,0]-mean_180)^2 + (dif[-1,1]-mean_180)^2 + (dif[1,-1]-mean_180)^2 + (dif[1,0]-mean_180)^2 + (dif[1,1]-mean_180)^2) / 6)^0.5"
r.mask -r

r.mask --o vector=buf_202p5
r.mapcalc --o "mean_202p5 = (dif[-1,0] + dif[-1,1] + dif[1,-1] + dif[1,0]) / 4"
r.mapcalc --o "rough_202p5 = (((dif[-1,0]-mean_202p5)^2 + (dif[-1,1]-mean_202p5)^2 + (dif[1,-1]-mean_202p5)^2 + (dif[1,0]-mean_202p5)^2) / 4)^0.5"
r.mask -r

r.mask --o vector=buf_225
r.mapcalc --o "mean_225 = (dif[-1,0] + dif[-1,1] + dif[0,1] + dif[1,0] + dif[1,-1] + dif[0,-1]) / 6"
r.mapcalc --o "rough_225 = (((dif[-1,0]-mean_225)^2 + (dif[-1,1]-mean_225)^2 + (dif[0,1]-mean_225)^2 + (dif[1,0]-mean_225)^2 + (dif[1,-1]-mean_225)^2 + (dif[0,-1]-mean_225)^2) / 6)^0.5"
r.mask -r

r.mask --o vector=buf_247p5
r.mapcalc --o "mean_247p5 = (dif[-1,1] + dif[0,1] + dif[0,-1] + dif[1,-1]) / 4"
r.mapcalc --o "rough_247p5 = (((dif[-1,1]-mean_247p5)^2 + (dif[0,1]-mean_247p5)^2 + (dif[0,-1]-mean_247p5)^2 + (dif[1,-1]-mean_247p5)^2) / 4)^0.5"
r.mask -r

r.mask --o vector=buf_270
r.mapcalc --o "mean_270 = (dif[-1,1] + dif[0,1] + dif[1,1] + dif[-1,-1] + dif[0,-1] + dif[1,-1]) / 6"
r.mapcalc --o "rough_270 = (((dif[-1,1]-mean_270)^2 + (dif[0,1]-mean_270)^2 + (dif[1,1]-mean_270)^2 + (dif[-1,-1]-mean_270)^2 + (dif[0,-1]-mean_270)^2 + (dif[1,-1]-mean_270)^2) / 6)^0.5"
r.mask -r

r.mask --o vector=buf_292p5
r.mapcalc --o "mean_292p5 = (dif[1,1] + dif[0,1] + dif[0,-1] + dif[-1,-1]) / 4"
r.mapcalc --o "rough_292p5 = (((dif[1,1]-mean_292p5)^2 + (dif[0,1]-mean_292p5)^2 + (dif[0,-1]-mean_292p5)^2 + (dif[-1,-1]-mean_292p5)^2) / 4)^0.5"
r.mask -r

r.mask --o vector=buf_315
r.mapcalc --o "mean_315 = (dif[1,0] + dif[1,1] + dif[0,1] + dif[0,-1] + dif[-1,-1] + dif[-1,0]) / 6"
r.mapcalc --o "rough_315 = (((dif[1,0]-mean_315)^2 + (dif[1,1]-mean_315)^2 + (dif[0,1]-mean_315)^2 + (dif[0,-1]-mean_315)^2 + (dif[-1,-1]-mean_315)^2 + (dif[-1,0]-mean_315)^2) / 6)^0.5"
r.mask -r

r.mask --o vector=buf_337p5
r.mapcalc --o "mean_337p5 = (dif[1,0] + dif[1,1] + dif[-1,-1] + dif[-1,0]) / 4"
r.mapcalc --o "rough_337p5 = (((dif[1,0]-mean_337p5)^2 + (dif[1,1]-mean_337p5)^2 + (dif[-1,-1]-mean_337p5)^2 + (dif[-1,0]-mean_337p5)^2) / 4)^0.5"
r.mask -r

r.series --o input=rough_337p5,rough_67p5,rough_45,rough_22p5,rough_0 output=rough_tot method=average
r.out.gdal --o input=rough_tot     output="$working_directory"/dir_SD_res_top_3x3.tif    

#~ r.out.gdal --o input=rough_0     output="$working_directory"/rough_0.tif    
#~ r.out.gdal --o input=rough_22p5  output="$working_directory"/rough_22p5.tif 
#~ r.out.gdal --o input=rough_45    output="$working_directory"/rough_45.tif  
#~ r.out.gdal --o input=rough_67p5  output="$working_directory"/rough_67p5.tif 
#~ r.out.gdal --o input=rough_90    output="$working_directory"/rough_90.tif   
#~ r.out.gdal --o input=rough_112p5 output="$working_directory"/rough_112p5.tif
#~ r.out.gdal --o input=rough_135   output="$working_directory"/rough_135.tif  
#~ r.out.gdal --o input=rough_157p5 output="$working_directory"/rough_157p5.tif
#~ r.out.gdal --o input=rough_180   output="$working_directory"/rough_180.tif  
#~ r.out.gdal --o input=rough_202p5 output="$working_directory"/rough_202p5.tif
#~ r.out.gdal --o input=rough_225   output="$working_directory"/rough_225.tif  
#~ r.out.gdal --o input=rough_247p5 output="$working_directory"/rough_247p5.tif
#~ r.out.gdal --o input=rough_270   output="$working_directory"/rough_270.tif  
#~ r.out.gdal --o input=rough_292p5 output="$working_directory"/rough_292p5.tif
#~ r.out.gdal --o input=rough_315   output="$working_directory"/rough_315.tif  
#~ r.out.gdal --o input=rough_337p5 output="$working_directory"/rough_337p5.tif



