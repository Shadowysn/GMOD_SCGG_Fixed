if CLIENT then return end

util.AddNetworkString("SCGG_Ragdoll_GetPlayerColor")
util.AddNetworkString("SCGG_Core_Muzzle")
util.AddNetworkString("SCGG_Charging_Particles")

local phys_string = "weapon_physcannon"
local superphys_string = "weapon_superphyscannon"

local function DissolveEntity(entity) -- The main dissolve function for dissolving things.
	local hasdissolve = nil
	for _,dissolver in pairs(ents.FindByName("scgg_addon_global_dissolver")) do -- We check if the dissolver exists.
		if dissolver:GetClass() == "env_entity_dissolver" then
			dissolver:Fire("Dissolve", "", 0, entity) -- If it exists, have it dissolve our given entity
			hasdissolve = true -- and set this to true...
			break
		end
	end
	
	if hasdissolve != true then -- ...otherwise we spawn one.
		local dissolver = ents.Create("env_entity_dissolver")
		dissolver:SetPos(Vector(0,0,0))
		dissolver:SetKeyValue( "target", "!activator" ) -- This makes the activator the target so we don't have to rename targeted entities.
		dissolver:SetKeyValue( "dissolvetype", 0 )
		dissolver:SetName("scgg_addon_global_dissolver")
		dissolver:Spawn()
		dissolver:Activate()
		dissolver:Fire("Dissolve", "", 0, entity) -- Have the new one dissolve our given entity.
	end
end

local function GlobalDissolve()
	for _,wpn in ipairs(ents.GetAll()) do
		wpn.SCGG_Dissolving = false -- Dissolve check.
			if IsValid(wpn) and wpn:IsValid() and ( wpn:IsWeapon() or wpn:GetClass() == "item_ammo_ar2_altfire" ) and !wpn:CreatedByMap() and 
			(wpn:GetClass() != phys_string and wpn:GetClass() != superphys_string) then
			-- ^ Valid check start
				for _, child in ipairs(wpn:GetChildren()) do
					if child:GetClass() == "env_entity_dissolver" then
						wpn.SCGG_Dissolving = true
						-- ^ Mark them as dissolving so we don't repeatedly try to dissolve an already vaporizing gun.
						break
					end
				end
				
				if ConVarExists("scgg_enabled") and GetConVar("scgg_enabled"):GetInt() >= 2 and 
				wpn:GetClass() == "item_ammo_ar2_altfire" then 
					-- ^ Check for scgg_enabled cvar num to be 2 and target being AR2 pulse ball ammo.
					
					local fakeitem = ents.Create("prop_physics_override") 
					-- ^ Replace AR2 pulse ball ammo with fake props, as they will still be picked up when vaporizing.
					fakeitem:SetPos( wpn:GetPos() )
					fakeitem:SetAngles( wpn:GetAngles() )
					fakeitem:SetModel( wpn:GetModel() )
					fakeitem:SetSkin( wpn:GetSkin() )
					fakeitem:SetColor( wpn:GetColor() )
					fakeitem:SetCollisionGroup( COLLISION_GROUP_WEAPON )
					fakeitem:Spawn()
					fakeitem:Activate()
					undo.ReplaceEntity( wpn, fakeitem )
					wpn:Remove()
					
					DissolveEntity(fakeitem)
				elseif !wpn:GetOwner():IsValid() and wpn.SCGG_Dissolving == false then 
					-- ^ Check if it's not in the hands of an NPC or Player, and not being dissolved.
					wpn:SetKeyValue("spawnflags", "2")
					DissolveEntity(wpn)
					-- ^ This is to prevent still picking up the weapons by pressing USE on them.
				end 
				-- ^ Dissolve end.
			end 
			-- ^ Valid check end
		--[[if IsValid(wpn) and wpn:IsWeapon() and !wpn:GetOwner():IsValid() and wpn.SCGG_Dissolving == false then
		wpn:SetKeyValue("spawnflags","0")
		-- ^ I don't know what I was trying to do with this.
		end--]]
	end
end

if !ConVarExists("scgg_style") then//
   CreateConVar("scgg_style", '0', (FCVAR_ARCHIVE), "to change if the weapon is styled like Half-Life 2 or Garry's Mod.", 0, 1)
end--1

