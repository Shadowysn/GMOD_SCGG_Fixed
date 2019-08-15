if (CLIENT) then return end

util.AddNetworkString("SCGG_Ragdoll_GetPlayerColor")
util.AddNetworkString("SCGG_Core_Muzzle")

local function DissolveEntity(entity)
	local name = "SCGG_Dissolving_"..entity:EntIndex()
	entity:SetName( name )
	--[[if !IsValid(dissolver) then
	local dissolver = ents.Create("env_entity_dissolver")
	dissolver:SetPos(Vector(0,0,0))
	dissolver:SetKeyValue( "dissolvetype", 0 )
	dissolver:SetName("scgg_addon_global_dissolver")
	dissolver:Spawn()
	dissolver:Activate()
	end
	dissolver:Fire("Dissolve", name, 0)--]]
	local check_bool = nil
	for _,ent in pairs(ents.FindByName("scgg_addon_global_dissolver")) do
		if ent:GetClass() == "env_entity_dissolver" then
			ent:Fire("Dissolve", name, 0)
			check_bool = true
		end
	end
	if !check_bool then
	local dissolver = ents.Create("env_entity_dissolver")
	dissolver:SetPos(Vector(0,0,0))
	dissolver:SetKeyValue( "dissolvetype", 0 )
	dissolver:SetName("scgg_addon_global_dissolver")
	dissolver:Spawn()
	dissolver:Activate()
	dissolver:Fire("Dissolve", name, 0)
	end
end

local phys_string = "weapon_physcannon"
local superphys_string = "weapon_superphyscannon"

if !ConVarExists("scgg_style") then	
   CreateConVar("scgg_style", '0', (FCVAR_ARCHIVE), "to change if the weapon is styled like Half-Life 2 or Garry's Mod.", true, true)
end--1

if !ConVarExists("scgg_light") then	
   CreateConVar("scgg_light", '0', (FCVAR_ARCHIVE), "to change if the weapon emits a light.", true, true)
end--2

if !ConVarExists("scgg_muzzle_flash") then	
   CreateConVar("scgg_muzzle_flash", '1', (FCVAR_ARCHIVE), "to change if the weapon emits a light when attacking.", true, true)
end--3

if !ConVarExists("scgg_zap") then	
   CreateConVar("scgg_zap", '1', (FCVAR_ARCHIVE), "to toggle victims being electrocuted.", true, true)
end--4

if !ConVarExists("scgg_allow_others") then	
   CreateConVar("scgg_allow_others", '0', (FCVAR_ARCHIVE), "to allow weapon interaction of other objects, including addons. (WILL have a chance to cause bugs.)", true, true)
end--5

if !ConVarExists("scgg_zap_sound") then	
   CreateConVar("scgg_zap_sound", '1', (FCVAR_ARCHIVE), "to toggle electrocuted victims emitting sound.", true, true)
end--6

if !ConVarExists("scgg_equip_sound") then	
   CreateConVar("scgg_equip_sound", '0', (FCVAR_ARCHIVE), "to toggle sound emitted when deploying weapon.", true, true)
end--7

if !ConVarExists("scgg_no_effects") then	
   CreateConVar("scgg_no_effects", '0', (FCVAR_ARCHIVE), "to toggle visual effects.", true, true)
end--8

if !ConVarExists("scgg_enabled") then	
   CreateConVar("scgg_enabled", '1', (FCVAR_ARCHIVE), "to toggle weapon availability. 0 = any super-charged gravity gun will revert to normal. 1 = Enable, don't do anything else. 2 = Enable, alter various settings.", true, true)
end--9

if !ConVarExists("scgg_allow_enablecvar_modify") then	
   CreateConVar("scgg_allow_enablecvar_modify", '1', (FCVAR_ARCHIVE), "to toggle whether the game can modify the status of the weapon.", true, true)
end--10

if !ConVarExists("scgg_cone") then	
   CreateConVar("scgg_cone", '0', (FCVAR_ARCHIVE), "DEBUG-TESTING; to enable grabbing objects without directly looking at them, via a cone.", true, true)
