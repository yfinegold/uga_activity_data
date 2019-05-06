cd ~/downloads/uganda_tiled_150_200_L8_2013_2019_NDMI;

for file in */results/tile*/bfast*.tif;
  do tile=`echo $file | cut -d'/' -f1`;
  cp -v $file $tile\_${file##*/};
done
