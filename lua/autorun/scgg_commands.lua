//Commands

if !ConVarExists("scgg_style") then	
   CreateConVar("scgg_style", '0', (FCVAR_GAMEDLL), "to change if the weapon is styled like Half-Life 2 or Garry's Mod.", true, true)
end

if !ConVarExists("scgg_light") then	
   CreateConVar("scgg_light", '0', (FCVAR_GAMEDLL), "to change if the weapon emits a light.", true, true)
end

if !ConVarExists("scgg_muzzle_flash") then	
   CreateConVar("scgg_muzzle_flash", '1', (FCVAR_GAMEDLL), "to change if the weapon emits a light when attacking.", true, true)
end

if !ConVarExists("scgg_zap") then	
   CreateConVar("scgg_zap", '1', (FCVAR_GAMEDLL), "to toggle victims being electrocuted.", true, true)
end

if !ConVarExists("scgg_zap_sound") then	
   CreateConVar("scgg_zap_sound", '1', (FCVAR_GAMEDLL), "to toggle electrocuted victims emitting sound.", true, true)
end

if !ConVarExists("scgg_equip_sound") then	
   CreateConVar("scgg_equip_sound", '1', (FCVAR_GAMEDLL), "to toggle sound emitted when deploying weapon.", true, true)
end

if !ConVarExists("scgg_no_effects") then	
   CreateConVar("scgg_no_effects", '0', (FCVAR_GAMEDLL), "to toggle visual effects.", true, true)
end

if !ConVarExists("scgg_enabled") then	
   CreateConVar("scgg_enabled", '1', (FCVAR_GAMEDLL), "to toggle weapon availability. 0 = any super-charged gravity gun will revert to normal. 1 = Enable, don't do anything else. 2 = Enable, alter various settings.", true, true)
end

if !ConVarExists("scgg_weapon_vaporize") then	
   CreateConVar("scgg_weapon_vaporize", '0', (FCVAR_GAMEDLL), "to toggle map-wide dropped weapon vaporization.", true, true)
end

if !ConVarExists("scgg_friendly_fire") then	
   CreateConVar("scgg_friendly_fire", '1', (FCVAR_GAMEDLL), "to toggle weapon damage against friendly NPCs.", true, true)
end

--if SERVER then
--function TheFunction(client, command, arguments, ply)
    	--ply:Give("weapon_megaphyscannon")
	--ply:StripWeapon( "weapon_physcannon" )
--end

--concommand.Add("physcannon_mega_enabled", TheFuction) end

if SERVER then
--[[function SCGG_AutoGive()
for _,ply in pairs(player.GetAll()) do
	if !ply:HasWeapon("weapon_megaphyscannon") and (GetConVar("scgg_enabled"):GetInt() >= 2) then
		ply:Give("weapon_megaphyscannon")
	end
end
end
hook.Add("Think","SCGG_Think_AutoGive",SCGG_AutoGive)--]]

--[[hook.Add("OnEntityCreated","SCGG_Weapon_Vaporize",function( entity ) 
if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
	--for _,wpn in pairs(ents.GetAll()) do
	local wpn = entity
	wpn.SCGG_Dissolving = false
		if IsValid(wpn) and wpn:IsWeapon() then
			wpn:SetKeyValue("spawnflags","2")
		end
			if IsValid(wpn) and wpn:IsValid() and wpn:IsWeapon() and !wpn:CreatedByMap() and wpn:GetClass() != ("weapon_physcannon" or "weapon_megaphyscannon") then
		for _, child in pairs(wpn:GetChildren()) do
			if child:GetClass() == "env_entity_dissolver" then
				wpn.SCGG_Dissolving = true
			end
		end
		--if !wpn:GetOwner():IsValid() and wpn.SCGG_Dissolving == false then
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
		end--
			end
		if IsValid(wpn) and wpn:IsWeapon() and wpn.SCGG_Dissolving == false then
		wpn:SetKeyValue("spawnflags","0")
		end
	--end
end
end)--]]

