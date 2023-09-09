# [TF2+SourceTV] Fix UTIL functions for listen servers

A number of console commands and VScript functions do not work on listen servers when `tv_enable` is set to 1 and the SourceTV bot is in the server. This is due to the game's assumption that the listen server host's entity index will *always* be 1. In reality, if SourceTV is enabled, the bot will have entity index 1 and the player 2.

This plugin detours two internal game functions to fix this:
 1. **UTIL_GetListenServerHost**
	- Fixes VScript global functions `SendToConsole()` and `GetListenServerHost()`
	- Fixes `ent_fire` console command not working
	- Fixes other miscellaneous console commands such as `soundscape_flush` 
 3. **UTIL_IsCommandIssuedByServerAdmin**
	- Fixes all VScript-related console commands (e.g. `script`, `script_execute`, `script_help`)
	- Fixes bot console commands (e.g. `tf_bot_add`, `tf_bot_kick`, `tf_bot_kill`)
	- Fixes other miscellaneous console commands such as `ent_cancelpendingentfires` or `dumpeventqueue`

## Installation

 1. Make sure you have [Metamod:Source](https://www.sourcemm.net/downloads.php?branch=stable) and [SourceMod 1.11 or above](https://www.sourcemod.net/downloads.php?branch=stable) installed
 2. [Download the plugin](https://github.com/kstf2/stv-listen-server-fix/archive/refs/heads/main.zip) and drag `plugins/`, `gamedata/` and `scripting/` folders into your `Team Fortress 2/tf/addons/sourcemod` folder
 3. Launch the game in `-insecure` mode and start a listen server with `map <mapname>`

You can disable the plugin detours by setting the ConVar `sm_listenserver_util_fix` to 0.  Setting it to 1 will enable the detours again (and is the default value).