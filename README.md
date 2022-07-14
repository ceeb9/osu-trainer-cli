# osu-trainer-cli
Modify osu! beatmaps from the terminal with an interactive script.  
Requires root permissions for automatic map detection.

# usage
first, you will need to set your songs directory  
- open the perl script, and change `$songdir` to your songs directory  

then, you can use it as follows:
- open osu
- go to the map you want to modify (just leave it playing)
- run the perl script as root
- follow the prompts in the script

# dependencies
uses [gosumemory](https://github.com/l3lackShark/gosumemory) to read info from the game.  
uses [osu-beatmod](https://github.com/MasterIO02/osu-beatmod) to search the songs directory and create the modified beatmap.
