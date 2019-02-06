//Commands

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

if !ConVarExists("scgg_cone") then	
   CreateConVar("scgg_cone", '0', (FCVAR_ARCHIVE), "DEBUG-TESTING; to enable grabbing objects without directly looking at them, via a cone.", true, true)
end--10

if !ConVarExists("scgg_weapon_vaporize") then	
   CreateConVar("scgg_weapon_vaporize", '0', (FCVAR_ARCHIVE), "to toggle map-wide dropped weapon vaporization.", true, true)
end--11

if !ConVarExists("scgg_keep_armor") then	
   CreateConVar("scgg_keep_armor", '0', (FCVAR_ARCHIVE), "to keep armor after weapon disable. 0 = remove all armor. 1 = lower to 100. 2 = keep armor.", true, true)
end--12

if !ConVarExists("scgg_friendly_fire") then	
   CreateConVar("scgg_friendly_fire", '1', (FCVAR_ARCHIVE), "to toggle direct weapon interaction against friendly NPCs.", true, true)
end--13

if !ConVarExists("scgg_claw_mode") then	
   CreateConVar("scgg_claw_mode", '1', (FCVAR_ARCHIVE), "to toggle claw movement options. 0 = closed. 1 = open. 2 = dynamic.", true, true)
end--14

--game.SetGlobalState( "super_phys_gun", GLOBAL_ON )

--if SERVER then
--function TheFunction(client, command, arguments, ply)
    	--ply:Give("weapon_superphyscannon")
	--ply:StripWeapon( "weapon_physcannon" )
--end

--concommand.Add("physcannon_mega_enabled", TheFuction) end

if SERVER then

local GetEnts = ents.GetAll()
hook.Add("OnEntityCreated","SCGG_Trigger_AddOutput",function( trigger ) 
--for _,trigger in pairs(GetEnts) do
	if IsValid(trigger) and trigger:GetClass() == "trigger_weapon_dissolve" then
		trigger:Fire("AddOutput", "onchargingphyscannon scgg_addon_global_env_for_weapondissolve,TurnOn")
		trigger:Fire("AddOutput", "onchargingphyscannon weapon_physcannon,Skin,1")
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
	end
end)

