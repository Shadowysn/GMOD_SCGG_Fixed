if SERVER then return end

include ("shared.lua")

SWEP.Category			= "Half-Life 2"

SWEP.PrintName			= "SUPER GRAVITY GUN"
SWEP.Slot			= 1
SWEP.SlotPos			= 0
SWEP.IconLetter			= "k"
SWEP.ViewModelFOV =		GetConVar("viewmodel_fov"):GetFloat()

SWEP.Slot				= 0
SWEP.SlotPos 			= 0
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair 		= true

SWEP.Author			= "ErrolLiamP, Î¤yler Blu, QuentinDylanP, pillow, Shadowysn"
SWEP.Purpose			= ""
SWEP.Instructions		= ""
SWEP.BounceWeaponIcon	= false
SWEP.DrawWeaponInfoBox	= false

--SWEP.WepSelectIcon = surface.GetTextureID("weapons/Megaphyscannon")

--[[surface.CreateFont("SCGG_Wep_Font", {
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
	scanlines = 2,
	antialias = true,
	additive = true,
})--]]

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
	surface.SetTextColor(255, 235, 0, alpha)
	
	surface.SetFont("SCGG_Wep_Font")
	local w, h = surface.GetTextSize("m")
	
	surface.SetTextPos(x + (wide / 2) - (w / 2), y + (tall / 2) - (h / 2))
	surface.DrawText("m")
	
	surface.SetTextPos(x + (wide / 2) - (w / 2), y + (tall / 2) - (h / 2))
	surface.SetFont("SCGG_Wep_Font_Glow")
	surface.DrawText("m")
end

--[[local GetRag = {} -- For some infathomable reason, putting this in cl_scgg_autorun doesn't work.

net.Receive("SCGG_Ragdoll_GetPlayerColor", function() 
	local rag = net.ReadInt(32)
	local ply = net.ReadInt(32)
	local col = net.ReadVector()
	if !col or col == nil then return end
	GetRag = {rag = rag, ply = ply, col = col}
end)

hook.Add("NetworkEntityCreated","SCGG_Ragdoll_SetPlayerColor",function(ent)
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
end)--]]

include("cl_glow_spr.lua")

function SWEP:Initialize() -- Initialization stuff.
	self:SetWeaponHoldType( self.HoldType )
	self:SetSkin(1)
end

local function PoseArithmetic(ent, pose_str, number)
	local pose = ent:GetPoseParameter(pose_str)
	local num_min, num_max = ent:GetPoseParameterRange(pose)
	--print(num_max)
	return number
	--return math.Remap(number, 0, 1, num_min, num_max)
end

local function GetVMPoses(wep)
	local active_string = "active"
	local ViewModel = wep.Owner:GetViewModel()
	local WorldModel = wep
	
	--[[local vm_active_pose = 0
	local wm_active_pose = 0
	--local vm_min, vm_max = 0
	--local wm_min, wm_max = 0
	if IsValid(ViewModel) then
		local vm_active_pose = ViewModel:GetPoseParameter(active_string)
		--vm_min, vm_max = ViewModel:GetPoseParameterRange(vm_active_pose)
		vm_active_pose = PoseArithmetic(ViewModel, active_string, vm_active_pose)
	end
	if IsValid(WorldModel) then
		local wm_active_pose = WorldModel:GetPoseParameter(active_string)
		--wm_min, wm_max = ViewModel:GetPoseParameterRange(vm_active_pose)
		wm_active_pose = PoseArithmetic(WorldModel, active_string, wm_active_pose)
	end--]]
	return ViewModel, WorldModel, --[[vm_active_pose, wm_active_pose,--]] active_string
end

