if (SERVER) then return end

CreateClientConVar( "cl_scgg_viewmodel", "models/weapons/shadowysn/c_superphyscannon.mdl", true, true, 
	"Set the viewmodel of your Super Gravity Gun. Does not affect worldmodel." )
	
CreateClientConVar( "cl_scgg_physgun_color", "0", true, true, 
	"Set the glow color to your physgun's color in first-person. Third-person is not affected." )

net.Receive("SCGG_Core_Muzzle", function()
	local core = net.ReadEntity()
	if IsValid(core) then
		core.Muzzle = true
		timer.Simple( 0.12, function() 
			if IsValid(core) then
			core.Muzzle = nil
			end
		end)
	end
end)

hook.Add("Think", "SCGG_Disable_Claw_Bug", function() 
	local grav = LocalPlayer():GetWeapon("weapon_physcannon")
	if IsValid(grav) then
		if IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "weapon_superphyscannon" then
		grav:SetNextClientThink(CurTime() + 0.2)
		else
		grav:SetNextClientThink(CurTime())
		end
	end
end)
-- ^^ Rubat still didn't apparently fix it. :|
	
if cvars.GetConVarCallbacks("cl_scgg_viewmodel", false) != nil then
	cvars.RemoveChangeCallback("cl_scgg_viewmodel", "scgg_viewmodel_cvar_checker")
end
cvars.AddChangeCallback("cl_scgg_viewmodel", function(cvar, old, new) 
	if !util.IsValidModel(new) or IsUselessModel(new) then
		--util.PrecacheModel(new)
		GetConVar("cl_scgg_viewmodel"):SetString("models/weapons/shadowysn/c_superphyscannon.mdl")
		LocalPlayer():PrintMessage( HUD_PRINTCONSOLE, "Model is not valid. If it exists, make sure it is precached serverside first." )
	end
end, "scgg_viewmodel_cvar_checker")

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