hook.Add("PlayerDroppedWeapon","SCGG_Weapon_CheckDrop",function( owner, wep ) 
-- ^ Remove the other gravity gun if one is dropped.
if GetConVar("scgg_enabled"):GetInt() >= 2 then
	owner.SCGG_Dropping = true
	local phys = "weapon_physcannon"
	local superphys = "weapon_superphyscannon"
	
	if wep:GetClass() == phys then
		if owner:HasWeapon(superphys) == true then
			local physgun = owner:GetWeapon(superphys)
			--[[if owner:GetActiveWeapon() == physgun then -- Unfinished.
				owner:
			end--]]
			physgun:Remove()
		end
	end
	--[[if wep:GetClass() == superphys then -- Buggy behaviour resulting in infinite grav guns, both normal and charged.
		if owner:HasWeapon(phys) == true then
			owner.SCGG_Dropping = true
			local physgun = owner:GetWeapon(phys)
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
if GetConVar("scgg_weapon_vaporize"):GetInt() == 1 then
-- ^ Start of vaporize cvar check

	for _,wpn in pairs(ents.GetAll()) do
		wpn.SCGG_Dissolving = false -- Dissolve check.
		--[[if IsValid(wpn) and wpn:IsWeapon() and !wpn:GetOwner():IsValid() then
			wpn:SetKeyValue("spawnflags","2") 
			-- ^ I don't know what I was trying to do with this.
		end--]]
			if IsValid(wpn) and wpn:IsValid() and ( wpn:IsWeapon() or wpn:GetClass() == "item_ammo_ar2_altfire" ) and !wpn:CreatedByMap() and 
			(wpn:GetClass() != "weapon_physcannon" and wpn:GetClass() != "weapon_superphyscannon") then
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
		
		local dissolver = ents.Create( "env_entity_dissolver" ) 
		dissolver:SetPos( fakeitem:LocalToWorld(fakeitem:OBBCenter()) )
		dissolver:SetKeyValue( "dissolvetype", 0 )
		dissolver:Spawn()
		dissolver:Activate()
		-- ^ Dissolving part for the AR2 ammo.
		local name = "SCGG_Dissolving_Item_"..math.random()
		fakeitem:SetName( name )
		dissolver:Fire( "Dissolve", name, 0 )
		dissolver:Fire( "Kill", "", 0.05 )
		
		elseif !wpn:GetOwner():IsValid() and wpn.SCGG_Dissolving == false then 
		-- ^ Check if it's not in the hands of an NPC or Player, and not being dissolved.
		
		wpn:SetKeyValue("spawnflags","2")
		local dissolver = ents.Create( "env_entity_dissolver" )
		dissolver:SetPos( wpn:LocalToWorld(wpn:OBBCenter()) )
		dissolver:SetKeyValue( "dissolvetype", 0 )
		dissolver:Spawn()
		dissolver:Activate()
		-- ^ Dissolving part.
		local name = "SCGG_Dissolving_Weapon_"..math.random()
		wpn:SetName( name )
		dissolver:Fire( "Dissolve", name, 0 )
		dissolver:Fire( "Kill", "", 0.05 )
		
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
if game.GetGlobalState( "super_phys_gun") == GLOBAL_ON and GetConVar("scgg_enabled"):GetInt() != 1 then 
-- ^ Check if global state turned on and cvar is not 1
	if GetConVar("scgg_enabled"):GetInt() <= 0 then
	GetConVar("scgg_enabled"):SetInt(2)
	end
	
	-- v Attempt to make gravity guns glow the physgun color, but went awry. (players were somehow affected)
	--[[for _,physcannon in pairs(ents.GetAll()) do
		if physcannon:GetClass("weapon_physcannon") then
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
	
	-- v Give the other variant to people that own one of them. (Notice: This only gives the scgg due to disappointing bugs)
	for _,foundply in pairs(player.GetAll()) do
		if foundply.SCGG_Dropping != true then
		
		for _,wep in pairs( foundply:GetWeapons() ) do
			local phys = "weapon_physcannon"
			local superphys = "weapon_superphyscannon"
			
			if foundply:Alive() and wep:GetClass() == phys then
				if !foundply:HasWeapon(superphys) then
				foundply:Give(superphys)
				end
			--[[elseif foundply:Alive() and wep:GetClass() == superphys then
				if !foundply:HasWeapon(phys) then
				foundply:Give(phys)
				end--]]
			end
		end
		
		end
	end
	-- ^ End of above for loops.
end

if game.GetGlobalState( "super_phys_gun") == GLOBAL_OFF and GetConVar("scgg_enabled"):GetInt() != 0 then
-- ^ Check if global state turned off and cvar is not 0
	GetConVar("scgg_enabled"):SetInt(0)
end

end) 
-- ^ End of think hook.

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

cvars.AddChangeCallback( "physcannon_mega_enabled", function( convar_name, value_old, value_new )
	-- ^ Support for physcannon_mega_enabled cvar.
	local megacvar = GetConVar("physcannon_mega_enabled"):GetInt()
	if megacvar >= 1 then
		GetConVar("scgg_enabled"):SetInt(2)
	end
	if megacvar <= 0 then
		GetConVar("scgg_enabled"):SetInt(0)
	end
end, "SCGG_MegaCvar_Support" )

cvars.AddChangeCallback( "scgg_enabled", function( convar_name, value_old, value_new )
-- ^ Checks for scgg enabled cvar change.
	local enablecvar = GetConVar("scgg_enabled"):GetInt()
	if enablecvar >= 2 then
		game.SetGlobalState( "super_phys_gun", GLOBAL_ON )
		if GetConVar("scgg_weapon_vaporize"):GetInt() <= 0 then
		GetConVar("scgg_weapon_vaporize"):SetInt(1)
		end
	end
	if enablecvar == 1 then
		game.SetGlobalState( "super_phys_gun", GLOBAL_ON )
		if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
		GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
	end
	if enablecvar <= 0 then
		game.SetGlobalState( "super_phys_gun", GLOBAL_OFF )
		if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
		GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
		
		for _,ply in pairs(player.GetAll()) do
		-- ^ Armor drainage.
			local getcvar = GetConVar("scgg_keep_armor"):GetInt()
			if getcvar <= 1 and ply:IsValid() and ply:Alive() and ply:Armor() >= 1 then
			-- ^ Won't run of
				local armorval_0 = ply:Armor()+1
				local armor_countdown = ply:Armor()
				if getcvar == 1 and ply:Armor() <= 100 then return end
				timer.Create( "SCGG_Armor_Lower", 0.01, armorval_0/2, function()
					if (ply:Armor() % 2 == 0) then
					armor_countdown = armor_countdown-2
					else
					armor_countdown = armor_countdown-1
					end
					if getcvar != 1 and ply:Armor() <= 0 -- If cvar is not just 1 (safety measure) and armor is 0...
					or getcvar == 1 and ply:Armor() <= 100 -- or cvar is 1 and armor is 100...
					then 
					timer.Remove("SCGG_Armor_Lower") -- Stop draining.
					return 
					end
					ply:SetArmor( armor_countdown ) -- Set the armor.
				end )
			end
		end
		-- ^ Armor drainage end.
	end
end, "SCGG_Disable_GlobalState" )
-- ^ More like 'global state checking'

end

if CLIENT then

local function HL2Options(panel) -- HL2 Options for the menu.
local HL2Options = {Options={},
CVars={},
Label="#Presets",
MenuButton="1",
Folder="options"}
panel:ControlHelp("")
panel:AddControl("Label", {Text = "The Super Gravity Gun is found under Weapons"})
panel:ControlHelp("Weapons")
panel:ControlHelp("Half-Life 2")
panel:AddControl("Label", {Text = "It can also be spawned under"})
panel:ControlHelp("Entities")
panel:ControlHelp("Half-Life 2")
panel:AddControl("Label", {Text = "Credits:"})
panel:ControlHelp("Î¤yler Blu  - Original Super Gravity Gun")
panel:ControlHelp("ErrolLiamP - Fixing / Porting and Additions")
HL2Options.Options["#Default"]={scgg_enabled="1", scgg_style="0", scgg_friendly_fire="1", scgg_weapon_vaporize="0", scgg_allow_others="0", scgg_keep_armor="0", scgg_claw_mode="1", scgg_light="0", scgg_muzzle_flash="1", scgg_zap="1", scgg_zap_sound="1", scgg_no_effects="0", scgg_equip_sound="0"}
panel:AddControl("ComboBox",HL2Options)
panel:AddControl("Slider",{Label = "Weapon Status",min = 0,max = 2,Command = "scgg_enabled"})--1
panel:ControlHelp("0 = The weapon will be disabled")
panel:ControlHelp("1 = The weapon will be enabled")
panel:ControlHelp("2 = The weapon will be enabled, with other changes to the map")
panel:AddControl("Slider",{Label = "Behavior",min = 0,max = 1,Command = "scgg_style"})--2
--panel:ControlHelp("")
panel:ControlHelp("0 = Half-Life 2 Styled - Slower and Weaker")
panel:ControlHelp("1 = Garry's Mod Styled - Faster and Stronger")
panel:AddControl("Slider",{Label = "Friendly Fire (NPC)",min = 0,max = 1,Command = "scgg_friendly_fire"})--3
panel:ControlHelp("0 = Friendly NPCs will not be directly targeted")
panel:ControlHelp("1 = Friendly NPCs will be directly targeted")
panel:AddControl("Slider",{Label = "Weapon Vaporization",min = 0,max = 1,Command = "scgg_weapon_vaporize"})--4
panel:ControlHelp("0 = Disabled")
panel:ControlHelp("1 = Dropped weapons will be vaporized map-wide")
panel:AddControl("Slider",{Label = "Foreign Interaction",min = 0,max = 1,Command = "scgg_allow_others"})--5
panel:ControlHelp("0 = The weapon will not interact with foreign objects")
panel:ControlHelp("1 = The weapon will interact with foreign objects")
panel:AddControl("Label", {Text = "Foreign Interaction can cause bugs! Use at your own risk."})
panel:AddControl("Slider",{Label = "Armor Drain",min = 0,max = 2,Command = "scgg_keep_armor"})--6
panel:ControlHelp("0 = All armor will be depleted on weapon disable")
panel:ControlHelp("1 = Armor will be depleted to 100% on weapon disable")
panel:AddControl("Slider",{Label = "Claw Behavior",min = 0,max = 2,Command = "scgg_claw_mode"})--7
panel:ControlHelp("0 = Claws always closed")
panel:ControlHelp("1 = Claws always open")
panel:ControlHelp("2 = Claws in dynamic state")
panel:AddControl("Slider",{Label = "Light Settings",min = 0,max = 1,Command = "scgg_light"})--8
panel:ControlHelp("0 = The weapon will not emit a light")
panel:ControlHelp("1 = The weapon will emit a light")
panel:AddControl("Slider",{Label = "Muzzle Flash Settings",min = 0,max = 1,Command = "scgg_muzzle_flash"})--9
panel:ControlHelp("0 = The weapon will not emit a light")
panel:ControlHelp("1 = The weapon will emit a light")
panel:AddControl("Slider",{Label = "Electrocute Victims",min = 0,max = 1,Command = "scgg_zap"})--10
panel:ControlHelp("0 = The victim will not be electrocuted")
panel:ControlHelp("1 = The victim will be electrocuted")
panel:AddControl("Slider",{Label = "Electrocuted Sounds",min = 0,max = 1,Command = "scgg_zap_sound"})--11
panel:ControlHelp("0 = Electrocuted victims will not emit sounds")
panel:ControlHelp("1 = Electrocuted victims will emit sounds")
panel:AddControl("Slider",{Label = "Visual Effects",min = 0,max = 1,Command = "scgg_no_effects"})--12
panel:ControlHelp("0 = Visual Effects enabled")
panel:ControlHelp("1 = Visual Effects disabled")
panel:ControlHelp("(Holster and Deploy weapon to take effect.)")
panel:AddControl("Slider",{Label = "Equipping Sound",min = 0,max = 1,Command = "scgg_equip_sound"})--13
panel:ControlHelp("0 = The weapon will not emit a charge sound after deploying")
panel:ControlHelp("1 = The weapon will emit a charge sound after deploying")
end

function HL2AddOption()
spawnmenu.AddToolMenuOption("Utilities", "Half-Life 2", "Main Settings - HL2", "Info / Settings", "", "", HL2Options)
end
hook.Add("PopulateToolMenu", "HL2AddOption", HL2AddOption)
end