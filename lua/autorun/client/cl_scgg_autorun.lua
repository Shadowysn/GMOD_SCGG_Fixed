if (SERVER) then return end

local phys_string = "weapon_physcannon"
local superphys_string = "weapon_superphyscannon"

CreateClientConVar( "cl_scgg_viewmodel", "models/weapons/shadowysn/c_superphyscannon.mdl", true, true, 
	"Set the viewmodel of your Super Gravity Gun. Does not affect worldmodel." )

CreateClientConVar( "cl_scgg_physgun_color", "0", true, true, 
	"Set the glow color to your physgun's color in first-person. Third-person is not affected. 1 = Weapon color, 2 = Physgun color" )

CreateClientConVar( "cl_scgg_effects_mode", "0", true, true, 
	"Set the effect style to emulate from a game. Third-person is not affected. 0 = Half-Life 2, 1 = Half-Life 2 Survivor" )

local GetRag = {}

net.Receive("SCGG_Ragdoll_GetPlayerColor", function() 
	local rag = net.ReadInt(32)
	local ply = net.ReadInt(32)
	local col = net.ReadVector()
	if !col or col == nil then return end
	GetRag = {rag = rag, ply = ply, col = col}
end)

hook.Add("NetworkEntityCreated","SCGG_Ragdoll_SetPlayerColor", function(ent)
	if not GetRag.rag then return end
	if GetRag.rag == ent:EntIndex() then
		local getcol = GetRag.col
		local getrag_ply = Entity(GetRag.ply)
		local getrag_rag = Entity(GetRag.rag)
		getrag_rag.GetPlayerColor = function(self) return getcol end
		
		if IsValid(getrag_ply) and getrag_ply:GetModel() == getrag_rag:GetModel() then
			getrag_rag:SnatchModelInstance(getrag_ply)
		end
		
		GetRag = {}
	end
end)

local function DoParticleEffects(entity)
	--[[local coreattachmentID = entity:LookupAttachment("core")
	if coreattachmentID <= 0 then return end
	local coreattachment = entity:GetAttachment(coreattachmentID)
	if coreattachment == nil or coreattachment.Pos == nil then return end
	local pos = coreattachment.Pos--]]
	
	local emitter = nil
	local timer_max = 110
	local timer_name = "SCGG_Charging_Particles_"..entity:EntIndex()
	timer.Create(timer_name, 0.05, timer_max, function()
		if IsValid(entity) then
			local coreattachmentID = entity:LookupAttachment("core")
			if !coreattachmentID or coreattachmentID <= 0 then
				coreattachmentID = entity:LookupAttachment("muzzle")
			end
			local coreattachment = nil
			local pos = nil
			if coreattachmentID > 0 then
				coreattachment = entity:GetAttachment(coreattachmentID)
				pos = coreattachment.Pos
			else
				pos = entity:GetPos()
				coreattachment = { Pos = pos }
			end
			
			if coreattachment != nil and coreattachment.Pos != nil then
				local fadePerc = 1.0
			
				local vecSkew = pos
			
				local spriteScale = 1.0
				spriteScale = math.Clamp( spriteScale, 0.75, 1.0 )
			
				local numParticles = math.Clamp( 4.0 * fadePerc, 1, 3 )
				
				if numParticles <= 0 then return end
				
				-- Orange particles supposed to surround the gun
				local numHitBoxSets = entity:GetHitboxSetCount() --print("numHitBoxSets: "..numHitBoxSets)
				for hboxset = 0, numHitBoxSets - 1 do
					--print("hboxset: "..hboxset)
					local numHitBoxes = entity:GetHitBoxCount( hboxset ) --print("numHitBoxes: "..numHitBoxes)
					
					for hitbox = 0, numHitBoxes - 1 do
						--print("hitbox: "..hitbox)
						--local bone = entity:GetHitBoxBone(hitbox, hboxset )
			
						--print( "Hit box set " .. hboxset .. ", hitbox " .. hitbox .. " is attached to bone " .. entity:GetBoneName(bone) )
						
						local xDir, yDir = entity:GetHitBoxBounds(hitbox, hboxset)
						
						local xScale = xDir:GetNormalized() * 0.75
						local yScale = yDir:GetNormalized() * 0.75
						
						for j = 0, numParticles do
							local offset = (xDir * math.Rand( -xScale*0.5, xScale*0.5 )) + (yDir * math.Rand( -yScale*0.5, yScale*0.5 ))

							offset = offset + vecSkew
							local emitter2 = ParticleEmitter(offset, false)

							local sParticle = emitter2:Add( "effects/combinemuzzle1", offset )
							--print(sParticle)
							if sParticle != nil then
								local startSize = 16.0 * spriteScale
								
								sParticle:SetVelocity(pos-offset)
								sParticle:SetStartSize(startSize)
								sParticle:SetDieTime(0.2)
								sParticle:SetLifeTime(0.0)
					
								sParticle:SetRoll(math.random(0, 360))
								sParticle:SetRollDelta(math.Rand(-2.0, 2.0))
					
								local alpha = 40
								
								sParticle:SetColor(alpha, alpha, alpha)
								sParticle:SetStartAlpha(alpha)
								sParticle:SetEndAlpha(0)
								sParticle:SetEndSize(startSize * 2)
								
								sParticle:SetGravity( Vector( 0, 0, 0 ) )
							end
							
							emitter2:Finish()
						end
					end
				end
				
				local emitter = ParticleEmitter(pos, false)
				
				-- Small core particles
				local jReps = 16
				print(timer.RepsLeft(timer_name))
				if timer.RepsLeft(timer_name) <= 5 then jReps = jReps * 3 end
				for j = 0, jReps do
					local offset = pos + VectorRand( -24.0, 24.0 )

					local sParticle = emitter:Add( "effects/strider_muzzle", offset )

					if sParticle != nil then
						sParticle:SetVelocity((pos-offset)*8)
						sParticle:SetDieTime(0.2)
						sParticle:SetLifeTime(0.0)

						sParticle:SetRoll(math.random(0, 360))
						sParticle:SetRollDelta(0.0)

						local alpha = 255

						sParticle:SetColor(alpha, alpha, alpha)
						sParticle:SetStartAlpha(alpha)
						sParticle:SetEndAlpha(0)

						sParticle:SetStartSize(math.Rand( 1.0, 2.0 ))
						sParticle:SetEndSize(0)
					end
				end

				emitter:Finish()
			end
		end
	end)