function SWEP:AdjustClaws()
	local function CalculateFrameAffectedNum(in_num)
		local frametime = FrameTime()
		
		local result = in_num + frametime
		
		return result
	end
	
	if self.PoseParam < 0 then
		self.PoseParam = 0
	elseif self.PoseParam > 1 then
		self.PoseParam = 1
	end
	if self.PoseParamDesired < self.PoseParam then -- For some reason, claw sounds from PlayClawSound are reversed here
		if self.PoseParam >= 1 then
			self:PlayClawSound(true) -- Should play open sound
		end
		local result = nil
		if game.SinglePlayer() then
			result = CalculateFrameAffectedNum(0.0025)
		else
			result = CalculateFrameAffectedNum(0.02)
		end
		self.PoseParam = self.PoseParam-result
	elseif self.PoseParamDesired > self.PoseParam then
		if self.PoseParam <= 0 then
			self:PlayClawSound(false) -- Should play close sound
		end
		local result = nil
		if game.SinglePlayer() then
			result = CalculateFrameAffectedNum(0.05)
		else
			result = CalculateFrameAffectedNum(0.1)
		end
		self.PoseParam = self.PoseParam+result
	end
	
	local ViewModel, WorldModel, --[[vm_active_pose, wm_active_pose,--]] active_string = GetVMPoses(self)
	
	if (ViewModel and IsValid(ViewModel)) or (WorldModel and IsValid(WorldModel)) then 
		if !IsValid(self) or !IsValid(self.Owner) or !self.Owner:Alive() then return end
		if IsValid(ViewModel) then -- Viewmodel claws are moved here.
			ViewModel:SetPoseParameter(active_string, self.PoseParam)
			ViewModel:InvalidateBoneCache()
		end
		if IsValid(WorldModel) then -- Worldmodel claws are moved here.
			WorldModel:SetPoseParameter(active_string, self.PoseParam)
			WorldModel:InvalidateBoneCache()
		end
	end
end

function SWEP:OpenClaws( boolean ) -- Open claws function.
	if !IsValid(self.Owner) or !self.Owner:Alive() then return end
	
	timer.Remove("scgg_claw_close_delay"..self:EntIndex()) -- Remove the delayed claw close timer often created by 'scgg_claw_mode 2'.
	
	if self.PoseParamDesired >= 1 then return end
	
	--[[if (self.PoseParam <= 0 and self.PoseParamDesired <= 0) and !IsValid(self:GetTP()) and boolean then -- Sound emitting!
		self:PlayClawSound(false) -- Should play open sound
	end--]]
	
	self.PoseParamDesired = 1
end
function SWEP:CloseClaws( boolean ) -- Close claws function.
	if !IsValid(self.Owner) or !self.Owner:Alive() or self.PoseParamDesired <= 0 then return end
	
	--[[if (self.PoseParam >= 1 and self.PoseParamDesired >= 1) and !IsValid(self:GetTP()) and boolean then -- Sound emitting!
		self:PlayClawSound(true) -- Should play close sound
	end--]]
	
	self.PoseParamDesired = 0
end

function SWEP:PlayClawSound(isClose)
	local snd_str = "Weapon_PhysCannon.OpenClaws"
	if isClose == true then
		snd_str = "Weapon_PhysCannon.CloseClaws"
	end
	--print(self.ActiveSnd)
	
	self:StopClawSound()
	
	local temp_snd = CreateSound( self, snd_str )
	self.ActiveSnd = temp_snd
	temp_snd:Play()
end
function SWEP:StopClawSound()
	if self.ActiveSnd != nil and self.ActiveSnd:IsPlaying() then
		self.ActiveSnd:Stop()
	end
end

function SWEP:Deploy()
	--[[print("didit")
	if ConVarExists("cl_scgg_viewmodel") then
		local newview_info = GetConVar("cl_scgg_viewmodel"):GetString()
		if util.IsValidModel(newview_info) and self.ViewModel != newview_info then
			-- Attempt to set the chosen cl_scgg_viewmodel model.
			self.ViewModel = newview_info
			local vm = self.Owner:GetViewModel()
			vm:SetWeaponModel(newview_info, self)
			vm:InvalidateBoneCache()
			print("didit")
		end
	end--]]
end

