# Computing terrain roughness as standard deviation of the residual topography (grohnman 2011)
# WINDOW SIZE EXPRESSED IN METERS

g.remove -f type=raster pattern="*" #remove all raster maps

# INPUT DATA
# set working directory path for output
working_directory="/home/tommaso/braema_roughness/results"
# set path to the input DSM
r.import -o --o input=/home/tommaso/braema_roughness/DSM_Braema_Duchli_20190617_10cm_AOI.tif output=DSM
# import mask to export the result maps
v.import -o --o input=/home/tommaso/braema_roughness/AOI.shp output=AOI

window_size="3" #set the window size

#########
reference_window_size="11"
 
########################################################################

##ALGORITHM
g.region -s raster=DSM
r.neighbors input=DSM size="$window_size_reference" method=average output=reference_surface #create the referenze surface
r.mapcalc "difference = DSM - reference_surface"
r.neighbors input=difference size="$window_size_SD" method=stddev output=SD_res_top		#SD of the residual topography
normalization
min="`r.univar SD_res_top | grep minimum | sed -e s/.*:\ *//`"
max="`r.quantile input=SD_res_top percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
max="`r.univar SD_res_top | grep maximum | sed -e s/.*:\ *//`"
r.mapcalc --o "SD_res_top_N= (SD_res_top - "$min")/("$max" - "$min")"

r.out.gdal --o -c -m input=SD_res_top output="$working_directory"/SD_res_top_"$window_size_SD"x"$window_size_SD".tif
r.out.gdal --o -c -m input=SD_res_top_N output="$working_directory"/SD_res_top_normalized_"$window_size_SD"x"$window_size_SD".tif

# loop for different moving window size
res=1
for reference_window_size in 11
do
echo reference window size: "$reference_window_size"
# set manually the resolution according with the window size
g.region -p nsres="$res" ewres="$res" raster=DSM		
r.resamp.stats --o input=DSM output=DSM_res method=average 
r.neighbors --o input=DSM_res size="$reference_window_size" method=average output=reference_surface

# loop for different moving window size
for window_size_m in 3 5 7
do

window_size=$(echo "$window_size_m / $res" | bc )
((test=$window_size%2))
echo $test
b=0
if [ $test = $b ]; then
   ((window_size=$window_size+1))
   else
   echo $window_size
fi;

echo reference window size: "$reference_window_size"
echo window size: "$window_size"
echo resolution: "$res"
#reference surface smoothed
r.mapcalc --o "difference = DSM - reference_surface"
r.neighbors --o input=difference size="$window_size" method=stddev output=SD_res_top

r.mask vector=AOI
#normalization
min="`r.univar SD_res_top | grep minimum | sed -e s/.*:\ *//`"
max="`r.quantile input=SD_res_top percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
#max="`r.univar SD_res_top | grep maximum | sed -e s/.*:\ *//`"
r.mapcalc --o "SD_res_top_N= (SD_res_top - "$min")/("$max" - "$min")"

res="`g.region -p| grep nsres | sed -e s/.*:\ *//`"
r.out.gdal --o -c -m input=SD_res_top output="$working_directory"/SD_res_top_"$window_size_m"x"$window_size_m"_res_"$res"_WS_m.tif createopt="COMPRESS"
r.out.gdal --o -c -m input=SD_res_top_N output="$working_directory"/SD_res_top_normalized_"$window_size_m"x"$window_size_m"_res_"$res"_WS_m.tif createopt="COMPRESS"

r.mask -r
done
done












