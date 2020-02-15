# GMOD_SCGG_Fixed
NOTICE:

With new features, comes new glitches. As I haven't really extensively tested it, the addon will have bugs. Make sure to report them either in my:

Steam discussion: https://steamcommunity.com/workshop/filedetails/discussion/550198171/1742229167180865559/

Workshop Addon: https://steamcommunity.com/sharedfiles/filedetails/?id=1641305846

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
* Primary attack is now better! (Previously, it took an agonizing 5 seconds if you missed.
In a nutshell, it means the dryfiring anim makes it look like attacking takes 5 secs, but the actual time is shorter.)
* Effects fixed! No more lua errors when switching from a camera to firstperson. (Still relies on entities, so it'll glitch in mirrors.)

Version 2.3+Workshop Release:
* Toggleable cone detection, however it is still W.I.P. and is not recommended to use if you want stability.
* Minor adjustments to the glowing effects.

Version 2.4
* Primary delay removed as soon as a valid object enters your crosshair.

[Github updating had stopped at this point, workshop version was focused on more.]

Version 5.0
* Fixed antlion workers on EP2 maps glitching out when using the weapon on them.
* Fixed a bug where grabbed entities stay stuck in the air when a player dies holding it with the weapon.
* Temp fix of certain frozen props on HL2 maps not being able to be picked up by the SWEP. (This will also affect props frozen by physgun)
* Edited SWEP to not be weaker than normal gravity gun in certain situations. (mostly)
* Fixed a bug that prevented punting.
* Fixed scgg_enabled being unable to be set to 1 unless scgg_allow_enablecvar_modify is inactive.
* Added two experimental client console variables: cl_scgg_viewmodel and cl_scgg_physgun_color.
* Fixed a bug where armor values would recede into negatives when the armor drained.
* Updated scgg_cone detection, it should no longer grab objects through walls. However, it is still far from finished.
* Made dissolving effects use a single but consistent env_entity_dissolver rather than spawning one for every single item that needed dissolving.
* Merged glow and muzzle entities to the main core effect entity. Originally they were all seperate entities. 
* Viewmodel will now change by itself when cl_scgg_viewmodel is modified.
* Fixed a bug with worldmodel effects caused by accidentally using the viewmodel's attachments in thirdperson, due to confusion with the code by the original creator.
* Muzzle effect no longer handled in serverside.
* Fixed effects for incompatible viewmodels so stray sprites will no longer be floating in the last position they were.

Version 5.5
* Fixed convars not initializing, which in turn broke the whole weapon.
* Pickup system now similar to the OG gravity gun! Pulls objects constantly towards you if they're out of range.
* Added new convar scgg_deploy_style, for legacy attributes to scgg_style.

Version 5.6
* Combine balls now bounce out in a random direction instead of staying still.