hook.Add("Think","SCGG_Weapon_Vaporize_Think",function() 
if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
	for _,wpn in pairs(ents.GetAll()) do
		wpn.SCGG_Dissolving = false
		if IsValid(wpn) and wpn:IsWeapon() and !wpn:GetOwner():IsValid() then
			wpn:SetKeyValue("spawnflags","2")
		end
			if IsValid(wpn) and wpn:IsValid() and ( wpn:IsWeapon() or wpn:GetClass() == "item_ammo_ar2_altfire" ) and !wpn:CreatedByMap() and wpn:GetClass() != ("weapon_physcannon" or "weapon_megaphyscannon") then
		for _, child in pairs(wpn:GetChildren()) do
			if child:GetClass() == "env_entity_dissolver" then
				wpn.SCGG_Dissolving = true
			end
		end
		
		if wpn:GetClass() == "item_ammo_ar2_altfire" then
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
end)

hook.Add("Think","SCGG_Weapon_ServerRagdoll_Think",function() 
if GetConVar("scgg_enabled"):GetInt() >= 2 then
	for _,npc in pairs(ents.GetAll()) do
		if npc:IsNPC() then
		if npc:GetShouldServerRagdoll() != true then
			npc:SetShouldServerRagdoll( true )
		end
		end
	end
end
end)

cvars.AddChangeCallback( "scgg_enabled", function( convar_name, value_old, value_new )
	if GetConVar("scgg_enabled"):GetInt() >= 2 then
		game.SetGlobalState( "super_phys_gun", GLOBAL_ON )
		if GetConVar("scgg_weapon_vaporize"):GetInt() <= 0 then
		GetConVar("scgg_weapon_vaporize"):SetInt(1)
		end
	elseif GetConVar("scgg_enabled"):GetInt() == 1 then
		game.SetGlobalState( "super_phys_gun", GLOBAL_ON )
		if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
		GetConVar("scgg_weapon_vaporize"):SetInt(0)
		end
	elseif GetConVar("scgg_enabled"):GetInt() <= 0 and game.GetGlobalState("super_phys_gun") != GLOBAL_DEAD then
		game.SetGlobalState( "super_phys_gun", GLOBAL_OFF )
		if GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
		GetConVar("scgg_weapon_vaporize"):SetInt(0)
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
HL2Options.Options["#Default"]={scgg_style="0", scgg_light="0", scgg_muzzle_flash="1", scgg_zap="1", scgg_no_effects="0"}
panel:AddControl("ComboBox",HL2Options)
panel:AddControl("Slider",{Label = "Behavior",min = 0,max = 1,Command = "scgg_style"})
--panel:ControlHelp("")
panel:ControlHelp("0 = Half-Life 2 Styled - Slower and Weaker")
panel:ControlHelp("1 = Garry's Mod Styled - Faster and Stronger")
panel:AddControl("Slider",{Label = "Light Settings",min = 0,max = 1,Command = "scgg_light"})
panel:ControlHelp("0 = The weapon will not emit a light")
panel:ControlHelp("1 = The weapon will emit a light")
panel:AddControl("Slider",{Label = "Muzzle Flash Settings",min = 0,max = 1,Command = "scgg_muzzle_flash"})
panel:ControlHelp("0 = The weapon will not emit a light")
panel:ControlHelp("1 = The weapon will emit a light")
panel:AddControl("Slider",{Label = "Electrocute Victims",min = 0,max = 1,Command = "scgg_zap"})
panel:ControlHelp("0 = The victim will not be electrocuted")
panel:ControlHelp("1 = The victim will be electrocuted")
panel:AddControl("Slider",{Label = "Visual Effects",min = 0,max = 1,Command = "scgg_no_effects"})
panel:ControlHelp("0 = Visual Effects enabled")
panel:ControlHelp("1 = Visual Effects disabled")
panel:ControlHelp("(Holster and Deploy weapon to take effect.)")
end

function HL2AddOption()
spawnmenu.AddToolMenuOption("Utilities", "Half-Life 2", "Main Settings - HL2", "Info / Settings", "", "", HL2Options)
end
hook.Add("PopulateToolMenu", "HL2AddOption", HL2AddOption)
end