//Commands

if !ConVarExists("scgg_style") then	
   CreateConVar("scgg_style", '0', (FCVAR_GAMEDLL), "to change if the weapon is styled like Half-Life 2 or Garry's Mod.", true, true)
end--1

if !ConVarExists("scgg_light") then	
   CreateConVar("scgg_light", '0', (FCVAR_GAMEDLL), "to change if the weapon emits a light.", true, true)
end--2

if !ConVarExists("scgg_muzzle_flash") then	
   CreateConVar("scgg_muzzle_flash", '1', (FCVAR_GAMEDLL), "to change if the weapon emits a light when attacking.", true, true)
end--3

if !ConVarExists("scgg_zap") then	
   CreateConVar("scgg_zap", '1', (FCVAR_GAMEDLL), "to toggle victims being electrocuted.", true, true)
end--4

if !ConVarExists("scgg_allow_others") then	
   CreateConVar("scgg_allow_others", '0', (FCVAR_GAMEDLL), "to allow weapon interaction of other objects, including addons. (WILL have a chance to cause bugs.)", true, true)
end--5

if !ConVarExists("scgg_zap_sound") then	
   CreateConVar("scgg_zap_sound", '0', (FCVAR_GAMEDLL), "to toggle electrocuted victims emitting sound.", true, true)
end--6

if !ConVarExists("scgg_equip_sound") then	
   CreateConVar("scgg_equip_sound", '0', (FCVAR_GAMEDLL), "to toggle sound emitted when deploying weapon.", true, true)
end--7

if !ConVarExists("scgg_no_effects") then	
   CreateConVar("scgg_no_effects", '0', (FCVAR_GAMEDLL), "to toggle visual effects.", true, true)
end--8

if !ConVarExists("scgg_enabled") then	
   CreateConVar("scgg_enabled", '1', (FCVAR_GAMEDLL), "to toggle weapon availability. 0 = any super-charged gravity gun will revert to normal. 1 = Enable, don't do anything else. 2 = Enable, alter various settings.", true, true)
end--9

if !ConVarExists("scgg_weapon_vaporize") then	
   CreateConVar("scgg_weapon_vaporize", '0', (FCVAR_GAMEDLL), "to toggle map-wide dropped weapon vaporization.", true, true)
end--10

if !ConVarExists("scgg_keep_armor") then	
   CreateConVar("scgg_keep_armor", '0', (FCVAR_GAMEDLL), "to keep armor after weapon disable. 0 = remove all armor. 1 = lower to 100. 2 = keep armor.", true, true)
end--11

if !ConVarExists("scgg_friendly_fire") then	
   CreateConVar("scgg_friendly_fire", '1', (FCVAR_GAMEDLL), "to toggle direct weapon interaction against friendly NPCs.", true, true)
end--12

--if SERVER then
--function TheFunction(client, command, arguments, ply)
    	--ply:Give("weapon_superphyscannon")
	--ply:StripWeapon( "weapon_physcannon" )
--end

--concommand.Add("physcannon_mega_enabled", TheFuction) end

if SERVER then

--[[hook.Add("PlayerDroppedWeapon","SCGG_Weapon_CheckDrop",function( owner, wep )
if GetConVar("scgg_weapon_vaporize"):GetInt() >= 2 then
	if wep:GetClass() == "weapon_physcannon" then
		local superphys = "weapon_superphyscannon"
		if owner:HasWeapon(superphys) == true then
			owner:StripWeapon(superphys)
			print("heybab")
		end
	end
end
end)--]]
--cvars.AddChangeCallback( "scgg_weapon_vaporize", function( convar_name, value_old, value_new )
hook.Add("Think","SCGG_Weapon_Vaporize_Think",function() 
if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then

	for _,wpn in pairs(ents.GetAll()) do
		wpn.SCGG_Dissolving = false
		if IsValid(wpn) and wpn:IsWeapon() and !wpn:GetOwner():IsValid() then
			wpn:SetKeyValue("spawnflags","2")
		end
			if IsValid(wpn) and wpn:IsValid() and ( wpn:IsWeapon() or wpn:GetClass() == "item_ammo_ar2_altfire" ) and !wpn:CreatedByMap() and wpn:GetClass() != ("weapon_physcannon" or "weapon_superphyscannon") then
		for _, child in pairs(wpn:GetChildren()) do
			if child:GetClass() == "env_entity_dissolver" then
				wpn.SCGG_Dissolving = true
			end
		end
		
		if GetConVar("scgg_enabled"):GetInt() >= 2 and wpn:GetClass() == "item_ammo_ar2_altfire" then
		local fakeitem = ents.Create("prop_physics_override")
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
		local name = "SCGG_Dissolving_Item_"..math.random()
		fakeitem:SetName( name )
		dissolver:Fire( "Dissolve", name, 0 )
		dissolver:Fire( "Kill", "", 0.05 )
		elseif !wpn:GetOwner():IsValid() and wpn.SCGG_Dissolving == false then
		wpn:SetKeyValue("spawnflags","2")
		local dissolver = ents.Create( "env_entity_dissolver" )
		dissolver:SetPos( wpn:LocalToWorld(wpn:OBBCenter()) )
		dissolver:SetKeyValue( "dissolvetype", 0 )
		dissolver:Spawn()
		dissolver:Activate()
		local name = "SCGG_Dissolving_Weapon_"..math.random()
		wpn:SetName( name )
		dissolver:Fire( "Dissolve", name, 0 )
		dissolver:Fire( "Kill", "", 0.05 )
		end
			end
		if IsValid(wpn) and wpn:IsWeapon() and !wpn:GetOwner():IsValid() and wpn.SCGG_Dissolving == false then
		wpn:SetKeyValue("spawnflags","0")
		end
	end
end
if game.GetGlobalState( "super_phys_gun") == GLOBAL_ON and GetConVar("scgg_enabled"):GetInt() != 1 then
	if GetConVar("scgg_enabled"):GetInt() <= 0 then
	GetConVar("scgg_enabled"):SetInt(2)
	end
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
	end--]]
	for _,foundply in pairs(player.GetAll()) do
		for _,weap in pairs( foundply:GetWeapons() ) do
			if foundply:Alive() and weap:GetClass() == "weapon_physcannon" then--or weap:GetClass() == "weapon_superphyscannon" then
				if !foundply:HasWeapon("weapon_superphyscannon") then
				foundply:Give("weapon_superphyscannon")
				end
				--[[if !foundply:HasWeapon("weapon_physcannon") then
				foundply:Give("weapon_physcannon")
				end--]]
			end
		end
	end