function SWEP:Think()
	if ConVarExists("cl_scgg_viewmodel") then
		local newview_info = GetConVar("cl_scgg_viewmodel"):GetString()
		if util.IsValidModel(newview_info) and self.ViewModel != newview_info then
			-- Attempt to set the chosen cl_scgg_viewmodel model.
			self.ViewModel = newview_info
			local vm = self.Owner:GetViewModel()
			vm:SetWeaponModel(newview_info, self)
			vm:InvalidateBoneCache()
		end
	end
	
	--local vimodel = self.Owner:GetViewModel()
	--print(vimodel:IsSequenceFinished())
	--print(vimodel:GetSequenceActivityName(vimodel:GetSequence()))
	
	if ConVarExists("scgg_light") and GetConVar("scgg_light"):GetBool() then
		if !self.Weapon:GetNWBool("Glow") then
			if !self.Owner:LookupBone("ValveBiped.Bip01_R_Hand") then return end
			local dlight = DynamicLight("lantern_"..self:EntIndex()) -- Create the light.
			if dlight then
				dlight.Pos = self.Owner:GetBonePosition(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"))
				dlight.r = 200
				dlight.g = 255
				dlight.b = 255
				dlight.Brightness = 0.1
				dlight.Size = 70
				dlight.DieTime = CurTime() + 0.0001
				--dlight.Style = 0
			end
		else
			if !self.Owner:LookupBone("ValveBiped.Bip01_R_Hand") then return end
			local dlight = DynamicLight("lantern_"..self:EntIndex())
			if dlight then
				dlight.Pos = self.Owner:GetBonePosition(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"))
				dlight.r = 255
				dlight.g = 255
				dlight.b = 255
				dlight.Brightness = 0.3
				dlight.Size = 100
				dlight.DieTime = CurTime() + 0.0001
				--dlight.Style = 0
			end
		end
	end
	
	if self.PoseParam == nil then
		self.PoseParam = 0
	end
	if self.PoseParamDesired == nil then
		self.PoseParamDesired = 0
	end
	self:AdjustClaws()
	
	local clawCvar = 1
	if ConVarExists("scgg_claw_mode") then
		clawCvar = GetConVar("scgg_claw_mode"):GetInt()
	end
	if clawCvar <= 0 then
		self:CloseClaws( false )
	elseif (clawCvar > 0 and clawCvar < 2) then
		self:OpenClaws( false )
	elseif clawCvar >= 2 then
		local glow_bool = self:GetGlow()
		if glow_bool then
			self:StopClawSound()
		end
		
		local trace = self.Owner:GetEyeTrace()
		local tracetgt = trace.Entity
		local tgt = nil
		
		if (!ConVarExists("scgg_cone") or GetConVar("scgg_cone"):GetBool()) and !self:PickupCheck(tracetgt) and (!IsValid(self:GetTP())) then
			tgt = self:GetConeEnt(trace)
		else
			tgt = tracetgt
		end
		--print(tgt)
		if IsValid(self:GetTP()) then
			timer.Remove("scgg_claw_close_delay"..self:EntIndex())
			self:OpenClaws( false )
		elseif self:PickupCheck(tgt) then
			self:OpenClaws( true )
		else
			if !timer.Exists("scgg_claw_close_delay"..self:EntIndex()) and IsValid(self) then
				timer.Create( "scgg_claw_close_delay"..self:EntIndex(), 0.6, 1, function()
					if IsValid(self) and IsValid(self.Owner) and self.Owner:Alive() then
						self:CloseClaws( true )
					end
				end)
			end
		end
	end
	
	self:SetNextClientThink(CurTime()+0.5)
end

--[[function SWEP:Deploy()
	print("clientdeploy")
	local claw_mode_cvar = GetConVar("scgg_claw_mode"):GetInt()
	if claw_mode_cvar <= 0 then
		self:CloseClaws( false )
	elseif (claw_mode_cvar > 0 and claw_mode_cvar < 2) then
		self:OpenClaws( false )
	end
end--]]

--[[function SWEP:Holster()
	self:SetHP(nil)
	return true
end--]]

-- Easier to not use this, as if you holster your weapon as it got it's viewmodel set, when you deploy it it'll glitch back to the old model
--[[function SWEP:Think()
	local VModel = self.Owner:GetViewModel()
	local cvar = GetConVar("cl_scgg_viewmodel"):GetString()
	if VModel:GetModel() != cvar then
		self.ViewModel = cvar
		VModel:SetModel(cvar)
	end
end--]]