if !ConVarExists("scgg_light") then//
   CreateConVar("scgg_light", '0', (FCVAR_ARCHIVE), "to change if the weapon emits a light.", 0, 1)
end--2

if !ConVarExists("scgg_muzzle_flash") then//
   CreateConVar("scgg_muzzle_flash", '1', (FCVAR_ARCHIVE), "to change if the weapon emits a light when attacking.", 0, 1)
end--3

if !ConVarExists("scgg_zap") then//
   CreateConVar("scgg_zap", '1', (FCVAR_ARCHIVE), "to toggle victims being electrocuted.", 0, 1)
end--4

if !ConVarExists("scgg_allow_others") then//
   CreateConVar("scgg_allow_others", '0', (FCVAR_ARCHIVE), 
   "to allow weapon interaction of other objects, including addons. (WILL have a chance to cause bugs.)", 
   0, 1)
end--5

if !ConVarExists("scgg_zap_sound") then//
   CreateConVar("scgg_zap_sound", '1', (FCVAR_ARCHIVE), "to toggle electrocuted victims emitting sound.", 0, 1)
end--6

if !ConVarExists("scgg_equip_sound") then//
   CreateConVar("scgg_equip_sound", '0', (FCVAR_ARCHIVE), "to toggle sound emitted when deploying weapon.", 0, 1)
end--7

if !ConVarExists("scgg_no_effects") then//
   CreateConVar("scgg_no_effects", '0', (FCVAR_ARCHIVE), "to toggle visual effects.", 0, 1)
end--8

if !ConVarExists("scgg_enabled") then//
   CreateConVar("scgg_enabled", '1', (FCVAR_ARCHIVE), 
   "to toggle weapon availability. 0 = any super-charged gravity gun will revert to normal. 1 = Enable, don't do anything else. 2 = Enable, alter various settings.", 
   0, 2)
end--9

if !ConVarExists("scgg_extra_function") then//
   CreateConVar("scgg_extra_function", '1', (FCVAR_ARCHIVE), 
   "to toggle whether the mods extra functionality is enabled or not. (Stuff like giving the mod SCGG if scgg_enabled is 2, etc.) Added due to the August 2020 update, which re-added the actual Super Gravity Gun.", 
   0, 1)
end--10

if !ConVarExists("scgg_vanilla_disable") then//
   CreateConVar("scgg_vanilla_disable", '1', (FCVAR_ARCHIVE), 
   "to toggle whether the vanilla Super Gravity Gun should be used. Added due to the August 2020 update, which re-added the actual Super Gravity Gun.", 
   0, 1)
end--11

if !ConVarExists("scgg_allow_enablecvar_modify") then//
   CreateConVar("scgg_allow_enablecvar_modify", '0', (FCVAR_ARCHIVE), "to toggle whether the game can modify the status of the weapon.", 0, 1)
end--12

if !ConVarExists("scgg_cone") then//
   CreateConVar("scgg_cone", '1', (FCVAR_ARCHIVE), "to enable grabbing objects without directly looking at them, via a cone.", 0, 1)
end--13

if !ConVarExists("scgg_weapon_vaporize") then//
   CreateConVar("scgg_weapon_vaporize", '0', (FCVAR_ARCHIVE), "to toggle map-wide dropped weapon vaporization.", 0, 2)
end--14

if !ConVarExists("scgg_keep_armor") then//
   CreateConVar("scgg_keep_armor", '0', (FCVAR_ARCHIVE), "to keep armor after weapon disable. 0 = remove all armor. 1 = lower to 100. 2 = keep armor.", 0, 2)
end--15

if !ConVarExists("scgg_friendly_fire") then//
   CreateConVar("scgg_friendly_fire", '1', (FCVAR_ARCHIVE), "to toggle direct weapon interaction against friendly NPCs.", 0, 1)
end--16

if !ConVarExists("scgg_claw_mode") then//
   CreateConVar("scgg_claw_mode", '1', (FCVAR_ARCHIVE), "to toggle claw movement options. 0 = closed. 1 = open. 2 = dynamic.", 0, 2)
end--17

if !ConVarExists("scgg_deploy_style") then//
   CreateConVar("scgg_deploy_style", '1', (FCVAR_ARCHIVE), "to change the deploy speed. Legacy attribute from scgg_style. 0 = HL2 speed. 1 = sv_defaultdeployspeed convar.", 0, 1)