end
if game.GetGlobalState( "super_phys_gun") == GLOBAL_OFF and GetConVar("scgg_enabled"):GetInt() != 0 then
	GetConVar("scgg_enabled"):SetInt(0)
end
end)

--end )

--[[hook.Add("Think","SCGG_Weapon_ServerRagdoll_Think",function() 
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

cvars.AddChangeCallback( "scgg_enabled", function( convar_name, value_old, value_new )
	if GetConVar("scgg_enabled"):GetInt() >= 2 then
		game.SetGlobalState( "super_phys_gun", GLOBAL_ON )
		if GetConVar("scgg_weapon_vaporize"):GetInt() <= 0 then
		GetConVar("scgg_weapon_vaporize"):SetInt(1)
		end
	end
	if GetConVar("scgg_enabled"):GetInt() == 1 then
		game.SetGlobalState( "super_phys_gun", GLOBAL_ON )
		if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
		GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
	end
	if GetConVar("scgg_enabled"):GetInt() <= 0 then
		game.SetGlobalState( "super_phys_gun", GLOBAL_OFF )
		if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
		GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
		for _,ply in pairs(player.GetAll()) do
			local getcvar = GetConVar("scgg_keep_armor"):GetInt()
			if getcvar <= 1 and ply:IsValid() and ply:Alive() and ply:Armor() >= 1 then
				local armorval_0 = ply:Armor()+1
				local armor_countdown = ply:Armor()
				if getcvar == 1 and ply:Armor() <= 100 then return end
				timer.Create( "SCGG_Armor_Lower", 0.01, armorval_0/2, function()
					if (ply:Armor() % 2 == 0) then
					armor_countdown = armor_countdown-2
					else
					armor_countdown = armor_countdown-1
					end
					if getcvar <= 0 and ply:Armor() <= 0 
					or getcvar == 1 and ply:Armor() <= 100
					then 
					timer.Remove("SCGG_Armor_Lower") 
					return 
					end
					ply:SetArmor( armor_countdown )
				end )
			end
		end
	end
end, "SCGG_Disable_GlobalState" )

end

if CLIENT then

local function HL2Options(panel)
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
HL2Options.Options["#Default"]={scgg_enabled="1", scgg_style="0", scgg_friendly_fire="1", scgg_weapon_vaporize="0", scgg_allow_others="0", scgg_keep_armor="0", scgg_light="0", scgg_muzzle_flash="1", scgg_zap="1", scgg_zap_sound="0", scgg_no_effects="0", scgg_equip_sound="0"}
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
panel:ControlHelp("2 = Armor will not be depleted")
panel:AddControl("Slider",{Label = "Light Settings",min = 0,max = 1,Command = "scgg_light"})--7
panel:ControlHelp("0 = The weapon will not emit a light")
panel:ControlHelp("1 = The weapon will emit a light")
panel:AddControl("Slider",{Label = "Muzzle Flash Settings",min = 0,max = 1,Command = "scgg_muzzle_flash"})--8
panel:ControlHelp("0 = The weapon will not emit a light")
panel:ControlHelp("1 = The weapon will emit a light")
panel:AddControl("Slider",{Label = "Electrocute Victims",min = 0,max = 1,Command = "scgg_zap"})--9
panel:ControlHelp("0 = The victim will not be electrocuted")
panel:ControlHelp("1 = The victim will be electrocuted")
panel:AddControl("Slider",{Label = "Electrocuted Sounds",min = 0,max = 1,Command = "scgg_zap_sound"})--10
panel:ControlHelp("0 = Electrocuted victims will not emit sounds")
panel:ControlHelp("1 = Electrocuted victims will emit sounds")
panel:AddControl("Slider",{Label = "Visual Effects",min = 0,max = 1,Command = "scgg_no_effects"})--11
panel:ControlHelp("0 = Visual Effects enabled")
panel:ControlHelp("1 = Visual Effects disabled")
panel:ControlHelp("(Holster and Deploy weapon to take effect.)")
panel:AddControl("Slider",{Label = "Equipping Sound",min = 0,max = 1,Command = "scgg_equip_sound"})--12
panel:ControlHelp("0 = The weapon will not emit a charge sound after deploying")
panel:ControlHelp("1 = The weapon will emit a charge sound after deploying")
end

function HL2AddOption()
spawnmenu.AddToolMenuOption("Utilities", "Half-Life 2", "Main Settings - HL2", "Info / Settings", "", "", HL2Options)
end
hook.Add("PopulateToolMenu", "HL2AddOption", HL2AddOption)
end