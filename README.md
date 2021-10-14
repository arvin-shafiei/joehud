# Joe HUD (HUD, Seatbelt & Speedlimiter)

Joe HUD (HUD, Seatbelt & Speedlimiter) - This is my first project & all feedback would be greatly appreciated - A HUD inspired by Cosmo_HUD & Nopixel 3.0 For FiveM (ESX)

## Installation

1. Download JoeHUD

2. Put 'joehud' into your ‘resources’ folder.

3. Start in servercfg.

Do not change the name or most parts will not function.*

## Features

• HUD elements toggled in /hud are saved to the users cache, meaning you don’t need to turn every element on and off each time you load into the server.

• Seatbelt System & Speed limiter with mappable keybinds

• 0.01ms - 0.5ms (If you have suggestions to reduce this please comment them)

• Circle Map & Streamed minimap/bigmap

• Change how often speedomoter updates in /hud to reduce or increase depending on PC

• Server sided commands / functions

# Voice Detection
For pma-voice compatibility, you need to add the code below in `pma-voice/client/main` on line 193

For mumble-voip compatibility, you need to add the code the code below to line ``mumble-voip/client.lua`` line 803

`exports['joehud']:Voicelevel(voiceMode)`

(Images of where the lines should go have been put on the fourm post)

## Requirements

• es_extended

• esx_basicneeds

## Usage
• /hud - Opens HUD menu to enable/disable elements of the HUD (Prefrences saved to cache).

• Seatbelt - Default Key [B] - Can be changed in FiveM settings

• Speedlimiter- Default Key [CAPSLOCK] - Can be changed in FiveM settings

• /Seatbelt & /Speedlimiter

## Big thanks to
https://forum.cfx.re/u/cosmokramer/ for snippets & inital inspiration.

https://forum.cfx.re/u/Antoine for the colored map.

https://loading.io/progress/ for the loading-Bar library.

## License
[MIT](https://choosealicense.com/licenses/mit/)