end

local function ScreenScaleH(n)
	return n * (ScrH() / 480)
end

surface.CreateFont("SCGG_Wep_Font", {
	font = "HalfLife2",
	size = ScreenScaleH(64),
	weight = 0,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	additive = true,
})

surface.CreateFont("SCGG_Wep_Font_Glow", {
	font = "HalfLife2",
	size = ScreenScaleH(64),
	weight = 0,
	blursize = ScreenScaleH(4),
	scanlines = 3,
	antialias = true,
	additive = true,
})

killicon.AddFont( "weapon_superphyscannon", "HL2MPTypeDeath", ",", Color( 255, 80, 0, 255 ) )

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

net.Receive("SCGG_Charging_Particles", function()
	local entity = net.ReadEntity()
	if IsValid(entity) then
		--timer.Create("SCGG_Charging_Particles_"..entity:EntIndex(), 0.1, 100, function()
			--if !IsValid(entity) then return end
			DoParticleEffects(entity)
		--end)
	end
end)
-- lua_run for _,ent in ipairs(ents.GetAll()) do if ent:GetClass() == "weapon_physcannon" then net.Start("SCGG_Charging_Particles") net.WriteEntity(ent) net.Broadcast() end end

--[[hook.Add("Think", "yay_temp_temp_temp", function() 
	for _,ent in pairs(ents.GetAll()) do
		if IsValid(ent) and ent:GetClass() == "weapon_physcannon" then
			ent:SetSaveValue("m_bPhyscannonState", true)
		end
	end
end)--]]

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
	
if cvars.GetConVarCallbacks("cl_scgg_viewmodel", false) != nil then
	cvars.RemoveChangeCallback("cl_scgg_viewmodel", "scgg_viewmodel_cvar_checker")
