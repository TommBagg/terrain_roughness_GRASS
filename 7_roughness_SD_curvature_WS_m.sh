# Computing terrain roughness as standard deviation of the profile curvature (grohnman 2011)
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


########################################################################

# ALGORITHM
g.region -s raster=DSM
r.slope.aspect --o elevation=DSM pcurvature=pcurvature
r.neighbors input=pcurvature size="$window_size" method=stddev output=SD_pcurvature #create the referenze surface
#normalization max=90th percentile
min="`r.univar SD_pcurvature | grep minimum | sed -e s/.*:\ *//`"
#max="`r.univar SD_pcurvature | grep maximum | sed -e s/.*:\ *//`"
max="`r.quantile input=SD_pcurvature percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
r.mapcalc --o "SD_pcurvature_N= (SD_pcurvature - "$min")/("$max" - "$min")"

r.out.gdal --o -c -m input=SD_pcurvature output="$working_directory"/SD_pcurvature_"$window_size"x"$window_size".tif
r.out.gdal --o -c -m input=SD_pcurvature_N output="$working_directory"/SD_pcurvature_normalized_"$window_size"x"$window_size".tif

#loop for different DSM resolutions
for res in 0.1 0.5 1
do 
g.region -p nsres="$res" ew="$res" raster=DSM
r.resamp.stats --o input=DSM output=DSM_res method=average 

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

echo window size: "$window_size"
r.slope.aspect --o elevation=DSM_res pcurvature=pcurvature
r.neighbors --o input=pcurvature size="$window_size" method=stddev output=SD_pcurvature

r.mask vector=AOI
#normalization max=90th percentile
min="`r.univar SD_pcurvature | grep minimum | sed -e s/.*:\ *//`"
#max="`r.univar SD_pcurvature | grep maximum | sed -e s/.*:\ *//`"
max="`r.quantile input=SD_pcurvature percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
r.mapcalc --o "SD_pcurvature_N= (SD_pcurvature - "$min")/("$max" - "$min")"

res="`g.region -p| grep nsres | sed -e s/.*:\ *//`"
r.out.gdal --o -c -m input=SD_pcurvature output="$working_directory"/SD_pcurvature_"$window_size_m"x"$window_size_m"_res_"$res"_WS_m.tif createopt="COMPRESS"
r.out.gdal --o -c -m input=SD_pcurvature_N output="$working_directory"/SD_pcurvature_normalized_"$window_size_m"x"$window_size_m"_res_"$res"_WS_m.tif createopt="COMPRESS"

r.mask -r
done
done

