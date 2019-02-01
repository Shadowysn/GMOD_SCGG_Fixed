# GMOD_SCGG_Fixed
NOTICE:

With new features, comes new glitches. As I haven't really extensively tested it, the addon will have bugs. Make sure to report them either in my:

Steam discussion: https://steamcommunity.com/workshop/filedetails/discussion/550198171/1742229167180865559/

Issues tab of this github. :P

Installation:

Access the Steam Files, go to steamapps/common/GarrysMod/garrysmod, and put the files into the folder. 
Make sure to disable the other Super Gravity Gun addon from the workshop before starting up a map.

OR

Access the Steam Files, go to steamapps/common/GarrysMod/garrysmod/addons, and make a new folder that is called something like 'Super Gravity Gun'. Put the files into that created folder. 
This method is more neater, but will require a restart if you've gotten your game open before the files were placed.

Update Log from version 1 onwards:

{List may or may not be accurate.}

Version 1:
* Effects mostly fixed.
* Now able to pick up combine balls.
* Moar commands:

==
* Allow ability to interact with entities, such as those from other addons.
* Enability. Downgrading works properly in HL2:EP1's Direct Intervention.
* Equipping Sound.
* NPC Friendly Fire Enable/Disable.
* Armor fading.
* World-wide dropped weapon vaporization.
* Enable/disable sounds from electrocuted ragdolls.
* HL2 style updated to feature range limitations.

==

* No more insta-killing things with higher-than-125 health. Instead it damages them for 125 health.
* Pick up weapons! :)
* Weapon will use the entity for it's dropped state. Glow effects!
* Collision group will be stored. (In a nutshell, it means that a non-collidable barrel will still be non collidable after dropping.)
* Able to kill manhacks by punting them into a wall now.
* Gravity gun pickup simulation. (Combine mines will now be friendly after you drop them, etc.)
* Proper deaths for NPCs and Players.

Version 1.1:

* Electrocution effects on more than 1 ragdoll at a time! (Previously, a new ragdoll's effects will have overridden the previous ragdoll's effects)
* Few minor changes.

Version 1.8:
* Proper claw animations! Closed, open or dynamic state. Applies to both viewmodel and worldmodel. (As with all new features, it may be buggy.)
* Debris ragdolls/props can now be picked up. Previously they could not be detected.

Version 2:
* Primary attack is now better! (Previously, it took an agonizing 5 seconds if you missed, whilst in the actual HL2 you could shoot earlier than that, with the dry firing animation taking it's own time. 
In a nutshell, it means the dryfiring anim makes it look like attacking takes 5 secs, but the actual time is shorter.)
* Effects fixed! No more lua errors when switching from a camera to firstperson. (Still relies on entities, so it'll glitch in mirrors.)

Version 2.3+Workshop Release:
* Toggleable cone detection, however it is still W.I.P. and is not recommended to use if you want stability.
* Minor adjustments to the glowing effects.
