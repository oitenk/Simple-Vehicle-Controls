# Changelog

## 0.1 (testing)

- First version: a hotkey panel (Numpad 5) with a clickable top-down car for the engine, doors, hood and trunk, plus buttons for the front windows.
- An engine switched off here stays off if something else turns it back on, until it is switched on here. Can be turned off in Mod Settings ("Keep the engine off").
- A running engine is started again if it stops when you get out (setting: "Keep the engine running when you get out").
- Saved with the game: engines held off and windows put down are remembered by vehicle model across loads (windows are put back down when you get in).
- A small API for other mods (SVCApi and SVCListener) to read and set the engine hold and the front windows, and to hear when they change.
- Quiet start-up: getting into a car whose engine is held off blanks that model's engine start sound until you get out or switch the engine on (setting: "Quiet start-up when held off"). Works on any model, stock or modded, that the game lists in its vehicle audio.
- Optional hotkeys, none bound by default, for the engine, both doors, both windows (down and up separately), hood and trunk.
