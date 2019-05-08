cd $1

for file in */results/tile*/bfast*.tif;
  do tile=`echo $file | cut -d'/' -f1`;
  cp -v $file $tile\_${file##*/};
done