end--18

if !ConVarExists("scgg_affect_players") then
   CreateConVar("scgg_affect_players", '1', (FCVAR_ARCHIVE), "to toggle whether the weapon should affect other players.", 0, 1)
end--19

if !ConVarExists("scgg_primary_extra") then
	--CreateConVar("scgg_primary_extra", '0', (FCVAR_ARCHIVE), "to toggle extra primary fire behaviour. 0 | none. 1 | the gatling primary fire seen in HL2:EP1. 2 | punt when second object is pointed at. 3 | both", 0, 3)
	CreateConVar("scgg_primary_extra", '0', (FCVAR_ARCHIVE), "to toggle the gatling primary fire seen in HL2:EP1.", 0, 1)
end--20

if !ConVarExists("scgg_normal_switch") then
	CreateConVar("scgg_normal_switch", '1', (FCVAR_ARCHIVE), "to toggle whether players can have access to the normal version of the Gravity Gun.", 0, 1)
end--21

--if !ConVarExists("scgg_worldmodel") then
--	CreateConVar("scgg_worldmodel", 'models/weapons/shadowysn/w_superphyscannon.mdl', (FCVAR_ARCHIVE), "Set the worldmodel of your Super Gravity Gun. Does not affect viewmodel.")
--end--20

--game.SetGlobalState( "super_phys_gun", GLOBAL_ON )

--if SERVER then
--function TheFunction(client, command, arguments, ply)
    	--ply:Give(superphys_string)
	--ply:StripWeapon( phys_string )
--end

--concommand.Add("physcannon_mega_enabled", TheFuction) end

local GetEnts = ents.GetAll()
local Has1ChangedModifyCvar = false
local HasVaporizeBeenSetFrom2 = true

local function HasActiveGlobal()
	local vanillaCvar = true
	if ConVarExists("scgg_vanilla_disable") then
		vanillaCvar = GetConVar("scgg_vanilla_disable"):GetBool()
	end
	if (!vanillaCvar and game.GetGlobalState("super_phys_gun") == GLOBAL_ON) or 
	(vanillaCvar and game.GetGlobalState("super_phys_gun_mod") == GLOBAL_ON) then
		--print("HasActiveGlobal is true")
		return true
	end
	--print("HasActiveGlobal is false")
	return false
end

local function HasInvalidGlobal()
	local vanillaCvar = true
	if ConVarExists("scgg_vanilla_disable") then
		vanillaCvar = GetConVar("scgg_vanilla_disable"):GetBool()
	end
	if (vanillaCvar and game.GetGlobalState("super_phys_gun") == GLOBAL_ON) or 
	(!vanillaCvar and game.GetGlobalState("super_phys_gun_mod") == GLOBAL_ON) then
		return true
	end
	return false
end

local function SetActiveGlobal(state)
	if !ConVarExists("scgg_vanilla_disable") or GetConVar("scgg_vanilla_disable"):GetBool() then
		game.SetGlobalState("super_phys_gun_mod", state)
	else
		game.SetGlobalState("super_phys_gun", state)
	end
end

local function ConvertGlobal(vanillaDis)
	if vanillaDis == true then
		game.SetGlobalState("super_phys_gun_mod", game.GetGlobalState("super_phys_gun"))
		game.SetGlobalState("super_phys_gun", GLOBAL_OFF)
		--print("global set to super_phys_gun_mod")
	else
		game.SetGlobalState("super_phys_gun", game.GetGlobalState("super_phys_gun_mod"))
		game.SetGlobalState("super_phys_gun_mod", GLOBAL_OFF)
		--print("global set to super_phys_gun")
	end
end

if cvars.GetConVarCallbacks("scgg_extra_function", false) != nil then
	cvars.RemoveChangeCallback("scgg_extra_function", "SCGG_Cvar_Notify")
end
cvars.AddChangeCallback( "scgg_extra_function", function( convar_name, value_old, value_new ) -- < No other reason for this to exist than notifying about scgg_vanilla_disable
	local vanillaCvar = true
	if ConVarExists("scgg_vanilla_disable") then
		vanillaCvar = GetConVar("scgg_vanilla_disable"):GetBool()
	end
	
	local new_cvar_val = tonumber(value_new)
	if new_cvar_val > 0 and vanillaCvar then
		print("It is recommended to also set scgg_vanilla_disable to 1 if you want just the mod's SCGG functionality.")
	elseif new_cvar_val <= 0 and vanillaCvar then
		print("It is recommended to also set scgg_vanilla_disable to 0 if you want just Gmod's vanilla SCGG functionality.")
	end
end, "SCGG_Cvar_Notify" )

