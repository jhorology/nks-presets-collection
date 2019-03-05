#!/bin/sh
KORG_PLUGINS="/Library/Audio/Plug-Ins/VST/KORG"
IFS=$'\n'

cd `dirname "$0"`
for file in $(find ${KORG_PLUGINS} -name "*.vst" -type d)
do
    fileName=${file##*/}
    pluginName=${fileName%.*}
    echo $pluginName
    mrswatson --display-info --plugin-root ${KORG_PLUGINS} -p ${pluginName} 2>&1 | col -bx > ${pluginName}-mrswatson.txt
done
