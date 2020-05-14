include ("shared.lua")

SWEP.Category			= "Half-Life 2"

	SWEP.PrintName			= "SUPER GRAVITY GUN"
	SWEP.Author			= "ErrolLiamP, Î¤yler Blu, QuentinDylanP, pillow, Shadowysn"
	SWEP.Slot			= 1
	SWEP.SlotPos			= 0
	SWEP.IconLetter			= "k"
	SWEP.ViewModelFOV =		GetConVar("viewmodel_fov"):GetFloat()

SWEP.Slot				= 0
SWEP.SlotPos 			= 0
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair 		= true

SWEP.Author			= "ErrolLiamP, Î¤yler Blu, pillow, Shadowysn"
SWEP.Purpose			= ""
SWEP.Instructions		= ""
SWEP.BounceWeaponIcon	= false
SWEP.DrawWeaponInfoBox	= false

SWEP.WepSelectIcon = surface.GetTextureID("weapons/Megaphyscannon")

if SERVER then return end

local GetRag = {}

net.Receive( "SCGG_Ragdoll_GetPlayerColor", function() 
	local rag = net.ReadInt(32)
	local ply = net.ReadInt(32)
	local col = net.ReadVector()
	if !ply or ply == nil then return end
	if !col or col == nil then return end
	GetRag = {rag=rag,ply=ply,col=col}
end )

hook.Add("NetworkEntityCreated","SCGG_Ragdoll_SetPlayerColor",function(ent)
	if not GetRag.rag then return end
	if GetRag.rag==ent:EntIndex() then
		local getcol = GetRag.col
		Entity(GetRag.rag).GetPlayerColor = function(self) return getcol end
		GetRag = {}
	end
end)

