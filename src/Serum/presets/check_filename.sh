#!/bin/sh
#
IFS=$'\n'
SERUM_PRESETS='/Library/Audio/Presets/Xfer Records/Serum Presets/Presets'

cd `dirname $0`

cat /dev/null > fxp.tmp
cat /dev/null > pchk.tmp
for file in $(find ${SERUM_PRESETS} -type f -name "*.fxp")
do
   filename=${file##*/}
   filename_without_extension=${filename%.*}
   echo $filename_without_extension >> fxp.tmp
done
cat fxp.tmp | sort > fxp_sorted.tmp
for file in $(find "./" -type f -name "*.pchk")
do
   filename=${file##*/}
   filename_without_extension=${filename%.*}
   echo $filename_without_extension >> pchk.tmp
done
cat pchk.tmp | sort > pchk_sorted.tmp
diff -c pchk_sorted.tmp fxp_sorted.tmp
rm *.tmp
