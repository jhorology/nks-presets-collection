# nks-presets-collection
NKS(Native Kontrol Standard) presets collection

## Status
|          |raw presets|mappings|meta|resources|download|
|----------|:---------:|:---:|:-------:|:------:|:-------:|
|[Velvet](http://www.airmusictech.com/product/velvet-2)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/743wwd9c4ai936x/Velvet.zip?dl=0)|
|[Serum](https://xferrecords.com/products/serum)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/02jll4mjpl2iwjw/Serum.zip?dl=0)|
|[Spire](http://www.reveal-sound.com/)|:heavy_check_mark:||||||
|[Xpand!2](http://www.airmusictech.com/product/xpand2)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_exclamation_mark:1|[:arrow_down:](https://www.dropbox.com/s/gc4xpz9mo0adngu/Xpand%212.zip?dl=0)|
|[Hybrid](http://www.airmusictech.com/product/hybrid-3)|:heavy_check_mark:||||||
|[Loom](http://www.airmusictech.com/product/loom)|:heavy_check_mark:||||||
|[Vacuum Pro](http://www.airmusictech.com/product/vacuum-pro)|:heavy_check_mark:||||||
|[theRiser](http://www.airmusictech.com/product/the-riser)|:heavy_check_mark:||||||
|[DiscoveryPro](http://www.discodsp.com/discoverypro/)|:heavy_check_mark:||||||
|[BassStation](http://us.novationmusic.com/software/bass-station#)|:heavy_check_mark:||||||
|[V-Station](http://us.novationmusic.com/software/v-station#)|||||||
|[Alchemy](https://www.camelaudio.com)|||||||
|[Twin 2](http://www.fabfilter.com/products/twin-2-powerful-synthesizer-plug-in)|||||||
|[EightyEight](http://sonivoxmi.com/products/details/eighty-eight-ensemble-2)|||||||
|[Hive](https://www.u-he.com/cms/hive)|:heavy_check_mark:||||||
|[AnalogLab](http://www.arturia.com/products/analog-classics/analoglab)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/82ew1f0vc603bhb/Analog%20Lab.zip?dl=0)|

 1. Image files were not recognized, maybe the reason that plugin name contains '!'.

## Build Instructions

### Software Requirements
  - [git](https://help.github.com/articles/set-up-git/)
  - [nodejs](https://nodejs.org)

  I recommend to use [nvm](https://github.com/creationix/nvm).
    ```shellscript
    nvm install stable
    nvm use stable
    ```

  - [gulp](http://gulpjs.com/)
    ```shellscript
    npm install gulp-cli -g
    ```

### Cloning this repository
```shellscript
git clone https://github.com/jhorology/nks-presets-collection.git

# install dependencies
cd nks-presets-collection
npm install
```

### Configuration
Modify configuration section of `gulpfile.coffee` to suit your environment.

### Workflows

In case of Serum.
 - I want to use own mappings.
  1. Edit parameter mappings in Komplete Kontrol, and save preset as `_Default.nksf`.

  1. Execute following command to generate `src/Serum/mappings/default.json`
     ```shellscript
     gulp serum-generate-default-mapping
     ```
  1. Edit `src/Serum/mappings/default.json` whatever you want. (Optional)
    - Sorry, I can't say nothing about json format, because officially not opened. Following command may help you.
    ```shellscript
    gulp serum-print-default-mapping
    ```

  1. Execute following command to build and deploy presets to your environment.
     ```shellscript
     gulp serum-deploy-presets
     ```

- I want to categorize presets by own policy.

  1. Edit each `.meta` files in `src/Serum/presets` folder. It's a nightmare.

  1. Another option is modifying `serum-generate-meta` task of `gulpfile.coffee`.
    - Sorry again, I can't say nothing about meta format, because officially not opened. Following command may help you.
    ```shellscript
    gulp serum-print-default-meta
    ```
    For some more information, refer to [gulp-nks-rewrite-meta](https://www.npmjs.com/package/gulp-nks-rewrite-meta).
  1. Execute following command to generate meta files in `src/Serum/presets` folder.
     ```shellscript
     gulp serum-generate-meta
     ```

  1. Execute following command to build and deploy presets to your environment.
     ```shellscript
     gulp serum-deploy-presets
     ```

### How-to

- How to automate saving preset in Komplete Kontrol.
  - I'm using [Keybord Maestro](https://www.keyboardmaestro.com). Example macro files exits in `src/Velvet/macros` and `src/Serum/macros`.
  - Caution, executing macro without adjusting mouse positions is very danger.

- How to rip raw preset files.
  - from Komplete Kontrol `.nksf` file
    - Please see the example task `velvet-extract-raw-presets`.
  - from Ableton Live rack `.adg` file
    - Please see the example task `analoglab-extract-raw-presets`.
    - It may doesn't work on windows, because using shell script '[adg2pchk](https://github.com/jhorology/nks-presets-collection/blob/master/tools/adg2pchk)'.
  - from Bitwig Studio `.bwpreset` file
    - Please see the example task `xpand2-extract-raw-presets`.
    - It may doesn't work on windows, because using shell script '[bwpreset2pchk](https://github.com/jhorology/nks-presets-collection/blob/master/tools/bwpreset2pchk)'.

- How to auto generate meta information.
  - Many plugin vendor using [SQLite](https://www.sqlite.org/) databse for own plugin browser.  
  - Please see the example task `serum-generate-meta` and `analoglab-generate-meta`.

### What is NKSF File (Unofficial)
NKSF file is the only type of [RIFF](https://msdn.microsoft.com/en-us/library/windows/desktop/dd798636(v=vs.85).aspx) (Resource Interchange File Format). File has 4 chunks inside.
```
  - NISI  (Native Instruments Summury Information)
  - NICA  (Native Instruments Controller Assignments)
  - PLID  (Plugin ID)
  - PCHK  (Plugin Chunk)
 ```
*naming is my guess.

It seems that first 3 chunks are using same object encoding method. My solution '[nks-json](https://www.npmjs.com/package/nks-json)' can exchange bidirectional between JSON and chunk.

PCHK chunk is the only pluginstates.

## License

Raw preset data (*.pchk files) and some image files are not my property. I'm not a lawyer, but I think the use of these come under [fair-use](https://en.wikipedia.org/wiki/Fair_use).

Download files are completely free under your own responsibility if you trust and believe fair-use. And of course you must be a legal user of these VSTi plugins.

All other script codes are licensed under MIT.