function SWEP:DrawWorldModel()
	self.SCGG_IsWorldModelDrawn = true
	self:DrawModel()
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
	--[[local active_string = "active"
	local ViewModel = self.Owner:GetViewModel()
	local WorldModel = self
	
	local vm_active_pose = 0
	local wm_active_pose = 0
	if IsValid(ViewModel) then
		local vm_active_pose = ViewModel:GetPoseParameter(active_string)
		vm_active_pose = PoseArithmetic(ViewModel, active_string, vm_active_pose)
	end
	if IsValid(WorldModel) then
		local wm_active_pose = WorldModel:GetPoseParameter(active_string)
		wm_active_pose = PoseArithmetic(WorldModel, active_string, wm_active_pose)
	end--]]
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
	--print(self:GetHP())
	--print("Open Claws!")
	if !IsValid(self.Owner) or !self.Owner:Alive() then return end
	
	--[[local active_string = "active"
	local ViewModel = self.Owner:GetViewModel()
	local WorldModel = self
	
	timer.Remove("scgg_claw_close_delay"..self:EntIndex()) -- Remove the delayed claw close timer often created by 'scgg_claw_mode 2'.
	
	local vm_active_pose = 0
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
	local ViewModel, WorldModel, active_string = GetVMPoses(self)
	timer.Remove("scgg_claw_close_delay"..self:EntIndex()) -- Remove the delayed claw close timer often created by 'scgg_claw_mode 2'.
	
	if !timer.Exists("scgg_move_claws_open"..self:EntIndex()) then
		-- ^ Does not run the rest of the code if a timer to open the claws exists.
		timer.Remove("scgg_move_claws_close"..self:EntIndex())
		
		timer.Create( "scgg_move_claws_open"..self:EntIndex(), 0, 60, function() -- The timer for claw opening is created.
			if !IsValid(self) or !IsValid(self.Owner) or !self.Owner:Alive() or self.PoseParam >= 1 then timer.Remove("scgg_move_claws_open"..self:EntIndex()) return end
			--if wm_active_pose > 1 or vm_active_pose > 1 then self.PoseParam = 1 return end
			self.PoseParam = self.PoseParam+0.1
		end)
		
		if (self.PoseParam <= 0) and boolean then -- Sound emitting!
			self.Weapon:StopSound("Weapon_PhysCannon.CloseClaws")
			self.Weapon:EmitSound("Weapon_PhysCannon.OpenClaws")
		end
	end
	--[[if (!IsValid(self.Owner) or !self.Owner:Alive()) or (!IsValid(ViewModel) and !IsValid(WorldModel)) then 
		-- ^ Remove the timer if the owner is invalid/dead or the viewmodel and worldmodel don't exist.
		timer.Remove("scgg_move_claws_open"..self:EntIndex()) return 
	end--]]
end
function SWEP:CloseClaws( boolean ) -- Open claws function.
	--print(self:GetHP())
	--print("Open Claws!")
	if !IsValid(self.Owner) or !self.Owner:Alive() then return end
	
	local ViewModel, WorldModel, active_string = GetVMPoses(self)
	
	if !timer.Exists("scgg_move_claws_close"..self:EntIndex()) then
		-- ^ Does not run the rest of the code if a timer to open the claws exists.
		timer.Remove("scgg_move_claws_open"..self:EntIndex())
		
		timer.Create( "scgg_move_claws_close"..self:EntIndex(), 0, 60, function() -- The timer for claw opening is created.
			if !IsValid(self) or !IsValid(self.Owner) or !self.Owner:Alive() or self.PoseParam <= 0 then timer.Remove("scgg_move_claws_close"..self:EntIndex()) return end
			--if wm_active_pose > 1 or vm_active_pose > 1 then self.PoseParam = 1 return end
			self.PoseParam = self.PoseParam-0.05
		end)
		
		if (self.PoseParam >= 1) and boolean then -- Sound emitting!
			self.Weapon:StopSound("Weapon_PhysCannon.OpenClaws")
			self.Weapon:EmitSound("Weapon_PhysCannon.CloseClaws")
		end
	end
	--[[if (!IsValid(self.Owner) or !self.Owner:Alive()) or (!IsValid(ViewModel) and !IsValid(WorldModel)) then 
		-- ^ Remove the timer if the owner is invalid/dead or the viewmodel and worldmodel don't exist.
		timer.Remove("scgg_move_claws_close"..self:EntIndex()) return 
	end--]]
end

--[[function SWEP:OpenClaws( boolean ) -- Open claws function.
	--print(self:GetHP())
	--print("Open Claws!")
	if !IsValid(self.Owner) or !self.Owner:Alive() then return end
	
	local active_string = "active"
	local ViewModel = self.Owner:GetViewModel()
	local WorldModel = self
	
	timer.Remove("scgg_claw_close_delay"..self:EntIndex()) -- Remove the delayed claw close timer often created by 'scgg_claw_mode 2'.
	
	local vm_active_pose = 0
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
	end
	
	if (ViewModel and vm_active_pose < 1) or (WorldModel and wm_active_pose < 1) then 
		local frame = ViewModel:GetPoseParameter(active_string)
		local worldframe = WorldModel:GetPoseParameter(active_string)
		if !timer.Exists("scgg_move_claws_open"..self:EntIndex()) then
			-- ^ Does not run the rest of the code if a timer to open the claws exists.
			timer.Remove("scgg_move_claws_close"..self:EntIndex())
			
			timer.Create( "scgg_move_claws_open"..self:EntIndex(), 0, 20, function() -- The timer for claw opening is created.
				if !IsValid(self) or !IsValid(self.Owner) or !self.Owner:Alive() then timer.Remove("scgg_move_claws_open"..self:EntIndex()) return end
				if IsValid(ViewModel) then -- Viewmodel claws are moved here.
					if frame > 1 then ViewModel:SetPoseParameter(active_string, 1) end
					--if frame >= 1 then timer.Remove("scgg_move_claws_open"..self:EntIndex()) return end
					frame = frame+0.1
					ViewModel:SetPoseParameter(active_string, frame)
					ViewModel:InvalidateBoneCache()
				end
				if IsValid(WorldModel) then -- Worldmodel claws are moved here.
					if worldframe > 1 then WorldModel:SetPoseParameter(active_string, 1) end
					--if worldframe >= 1 then timer.Remove("scgg_move_claws_open"..self:EntIndex()) return end
					worldframe = worldframe+0.1
					WorldModel:SetPoseParameter(active_string, worldframe)
					WorldModel:InvalidateBoneCache()
					if wm_active_pose >= 0.5 then
						self.ClawOpenState = true
					end
				end
			end)
			if (frame <= 0 or worldframe <= 0) and !IsValid(self:GetHP()) and boolean then -- Sound emitting!
				self.Weapon:StopSound("Weapon_PhysCannon.CloseClaws")
				self.Weapon:EmitSound("Weapon_PhysCannon.OpenClaws")
			end
		end
		if (!IsValid(self.Owner) or !self.Owner:Alive()) or (!IsValid(ViewModel) and !IsValid(WorldModel))
		or (vm_active_pose >= 1 and wm_active_pose >= 1) then 
			-- ^ Remove the timer if the owner is invalid/dead or the viewmodel and worldmodel don't exist.
			timer.Remove("scgg_move_claws_open"..self:EntIndex()) return 
		end
	end

end

function SWEP:CloseClaws( boolean ) -- Close claws function.
	--print("Close Claws!")
	if !IsValid(self.Owner) or !self.Owner:Alive() then return end
	
	local active_string = "active"
	local ViewModel = self.Owner:GetViewModel()
	local WorldModel = self
	
	timer.Remove("scgg_claw_close_delay"..self:EntIndex()) -- Remove the delayed claw close timer often created by 'scgg_claw_mode 2'.
	
	local vm_active_pose = 0
	local wm_active_pose = 0
	if IsValid(ViewModel) then
		local vm_active_pose = ViewModel:GetPoseParameter(active_string)
	end
	if IsValid(WorldModel) then
		local wm_active_pose = WorldModel:GetPoseParameter(active_string)
	end
	
	--if ViewModel and self.ClawOpenState == true then
	if (ViewModel and vm_active_pose > 0) or (WorldModel and wm_active_pose > 0) then
		local frame = vm_active_pose
		local worldframe = wm_active_pose
		if !timer.Exists("scgg_move_claws_close"..self:EntIndex()) then
			-- ^ Does not run the rest of the code if a timer to close the claws exists.
			timer.Remove("scgg_move_claws_open"..self:EntIndex())
			
			timer.Create( "scgg_move_claws_close"..self:EntIndex(), 0, 20, function() -- The timer for claw closing is created.
				if !IsValid(self) or !IsValid(self.Owner) or !self.Owner:Alive() then timer.Remove("scgg_move_claws_close"..self:EntIndex()) return end
				if IsValid(ViewModel) then
					if frame < 0 then ViewModel:SetPoseParameter(active_string, 0) end
					--if frame <= 0 then print("doh2") timer.Remove("scgg_move_claws_close"..self:EntIndex()) return end
					frame = frame-0.05
					ViewModel:SetPoseParameter(active_string, frame)
					ViewModel:InvalidateBoneCache()
				end
				if IsValid(WorldModel) then
					if worldframe < 0 then WorldModel:SetPoseParameter(active_string, 0) end
					--if worldframe <= 0 then print("doh3") timer.Remove("scgg_move_claws_close"..self:EntIndex()) return end
					worldframe = worldframe-0.05
					WorldModel:SetPoseParameter(active_string, worldframe)
					WorldModel:InvalidateBoneCache()
				end
				if wm_active_pose < 0.5 then
					self.ClawOpenState = false
				end
			end)
			if (frame >= 1 or worldframe >= 1) and !IsValid(self:GetHP()) and boolean then
				self.Weapon:StopSound("Weapon_PhysCannon.OpenClaws")
				self.Weapon:EmitSound("Weapon_PhysCannon.CloseClaws")
			end
		end
		if (!IsValid(self.Owner) or !self.Owner:Alive()) or (!IsValid(ViewModel) and !IsValid(WorldModel))
		or (vm_active_pose <= 0 and wm_active_pose <= 0) then
			-- ^ Remove the timer if the owner is invalid/dead or the viewmodel and worldmodel don't exist.
			timer.Remove("scgg_move_claws_close"..self:EntIndex()) return
		end
	end
end--]]

function SWEP:Think()
	local newview_info = GetConVar("cl_scgg_viewmodel"):GetString()
	if self.ViewModel != newview_info then -- Attempt to set the chosen cl_scgg_viewmodel model.
		self.ViewModel = newview_info
		self.Owner:GetViewModel():SetWeaponModel(newview_info, self)
	end
	
	if GetConVar("scgg_light"):GetBool() then
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
	self:AdjustClaws()
	
	local clawcvar = GetConVar("scgg_claw_mode"):GetInt()
	if clawcvar <= 0 then
		self:CloseClaws( false )
	elseif (clawcvar > 0 and clawcvar < 2) then
		self:OpenClaws( false )
	elseif clawcvar >= 2 then
		local trace = self.Owner:GetEyeTrace()
		local tracetgt = trace.Entity
		local tgt = nil
		
		if GetConVar("scgg_cone"):GetBool() and !self:PickupCheck(tracetgt) then--and (!IsValid(self:GetHP())) then
			tgt = self:GetConeEnt(trace)
		else
			tgt = tracetgt
		end
		--print(tgt)
		if self:PickupCheck(tgt) then
			self:OpenClaws( true )
		--[[elseif IsValid(self:GetHP()) and self.Fading != true then
			timer.Remove("scgg_claw_close_delay"..self:EntIndex())
			self:OpenClaws( false )--]]
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

function SWEP:Holster()
	self:SetHP(nil)
	return true
end

local Mat = Material( "sprites/blueflare1_noz" )
Mat:SetInt("$spriterendermode",5)
local MatWorld = Material( "sprites/blueflare1" )
MatWorld:SetInt("$spriterendermode",5)
local Main = Material( "effects/fluttercore" )
Main:SetInt("$spriterendermode",9)

--[[function SWEP:PreDrawViewModel(vm)
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