end--11

if !ConVarExists("scgg_weapon_vaporize") then	
   CreateConVar("scgg_weapon_vaporize", '0', (FCVAR_ARCHIVE), "to toggle map-wide dropped weapon vaporization.", true, true)
end--12

if !ConVarExists("scgg_keep_armor") then	
   CreateConVar("scgg_keep_armor", '0', (FCVAR_ARCHIVE), "to keep armor after weapon disable. 0 = remove all armor. 1 = lower to 100. 2 = keep armor.", true, true)
end--13

if !ConVarExists("scgg_friendly_fire") then	
   CreateConVar("scgg_friendly_fire", '1', (FCVAR_ARCHIVE), "to toggle direct weapon interaction against friendly NPCs.", true, true)
end--14

if !ConVarExists("scgg_claw_mode") then	
   CreateConVar("scgg_claw_mode", '1', (FCVAR_ARCHIVE), "to toggle claw movement options. 0 = closed. 1 = open. 2 = dynamic.", true, true)
end--15

--game.SetGlobalState( "super_phys_gun", GLOBAL_ON )

--if SERVER then
--function TheFunction(client, command, arguments, ply)
    	--ply:Give(superphys_string)
	--ply:StripWeapon( phys_string )
--end

--concommand.Add("physcannon_mega_enabled", TheFuction) end

local GetEnts = ents.GetAll()
local Has1ChangedModifyCvar = false
hook.Add("OnEntityCreated","SCGG_Trigger_AddOutput",function( trigger ) 
--for _,trigger in pairs(GetEnts) do
	if IsValid(trigger) and trigger:GetClass() == "trigger_weapon_dissolve" then
		local function EntityGlobalCheck()
			for _,ent in pairs(GetEnts) do
			if IsValid(ent) and ent:GetClass() == "env_global" and ent:GetName() == "scgg_addon_global_env_for_weapondissolve" then
				return true
			end
			end
			return false
		end
		if EntityGlobalCheck() == false then
		local global_entity = ents.Create("env_global")
		global_entity:SetKeyValue("globalstate", "super_phys_gun")
		global_entity:SetName("scgg_addon_global_env_for_weapondissolve")
		global_entity:Spawn()
		global_entity:Activate()
		end
		trigger:Fire("AddOutput", "onchargingphyscannon scgg_addon_global_env_for_weapondissolve,TurnOn")
		--trigger:Fire("AddOutput", "onchargingphyscannon !activator,AddOutput,spawnflags 0, 4")
		trigger:Fire("AddOutput", "onchargingphyscannon weapon_physcannon,Skin,1")
		trigger:Fire("AddOutput", "onchargingphyscannon weapon_physcannon,AddOutput,spawnflags 0, 8")
	end
end)

hook.Add("PlayerDroppedWeapon","SCGG_Weapon_CheckDrop",function( owner, wep ) 
-- ^ Remove the other gravity gun if one is dropped.
if GetConVar("scgg_enabled"):GetInt() >= 2 then
	owner.SCGG_Dropping = true
	
	if wep:GetClass() == phys_string then
		if owner:HasWeapon(superphys_string) == true then
			local physgun = owner:GetWeapon(superphys_string)
			--[[if owner:GetActiveWeapon() == physgun then -- Unfinished.
				owner:
			end--]]
			physgun:Remove()
		end
	end
	--[[if wep:GetClass() == superphys_string then -- Buggy behaviour resulting in infinite grav guns, both normal and charged.
		if owner:HasWeapon(phys_string) == true then
			owner.SCGG_Dropping = true
			local physgun = owner:GetWeapon(phys_string)
			--if owner:GetActiveWeapon() == physgun then
			--	owner:
			--end
			physgun:Remove()
		end
	end--]]
	owner.SCGG_Dropping = nil
end
end )

