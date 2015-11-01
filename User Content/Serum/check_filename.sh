#!/bin/sh
#
IFS=$'\n'
SERUM_PRESETS='/Library/Audio/Presets/Xfer Records/Serum Presets/Presets'

cd `dirname $0`

cat /dev/null > fxp.tmp
cat /dev/null > bwpreset.tmp
for file in $(find ${SERUM_PRESETS} -type f -name "*.fxp")
do
   filename=${file##*/}
   filename_without_extension=${filename%.*}
   echo $filename_without_extension >> fxp.tmp
done
cat fxp.tmp | sort > fxp_sorted.tmp
for file in $(find "./" -type f -name "*.nksf")
do
   filename=${file##*/}
   filename_without_extension=${filename%.*}
   echo $filename_without_extension >> bwpreset.tmp
done
cat bwpreset.tmp | sort > bwpreset_sorted.tmp
diff -c bwpreset_sorted.tmp fxp_sorted.tmp
rm *.tmp
