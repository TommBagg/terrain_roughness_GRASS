# Computing terrain roughness as TERRAIN RUGGEDNESS INDEX -> Riley, S.J., S.D. DeGloria and R. Elliot (1999)

# WINDOW SIZE EXPRESSED IN METERS

g.remove -f type=raster pattern="*" #remove all raster maps

# INPUT DATA
# set working directory path for output
working_directory="/home/tommaso/braema_roughness/results"
# set path to the input DSM
r.import -o --o input=/home/tommaso/braema_roughness/DSM_Braema_Duchli_20190617_10cm_AOI.tif output=DSM
# import mask to export the result maps
v.import -o --o input=/home/tommaso/braema_roughness/AOI.shp output=AOI

window_size="11" #set the window size

 
########################################################################

##ALGORITHM
g.region -s raster=DSM
r.tri input=DSM output=tri size="$window_size"
#normalization
min="`r.univar tri | grep minimum | sed -e s/.*:\ *//`"
max="`r.quantile input=tri percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
r.mapcalc --o "tri_N = (tri - "$min")/("$max" - "$min")"

res="`g.region -p | grep nsres | sed -e s/.*:\ *//`"
r.out.gdal --o -c -m input=tri output="$working_directory"/tri_"$window_size"x"$window_size"_"$res".tif
r.out.gdal --o -c -m input=area_ratio_mw_N output="$working_directory"/tri_normalized"$window_size"x"$window_size"_"$res".tif


#loop for different DSM resolutions
for res in  0.1 0.5 1
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
r.tri --o input=DSM output=tri size="$window_size"
r.mask vector=AOI
#normalization
min="`r.univar tri | grep minimum | sed -e s/.*:\ *//`"
max="`r.quantile input=tri percentiles=90 | grep 90 | sed -e s/.*:\ *//`"
r.mapcalc --o "tri_N = (tri - "$min")/("$max" - "$min")"

res="`g.region -p | grep nsres | sed -e s/.*:\ *//`"
r.out.gdal --o -c -m input=tri output="$working_directory"/tri_"$window_size_m"x"$window_size_m"_"$res"_WS_m.tif createopt="COMPRESS"
r.out.gdal --o -c -m input=tri_N output="$working_directory"/tri_normalized_"$window_size_m"x"$window_size_m"_"$res"_WS_m.tif createopt="COMPRESS"
r.mask -r
done
done