hook.Add("Think","SCGG_Global_Think",function() 
-- ^ Start of think hook
if (GetConVar("scgg_weapon_vaporize"):GetInt() > 0 and GetConVar("scgg_weapon_vaporize"):GetInt() < 2) then
-- ^ Start of vaporize cvar check

	for _,wpn in pairs(ents.GetAll()) do
		wpn.SCGG_Dissolving = false -- Dissolve check.
		--[[if IsValid(wpn) and wpn:IsWeapon() and !wpn:GetOwner():IsValid() then
			wpn:SetKeyValue("spawnflags","2") 
			-- ^ I don't know what I was trying to do with this.
		end--]]
			if IsValid(wpn) and wpn:IsValid() and ( wpn:IsWeapon() or wpn:GetClass() == "item_ammo_ar2_altfire" ) and !wpn:CreatedByMap() and 
			(wpn:GetClass() != phys_string and wpn:GetClass() != superphys_string) then
			-- ^ Valid check start
		for _, child in pairs(wpn:GetChildren()) do
			if child:GetClass() == "env_entity_dissolver" then
				wpn.SCGG_Dissolving = true 
				-- ^ Mark them as dissolving so we don't repeatedly try to dissolve an already vaporizing gun.
			end
		end
		
		if GetConVar("scgg_enabled"):GetInt() >= 2 and wpn:GetClass() == "item_ammo_ar2_altfire" then 
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
		DissolveEntity(wpn)
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
-- ^ End of vaporize cvar check
if (game.GetGlobalState( "super_phys_gun") == GLOBAL_ON or GetConVar("scgg_enabled"):GetInt() >= 2) then 
-- ^ Check if global state turned on and cvar is not 1
	if GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0 and game.GetGlobalState( "super_phys_gun") == GLOBAL_ON then
	GetConVar("scgg_enabled"):SetInt(2)
	end
	
	-- v Attempt to make gravity guns glow the physgun color, but went awry. (players were somehow affected)
	--[[for _,physcannon in pairs(ents.GetAll()) do
		if physcannon:GetClass(phys_string) then
		--local supermdl = "models/weapons/errolliamp/w_superphyscannon.mdl"
		--local mdl = "models/weapons/w_physics.mdl"
		
		if !IsValid( physcannon:GetOwner() ) then
			if physcannon:GetSkin() != 1 then
			physcannon:SetSkin( 1 )
			end
		elseif IsValid( physcannon:GetOwner() ) then
			if physcannon:GetSkin() != 0 then
			physcannon:SetSkin( 0 )
			end
		end
		
		end
	end --]]
	
if GetConVar("scgg_enabled"):GetInt() >= 2 then
	-- v Give the other variant to people that own one of them. (Notice: This only gives the scgg due to disappointing bugs)
	for _,foundply in pairs(player.GetAll()) do
		if foundply.SCGG_Dropping != true then
		
		for _,wep in pairs( foundply:GetWeapons() ) do
			
			if foundply:Alive() and wep:GetClass() == phys_string then
				if !foundply:HasWeapon(superphys_string) then
				foundply:Give(superphys_string)
				end
			--[[elseif foundply:Alive() and wep:GetClass() == superphys_string then
				if !foundply:HasWeapon(phys_string) then
				foundply:Give(phys_string)
				end--]]
			end
		end
		
		end
	end
end
	-- ^ End of above for loops.
end

if (game.GetGlobalState( "super_phys_gun") == GLOBAL_OFF) and GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0 then
-- ^ Check if global state turned off and cvar is not 0
	GetConVar("scgg_enabled"):SetInt(0)
end

end) 
-- ^ End of think hook.

--[[hook.Add("PlayerDeath","SCGG_Weapon_Drop_OnDeath",function( ply ) -- Acts like Keep Corpses :\
if ply:HasWeapon(superphys_string) then
	print("yeah")
	local phys = ply:GetWeapon(superphys_string)
	if phys.TP and phys.TP:IsValid() then
		--if phys.HP then
		
		--end
	ply:GetWeapon(superphys_string):Drop()
	end
end
end)--]]

