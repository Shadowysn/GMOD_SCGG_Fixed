# GMOD_SCGG_Fixed
NOTICE:

With new features, comes new glitches. As I haven't really extensively tested it, the addon will have bugs. Make sure to report them either in my:

Steam discussion: https://steamcommunity.com/workshop/filedetails/discussion/550198171/1742229167180865559/

Workshop Addon: https://steamcommunity.com/sharedfiles/filedetails/?id=1641305846

Issues tab of this github. :P

Installation:

-

To 'Access the Steam Files':

Right-click on a game, select the 'Properties' tab, then click on the Local Files tab on the window that pops up.
It does not strictly need to be Garry's Mod.

Then, click on the 'Browse Local Files' button, and a File Explorer window should pop up.

-

Important: Make sure to disable the other Super Gravity Gun addon from the workshop before starting up a map.

Access the Steam Files, go to steamapps/common/GarrysMod/garrysmod, and put the files into the folder.

OR

Access the Steam Files, go to steamapps/common/GarrysMod/garrysmod/addons, and make a new folder called something like 'Super Gravity Gun'. Put the files into that created folder. 
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

[Another Github update drainage.]

Version 7.0
* Further fix of previous fix. Sorry.

* Fixed scgg_enabled 0 not removing the SCGG upon deploy.
* Added scgg_affect_players, a toggleable cvar for whether the SCGG should pick up and/or shoot players.
* Fixed a multiplayer bug where the SCGG would fail to pick up anymore objects after picking up the first object properly.
* Fixed bugs pertaining to dying whilst grabbing an object.
* Fixed the damage-on-collision callback still being active on a Manhack that survived the weapon's punts.
* Some minor bugfixes.

* The SCGG's max health for targets are now 225 in HL2 or 1000 in GMOD.
* Antlion Workers now explode (without errors) upon death instead of ragdolling from the SCGG.
* Picking up props now uses their World Space Center instead of their actual position, fixing problems such as barrels not properly situated in the middle of the screen.
* Ragdolls directly picked up via cursor/traces will now grab the bone that the player is looking at.
Indirect pickups (such as scgg_cone) will still pick them up in their 0th or 1st bone, usually their pelvis.
* Increased prop locking time to 2 seconds to prevent console props in the citadel getting released and killing the player after attempting to pick them up.
* Tidied up the code's checks for punting/grabbing.
* Added the punt/grab check to scgg_cone's detection, making cone detection more stable. Can't believe I didn't do this sooner...

* Decreased the punt/pull force of the HL2 style by a bit.

Version 8.0

Map functionality update! The following changes for the weapon strippers in Half-Life 2, Episode 1, or potentially any other map featuring them are:
* - Fixed grab functionality after gravity gun is dropped to the ground.
* - scgg_enabled will be set to 0 if a weapon dissolver is loaded, to try and prevent crashes.
* - Gravity gun now uses the addon's blue model instead of just a skin change. (could be subject to change)
* - Gravity gun now emits a charge particle effect whilst charging.

Previous features...
* Fixed a bug with grabbed props potentially getting glitched when the SCGG converts to normal. (scgg_enabled 0)
* Added W.I.P. discharge (convert-to-normal) effect for thirdperson.
* Fixed issues with detecting motion-disabled props, that should hopefully make cone detection finally stable enough for everyday use.
* Thrown Manhacks with the SCGG can now kill enemies in a direct hit.
* Fixed some repeat damage done on Manhacks.
* Removed Punt-available on crosshair and re-added Gatling Mode, and created a seperate cvar, scgg_primary_extra to toggle. Disabled by default, enable if you want to experience the SCGG on Episode 1.
* Updated spawnmenu settings.
* Performance update, dynamic claws now done client-side. Should no longer suck out performance server-wise.
