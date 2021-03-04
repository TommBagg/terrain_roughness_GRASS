# Computing terrain roughness as VECTOR DISPERSION (grohnman 2011)
# WINDOW SIZE EXPRESSED IN METERS

# COPY AND PASTE THE SCRIPT IN THE TERMINAL

g.remove -f type=raster pattern="*" #remove all raster maps

# INPUT DATA
# set working directory path for output
working_directory="/home/tommaso/braema_roughness/results"
# set path to the input DSM
r.import -o --o input=/home/tommaso/braema_roughness/DSM_Braema_Duchli_20190617_10cm_AOI.tif output=DSM
# import mask to export the result maps
v.import -o --o input=/home/tommaso/braema_roughness/AOI.shp output=AOI

window_size="3" #set the window size
 
#########################################################################

# ALGORITHM
g.region -s raster=DSM
#calculate slope and aspect
r.slope.aspect --o elevation=DSM slope=slope aspect=aspect
r.roughness.vector --o elevation=DSM slope=slope aspect=aspect window="$window_size" strength=strength fisher=fisher

#normalization of the fisher map
min="`r.univar fisher | grep minimum | sed -e s/.*:\ *//`"
#max="`r.univar fisher | grep maximum | sed -e s/.*:\ *//`"
max="`r.quantile input=fisher percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
r.mapcalc --o "fisher_N= (fisher - "$min")/("$max" - "$min")"

#r.out.gdal --o -c -m input=strength output="$working_directory"/strength"$window_size"x"$window_size".tif
#r.out.gdal --o -c -m input=fisher output="$working_directory"/fisher"$window_size"x"$window_size".tif
r.out.gdal --o -c -m input=fisher_N output="$working_directory"/vector_dispersion_normalized_"$window_size"x"$window_size".tif


#loop for different DSM resolutions
for res in 0.1 0.5 1
do 
g.region nsres="$res" ew="$res" raster=DSM
r.resamp.stats --o input=DSM output=DSM_res method=average 
g.region -p

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
r.slope.aspect --o elevation=DSM_res slope=slope aspect=aspect
r.roughness.vector --o elevation=DSM_res slope=slope aspect=aspect window="$window_size" strength=strength fisher=fisher

r.mask vector=AOI

#normalization of the fisher map
min="`r.univar fisher | grep minimum | sed -e s/.*:\ *//`"
#max="`r.univar fisher | grep maximum | sed -e s/.*:\ *//`"
max="`r.quantile input=fisher percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
r.mapcalc --o "fisher_N= (fisher - "$min")/("$max" - "$min")"

#~ res="`g.region -p| grep nsres | sed -e s/.*:\ *//`"
#r.out.gdal --o -c -m input=strength output="$working_directory"/strength"$window_size"x"$window_size"_"$res".tif
r.out.gdal --o -c -m input=fisher output="$working_directory"/vector_dispersion_k_"$window_size_m"x"$window_size_m"_res_"$res"_WS_m.tif createopt="COMPRESS"
r.out.gdal --o -c -m input=fisher_N output="$working_directory"/vector_dispersion_k_norm_"$window_size_m"x"$window_size_m"_res_"$res"_WS_m.tif createopt="COMPRESS"

r.mask -r
done
done