--[[hook.Add("Think","SCGG_Weapon_ServerRagdoll_Think",function() -- Acts like Keep Corpses :\
if GetConVar("scgg_enabled"):GetInt() >= 2 then
	for _,npc in pairs(ents.GetAll()) do
		if npc:IsNPC() then
		if npc:GetShouldServerRagdoll() != true then
			npc:SetShouldServerRagdoll( true )
		end
		end
	end
end
end)--]]

--[[hook.Add("PlayerCanPickupWeapon","SCGG_PreventWeaponPickup",function(ply, wep)
	if GetConVar("scgg_enabled"):GetInt() >= 2 then
		return false
	end
end)--]]

cvars.AddChangeCallback( "physcannon_mega_enabled", function( convar_name, value_old, value_new )
	-- ^ Support for physcannon_mega_enabled cvar.
	local megacvar = tonumber(value_new)
	if megacvar > 0 then
		GetConVar("scgg_enabled"):SetInt(2)
	end
	if megacvar <= 0 then
		GetConVar("scgg_enabled"):SetInt(0)
	end
end, "SCGG_MegaCvar_Support" )

cvars.AddChangeCallback( "scgg_enabled", function( convar_name, value_old, value_new )
-- ^ Checks for scgg enabled cvar change.
	local enablecvar = tonumber(value_new)
	if enablecvar >= 2 then
		if Has1ChangedModifyCvar == true then
		GetConVar("scgg_allow_enablecvar_modify"):SetInt(1)
		Has1ChangedModifyCvar = false
		end
		game.SetGlobalState( "super_phys_gun", GLOBAL_ON )
		if GetConVar("scgg_weapon_vaporize"):GetInt() <= 0 then
		GetConVar("scgg_weapon_vaporize"):SetInt(1)
		end
	end
	if (enablecvar < 2 and enablecvar > 0) then
		--game.SetGlobalState( "super_phys_gun", GLOBAL_ON )
		if GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0 then
		GetConVar("scgg_allow_enablecvar_modify"):SetInt(0)
		Has1ChangedModifyCvar = true
		end
		if GetConVar("scgg_weapon_vaporize"):GetInt() > 0 then
		GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
	end
	if enablecvar <= 0 then
		if Has1ChangedModifyCvar == true then
		GetConVar("scgg_allow_enablecvar_modify"):SetInt(1)
		Has1ChangedModifyCvar = false
		end
		game.SetGlobalState( "super_phys_gun", GLOBAL_OFF )
		if GetConVar("scgg_weapon_vaporize"):GetInt() > 0 then
		GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
		
		for _,ply in pairs(player.GetAll()) do
		-- ^ Armor drainage.
			local getcvar = GetConVar("scgg_keep_armor"):GetInt()
			if getcvar <= 1 and ply:IsValid() and ply:Alive() and ply:Armor() >= 1 then
			-- ^ Won't run of
				local armorval_0 = ply:Armor()+1
				local armor_countdown = ply:Armor()
				local armor_reference = ply:Armor() -- Used to prevent added armor being removed. Although, doesn't work very well...
				if (getcvar > 0 and getcvar < 2) and armor_reference <= 100 then return end
				timer.Create( "SCGG_Armor_Lower", 0.01, armorval_0/2, function()
					if (armor_reference % 2 == 0) then
					armor_countdown = armor_countdown-2
					else
					armor_countdown = armor_countdown-1
					end
					if (getcvar <= 0 or getcvar >= 2) and ply:Armor() <= 0 -- If cvar is not just 1 (safety measure) and armor is 0...
					or (getcvar > 0 and getcvar < 2) and ply:Armor() <= 100 -- or cvar is 1 and armor is 100...
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
cvars.AddChangeCallback( "scgg_allow_enablecvar_modify", function( convar_name, value_old, value_new )
	if tonumber(value_new) > 0 then
		Has1ChangedModifyCvar = false
	end
end, "SCGG_MegaCvar_Support" )