if cvars.GetConVarCallbacks("scgg_vanilla_disable", false) != nil then
	cvars.RemoveChangeCallback("scgg_vanilla_disable", "SCGG_Vanilla_Disable")
end
cvars.AddChangeCallback( "scgg_vanilla_disable", function( convar_name, value_old, value_new )
	-- ^ scgg_vanilla_disable cvar functionality.
	local new_cvar_val = tonumber(value_new)
	ConvertGlobal(new_cvar_val)
	
	local extraCvar = false
	if ConVarExists("scgg_extra_function") then
		extraCvar = GetConVar("scgg_extra_function"):GetBool()
	end
	
	if new_cvar_val > 0 and extraCvar then
		print("It is recommended to also set scgg_extra_function to 1 if you want just the mod's SCGG functionality.")
	elseif  new_cvar_val <= 0 and extraCvar then
		print("It is recommended to also set scgg_extra_function to 0 if you want just Gmod's vanilla SCGG functionality.")
	end
	
	if new_cvar_val <= 0 then
		print("TIP: Gravity Guns, in vanilla Gmod, will only check for whether to supercharge or not when spawned. Suicide and respawn if it doesn't supercharge.")
	end
end, "SCGG_Vanilla_Disable" )

hook.Add("OnEntityCreated", "SCGG_Trigger_AddOutput", function( trigger ) 
	if ConVarExists("scgg_extra_function") and !GetConVar("scgg_extra_function"):GetBool() then return end
	
	local enabledCvar = 1
	if ConVarExists("scgg_enabled") then
		enabledCvar = GetConVar("scgg_enabled"):GetInt()
	end
	
	if IsValid(trigger) and trigger:GetClass() == superphys_string and !trigger.Fading and enabledCvar <= 0 then
		trigger:Discharge()
	end
--for _,trigger in pairs(GetEnts) do
	if IsValid(trigger) and trigger:GetClass() == "trigger_weapon_dissolve" then
		if enabledCvar >= 2 and
		ConVarExists("scgg_allow_enablecvar_modify") and GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0
		then
			GetConVar("scgg_enabled"):SetInt(0)
		end
		
		if ConVarExists("scgg_weapon_vaporize") and GetConVar("scgg_weapon_vaporize"):GetInt() > 0 then
			if GetConVar("scgg_weapon_vaporize"):GetInt() >= 2 then
				HasVaporizeBeenSetFrom2 = true
			else
				HasVaporizeBeenSetFrom2 = false
			end
			GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
		
		--[[local function EntityGlobal()
			for _,ent in pairs(GetEnts) do
				if IsValid(ent) and ent:GetClass() == "env_global" and ent:GetName() == "scgg_addon_global_env_for_weapondissolve" then
					return ent
				end
			end
			local temp = ents.Create("env_global")
			temp:SetKeyValue("globalstate", "super_phys_gun")
			temp:SetName("scgg_addon_global_env_for_weapondissolve")
			temp:Spawn()
			temp:Activate()
			return temp
		end--]]
		local function EntityLua()
			for _,ent in pairs(GetEnts) do
				if IsValid(ent) and ent:GetClass() == "lua_run" and ent:GetName() == "scgg_addon_lua_run" then
					return ent
				end
			end
			local temp = ents.Create("lua_run")
			temp:SetName("scgg_addon_lua_run")
			temp:SetKeyValue( "Code", 'include("scgg_addon_lua_weaponstrip.lua")' )
			--temp:SetKeyValue( "spawnflags", "1" )
			temp:SetParent(trigger)
			temp:Spawn()
			temp:Activate()
			return temp
		end
		
		--EntityGlobal()
		EntityLua()
		
		--trigger:Fire("AddOutput", "onchargingphyscannon scgg_addon_global_env_for_weapondissolve,TurnOn")
		--trigger:Fire("AddOutput", "onchargingphyscannon !activator,AddOutput,spawnflags 0, 4")
		trigger:Fire("AddOutput", "onchargingphyscannon scgg_addon_lua_run,RunCode")
		
		--[[if game.GetMap() == "d3_citadel_03" then
			trigger:Fire("AddOutput", "onchargingphyscannon weapon_physcannon, Use, , 10")
		end--]]
	end
end)

