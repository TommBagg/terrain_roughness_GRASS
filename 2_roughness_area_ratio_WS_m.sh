# Computing terrain roughness as AREA RATIO (ratio between horizontal and slope area)
# WINDOW SIZE EXPRESSED IN METERS

g.remove -f type=raster pattern="*" #remove all raster maps

# INPUT DATA
# set working directory path for output
working_directory="/home/tommaso/braema_roughness/results"
# set path to the input DSM
r.import -o --o input=/home/tommaso/braema_roughness/DSM_Braema_Duchli_20190617_10cm_AOI.tif output=DSM
# import mask to export the result maps
v.import -o --o input=/home/tommaso/braema_roughness/AOI.shp output=AOI

window_size="5" #set the window size

 
########################################################################

##ALGORITHM
g.region -s raster=DSM
res="`g.region -p | grep nsres | sed -e s/.*:\ *//`"
r.slope.aspect --o elevation=DSM slope=slope
r.mapcalc --o "area_ratio = ((("$res"/cos(slope)) * "$res") / (exp("$res",2)))"
r.neighbors --o input=area_ratio method=average output=area_ratio_mw size="$window_size"
#normalization
min="`r.univar area_ratio_mw | grep minimum | sed -e s/.*:\ *//`"
max="`r.quantile input=area_ratio_mw percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
r.mapcalc --o "area_ratio_mw_N = (area_ratio_mw - "$min")/("$max" - "$min")"

r.out.gdal --o -c -m input=area_ratio_mw output="$working_directory"/area_ratio_"$window_size"x"$window_size"_"$res".tif
r.out.gdal --o -c -m input=area_ratio_mw_N output="$working_directory"/area_ratio__normalized_"$window_size"x"$window_size"_"$res".tif


#loop for different DSM resolutions
for res in  0.1 0.5 1
do 
g.region -p nsres="$res" ew="$res" raster=DSM
r.resamp.stats --o input=DSM output=DSM_res method=average 
r.slope.aspect --o elevation=DSM_res slope=slope

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
res="`g.region -p | grep nsres | sed -e s/.*:\ *//`"
r.mapcalc --o "area_ratio = ((("$res"/cos(slope)) * "$res") / (exp("$res",2)))"
r.neighbors --o input=area_ratio method=average output=area_ratio_mw size="$window_size"
#normalization
r.mask vector=AOI
min="`r.univar area_ratio_mw | grep minimum | sed -e s/.*:\ *//`"
max="`r.quantile input=area_ratio_mw percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
r.mapcalc --o "area_ratio_mw_N = (area_ratio_mw - "$min")/("$max" - "$min")"

r.out.gdal --o -c -m input=area_ratio_mw output="$working_directory"/area_ratio_"$window_size_m"x"$window_size_m"_res_"$res"_WS_m.tif createopt="COMPRESS"
r.out.gdal --o -c -m input=area_ratio_mw_N output="$working_directory"/area_ratio_normalized_"$window_size_m"x"$window_size_m"_res_"$res"_WS_m.tif createopt="COMPRESS"
r.mask -r
done
done





