# nks-presets-collection
NKS(Native Kontrol Standard) presets collection

## Status

18100/26084(69%)

|          |raw presets|mappings|meta|resources|download|last update|
|----------|:---------:|:------:|:--:|:-------:|:------:|:---------:|
|[Velvet](http://www.airmusictech.com/product/velvet-2)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/743wwd9c4ai936x/Velvet.zip?dl=0)|Nov 12, 2015|
|[Serum](https://xferrecords.com/products/serum)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/02jll4mjpl2iwjw/Serum.zip?dl=0)|Nov 4, 2015|
|[Spire 1.0.x](http://www.reveal-sound.com/)|:heavy_check_mark:|:heavy_check_mark:2|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/yqm4bqbmj1n88cs/Spire.zip?dl=0)|Nov 16, 2015|
|[Spire 1.1.x](http://www.reveal-sound.com/)|:heavy_check_mark:|:heavy_check_mark:2|:heavy_check_mark:|:heavy_check_mark:1|[:arrow_down:](https://www.dropbox.com/s/eq371tcj8rdjhhb/Spire-1.1.zip?dl=0)|Aug 10, 2016|
|[Xpand!2](http://www.airmusictech.com/product/xpand2)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:1|[:arrow_down:](https://www.dropbox.com/s/gc4xpz9mo0adngu/Xpand%212.zip?dl=0)|Nov 28, 2015|
|[Hybrid](http://www.airmusictech.com/product/hybrid-3)|:heavy_check_mark:||:heavy_check_mark:||||
|[Loom](http://www.airmusictech.com/product/loom)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/5a486tgstdqo8kh/Loom.zip?dl=0)|Nov 30, 2015|
|[Vacuum Pro](http://www.airmusictech.com/product/vacuum-pro)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/k9itodzfl6kn0ij/VacuumPro.zip?dl=0)|Nov 30, 2015|
|[theRiser](http://www.airmusictech.com/product/the-riser)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/j02hreqw1ykg3ac/theRiser.zip?dl=0)|Nov 30, 2015|
|[Strike](http://www.airmusictech.com/product/strike-2)|:heavy_check_mark:||:heavy_check_mark:||||
|[Structure](http://www.airmusictech.com/product/structure-2)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/wpz2z8pbwv2r714/Structure.zip?dl=0)|Nov 28, 2015|
|[BassStation](http://us.novationmusic.com/software/bass-station#)|:heavy_check_mark:||:heavy_check_mark:||||
|[V-Station](http://us.novationmusic.com/software/v-station#)|:heavy_check_mark:||:heavy_check_mark:||||
|[Alchemy](https://www.camelaudio.com)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/2u6547fsvl7yrz2/Alchemy.zip?dl=0)|Nov 21, 2015|
|[Twin 2](http://www.fabfilter.com/products/twin-2-powerful-synthesizer-plug-in)|:heavy_check_mark:||||||
|[EightyEight](http://sonivoxmi.com/products/details/eighty-eight-ensemble-2)|:heavy_check_mark:|:heavy_check_mark:|||||
|[Hive](https://www.u-he.com/cms/hive)|:heavy_check_mark:||||||
|[AnalogLab](http://www.arturia.com/products/analog-classics/analoglab)|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|[:arrow_down:](https://www.dropbox.com/s/82ew1f0vc603bhb/Analog%20Lab.zip?dl=0)|Nov 9, 2015|
|[AnalogLab 2](https://www.arturia.com/products/analog-classics/analoglab)|:heavy_check_mark:||:heavy_check_mark:||||

 1. Plugin name(root of bankchain) were changed from original name, beacuse resource folder name can not contain some characters.
 2. Contributed from Kymeia@NI Forum.

## Build Instructions

### Software Requirements
  - [git](https://help.github.com/articles/set-up-git/)
  - [nodejs](https://nodejs.org)

  I recommend to use [nvm](https://github.com/creationix/nvm).
    ```shellscript
    nvm install v5.11.1
    nvm use v5.11.1
    ```
    *Some tasks will may not work on node v6.x.x due to dep issue. Please use node v5.x.x

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
    - For some more information, refer to [gulp-riff-extractor](https://www.npmjs.com/package/gulp-riff-extractor).
  - from Ableton Live rack `.adg` file
    - Please see the example task `analoglab-extract-raw-presets`.
    - It doesn't work on windows, because using shell script '[adg2pchk](https://github.com/jhorology/nks-presets-collection/blob/master/tools/adg2pchk)'.
  - from Bitwig Studio `.bwpreset` file
    - Please see the example task `xpand2-extract-raw-presets`.
    - It doesn't work on windows, because using shell script '[bwpreset2pchk](https://github.com/jhorology/nks-presets-collection/blob/master/tools/bwpreset2pchk)'.

- How to auto generate meta information.
  - Many plugin vendors uses [SQLite](https://www.sqlite.org/) database for own plugin browser.  
  - Please see the example task `serum-generate-meta` and `analoglab-generate-meta`.

### What is NKSF File (Unofficial)
NKSF file is the only type of [RIFF](https://msdn.microsoft.com/en-us/library/windows/desktop/dd798636(v=vs.85).aspx) (Resource Interchange File Format). File has 4 chunks inside.
```
  - NISI  (Native Instruments Summary Information)
  - NICA  (Native Instruments Controller Assignments)
  - PLID  (Plugin ID)
  - PCHK  (Plugin Chunk)
 ```
*naming is my guess.

It seems that first 3 chunks are encoded using [MessagePack](http://msgpack.org). PCHK chunk is the only pluginstates.

## License

Raw preset data (*.pchk files) and some image files are not my property. I'm not a lawyer, but I think the use of these come under [fair-use](https://en.wikipedia.org/wiki/Fair_use).

Download files are completely free under your own responsibility if you trust and believe fair-use. And of course you must be a legal user of these VSTi plugins.

All other script codes are licensed under MIT.
