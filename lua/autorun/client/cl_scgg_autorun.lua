if (SERVER) then return end

local phys_string = "weapon_physcannon"
local superphys_string = "weapon_superphyscannon"

CreateClientConVar( "cl_scgg_viewmodel", "models/weapons/shadowysn/c_superphyscannon.mdl", true, true, 
	"Set the viewmodel of your Super Gravity Gun. Does not affect worldmodel." )

CreateClientConVar( "cl_scgg_physgun_color", "0", true, true, 
	"Set the glow color to your physgun's color in first-person. Third-person is not affected." )

CreateClientConVar( "cl_scgg_effects_mode", "0", true, true, 
	"Set the effect style to emulate from a game. Third-person is not affected. 0 = Half-Life 2, 1 = Half-Life 2 Survivor" )

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

--[[hook.Add("Think", "Grav_Disable_Claw_Bug", function() 
	local grav = LocalPlayer():GetWeapon("weapon_physcannon")
	if IsValid(grav) then
		if IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "weapon_physcannon" then
		grav:SetNextClientThink(CurTime())
		else
		grav:SetNextClientThink(CurTime() + 0.2)
		end
	end
end)--]]
-- ^^ Rubat fixed it, it seems

--[[hook.Add("NetworkEntityCreated", "Grav_FadeCore_Align", function(ent) 
	
end)--]]


/*local Mat = Material( "sprites/blueflare1_noz" )
Mat:SetInt("$spriterendermode",5)
local MatWorld = Material( "sprites/blueflare1" )
MatWorld:SetInt("$spriterendermode",5)
local Main = Material( "effects/fluttercore" )
Main:SetInt("$spriterendermode",9)

hook.Add("PreDrawEffects", "Grav_PreDraw_Effects", function()
	local ply = LocalPlayer()
	local ply_active = ply:GetActiveWeapon()
	if !IsValid(ply) or !IsValid(ply_active) or ply_active:GetClass() != superphys_string then
		return
	end
	
	--Mat:SetInt("$spriterendermode",5)
	--Main:SetInt("$spriterendermode",9)
	--MatWorld:SetInt("$spriterendermode",5)
	local function CheckDrawSprite(position, width, height, color)
		if position != nil and width != nil and height != nil and color != nil then
			render.DrawSprite( position, width, height, color)
		end
	end
	local function ColorSet(alpha)
		if GetConVar("cl_scgg_physgun_color"):GetInt() > 0 then
			local getcol = LocalPlayer():GetPlayerColor():ToColor()
			return Color(getcol.r,getcol.g,getcol.b,alpha)
		end
	return nil
	end
	
	local StartPos = nil
	local StartPosO = nil
	local StartPosL = nil
	local StartPosOH = nil
	local StartPosLH = nil
	local function DoCoreEffect(active)
		local scale = math.Rand( 8, 10 )
		--local scale2 = math.Rand( 25, 27 )
		local scale2 = math.Rand( 20, 24 )
		local scale3 = math.Rand( 3, 4 )
		local scale7 = math.Rand( 12, 14 )
		
		local vm = ply:GetViewModel()
		
		if IsValid(vm) then
			local attachmentID=vm:LookupAttachment("muzzle")
			if attachmentID > 0 then
			local attachment = vm:GetAttachment(attachmentID)
			StartPos = LocalToWorld( Vector(0, 0, 0), Angle(), attachment.Pos, attachment.Ang )
			StartPos = attachment.Pos
			end
			
			local attachmentID2=vm:LookupAttachment("fork1t")
			if attachmentID2 > 0 then
			local attachment_O = vm:GetAttachment( attachmentID2 )
			StartPosO = attachment_O.Pos
			end
			
			local attachmentID3=vm:LookupAttachment("fork2t")
			if attachmentID3 > 0 then
			local attachment_L = vm:GetAttachment( attachmentID3 )
			StartPosL = attachment_L.Pos
			end
			
			local attachmentID4=vm:LookupAttachment("fork1b")
			if attachmentID4 > 0 then
			local attachment_OH = vm:GetAttachment( attachmentID4)
			StartPosOH = attachment_OH.Pos
			end
			
			local attachmentID5=vm:LookupAttachment("fork2b")
			if attachmentID5 > 0 then
			local attachment_LH = vm:GetAttachment( attachmentID5 )
			StartPosLH = attachment_LH.Pos
			end
			render.SetMaterial( Main )
			--CheckDrawSprite( StartPos, scale2, scale2, Color(255,255,255,240))
			CheckDrawSprite( StartPos, scale2, scale2, ColorSet(90) or Color(255,255,255,90))
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPosO, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale, scale, ColorSet(80) or Color(255,255,255,80))
		end
	end
	
	DoCoreEffect(false)
end)*/

	
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