local think_Tick = 0

hook.Add("Think","SCGG_Global_Think",function() 
	-- ^ Start of think hook
	if ConVarExists("scgg_extra_function") and !GetConVar("scgg_extra_function"):GetBool() then return end
	
	if think_Tick < 1 then
		think_Tick = think_Tick + 0.25
		return
	else
		think_Tick = 0
	end
	-- ^ Reduces how often this think hook's functions are exec'd
	
	if ConVarExists("scgg_vanilla_disable") and HasInvalidGlobal() then
		ConvertGlobal(GetConVar("scgg_vanilla_disable"):GetBool())
	end
	
	if (ConVarExists("scgg_weapon_vaporize") and 
	GetConVar("scgg_weapon_vaporize"):GetInt() > 0 and GetConVar("scgg_weapon_vaporize"):GetInt() < 2) then
		-- ^ Start of vaporize cvar check
		GlobalDissolve()
	end
	-- ^ End of vaporize cvar check
	
	local hasCvarEnabled = ConVarExists("scgg_enabled")
	local hasCvarModify = ConVarExists("scgg_allow_enablecvar_modify")
	local enabledCvar = 1
	if hasCvarEnabled then
		enabledCvar = GetConVar("scgg_enabled"):GetInt()
	end
	
	if HasActiveGlobal() or enabledCvar >= 2 then 
	-- ^ Check if global state turned on and cvar is not 1
		if hasCvarModify and GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0 then
			GetConVar("scgg_enabled"):SetInt(2)
		end
	end
	
	if hasCvarEnabled and hasCvarModify and !HasActiveGlobal() and GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0 then
	-- ^ Check if global state turned off and cvar is not 0
		GetConVar("scgg_enabled"):SetInt(0)
	end
	
end) 
-- ^ End of think hook.

hook.Add("PostEntityTakeDamage","SCGG_NPC_Death_Post",function( ent, dmg )
	if ConVarExists("scgg_extra_function") and !GetConVar("scgg_extra_function"):GetBool() then return end
	
	if IsValid(ent) and 
	(
	(ent:IsNPC() and (ent:Health() < 0 or ent:GetNPCState() == NPC_STATE_DEAD))
	--or
	--(ent:IsPlayer() and !ent:Alive())
	)
	and 
	ConVarExists("scgg_weapon_vaporize") and GetConVar("scgg_weapon_vaporize"):GetInt() >= 2 then
		GlobalDissolve()
	end
end)

hook.Add("PostPlayerDeath","SCGG_Weapon_DropVaporize",function( ply )
	if ConVarExists("scgg_extra_function") and !GetConVar("scgg_extra_function"):GetBool() then return end
	
	if IsValid(ply) and !ply:Alive() and 
	ConVarExists("scgg_weapon_vaporize") and GetConVar("scgg_weapon_vaporize"):GetInt() >= 2 then
		GlobalDissolve()
	end
	--[[if ply:HasWeapon(superphys_string) then
		print("yeah")
		local phys = ply:GetWeapon(superphys_string)
		if phys.TP and phys.TP:IsValid() then
			--if phys.HP then
			
			--end
		ply:GetWeapon(superphys_string):Drop()
		end
	end--]]
end)

local function EquipGravGuns(wep, ply, isPlayerSpawn)
	if !IsValid(ply) or !IsValid(wep) or (!isPlayerSpawn and ply.SCGG_Dropping) then return end
	if isPlayerSpawn == nil then isPlayerSpawn = false end
	
	--print(isPlayerSpawn)
	if !isPlayerSpawn then
		ply.SCGG_Dropping = true -- Needed, unless you want overflows everywhere
		timer.Simple(0, function()
			if !IsValid(ply) then return end
			ply.SCGG_Dropping = nil
		end)
	end
	
	local switch_cvar = false
	if ConVarExists("scgg_normal_switch") then
		switch_cvar = GetConVar("scgg_normal_switch"):GetBool()
	end
	local class = wep:GetClass()
	--print(class)
	--return
	if ply:Alive() and class == phys_string and !ply:HasWeapon(superphys_string) then
		ply:Give(superphys_string)
		
		--[[local active_wep = ply:GetActiveWeapon()
		if IsValid(active_wep) and active_wep == wep then
			
		end--]]
		
		if !switch_cvar then
			--print("drop_equip")
			--print(wep)
			if ply:HasWeapon(class) then
				ply:StripWeapon(class)
			else
				wep:Remove()
			end
		end
	elseif switch_cvar and ply:Alive() and class == superphys_string and !ply:HasWeapon(phys_string) then
		ply:Give(phys_string)
	end