end
cvars.AddChangeCallback("cl_scgg_viewmodel", function(cvar, old, new) 
	if !util.IsValidModel(new) or IsUselessModel(new) then
		--util.PrecacheModel(new)
		GetConVar("cl_scgg_viewmodel"):SetString("models/weapons/shadowysn/c_superphyscannon.mdl")
		LocalPlayer():PrintMessage( HUD_PRINTCONSOLE, "Model is not valid. If it exists, make sure it is precached serverside first.\n" )
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
	panel:ControlHelp("Shadowysn - Further Code and Error Fixes")
	
	HL2Options.Options["#Default"] = {
		scgg_enabled="1", 
		scgg_allow_enablecvar_modify="0", 
		scgg_cone="1", 
		scgg_style="0", 
		scgg_friendly_fire="1", 
		scgg_affect_players="1", 
		scgg_weapon_vaporize="0", 
		scgg_primary_extra="0",
		scgg_allow_others="0", 
		scgg_keep_armor="0", 
		scgg_claw_mode="1", 
		scgg_light="0", 
		scgg_muzzle_flash="1", 
		scgg_zap="1", 
		scgg_zap_sound="1", 
		scgg_deploy_style="1", 
		scgg_no_effects="0", 
		scgg_equip_sound="0",
		scgg_normal_switch="1",
		scgg_vanilla_disable="1",
		scgg_extra_function="1"
	}
	HL2Options.Options["#Vanilla"] = {
		scgg_enabled="2", 
		scgg_allow_enablecvar_modify="0", 
		scgg_cone="0", 
		scgg_style="0", 
		scgg_friendly_fire="0", 
		scgg_affect_players="0", 
		scgg_weapon_vaporize="0", 
		scgg_primary_extra="0",
		scgg_allow_others="0", 
		scgg_keep_armor="0", 
		scgg_claw_mode="0", 
		scgg_light="0", 
		scgg_muzzle_flash="0", 
		scgg_zap="0", 
		scgg_zap_sound="0", 
		scgg_deploy_style="0", 
		scgg_no_effects="0", 
		scgg_equip_sound="0",
		scgg_normal_switch="0",
		scgg_vanilla_disable="0",
		scgg_extra_function="0"
	}
	
	panel:AddControl("ComboBox",HL2Options)
	
	panel:AddControl("Slider",{Label = "Weapon Status",min = 0,max = 2,Command = "scgg_enabled"})--1
	panel:ControlHelp("0 = The weapon will be disabled")
	panel:ControlHelp("1 = The weapon will be enabled")
	panel:ControlHelp("2 = The weapon will be enabled, with other changes to the map")
	
	panel:AddControl("Toggle",{Label = "Allow Map-Altering Status",min = 0,max = 1,Command = "scgg_allow_enablecvar_modify"})--2
	--panel:ControlHelp("")
	panel:ControlHelp("0 = Prevent altering")
	panel:ControlHelp("1 = Allow altering")
	
	panel:AddControl("Toggle",{Label = "Cone Detection",min = 0,max = 1,Command = "scgg_cone"})--3
	--panel:ControlHelp("")
	panel:ControlHelp("0 = Disabled")
	panel:ControlHelp("1 = Enabled")
	
	panel:AddControl("Toggle",{Label = "Behavior",min = 0,max = 1,Command = "scgg_style"})--4
	--panel:ControlHelp("")
	panel:ControlHelp("0 = Half-Life 2 Styled - Slower and Weaker")
	panel:ControlHelp("1 = Garry's Mod Styled - Faster and Stronger")
	
	panel:AddControl("Toggle",{Label = "Friendly Fire (NPC)",min = 0,max = 1,Command = "scgg_friendly_fire"})--5
	panel:ControlHelp("0 = Friendly NPCs will not be directly targeted")
	panel:ControlHelp("1 = Friendly NPCs will be directly targeted")
	
	panel:AddControl("Toggle",{Label = "Affect Players",min = 0,max = 1,Command = "scgg_affect_players"})--6
	panel:ControlHelp("0 = Players will not be directly killed")
	panel:ControlHelp("1 = Players can be directly killed")
	
	panel:AddControl("Slider",{Label = "Weapon Vaporization",min = 0,max = 2,Command = "scgg_weapon_vaporize"})--7
	panel:ControlHelp("0 = Disabled")
	panel:ControlHelp("1 = Dropped weapons vaporized map-wide every tick")
	panel:ControlHelp("2 = Dropped weapons vaporized map-wide every time an NPC or Player dies")
	
	panel:AddControl("Toggle",{Label = "Extra Primary Attack Behavior",min = 0,max = 1,Command = "scgg_primary_extra"})--8
	--panel:ControlHelp("")
	panel:ControlHelp("0 = None")
	panel:ControlHelp("1 = Gatling primary fire with individual M1 spam, seen in HL2:EP1")
	
	panel:AddControl("Toggle",{Label = "Access to Normal",min = 0,max = 1,Command = "scgg_normal_switch"})--9
	panel:ControlHelp("0 = The normal version of the Gravity Gun will be inaccessible")
	panel:ControlHelp("1 = The normal version of the Gravity Gun will be accessible")
	
	panel:AddControl("Toggle",{Label = "Foreign Interaction",min = 0,max = 1,Command = "scgg_allow_others"})--10
	panel:ControlHelp("0 = The weapon will not interact with foreign objects")
	panel:ControlHelp("1 = The weapon will interact with foreign objects")
	panel:AddControl("Label", {Text = "Foreign Interaction can cause bugs! Use at your own risk."})
	
	panel:AddControl("Slider",{Label = "Armor Drain",min = 0,max = 2,Command = "scgg_keep_armor"})--11
	panel:ControlHelp("0 = All armor will be depleted on weapon disable")
	panel:ControlHelp("1 = Armor will be depleted to 100% on weapon disable")
	panel:ControlHelp("2 = Armor will not deplete")
	
	panel:AddControl("Slider",{Label = "Claw Behavior",min = 0,max = 2,Command = "scgg_claw_mode"})--12
	panel:ControlHelp("0 = Claws always closed")
	panel:ControlHelp("1 = Claws always open")
	panel:ControlHelp("2 = Claws in dynamic state")
	
	panel:AddControl("Toggle",{Label = "Light Settings",min = 0,max = 1,Command = "scgg_light"})--13
	panel:ControlHelp("0 = The weapon will not emit a light")
	panel:ControlHelp("1 = The weapon will emit a light")
	
	panel:AddControl("Toggle",{Label = "Muzzle Flash Settings",min = 0,max = 1,Command = "scgg_muzzle_flash"})--14
	panel:ControlHelp("0 = The weapon will not emit a light")
	panel:ControlHelp("1 = The weapon will emit a light")
	
	panel:AddControl("Toggle",{Label = "Electrocute Victims",min = 0,max = 1,Command = "scgg_zap"})--15
	panel:ControlHelp("0 = The victim will not be electrocuted")
	panel:ControlHelp("1 = The victim will be electrocuted")
	
	panel:AddControl("Toggle",{Label = "Electrocuted Sounds",min = 0,max = 1,Command = "scgg_zap_sound"})--16
	panel:ControlHelp("0 = Electrocuted victims will not emit sounds")
	panel:ControlHelp("1 = Electrocuted victims will emit sounds")
	
	panel:AddControl("Toggle",{Label = "Deploy Behavior",min = 0,max = 1,Command = "scgg_deploy_style"})--17
	--panel:ControlHelp("")
	panel:ControlHelp("0 = HL2 speed")
	panel:ControlHelp("1 = GMOD speed (sv_defaultdeployspeed)")
	
	panel:AddControl("Toggle",{Label = "No Visual Effects",min = 0,max = 1,Command = "scgg_no_effects"})--18
	panel:ControlHelp("0 = Visual Effects enabled")
	panel:ControlHelp("1 = Visual Effects disabled")
	
	panel:AddControl("Toggle",{Label = "Equipping Sound",min = 0,max = 1,Command = "scgg_equip_sound"})--19
	panel:ControlHelp("0 = The weapon will not emit a charge sound after deploying")
	panel:ControlHelp("1 = The weapon will emit a charge sound after deploying")
	
	panel:ControlHelp("")
	panel:ControlHelp("")
	panel:AddControl("Label", {Text = "August-2020-SCGG-related options"})
	panel:ControlHelp("")
	
	panel:AddControl("Toggle",{Label = "Disable Vanilla SCGG",min = 0,max = 1,Command = "scgg_vanilla_disable"})--20
	panel:ControlHelp("0 = Vanilla GMOD's SCGG will be disabled")
	panel:ControlHelp("1 = Vanilla GMOD's SCGG will be enabled")
	
	panel:AddControl("Toggle",{Label = "Mod SCGG's Extra Functions",min = 0,max = 1,Command = "scgg_extra_function"})--21
	panel:ControlHelp("0 = Extra functions, like giving the mod SCGG if scgg_enabled is 2, will be disabled")
	panel:ControlHelp("1 = Extra functions, like giving the mod SCGG if scgg_enabled is 2, will be enabled")
end

function HL2AddOption()
	spawnmenu.AddToolMenuOption("Utilities", "Half-Life 2", "Main Settings - HL2", "Info / Settings", "", "", HL2Options)
end
hook.Add("PopulateToolMenu", "HL2AddOption", HL2AddOption)
