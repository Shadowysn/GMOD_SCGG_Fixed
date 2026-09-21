AddCSLuaFile("cl_glow_spr.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local function InitChangeableVars(self)
	--self.ClawOpenState = false
	self.Fading = false
	self.CoreAllowRemove = true
	--self:SetNWBool("SCGG_PrimaryFired", false)
	self.HPCollideG = COLLISION_GROUP_NONE
	self.HPHealth = -1
	self.HPBone = nil
	self.OnDropOwner = nil
	--self.oldHP = nil
end

local function DetermineHoldType(swep)
	if !IsValid(swep:GetOwner()) then return end
	
	if swep:GetOwner():IsNPC() then
		swep:SetHoldType( "shotgun" )
		if SERVER then
			if swep:GetOwner():Classify() == CLASS_METROPOLICE then
				swep:SetHoldType( "smg" )
			end
		end
	else
		swep:SetHoldType( swep.HoldType )
	end
end

function SWEP:Initialize() -- Initialization stuff.
	DetermineHoldType(self)
	self:SetSkin(1)
	InitChangeableVars(self)
end

function SWEP:OwnerChanged() -- Owner changed. Useful for changing hold type between NPC and Player.
	self:TPrem()
	self:HPrem()
	DetermineHoldType(self)
end

local function TimerDestroyAll(self) -- DESTROY ALL TIMERS! DESTROY ALL TIMERS!
	timer.Remove("deploy_idle"..self:EntIndex())
	timer.Remove("attack_idle"..self:EntIndex())
	timer.Remove("scgg_move_claws_open"..self:EntIndex())
	timer.Remove("scgg_move_claws_close"..self:EntIndex())
	timer.Remove("scgg_claw_close_delay"..self:EntIndex())
	--timer.Remove("scgg_primaryfired_timer"..self:EntIndex())
end

function SWEP:Deploy()
	InitChangeableVars(self)
	
	self.OnDropOwner = self:GetOwner()
	
	--self:SetNextPrimaryFire( CurTime() + 5 )
	self:SetNextSecondaryFire( CurTime() + 5 )
	--[[if IsValid(self:GetOwner():GetWeapon("weapon_physcannon")) then
		--print("yeah")
		net.Start("SCGG_Deploy_DisableGrav")
		net.Send( self:GetOwner() )
	end--]]
	--self:CoreEffect()
	TimerDestroyAll(self)
	
	--[[local claw_mode_cvar = GetConVar("scgg_claw_mode"):GetInt()
	if claw_mode_cvar <= 0 then
		self:CloseClaws( false )
	elseif (claw_mode_cvar > 0 and claw_mode_cvar < 2) then
		self:OpenClaws( false )
	end--]]
	--if !GetConVar("scgg_style"):GetBool() then
	--self:SendWeaponAnim( ACT_VM_DRAW )
	if ConVarExists("scgg_equip_sound") and GetConVar("scgg_equip_sound"):GetBool() and 
	ConVarExists("scgg_enabled") and GetConVar("scgg_enabled"):GetInt() > 0 then
		self:EmitSound("weapons/physcannon/physcannon_charge.wav") 
	end
	--end
	
	if IsValid(self:GetOwner()) then
		if self:GetOwner():IsPlayer() then
			local vm = self:GetOwner():GetViewModel()
			local duration = 0
			duration = vm:SequenceDuration()
			
			timer.Create( "deploy_idle"..self:EntIndex(), duration, 1, function()
				if !IsValid( self ) then return true end
				if IsValid(self) and IsValid(self:GetOwner()) and IsValid(self:GetOwner():GetActiveWeapon()) and self:GetOwner():GetActiveWeapon() == self 
				and self.Fading == false then
					self:SendWeaponAnim( ACT_VM_IDLE )
				end
				--self:SetNextPrimaryFire( CurTime() + 0.01 )
				self:SetNextSecondaryFire( CurTime() + 0.01 )
			end)
		end
	end
	return true
end

function SWEP:Holster()
	local HP = self:GetHP()
	
	--[[if ConVarExists("scgg_worldmodel") and GetConVar("scgg_worldmodel"):GetString() != self.WorldModel then
		self.WorldModel = GetConVar("scgg_worldmodel"):GetString()
	end--]]
	
	--if SERVER then
		--print(self:GetOwner():GetInfo("cl_scgg_viewmodel"))
		local newview_info = nil
		newview_info = "models/weapons/shadowysn/c_superphyscannon.mdl"
		if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() and self:GetOwner():GetInfo("cl_scgg_viewmodel") then
			newview_info = self:GetOwner():GetInfo("cl_scgg_viewmodel")
		end
		if self.ViewModel != self.WorldModel and util.IsValidModel(newview_info) and !IsUselessModel(newview_info) then
			-- Useless model doesn't work :/
			self.ViewModel = newview_info
		end
	--end
	
	if ConVarExists("scgg_deploy_style") and !GetConVar("scgg_deploy_style"):GetBool() then
		self:SetDeploySpeed(1)
	else
		self:SetDeploySpeed(GetConVar("sv_defaultdeployspeed"):GetInt())
	end
	if IsValid(HP) and self:GetOwner():Health() > 0 then
		return false
	end
	TimerDestroyAll(self)
	--[[if SERVER then
		if IsValid(self:GetOwner():GetWeapon("weapon_physcannon")) then
			local ply = self:GetOwner()
			--print("yeah2")
			net.Start("SCGG_Holster_EnableGrav")
			net.Send( ply )
		end
	end--]]
	
	if IsValid(HP) then
		self:Drop()
	end
	self:SetPoseParameter("active", 0)
	self:SetHP(nil)
	--self:RemoveCore()
	self:TPrem()
	self:HPrem()
	
	--[[if IsValid(self.FadeCore) then
		self.FadeCore:Remove()
	end--]]
	
	return true
end

function SWEP:Discharge() -- Revert-to-normal effect of the SCGG. Think of HL2:EP1's Direct Intervention chapter, after you've stabilized the core.
	if self.Fading == true or IsValid(self.FadeCore) then return end
	self.Fading = true
	
	if IsValid(self:GetHP()) then
		self:Drop()
	end
	
	self:EmitSound("Weapon_Physgun.Off", 75, 100, 0.6)
	--self:CloseClaws( false )
	--[[self.FadeCore = ents.Create("PhyscannonFade")
	timer.Create("SCGG_FadeCore_Position"..self:EntIndex(), 0.10, 0, function()
		if !IsValid(self.FadeCore) then 
			timer.Remove("SCGG_FadeCore_Position"..self:EntIndex())
			return 
		end
		self.FadeCore:SetPos( self:GetOwner():GetShootPos() )
	end )
	self.FadeCore:Spawn()
	self.FadeCore:SetParent(self:GetOwner())
	self.FadeCore:SetOwner(self:GetOwner())--]] -- An attempt at a fading core.
	local model_base = self
	local model_attachstr = "core"
	if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
		model_attachstr = "muzzle"
	end
	
	--[[local coreattachmentID = nil
	local coreattachment = nil
	if IsValid(model_base) then
		coreattachmentID = model_base:LookupAttachment(model_attachstr)
		coreattachment = model_base:GetAttachment(coreattachmentID)
	end--]]
	
	-- NOTICE: This appears weird in firstperson.
	local core = ents.Create("env_citadel_energy_core")
	if coreattachmentID != nil and coreattachment != nil then
		core:SetPos( coreattachment.Pos )
		core:SetAngles( coreattachment.Ang )
	else
		core:SetPos( self:GetPos() )
		core:SetAngles( self:GetAngles() )
	end
	core:SetParent(self)
	core:Spawn()
	core:Fire( "SetParentAttachment", model_attachstr, 0 )
	core:Fire( "AddOutput","scale 1.5",0 )
	core:Fire( "StartDischarge","",0.1 )
	core:Fire( "ClearParent","",0.89 )
	core:Fire( "Stop","",0.9 )
	core:Fire( "Kill","",1.9 )
	self.FadeCore = core
	
	timer.Simple(0.20, function()
		if !IsValid(self) or !IsValid(self) or !IsValid(self:GetOwner()) or !self:GetOwner():IsPlayer() then return end
		self:SendWeaponAnim(ACT_VM_HOLSTER)
	end)
	timer.Simple(0.90, function()
		if !IsValid(self) then return end
		if IsValid(self.FadeCore) then
			self.FadeCore:Remove()
		end
		
		--[[if IsValid(self:GetOwner()) and self:GetOwner():Alive() then
			if !self:GetOwner():HasWeapon( "weapon_physcannon" ) then -- Give the old, cranky version of this energetic weapon.
				self:GetOwner():Give("weapon_physcannon")
			end
			if self:GetOwner():HasWeapon( "weapon_physcannon" ) and self:GetOwner():GetActiveWeapon() == self then
				self:GetOwner():SelectWeapon("weapon_physcannon") -- Switch to the Mr. CrankyWeak version.
			end
		end--]]
		local weak_grav = SpawnNormalGrav(self)
		if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
			if self:GetOwner():HasWeapon( "weapon_physcannon" ) and IsValid(self:GetOwner():GetActiveWeapon()) and self:GetOwner():GetActiveWeapon() == self then
				self:GetOwner():SelectWeapon("weapon_physcannon") -- Switch to the Mr. CrankyWeak version.
			end
		end
		local class = self:GetClass()
		if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() and self:GetOwner():HasWeapon(class) and self:GetOwner():GetWeapon(class) == self then
			self:GetOwner():StripWeapon(class)
		else
			if IsValid(self:GetOwner()) and self:GetOwner():IsNPC() then
				self:GetOwner():DropWeapon(self)
				--self:GetOwner():PickupWeapon(weak_grav)
			end
			self:Remove()
		end
	end)
end

function SWEP:MuzzleEffect()
	net.Start("SCGG_Core_Muzzle")
	net.WriteEntity(self)
	net.Broadcast()
	--[[if IsValid(self.Core) and !self.Muzzle then
		net.Start("SCGG_Core_Muzzle")
		net.WriteEntity(self.Core)
		net.Broadcast()
		--self.Core:SetNWBool("SCGG_Muzzle", true)
		--self.Muzzle = true
		/*timer.Simple( 0.12, function() 
			if IsValid(self) then
			self:RemoveMuzzle()
			end
		end)*/
	end--]]
end

--[[function SWEP:RemoveMuzzle()
	if IsValid(self.Core) and self.Muzzle then
		--self.Core:SetNWBool("SCGG_Muzzle", false)
		--self.Muzzle = nil
	end
end--]]

function SWEP:CoreEffect()
	if ConVarExists("scgg_no_effects") and GetConVar("scgg_no_effects"):GetBool() then return end
	if !IsValid(self.Core) then
		self.Core = ents.Create("MegaPhyscannonCore")
		self.Core:SetPos( self:GetOwner():GetShootPos() )
		self.Core:Spawn()
		--self.Core:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
	end
	self.CoreAllowRemove = false
	if !IsValid(self.Core) then return end
	self.Core:SetParent(self:GetOwner())
	self.Core:SetOwner(self:GetOwner())
end
	
function SWEP:GlowEffect()
	if ConVarExists("scgg_no_effects") and GetConVar("scgg_no_effects"):GetBool() then return end
	self:SetGlow(true)
end

function SWEP:RemoveCore()
	if !self.Core then return end
	if !IsValid(self.Core) then return end
	self.CoreAllowRemove = true
	self.Core:Remove()
	self.Core = nil
end

function SWEP:RemoveGlow()
	self:SetGlow(false)
end