end

local function DropGravGuns(wep, ply)
	if !ply or !wep or !IsValid(ply) or !IsValid(wep) or ply.SCGG_Dropping then return end
	
	ply.SCGG_Dropping = true
	timer.Simple(0, function()
		if !IsValid(ply) then return end
		ply.SCGG_Dropping = nil
	end)
	
	local switch_cvar = false
	if ConVarExists("scgg_normal_switch") then
		switch_cvar = GetConVar("scgg_normal_switch"):GetBool()
	end
	
	local class = wep:GetClass()
	if class == phys_string then
		if !switch_cvar then
			--print("drop_pre")
			--print(wep)
			if ply:IsPlayer() and ply:HasWeapon(class) then
				ply:StripWeapon(class)
			else
				wep:Remove()
			end
			if ply:IsPlayer() and !ply:HasWeapon(superphys_string) then
				ply:Give(superphys_string)
			end
		elseif ply:IsPlayer() and ply:HasWeapon(superphys_string) then
			--print("drop_super")
			--print(physgun)
			ply:StripWeapon(superphys_string)
		--[[else
			print("drop_super_else")
			local physgun = ply:GetWeapon(superphys_string)
			physgun:Remove()--]]
		end
	elseif switch_cvar and class == superphys_string then
		if ply:IsPlayer() and ply:HasWeapon(phys_string) then
			--print("drop")
			--print(physgun)
			ply:StripWeapon(phys_string)
		--[[elseif ply:HasWeapon(phys_string) then
			print("drop_else")
			local physgun = ply:GetWeapon(phys_string)
			physgun:Remove()--]]
		end
	end
end

-- These two hooks need each other to have the game seemingly treat both gravity guns as one.
-- Otherwise weapons could disappear and never be brought back without spawnmenu.
hook.Add("PlayerDroppedWeapon","SCGG_Weapon_CheckDrop",function(owner, wep) -- For when a player drops a weapon
-- ^ Remove the other gravity gun if one is dropped.
	if ConVarExists("scgg_extra_function") and !GetConVar("scgg_extra_function"):GetBool() then return end
	if !IsValid(owner) then return end
	
	if ConVarExists("scgg_enabled") and GetConVar("scgg_enabled"):GetInt() >= 2 and !owner.SCGG_Dropping then
		-- If one variant is dropped, remove the other variant.
		DropGravGuns(wep, owner)
	end
end)

hook.Add("WeaponEquip","SCGG_Weapon_Pickup",function(wep, ply)-- For when a player picks up a weapon.
	-- ^ Give the other variant to people that own one of them, if the other variant does not exist.
	if ConVarExists("scgg_extra_function") and !GetConVar("scgg_extra_function"):GetBool() then return end
	--[[local class = wep:GetClass()
	local function HasWeaponOrEquipped(wep_str)
		-- Doesn't work, will create annoying overflows. Use player spawn hook for everything instead.
		if class == wep_str or ply:HasWeapon(wep_str) then
			return true
		end
		return false
	end
	print("Super:")
	print(HasWeaponOrEquipped(superphys_string))
	print("Normal:")
	print(HasWeaponOrEquipped(phys_string))--]]
	--if GetConVar("scgg_enabled"):GetInt() >= 2 and (!HasWeaponOrEquipped(superphys_string) or !HasWeaponOrEquipped(phys_string)) then
	if ConVarExists("scgg_enabled") and GetConVar("scgg_enabled"):GetInt() >= 2 then
		EquipGravGuns(wep, ply)
	end
end)

