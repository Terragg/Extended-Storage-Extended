# Extended Storage - now Extended! #
## About ##
------

Expands the options for storing stuff by providing Extended Storage-derived buildings in a new 'Storage' menu.

## Contents ##
------

There is a limit to Steam description readibility and size.  The breakdown or what building does what is availible online at:

   https://github.com/Terragg/Extended-Storage-Extended/blob/master/Docs/Contents.md

## Dependancies ##
------

Requires a working copy of Extended Storage:

   https://steamcommunity.com/sharedfiles/filedetails/?id=731732064

## Supports ##
------
### Combat Extended ###

Ammo storage in Pallets and Explosives Containers base on type.

Hat-tip: jinlan

## KNOWN ISSUES ##
------

### Overall: Must be loaded immediately after Extended Storage ###
------

There is an issue with some other mods that define a FurnitureBase abstract.  To prevent loss of functionality, make sure Extended Storage Exteneded is loaded <b>immediately</b> after Extended Storage.

### Meat Hooks: Visual glitch ###
------

The game will throw a "missing image" icon (the bright magenta X in a cell) once the corpses are moved onto the output stack (the part of the building that holds the biggest 'stack' of corpses). I know why it's doing this, but I can't address it yet.  I have not found any gameplay issues associated with it.  Once the last corpse is removed, the missing image icon disappears.  If this is unacceptable - don't build Meat Hooks.

### Meat Hooks: Disappearing corpses glitch ###
------

A patch to fix a semi-related issue in Extended Storage now allows corspes to be built in a 'bugged' state when splurged.  This bugged state is detected by the game and those corpses are immediately deleted.  There is only one current workaround, do not adjust Meat Hook filters while there are corpses stored - allow pawns to remove all corpses before adjusting filters.

### Weapons Racks: Only top weapon is right-click selectable ###
------

Unlike Extended Storage Clothes racks, there is no supporting code to 'Equip' any weapon other than the one on the 'top' of the stack in the container building.  The C# coding needed to implement is a bit beyond me at the moment, but I am making progress.

## Thanks to ##
------

scullywag, DrVanGogh, and others:  Making and maintaining Extended Storage
typesgal:  Stamper Font
Marnador:  Rimword Font

## Version ##
------

This is version 0.5.0.1 and is for RimWorld 1.0.2150.

## Non-Steam Release URL ##
------

   https://github.com/Terragg/Extended-Storage-Extended/releases/latest on Github.