hook.Add("PlayerLoadout","SCGG_Spawn_Weapon",function(ply, isTransition)-- For when a player spawns.
	if ConVarExists("scgg_extra_function") and !GetConVar("scgg_extra_function"):GetBool() then return end
	--print(isTransition)
	timer.Simple(0, function()
		if ConVarExists("scgg_enabled") and GetConVar("scgg_enabled"):GetInt() >= 2 and !isTransition then
			for _,wep in pairs(ply:GetWeapons()) do
				if IsValid(wep) then
					EquipGravGuns(wep, ply, true)
				end
			end
		end
	end)
end)

-- NOTE TO SELF: Every time a gravity gun is spawned when the global super_phys_gun is on, it is spawned as a super version of itself
-- Rubat managed to make both versions of the gravity gun co-exist, but only one gravity gun can be used.
if cvars.GetConVarCallbacks("physcannon_mega_enabled", false) != nil then
	cvars.RemoveChangeCallback("physcannon_mega_enabled", "SCGG_MegaCvar_Support")
end
cvars.AddChangeCallback( "physcannon_mega_enabled", function( convar_name, value_old, value_new )
	-- ^ Support for physcannon_mega_enabled cvar.
	if !ConVarExists("scgg_enabled") then return end
	
	local new_cvar_val = tonumber(value_new)
	
	if !ConVarExists("scgg_vanilla_disable") or GetConVar("scgg_vanilla_disable"):GetBool() then
		if new_cvar_val > 0 then
			print("WARNING! scgg_vanilla_disable is active, however, physcannon_mega_enabled is hardcoded to activate the vanilla Super Gravity Gun no matter what.")
			print("Use scgg_enabled instead.")
		end
		return
	end
	
	if new_cvar_val > 0 then
		GetConVar("scgg_enabled"):SetInt(2)
	end
	if new_cvar_val <= 0 then
		GetConVar("scgg_enabled"):SetInt(0)
	end
end, "SCGG_MegaCvar_Support" )

if cvars.GetConVarCallbacks("scgg_normal_switch", false) != nil then
	cvars.RemoveChangeCallback("scgg_normal_switch", "SCGG_NormalSwitch_Cvar")
end
cvars.AddChangeCallback( "scgg_normal_switch", function( convar_name, value_old, value_new )
	-- ^ Handle changing of scgg_normal_switch cvar.
	if !ConVarExists("scgg_enabled") or GetConVar("scgg_enabled"):GetInt() < 2 then return end
	
	local all_ply = player.GetAll()
	local switch_cvar = tonumber(value_new)
	for _,ply in pairs(all_ply) do
		if IsValid(ply) and ply:Alive() and (ply:HasWeapon(phys_string) or ply:HasWeapon(superphys_string)) then
			local wep = nil
			if ply:HasWeapon(phys_string) then
				wep = ply:GetWeapon(phys_string)
			elseif ply:HasWeapon(superphys_string) then
				wep = ply:GetWeapon(superphys_string)
			end
			
			if switch_cvar > 0 then
				EquipGravGuns(wep, ply)
			else
				DropGravGuns(wep, ply)
			end
		end
	end
end, "SCGG_NormalSwitch_Cvar" )

if cvars.GetConVarCallbacks("scgg_enabled", false) != nil then
	cvars.RemoveChangeCallback("scgg_enabled", "SCGG_Disable_GlobalState")
end
cvars.AddChangeCallback( "scgg_enabled", function( convar_name, value_old, value_new )
	local all_ply = player.GetAll()
	-- ^ Checks for scgg enabled cvar change.
	
	local vaporCvar = 0
	if ConVarExists("scgg_weapon_vaporize") then
		vaporCvar = GetConVar("scgg_weapon_vaporize"):GetInt()
	end
	
	local enablecvar = tonumber(value_new)
	if enablecvar >= 2 then
		if ConVarExists("scgg_allow_enablecvar_modify") and Has1ChangedModifyCvar == true then
			GetConVar("scgg_allow_enablecvar_modify"):SetInt(1)
			Has1ChangedModifyCvar = false
		end
		SetActiveGlobal( GLOBAL_ON )
		
		if vaporCvar <= 0 then
			if HasVaporizeBeenSetFrom2 then
				GetConVar("scgg_weapon_vaporize"):SetInt(2)
			else
				GetConVar("scgg_weapon_vaporize"):SetInt(1)
			end
			HasVaporizeBeenSetFrom2 = false
		end
		
		-- Check for players that have one variant of the gravity gun
		if enablecvar >= 2 and (!ConVarExists("scgg_extra_function") or GetConVar("scgg_extra_function"):GetBool()) then
			for _,ply in pairs(all_ply) do
				if IsValid(ply) and (!ply:HasWeapon(phys_string) or !ply:HasWeapon(superphys_string)) then
				-- ^ If player is valid, and either doesn't have normal or super variant...
					if ply:HasWeapon(superphys_string) then
						EquipGravGuns(ply:GetWeapon(superphys_string), ply)
					elseif ply:HasWeapon(phys_string) then
						EquipGravGuns(ply:GetWeapon(phys_string), ply)
					end
				end
			end
		end
	elseif (enablecvar < 2) then
		--SetActiveGlobal( GLOBAL_ON )
		if enablecvar > 0 and ConVarExists("scgg_allow_enablecvar_modify") and GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0 then
			GetConVar("scgg_allow_enablecvar_modify"):SetInt(0)
			Has1ChangedModifyCvar = true
		end
		if vaporCvar > 0 then
			if vaporCvar >= 2 then
				HasVaporizeBeenSetFrom2 = true
			else
				HasVaporizeBeenSetFrom2 = false
			end
			GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
	end
	if enablecvar <= 0 then
		SetActiveGlobal( GLOBAL_OFF )
		
		for _,ent in pairs(ents.GetAll()) do
			if IsValid(ent) and ent:GetClass() == superphys_string then
				local owner = ent:GetOwner()
				local active_wep = nil
				if (owner:IsPlayer() or owner:IsNPC()) then
					active_wep = owner:GetActiveWeapon()
				end
				if (!IsValid(owner) or 
				((owner:IsPlayer() and owner:HasWeapon(superphys_string) or owner:IsNPC())
				and IsValid(active_wep) and active_wep == ent)) then
					ent:Discharge()
				elseif IsValid(owner) then
					if owner:IsPlayer() and owner:HasWeapon(superphys_string) then
						owner:StripWeapon(superphys_string)
					else
						ent:Remove()
					end
					if (owner:IsPlayer() and !owner:HasWeapon(phys_string)) or (owner:IsNPC()) then
						owner:Give(phys_string)
					end
				end
			end
		end
		
		for _,ply in pairs(all_ply) do
		-- ^ Armor drainage.
			local armorCvar = 2
			if ConVarExists("scgg_keep_armor") then
				armorCvar = GetConVar("scgg_keep_armor"):GetInt()
			end
			if armorCvar <= 1 and ply:IsValid() and ply:Alive() and ply:Armor() >= 1 then
			-- ^ Won't run of
				local armorval_0 = ply:Armor()+1
				local armor_countdown = ply:Armor()
				local armor_reference = ply:Armor() -- Used to prevent added armor being removed. Although, doesn't work very well...
				if (armorCvar > 0 and armorCvar < 2) and armor_reference <= 100 then return end
				timer.Create( "SCGG_Armor_Lower", 0.01, armorval_0/2, function()
					if (armor_reference % 2 == 0) then
						armor_countdown = armor_countdown-2
					else
						armor_countdown = armor_countdown-1
					end
					if (armorCvar <= 0 or armorCvar >= 2) and ply:Armor() <= 0 -- If cvar is not just 1 (safety measure) and armor is 0...
					or (armorCvar > 0 and armorCvar < 2) and ply:Armor() <= 100 -- or cvar is 1 and armor is 100...
					then 
					timer.Remove("SCGG_Armor_Lower") -- Stop draining.
					return 
					end
					if ply:Armor() < armor_reference then
						armor_reference = ply:Armor()
					end
					ply:SetArmor( armor_countdown+(ply:Armor()-armor_reference) ) -- Set the armor.
				end )
			end
		end
		-- ^ Armor drainage end.
	end
end, "SCGG_Disable_GlobalState" )
-- ^ More like 'global state checking'
-- v 
if cvars.GetConVarCallbacks("scgg_allow_enablecvar_modify", false) != nil then
	cvars.RemoveChangeCallback("scgg_allow_enablecvar_modify", "SCGG_EnableCvar_Modify")
end
cvars.AddChangeCallback( "scgg_allow_enablecvar_modify", function( convar_name, value_old, value_new )
	if tonumber(value_new) > 0 then
		Has1ChangedModifyCvar = false
	end
end, "SCGG_EnableCvar_Modify" )
