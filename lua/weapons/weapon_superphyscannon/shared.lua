SWEP.Spawnable					= true
SWEP.AdminSpawnable				= true

SWEP.ViewModel					= "models/weapons/shadowysn/c_superphyscannon.mdl"

--SWEP.WorldModel				= "models/weapons/errolliamp/w_superphyscannon.mdl"
SWEP.WorldModel					= "models/weapons/shadowysn/w_superphyscannon.mdl"

SWEP.UseHands 					= true
SWEP.ViewModelFlip				= false
--SWEP.ViewModelFOV				= 54
SWEP.Weight 					= 42
SWEP.AutoSwitchTo 				= true
SWEP.AutoSwitchFrom 			= true
SWEP.HoldType					= "physgun"

SWEP.PuntForce					= 1000000
--SWEP.HL2PuntForce				= 280000
SWEP.PuntMultiply				= 800
SWEP.PullForce					= 8000
SWEP.HL2PullForce				= 6000
SWEP.HL2PullForceRagdoll		= 4000
SWEP.MaxMass					= 16500
SWEP.HL2MaxMass					= 5500
SWEP.MaxPuntRange				= 1650
SWEP.HL2MaxPuntRange			= 550
SWEP.MaxPickupRange				= 2550-- The cone detection is not as range-perfect as traces. It will cause the weapon to fail grabbing an object!
SWEP.HL2MaxPickupRange			= 850
SWEP.ConeWidth					= 0.88 -- Higher numbers make it thinner, lower numbers widen it.
SWEP.MaxTargetHealth			= 1000
SWEP.HL2MaxTargetHealth			= 225
SWEP.GrabDistance				= 45
SWEP.GrabDistanceRagdoll		= 25
	
SWEP.Primary.ClipSize			= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic			= true
SWEP.Primary.Ammo				= ""
	
SWEP.Secondary.ClipSize			= -1
SWEP.Secondary.DefaultClip		= -1
SWEP.Secondary.Automatic		= true
SWEP.Secondary.Ammo				= ""
	
local HoldSound					= Sound("Weapon_MegaPhysCannon.HoldSound")

util.PrecacheModel(SWEP.ViewModel) -- Precaching stuff :D
util.PrecacheModel(SWEP.WorldModel) -- Precaching stuff :D
--util.PrecacheModel("models/props_junk/PopCan01a.mdl")

local function DissolveEntity(entity) -- The main dissolve function for dissolving things.
	local name = "SCGG_Dissolving_"..entity:EntIndex()
	entity:SetName( name )
	local hasdissolve = nil
	for _,dissolver in pairs(ents.FindByName("scgg_addon_global_dissolver")) do -- We check if the dissolver exists.
		if ent:GetClass() == "env_entity_dissolver" then
			ent:Fire("Dissolve", name, 0) -- If it exists, have it dissolve our given entity
			hasdissolve = true -- and set this to true...
		end
	end
	--print(hasdissolve)
	if hasdissolve != true then -- ...otherwise we spawn one.
	local dissolver = ents.Create("env_entity_dissolver")
	dissolver:SetPos(Vector(0,0,0))
	dissolver:SetKeyValue( "dissolvetype", 0 )
	dissolver:SetName("scgg_addon_global_dissolver")
	dissolver:Spawn()
	dissolver:Activate()
	dissolver:Fire("Dissolve", name, 0) -- Have the new one dissolve our given entity.
	end
end

function SWEP:IsMotionEnabledOrGrabbableFlag(tgt)
	if IsValid(tgt) and tgt:GetMoveType() == MOVETYPE_VPHYSICS and IsValid(tgt:GetPhysicsObject()) and 
	(
	tgt:GetPhysicsObject():IsMotionEnabled() or
	!tgt:GetPhysicsObject():IsMotionEnabled() and (tgt:HasSpawnFlags(64) or (tgt:GetClass() == "func_physbox" and tgt:HasSpawnFlags(131072)))
	)
	then
		return true
	end
	return false
end

local function FadeScreen(ply)
	if IsValid(ply) and ply:GetInfoNum("cl_scgg_effects_mode", 0) < 1 then
		ply:ScreenFade( SCREENFADE.IN, Color( 255, 255, 255, 40 ), 0.1, 0 )
	end
end

function SWEP:GetHP()
	return self:GetNWEntity("SCGG_HP", nil)
end
function SWEP:SetHP(entity)
	self:SetNWEntity("SCGG_HP", entity)
	--print(self:GetHP())
end
function SWEP:GetHP_PickedUp()
	--return self:GetNWBool("SCGG_HP_PickedUp", false)
	return self.HP_PickedUp
end
function SWEP:SetHP_PickedUp(boolean)
	--self:SetNWBool("SCGG_HP_PickedUp", boolean)
	self.HP_PickedUp = boolean
end

function SWEP:Initialize() -- Initialization stuff.
	self:SetWeaponHoldType( self.HoldType )
	self:SetSkin(1)
	self:InitChangeableVars()
end

function SWEP:InitChangeableVars()
	self.ClawOpenState = false
	self.Fading = false
	self.CoreAllowRemove = true
	self.MuzzleAllowRemove = true
	--self:SetNWBool("SCGG_PrimaryFired", false)
	self.HPCollideG = COLLISION_GROUP_NONE
	self.HPHealth = -1
	self.HPBone = nil
	self.OnDropOwner = nil
	--self.oldHP = nil
end
	
-- Place OpenClaws and CloseClaws holder

function SWEP:TimerDestroyAll() -- DESTROY ALL TIMERS! DESTROY ALL TIMERS!
	timer.Remove("deploy_idle"..self:EntIndex())
	timer.Remove("attack_idle"..self:EntIndex())
	timer.Remove("scgg_move_claws_open"..self:EntIndex())
	timer.Remove("scgg_move_claws_close"..self:EntIndex())
	timer.Remove("scgg_claw_close_delay"..self:EntIndex())
	--timer.Remove("scgg_primaryfired_timer"..self:EntIndex())
end

function SWEP:OwnerChanged() -- Owner changed, idfk. I don't think it's important but eh.
	if SERVER and !GetConVar("scgg_no_effects"):GetBool() then
		self:RemoveCore()
		self:TPrem()
		self:HPrem()
	end
end

function SWEP:PuntCheck(tgt) -- Punting check, use this as if it were something like IsValid() - self:PuntCheck(entity)
	local DistancePunt_Test = 0
	if IsValid(tgt) then
		DistancePunt_Test = (tgt:GetPos()-self.Owner:GetPos()):Length()
	else
		DistancePunt_Test = self:GetMaxPuntRange()+10
	end
	
	if self:DirectCheck(tgt) and
	( DistancePunt_Test < self:GetMaxPuntRange() )
	--and !self.Owner:KeyDown(IN_ATTACK) -- Don't know why I commented this out, but I must've did it for a reason. Glitch, maybe?
	then
		return true
	end
	return false
end

function SWEP:PickupCheck(tgt) -- Pickup check. Like beforehand, use this as if it were something like IsValid() - self:PickupCheck(entity)
	local Distance_Test = 0
	if IsValid(tgt) then
		Distance_Test = (tgt:GetPos()-self.Owner:GetPos()):Length()
	else
		Distance_Test = self:GetMaxPickupRange()+10
	end
	
	if self:DirectCheck(tgt) and
	( Distance_Test < self:GetMaxPickupRange() )
	then
		return true
	end
	return false
end

function SWEP:DirectCheck(tgt) -- Check if can be punted/grabbed, but without distance checking. - self:DirectCheck(entity)
	-- v I sincerely apologize for this mess of a check, but it gets the job done.
	if IsValid(tgt) and self.Fading != true and
	(
		(
			(
				self:AllowedClass(tgt) and tgt:GetMoveType() == MOVETYPE_VPHYSICS
			)
			and
			(
			IsValid(tgt:GetPhysicsObject()) and tgt:GetPhysicsObject():GetMass() < (self:GetMaxMass()) and self:IsMotionEnabledOrGrabbableFlag(tgt)
			or
			CLIENT -- Physics objects don't exist on client, so we don't check for them else it just doesn't work
			)
		)
		or
		(
			(
				tgt:IsNPC() and
				(
					GetConVar("scgg_friendly_fire"):GetBool() or !self:FriendlyNPC( tgt )
				)
				and tgt:Health() <= self:GetMaxTargetHealth()
			)
		or
		tgt:IsPlayer() or tgt:IsRagdoll()
		)
	and !self:NotAllowedClass(tgt)
	)
	then
		return true
	end
	return false
end

function SWEP:GetConeEnt(trace) -- Punting check. Use like IsValid() but with a trace, not an entity. - self:GetConeEnt(trace)
	local function CheckEnt(cone_tbl) -- This is a local function for this function. Much function, such wow.
		local cone_dist_table = {}
		--print("Before (cone_tbl):")
		--PrintTable(cone_tbl)
		for T,ent in pairs( cone_tbl ) do
			if IsValid(ent) and ent != self and ent != self.Owner then
				--[[local trace = util.TraceHull( {
					start = self.Owner:EyePos(),
					endpos = ent:GetPos(),
					maxs = Vector(8,8,8),
					mins = -Vector(8,8,8),
					filter = {self, self.Owner}
				} )--]] -- NOTE: May sometimes not function! Example: Cannot pickup combines without direct trace until you get close. Try to find a fix.
				--print(trace.Entity)
				local ent_pos = ent:WorldSpaceCenter()
				if ent_pos:IsZero() then
					ent_pos = ent:GetPos()
				end
				
				local trace = util.TraceLine( {
					start = self.Owner:EyePos(),
					endpos = ent_pos,
					filter = {self, self.Owner},
					mask = MASK_SHOT_HULL
				} )
				if trace.Entity == ent then--and !trace.HitWorld and trace.HitNonWorld and !trace.StartSolid and !trace.AllSolid then
					local temp_tbl = { {ent, (ent:GetPos()-self.Owner:EyePos()):Length()} }
					table.Add(cone_dist_table, temp_tbl)
					--print(ent, "passed!")
				else
					--table.remove(cone_tbl, cone_tbl[ent])
					--cone_tbl = table.sort(cone_tbl, true)
					--cone_dist_table = table.sort(cone_dist_table, true)
					--print(ent, "failed!")
				end
			end
		end
		--print("After (cone_tbl):")
		--PrintTable(cone_tbl)
		--print("After (cone_dist_table):")
		--PrintTable(cone_dist_table)
		local fin_dist_table = {} -- Final distance table. For use to return the winning entity, which is the one with shortest distance.
		for _,tbl in pairs(cone_dist_table) do
			local temp_tbl = {tbl[#tbl]}
			table.Add(fin_dist_table, temp_tbl)
			--PrintTable(cone_dist_table)
			--print(tbl) print(#cone_dist_table)
			if tbl == cone_dist_table[#cone_dist_table] then 
			-- ^ If we reach the last keyvalue in the cone distance table, we begin to kick the losers out and decide a winner.
				local shortest_distance_entnum = table.KeyFromValue(table.SortByKey(fin_dist_table, true), 1)
				local winning_tbl = cone_dist_table[shortest_distance_entnum]
				local winning_ent = winning_tbl[1]
				
				if IsValid(winning_ent) then
					return winning_ent -- a winrar is uu!!1
				end
			end
		end
		--[[local shortest_distance_entnum = table.KeyFromValue(table.SortByKey(cone_dist_table, true), 1) 
		local winning_ent = cone_tbl[shortest_distance_entnum]
		
		if IsValid(winning_ent) then
			return winning_ent
		end--]] -- Ignore this, failed iteration of entity distance checking.
	end
	
	local combineball_cone_tbl = {}
	local living_cone_tbl = {}
	local rag_cone_tbl = {}
	local other_cone_tbl = {}
	-- ^ Priority tables. See the below !table.IsEmpty tree for what takes priority first.
	
	local cone = ents.FindInCone( self.Owner:EyePos(), self.Owner:GetAimVector(), self:GetMaxPickupRange(), self.ConeWidth )
	for T,ent in pairs( cone ) do -- This sets up the tables for the decision of the winner entity.
		if self:DirectCheck(ent) and ent != self and ent != self.Owner then
			if ent:GetClass() == "prop_combine_ball" then
				local temp_tbl = { ent }
				table.Add(combineball_cone_tbl, temp_tbl)
			elseif (ent:IsNPC() and ent:Health() > 0 and (GetConVar("scgg_friendly_fire"):GetBool() or !self:FriendlyNPC( tgt ) )) 
			or (ent:IsPlayer() and ent:Alive()) then
				local temp_tbl = { ent }
				table.Add(living_cone_tbl, temp_tbl)
			elseif ent:IsRagdoll() then
				local temp_tbl = { ent }
				table.Add(rag_cone_tbl, temp_tbl)
			elseif ent:GetMoveType() == MOVETYPE_VPHYSICS or ( self:AllowedClass(ent) and !self:NotAllowedClass(ent) ) then
				local temp_tbl = { ent }
				table.Add(other_cone_tbl, temp_tbl)
			end
		end
	end
	-- You 
	if !table.IsEmpty(combineball_cone_tbl) then -- Combine balls get first class.
		--PrintTable(combineball_cone_tbl)
		return CheckEnt(combineball_cone_tbl)
	elseif !table.IsEmpty(living_cone_tbl) then -- Entities like NPCs and players take second.
		--PrintTable(living_cone_tbl)
		return CheckEnt(living_cone_tbl)
	elseif !table.IsEmpty(rag_cone_tbl) then -- Ragdolls take third.
		--PrintTable(rag_cone_tbl)
		return CheckEnt(rag_cone_tbl)
	elseif !table.IsEmpty(other_cone_tbl) then -- Misc. stuff like props and physical entities are last.
		--PrintTable(other_cone_tbl)
		return CheckEnt(other_cone_tbl)
	end
	
	--PrintTable(cone)
	--PrintTable(cone_dist_table)
	--[[for T,ent in pairs( cone ) do
		if IsValid(ent) and ent != self and ent != self.Owner then
			if ent:GetClass() == "prop_combine_ball" then
			return ent
			end
			if (ent:IsNPC() and ent:Health() > 0) or (ent:IsPlayer() and ent:Alive()) then
			return ent
			end
			if ent:IsRagdoll() or ( self:AllowedClass(ent) and !self:NotAllowedClass(ent) ) then
			return ent
			end
			if ent:GetMoveType() == MOVETYPE_VPHYSICS and !self:NotAllowedClass(ent) then
			return ent
			end
		end
	end--]] -- Old cone detection method, don't use.
	
	return nil -- Whoops, no one is a winrar!
end

function SWEP:Discharge() -- Revert-to-normal effect of the SCGG. Think of HL2:EP1's Direct Intervention chapter, after you've stabilized the core.
	if IsValid(self:GetHP()) then
		self:Drop()
	end
	
	self.Weapon:EmitSound("Weapon_Physgun.Off", 75, 100, 0.6)
	--self:CloseClaws( false )
	--[[self.FadeCore = ents.Create("PhyscannonFade")
	timer.Create("SCGG_FadeCore_Position"..self:EntIndex(), 0.10, 0, function()
		if !IsValid(self.FadeCore) then 
			timer.Remove("SCGG_FadeCore_Position"..self:EntIndex())
			return 
		end
		self.FadeCore:SetPos( self.Owner:GetShootPos() )
	end )
	self.FadeCore:Spawn()
	self.FadeCore:SetParent(self.Owner)
	self.FadeCore:SetOwner(self.Owner)--]] -- An attempt at a fading core.
	local coreattachmentID = nil
	local coreattachment = nil
	
	local model_base = self
	local model_attachstr = "muzzle"
	
	if IsValid(model_base) then
		coreattachmentID = model_base:LookupAttachment(model_attachstr)
		coreattachment = model_base:GetAttachment(coreattachmentID)
	end
	if coreattachmentID != nil and coreattachment != nil then
		local core = ents.Create("env_citadel_energy_core")
		core:SetPos( coreattachment.Pos )
		core:SetAngles( coreattachment.Ang )
		core:SetParent( self )
		core:Spawn()
		core:Fire( "SetParentAttachment", model_attachstr, 0 )
		core:Fire( "AddOutput","scale 1.5",0 )
		core:Fire( "StartCharge","0.1``",0.1 )
		core:Fire( "ClearParent","",0.89 )
		core:Fire( "Stop","",0.9 )
		core:Fire( "Kill","",1.9 )
		self.FadeCore = core
	end -- NOTICE: It'd appear weird in firstperson.
	
	timer.Simple(0.20, function()
		if !IsValid(self) or !IsValid(self.Weapon) then return end
		self.Weapon:SendWeaponAnim(ACT_VM_HOLSTER)
	end)
	timer.Simple(0.90, function()
		if !IsValid(self) then return end
		if IsValid(self.FadeCore) then
			self.FadeCore:Remove()
		end
		if IsValid(self.Owner) and self.Owner:Alive() then
			if !self.Owner:HasWeapon( "weapon_physcannon" ) then -- Give the old, cranky version of this energetic weapon.
				self.Owner:Give("weapon_physcannon")
			end
			if self.Owner:HasWeapon( "weapon_physcannon" ) and self.Owner:GetActiveWeapon() == self then
				self.Owner:SelectWeapon("weapon_physcannon") -- Switch to the Mr. CrankyWeak version.
			end
		end
		self:Remove()
	end)
end

function SWEP:Think() -- Think function for the weapon.
	if !GetConVar("scgg_style"):GetBool() then -- Sway scales for scgg_style
		self.SwayScale 	= 3
		self.BobScale 	= 1
	else
		self.SwayScale 	= 1
		self.BobScale 	= 1
	end
	
	if GetConVar("scgg_enabled"):GetInt() <= 0 and !self.Fading then
		self.Fading = true
		self:Discharge()
	end
		
	if SERVER then
		--if !GetConVar("scgg_cone"):GetBool() then
		for _,ent in pairs(ents.FindInSphere( self.Owner:GetShootPos(), self:GetMaxPickupRange() )) do
			if self:DirectCheck(ent) and ent:GetCollisionGroup() == COLLISION_GROUP_DEBRIS then
				-- For some reason, ragdolls/props that are debris cannot be targeted by the weapon, so this converts them to a targetable version.
				ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
			end
		end
		--end
		if IsValid(self.Core) then
			self.Core:SetPos( self.Owner:GetShootPos() )
		end
		if !IsValid(self.Core) and self.CoreAllowRemove == false then
			self:CoreEffect()
		end
	end
	
	--local trace = self.Owner:GetEyeTrace()
	--local tracetgt = trace.Entity
	local tgt = nil
	
	--[[if GetConVar("scgg_cone"):GetBool() and !self:PickupCheck(tracetgt) then--and (!IsValid(self:GetHP())) then
		tgt = self:GetConeEnt(trace)
		--print(tgt)
	else
		tgt = tracetgt
	end--]]
	
	--[[if SERVER then
		if bit.band(GetConVar("scgg_primary_extra"):GetInt(), 2) == 2 and self:PuntCheck(tracetgt) and tracetgt != self.oldHP then
			self.Weapon:SetNextPrimaryFire( CurTime() )
		end
	end--]]
	
	--[[if SERVER then
		local clawcvar = GetConVar("scgg_claw_mode"):GetInt()
		if clawcvar >= 2 then
			if self:PickupCheck(tgt) then
				self:OpenClaws( true )
			elseif IsValid(self:GetHP()) and self.Fading != true then
				timer.Remove("scgg_move_claws_close"..self:EntIndex())
				self:OpenClaws( false )
			else
				if !timer.Exists("scgg_claw_close_delay"..self:EntIndex()) and IsValid(self) then
					timer.Create( "scgg_claw_close_delay"..self:EntIndex(), 0.6, 1, function()
						if IsValid(self) and IsValid(self.Owner) and self.Owner:Alive() and IsValid(self.Owner:GetViewModel()) then
							self:CloseClaws( true )
						end
					end)
				end
			end
		end
	end--]]
	
	if math.random(  6,  98 ) == 16 and !IsValid(self:GetHP()) and !self.Owner:KeyDown(IN_ATTACK2) and !self.Owner:KeyDown(IN_ATTACK) 
	--and !IsValid(self.Zap1) and !IsValid(self.Zap2) and !IsValid(self.Zap3) 
	then
		if self.Fading == true then return end
		self:ZapEffect()
	end
	
	if SERVER then
		if self.Owner:KeyPressed(IN_ATTACK2) or IsValid(self:GetHP()) then
			if self.Fading == true then return end
			self:GlowEffect()
			if IsValid(self.Zap1) then
				self.Zap1:Remove()
				self.Zap1 = nil
			end
			if IsValid(self.Zap2) then
				self.Zap2:Remove()
				self.Zap2 = nil
			end
			if IsValid(self.Zap3) then
				self.Zap3:Remove()
				self.Zap3 = nil
			end
		elseif self.Owner:KeyReleased(IN_ATTACK2) and !IsValid(self:GetHP()) then
			if self.Fading == true then return end
			self:RemoveGlow()
		end
	end
	
	if !self.Owner:KeyDown(IN_ATTACK) then
		--if GetConVar("scgg_style"):GetBool() then
		if bit.band(GetConVar("scgg_primary_extra"):GetInt(), 1) == 1 then
			self.Weapon:SetNextPrimaryFire( CurTime() - 0.55 ) 
		end
	end
	
	if SERVER then
		if self.Owner:KeyPressed(IN_ATTACK2) then
		if self.Fading == true then return end
		--if self:GetHP() then return end   This fixes the secondary dryfire not playing
		
			if IsValid(tgt) and tgt:GetMoveType() == MOVETYPE_VPHYSICS then
				local Mass = tgt:GetPhysicsObject():GetMass()
				if Mass > (self:GetMaxMass()) then
					--if !GetConVar("scgg_style"):GetBool() then
					self.Weapon:EmitSound("Weapon_PhysCannon.TooHeavy")
					return
					--end
				end
			else
				self.Weapon:EmitSound("Weapon_PhysCannon.TooHeavy")
				return
			end
		end
	end
	
	if IsValid(self.TP) then
		for _, child in pairs(self.TP:GetChildren()) do
			if child:GetClass() == "env_entity_dissolver" then
				child:Remove()
			end
		end
	end
	if IsValid(self:GetHP()) then
		if !IsValid(self.Owner) or !self.Owner:Alive() or !IsValid(self:GetHP():GetPhysicsObject()) then
			self:Drop()
		end
		if SERVER then
			--if !IsValid(self.TP) then self:TPrem() return end
			if !IsValid(self:GetHP()) then return end
			
			local phys_obj = nil
			if self:GetHP():IsRagdoll() and self.HPBone != nil and self.HPBone > -1 then
				phys_obj = self:GetHP():GetPhysicsObjectNum(self.HPBone)
			end
			if !IsValid(phys_obj) then
				phys_obj = self:GetHP():GetPhysicsObject()
			end
			
			if self.HP_OldAngles == nil then
				self.HP_OldAngles = phys_obj:GetAngles()
			end
			HPrad = self:GetHP():BoundingRadius()--/1.5
			if !IsValid(self.Owner) then return end
			
			local grabpos = self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistance+HPrad)
			local grabragpos = self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistanceRagdoll+HPrad)
			--local HPpos = self:GetHP():GetPos()
			
			local function FindHP(entity)
				local grabpos_sphere = ents.FindInSphere(grabpos, 5)
				local shootpos_sphere = ents.FindInSphere(self.Owner:GetShootPos(), 15)
				for _,ent in pairs(grabpos_sphere) do
					if IsValid(ent) and ent == entity then return true end
				end
				for _,ent in pairs(shootpos_sphere) do
					if IsValid(ent) and ent == entity then return true end
				end
				return false
			end
			
			local pullDir = self.Owner:GetShootPos() - self:GetHP():WorldSpaceCenter()
			pullDir:Normalize()
			pullDir = pullDir*self:GetPullForce(self:GetHP())
			
			local mass = 50.0
			mass = phys_obj:GetMass()
			
			pullDir = pullDir* (mass + 0.5) * (1/5.0)
			if !FindHP(self:GetHP()) and !IsValid(self.TP) then
				phys_obj:SetVelocity(Vector(0,0,0))
				phys_obj:ApplyForceCenter(pullDir)
			elseif IsValid(self.TP) then
				if self:GetHP():IsRagdoll() then
					self.TP:SetPos(grabragpos)
				else
					self.TP:SetPos(grabpos)
				end
				self.TP:PointAtEntity(self.Owner)
			else
				self:CreateTP()
			end
			
			local prev_angles = self:GetHP():GetAngles()
			self:GetHP():SetAngles(Angle(0, prev_angles.y, prev_angles.r))
			if IsValid(phys_obj) then
				phys_obj:Wake()
			end
		end
		
		if self.PropLockTime == nil then
			self.PropLockTime = CurTime()+2.0
		end
		if !GetConVar("scgg_style"):GetBool() and CurTime() >= self.PropLockTime then
			if !IsValid(self:GetHP()) then self:SetHP(nil) return end
			if (self:GetHP():GetPos()-(self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistance+HPrad))):Length() >= 80 then
				self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
				self.Owner:SetAnimation( PLAYER_ATTACK1 )
				self:Drop()
			end
		end
	elseif self:GetHP_PickedUp() then
		self:Drop()
		self.HP_OldAngles = nil
		self:SetHP_PickedUp(nil) -- GARRY'S MOD JUST CAN'T DO THIS WITH HPREM OMFG
	end
	--self:NextThink(CurTime()+5.0)
end

function SWEP:ZapEffect() -- The random zap effects of the SCGG.
	if self.Fading == true then return end
	if SERVER then
		if GetConVar("scgg_no_effects"):GetBool() then return end
		--if GetConVar("scgg_style"):GetInt() <= 1 then return end
		if IsValid(self.Zap1) and IsValid(self.Zap2) and IsValid(self.Zap3) then return end
		local zap_math = table.Random( { 1, 2, 3 } )
		if zap_math == 1 and !IsValid(self.Zap1) then
			self.Zap =  ents.Create("MegaPhyscannonZap")
			--self.Zap:SetNWInt("tempent_SCGGzapmode", -1)
			self.Zap1 = self.Zap
		elseif zap_math == 2 and !IsValid(self.Zap2) then
			self.Zap =  ents.Create("MegaPhyscannonZap")
			self.Zap:SetNWInt("tempent_SCGGzapmode", 0)
			self.Zap2 = self.Zap
		elseif zap_math == 3 and !IsValid(self.Zap3) then
			self.Zap =  ents.Create("MegaPhyscannonZap")
			self.Zap:SetNWInt("tempent_SCGGzapmode", 1)
			self.Zap3 = self.Zap
		end
		if IsValid(self.Zap) then
		self.Zap:SetPos( self.Owner:GetShootPos() )
		self.Zap:Spawn()
		self.Zap:SetParent(self.Owner)
		self.Zap:SetOwner(self.Owner)
		end
	end
end

function SWEP:NotAllowedClass(ent)
	if !IsValid(ent) then return false end
	if !GetConVar("scgg_affect_players"):GetBool() and ent:IsPlayer() then return true end
	local class = ent:GetClass()
	if class == "npc_strider"
		or class == "npc_helicopter"
		or class == "npc_combinedropship"
		or class == "npc_antliongrub"
		or class == "npc_turret_ceiling"
		or class == "npc_sniper"
		or class == "npc_combine_camera"
		or class == "npc_combinegunship"
		or class == "npc_bullseye" then return true
	else
		return false
	end
end

function SWEP:AllowedClass(ent)
	if !IsValid(ent) then return false end
	--local trace = self.Owner:GetEyeTrace()
	local class = ent:GetClass()
	for _,child in pairs(ent:GetChildren()) do
		if child:GetClass() == "env_entity_dissolver" then
			return false
		end
	end -- Not yet fully tested
	if !GetConVar("scgg_affect_players"):GetBool() and ent:IsPlayer() then return false end
	if class == "npc_manhack"
		or class == "npc_turret_floor"
		or class == "npc_sscanner"
		or class == "npc_cscanner"
		or class == "npc_clawscanner"
		or class == "npc_rollermine"
		or class == "npc_grenade_frag"
		or class == "item_ammo_357"
		or class == "item_ammo_ar2_altfire"
		or class == "item_ammo_crossbow"
		or class == "item_ammo_pistol"
		or class == "item_ammo_smg1"
		or class == "item_ammo_smg1_grenade"
		or class == "item_battery"
		or class == "item_box_buckshot"
		or class == "item_healthvial"
		or class == "item_healthkit"
		or class == "item_rpg_round"
		or class == "item_ammo_ar2"
		or class == "item_item_crate"
		or (ent:IsWeapon() and !IsValid(ent:GetOwner()))
		or class == "megaphyscannon"
		or class == "weapon_striderbuster"
		or class == "combine_mine"
		or class == "bounce_bomb" -- Alternate classnames of combine_mine
		or class == "combine_bouncemine" -- Alternate classnames of combine_mine
		or class == "gmod_camera"
		or class == "gmod_cameraprop"
		or class == "helicopter_chunk"
		or class == "func_physbox"
		or class == "grenade_helicopter"
		or class == "prop_combine_ball"
		or class == "gmod_wheel"
		or class == "prop_vehicle_prisoner_pod"
		or class == "prop_physics_respawnable"
		or class == "prop_physics_multiplayer"
		or class == "prop_physics_override"
		or class == "prop_physics"
		or class == "prop_dynamic" then return true
	elseif !ent:IsNPC() and !ent:IsPlayer() and !ent:IsRagdoll() and GetConVar("scgg_allow_others"):GetBool() and !self:NotAllowedClass(ent) then
		return true
	else
		return false
	end
end

function SWEP:FriendlyNPC( npc )
	if SERVER then
		if !IsValid(npc) then return false end
		if !npc:IsNPC() then return false end
		
		if npc:Disposition( self.Owner ) == (D_LI or D_NU or D_ER) then
			return true
		else
			return false
		end
	end
end

--[[function SWEP:AllowedCenterPhysicsClass()
	local trace = self.Owner:GetEyeTrace()
	local class = trace.Entity:GetClass()
	if !IsValid(trace.Entity) then return false end
	if class == "gmod_wheel"
	or class == "prop_vehicle_prisoner_pod"
	or class == "prop_physics_respawnable"
	or class == "prop_physics_multiplayer"
	or class == "prop_physics"
	or class == "prop_physics_override"
	or class == "prop_dynamic"
	or class == "gmod_cameraprop"
	or class == "helicopter_chunk"
	or class == "func_physbox"
	or class == "grenade_helicopter"
	or class == "func_brush"
	or class == "npc_manhack"
	or class == "npc_turret_floor"
	or class == "npc_sscanner"
	or class == "npc_cscanner"
	or class == "npc_clawscanner"
	or class == "npc_rollermine"
	or class == "npc_grenade_frag" 
	or class == "item_ammo_357"
	or class == "item_ammo_ar2_altfire"
	or class == "item_ammo_crossbow"
	or class == "item_ammo_pistol"
	or class == "item_ammo_smg1"
	or class == "item_ammo_smg1_grenade"
	or class == "item_battery"
	or class == "item_box_buckshot"
	or class == "item_healthvial"
	or class == "item_healthkit"
	or class == "item_rpg_round"
	or class == "item_ammo_ar2"
	or class == "item_item_crate"
	or trace.Entity:IsWeapon()
	or class == "weapon_striderbuster"
	or class == "combine_mine"
	or class == "bounce_bomb" -- Alternate classnames of combine_mine
	or class == "combine_bouncemine" -- Alternate classnames of combine_mine
	or class == "megaphyscannon" then
	return true
	else
	return false
	end
end--]]

function SWEP:HookPhysicsHurting(entity)
	if !IsValid(entity) then return end
	local class = entity:GetClass()
	if class != "npc_manhack" then return end
	entity.SCGG_HurtByHookPhys = nil
	
	local function SCGG_Collide_Damage( entity, data )
		if !entity.SCGG_HurtByHookPhys and data.OurOldVelocity:Length() > 250 then
			entity.SCGG_HurtByHookPhys = true
			local dmginfo = DamageInfo()
			dmginfo:SetDamage( data.OurOldVelocity:Length()/10 )
			--print(dmginfo:GetDamage())
			dmginfo:SetDamageForce( self.Owner:GetPos() )
			dmginfo:SetReportedPosition( self.Owner:GetPos() )
			dmginfo:SetAttacker( self.Owner )
			dmginfo:SetInflictor( self.Weapon )
			entity:TakeDamageInfo(dmginfo)
			if IsValid(data.HitEntity) and data.HitEntity:Health() > 0 and 
			(GetConVar("scgg_friendly_fire"):GetBool() or !self:FriendlyNPC(data.HitEntity)) then
				--dmginfo:SetDamage( data.OurOldVelocity:Length() )
				data.HitEntity:TakeDamageInfo(dmginfo)
			end
		end
		--local callbackget = self:GetCallbacks("PhysicsCollide")
		--print("me is here")
	end
	
	local callback = entity:AddCallback("PhysicsCollide", SCGG_Collide_Damage)
	timer.Simple(1.0, function()
		if IsValid(entity) then
			entity:RemoveCallback("PhysicsCollide", callback)
		end
	end)
end

function SWEP:SCGGDissolveEntity(entity)
	local name = "SCGG_Dissolving_"..entity:EntIndex()
	entity:SetName( name )
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

function SWEP:PrimaryAttack()
	--local PrimaryFired = self:GetNWBool("SCGG_PrimaryFired", false)
	--if self.Fading or self.PrimaryFired then return end
	if self.Fading or PrimaryFired then return end
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	local primaryfire_delay = 0
	if !GetConVar("scgg_style"):GetBool() then
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.5 )
		primaryfire_delay = 0.5
	elseif GetConVar("scgg_style"):GetBool() then
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.55 )
		primaryfire_delay = 0.55
	end
	--[[if bit.band(GetConVar("scgg_primary_extra"):GetInt(), 2) == 2 then
		if self:PuntCheck(self.Owner:GetEyeTrace().Entity) or IsValid(self:GetHP()) then
			self:SetNWBool("SCGG_PrimaryFired", true)
			timer.Create( "scgg_primaryfired_timer"..self:EntIndex(), primaryfire_delay, 1, function() 
				if IsValid(self) and IsValid(self.Owner) and IsValid(self.Weapon) and self.Owner:Alive() and self.Owner:GetActiveWeapon() == self then
					self:SetNWBool("SCGG_PrimaryFired", false)
				end
			end)
		end
	end--]]
	self.Weapon:SetNextSecondaryFire( CurTime() + 0.3 )
	
	if self.Owner:IsPlayer() then
		local vm = self.Owner:GetViewModel()
		timer.Create( "attack_idle"..self:EntIndex(), 0.4, 1, function()
			if !IsValid( self.Weapon ) then return end
			if IsValid(self.Owner) and IsValid(self) and self.Owner:GetActiveWeapon() == self and self.Fading == false then
				self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
			end
		end)
	end
	
	if IsValid(self:GetHP()) then
		--print((self:GetHP():GetPos()-(self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistance+HPrad))):Length() >= 80)
		if (self:GetHP():GetPos()-(self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistance+HPrad))):Length() >= 80 then
			return
		else
			self:DropAndShoot()
			return
		end
	end
	
	local trace = nil
	if self.Owner:IsPlayer() then
		trace = self.Owner:GetEyeTrace()
	else
		trace = util.TraceLine( {
			start = self.Owner:EyePos(),
			endpos = self.Owner:EyePos(),
			filter = {self, self.Owner},
			mask = MASK_SHOT_HULL
		} )
	end
	local tgt = trace.Entity
	
	if !IsValid(tgt) or 
	( (self.Owner:GetShootPos()-tgt:GetPos()):Length() > self:GetMaxPuntRange() )
	or self:NotAllowedClass(tgt) 
	or ( tgt:IsNPC() and !GetConVar("scgg_friendly_fire"):GetBool() and self:FriendlyNPC(tgt) ) then
		self.Weapon:EmitSound("Weapon_MegaPhysCannon.DryFire")
		return
	end
	
	--self.oldHP = tgt
	
	if tgt:IsNPC() and !self:AllowedClass(tgt) and !self:NotAllowedClass(tgt) or tgt:IsPlayer() then
		local ragdoll = nil
		if (SERVER) then
			if tgt:IsPlayer() and tgt:HasGodMode() == true then return end
			--if (tgt:IsPlayer() and server_settings.Int( "sbox_plpldamage" ) == 1) then
				--self.Weapon:EmitSound("Weapon_MegaPhysCannon.DryFire")
				--return
			--end
			if ( !GetConVar("scgg_style"):GetBool() and ( tgt:IsNPC() and tgt:Health() > self:GetMaxTargetHealth() or tgt:IsPlayer() and tgt:Health()+tgt:Armor() > self:GetMaxTargetHealth() ) ) or ( !util.IsValidRagdoll(tgt:GetModel()) ) then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage( self:GetMaxTargetHealth() )
				dmginfo:SetDamageForce( self.Owner:GetShootPos() )
				dmginfo:SetDamagePosition( trace.HitPos )
				dmginfo:SetDamageType( DMG_PHYSGUN )
				dmginfo:SetAttacker( self.Owner )
				dmginfo:SetInflictor( self.Weapon )
				dmginfo:SetReportedPosition( self.Owner:GetShootPos() )
				tgt:TakeDamageInfo( dmginfo )
			else
			
			if tgt:IsPlayer() then
				--[[net.Start( "PlayerKilledByPlayer" )
				net.WriteEntity( tgt )
				net.WriteString( "weapon_superphyscannon" )
				net.WriteEntity( self.Owner )
				net.Broadcast()--]]
			elseif tgt:IsNPC() then
				if tgt:GetShouldServerRagdoll() != true then
				tgt:SetShouldServerRagdoll( true )
				end
				if tgt:Health() >= 1 then
					--tgt:Fire( "AddOutput", "health 0", 0 )
					tgt:SetHealth( 0 )
				end
				--if tgt:GetClass() != "npc_antlion_worker" and (tgt:GetClass() != "npc_antlion" or 
				--tgt:GetModel()!="models/antlion_worker.mdl") then
				local dmg = DamageInfo()
				dmg:SetDamage( tgt:Health() )
				dmg:SetDamageForce( self.Owner:GetShootPos() )
				dmg:SetDamagePosition( trace.HitPos )
				dmg:SetDamageType( DMG_PHYSGUN )
				dmg:SetAttacker( self.Owner )
				dmg:SetInflictor( self.Weapon )
				dmg:SetReportedPosition( self.Owner:GetShootPos() )
				tgt:TakeDamageInfo( dmg )
				--end
				
				for _,rag in pairs( ents.FindInSphere( tgt:GetPos(), tgt:GetModelRadius() ) ) do
					if rag:IsRagdoll() and rag:GetModel() == tgt:GetModel() and rag:GetCreationTime() == CurTime() then
						--rag:Remove()
						ragdoll = rag
						break
					end
				end
			end
			
			--if tgt:GetClass() == "npc_antlion_worker" then return end
			
			if !IsValid(ragdoll)
			and tgt:GetClass() != "npc_antlion_worker" and (tgt:GetClass() != "npc_antlion" or tgt:GetModel() != "models/antlion_worker.mdl")
			then
				local newragdoll = ents.Create( "prop_ragdoll" )
				newragdoll:SetPos( tgt:GetPos())
				newragdoll:SetAngles(tgt:GetAngles()-Angle(tgt:GetAngles().p,0,0))
				newragdoll:SetModel( tgt:GetModel() )
				if tgt:GetSkin() then
					newragdoll:SetSkin( tgt:GetSkin() )
				end
				newragdoll:SetColor( tgt:GetColor() )
				for k,v in pairs(tgt:GetBodyGroups()) do
					newragdoll:SetBodygroup(v.id,tgt:GetBodygroup(v.id))
				end
				newragdoll:SetMaterial( tgt:GetMaterial() )
				newragdoll:SetKeyValue("spawnflags",8192)
				newragdoll:Spawn()
				ragdoll = newragdoll
				self.SCGGNewRagdollFormed = true
			end
			
			-- Just in case the NPC is scripted like VJ Base
			if IsValid(tgt:GetActiveWeapon()) then
			local wep = tgt:GetActiveWeapon()
			--local model = wep:GetModel()
			local wepclass = wep:GetClass()
			
				if tgt:IsNPC() then
					if !GetConVar("scgg_weapon_vaporize"):GetBool() then
						local weaponmodel = ents.Create( wepclass )
						weaponmodel:SetPos( tgt:GetShootPos() )
						weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
						weaponmodel:SetSkin( wep:GetSkin() )
						weaponmodel:SetColor( wep:GetColor() )
						weaponmodel:SetKeyValue("spawnflags","2")
						weaponmodel:Spawn()
						weaponmodel:Fire("Addoutput","spawnflags 0",1)
					elseif GetConVar("scgg_weapon_vaporize"):GetBool() then
						local weaponmodel = ents.Create( "prop_physics_override" )
						weaponmodel:SetPos( tgt:GetShootPos() )
						weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
						weaponmodel:SetModel( wep:GetModel() )
						weaponmodel:SetSkin( wep:GetSkin() )
						weaponmodel:SetColor( wep:GetColor() )
						weaponmodel:SetCollisionGroup( COLLISION_GROUP_WEAPON )
						weaponmodel:Spawn()
						self:SCGGDissolveEntity(weaponmodel)
					end
				end
			end
			
		if GetConVar("scgg_zap"):GetBool() and IsValid(ragdoll) then
		ragdoll:SCGG_RagdollZapper()
		end
		if IsValid(ragdoll) then
		ragdoll:SCGG_RagdollCollideTimer()
		
		ragdoll:SetPhysicsAttacker(self.Owner, 10)
		ragdoll:SetCollisionGroup( self.HPCollideG )
	
			--tgt:DropWeapon( tgt:GetActiveWeapon() )
			--if tgt:HasWeapon()
			ragdoll:SetMaterial( tgt:GetMaterial() )
			
			--if server_settings.Int( "ai_keepragdolls" ) == 0 then
				--ragdoll.Entity:Fire("FadeAndRemove","",0.3)
			--else
				ragdoll:Fire("FadeAndRemove","",120)
			--end
			if tgt:IsPlayer() then
			net.Start("SCGG_Ragdoll_GetPlayerColor")
			net.WriteInt(ragdoll:EntIndex(),32)
			net.WriteInt(tgt:EntIndex(),32)
			net.WriteVector(tgt:GetPlayerColor())
			net.Send(player.GetAll())
			end
		end
			
			if self.SCGGNewRagdollFormed == true and IsValid(ragdoll) then
			cleanup.Add (self.Owner, "props", ragdoll)
			undo.Create ("Ragdoll")
			undo.AddEntity (ragdoll)
			undo.SetPlayer (self.Owner)
			undo.Finish()
			
			--[[if !tgt:IsPlayer() and tgt:Health() <= 0 and IsValid(tgt) then
			net.Start( "PlayerKilledNPC" )
			net.WriteString( tgt:GetClass() )
			net.WriteString( self.Weapon:GetClass() )
			net.WriteEntity( self.Owner )
			net.Broadcast()
			end--]]
			end
			
			if tgt:IsPlayer() then
				--tgt:KillSilent()
				--ragdoll:SetPlayerColor( tgt:GetPlayerColor() )
				--tgt:AddDeaths(1)
				local dmg = DamageInfo()
				dmg:SetDamage( tgt:Health() )
				dmg:SetDamageForce( self.Owner:GetShootPos() )
				dmg:SetDamagePosition( trace.HitPos )
				dmg:SetDamageType( DMG_PHYSGUN )
				dmg:SetAttacker( self.Owner )
				dmg:SetInflictor( self.Weapon )
				dmg:SetReportedPosition( self.Owner:GetShootPos() )
				tgt:TakeDamageInfo( dmg )
				if IsValid(tgt:GetRagdollEntity()) then
					tgt:GetRagdollEntity():Remove()
				end
				tgt:SpectateEntity(ragdoll)
				tgt:Spectate(OBS_MODE_CHASE)

			elseif tgt:IsNPC() then
				--if tgt:Health() >= 1 then
				tgt:Fire("Kill","",0)
				--net.Start( "PlayerKilledNPC" )
				--net.WriteString( tgt:GetClass() )
				--net.WriteString( "weapon_superphyscannon" )
				--net.WriteEntity( self.Owner )
				--net.Broadcast()
				--end
			end
			
			self.Owner:AddFrags(1)
			
			if GetConVar("scgg_zap"):GetBool() and IsValid(ragdoll) then
			ragdoll:Fire("StartRagdollBoogie","",0) end
			--ragdoll:Fire("SetBodygroup","15",0)
			--timer.Remove( "SCGG_Ragdoll_Collision_Timer"..self:EntIndex() )
			
			--RagdollVisual(ragdoll, 1)
					if IsValid(ragdoll) then
			for i = 1, ragdoll:GetPhysicsObjectCount() do
				local bone = ragdoll:GetPhysicsObjectNum(i)
				
				if bone and bone.IsValid and bone:IsValid() then
					local bonepos, boneang = tgt:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
					
					if self.SCGGNewRagdollFormed == true then
					bone:SetPos(bonepos)
					bone:SetAngles(boneang)
					end
					timer.Simple( 0.01, 
					function()
						if IsValid(bone) then
							if !GetConVar("scgg_style"):GetBool() then --Ragdoll Thrown
								bone:AddVelocity(self.Owner:GetAimVector()*(13000/8))--/(ragdoll:GetPhysicsObject():GetMass()/200)) 
							else
								bone:AddVelocity(self.Owner:GetAimVector()*(ragdoll:GetPhysicsObject():GetMass()*self.PuntMultiply)) 
							end
						end
					end )
				end
			end
					end
		end
		
		end
		
		local ragdoll = ragdoll
		ragdoll = nil
		self.SCGGNewRagdollFormed = nil
		self:Visual()
		FadeScreen(self.Owner)
		--self:DoSparks()
	end
	if tgt:GetClass() == "npc_antlion_grub" then
		tgt:Fire("Squash","",0)
	end
	
	if self:IsMotionEnabledOrGrabbableFlag(tgt) then
		tgt:GetPhysicsObject():EnableMotion( true )
	end
	
	--if self:AllowedClass(tgt) or tgt:GetClass() == "prop_vehicle_airboat" or tgt:GetClass() == "prop_vehicle_jeep" and tgt:GetPhysicsObject():IsMoveable() then
	if self:AllowedClass(tgt) or tgt:GetClass() == "prop_vehicle_airboat" or tgt:GetClass() == "prop_vehicle_jeep" then
		self:Visual()
		FadeScreen(self.Owner)
		if tgt:GetClass() == "prop_combine_ball" then
			self.Owner:SimulateGravGunPickup( tgt )
			timer.Simple( 0.01, function() 
			if IsValid(tgt) then
			self.Owner:SimulateGravGunDrop( tgt ) 
			end
			end)
		end
		if (SERVER) then
			if !IsValid(tgt) or !IsValid(tgt:GetPhysicsObject()) then return end
			local position = trace.HitPos
			if !GetConVar("scgg_style"):GetBool() then --Prop Punting
			
			if tgt:GetClass() == "prop_combine_ball" or tgt:GetClass() == "npc_grenade_frag" then
			tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*480000) -- 100
			tgt:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*480000, position ) 
			tgt:SetOwner(self.Owner)
			else
			
			tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*(tgt:GetPhysicsObject():GetMass()*self.PuntMultiply)) --1000000
			tgt:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*(tgt:GetPhysicsObject():GetMass()*self.PuntMultiply), position )
			end
			
			else
			
			if tgt:GetClass() == "prop_combine_ball" then
			tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector())
			tgt:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector(), position )
			tgt:SetOwner(self.Owner)
			else
			tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*(tgt:GetPhysicsObject():GetMass()*self.PuntMultiply))
			tgt:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*(tgt:GetPhysicsObject():GetMass()*self.PuntMultiply), position )
			end
			
			end 
		tgt:SetPhysicsAttacker(self.Owner, 10)
		tgt:Fire("physdamagescale","99999",0)
		
		end
		
		self:HookPhysicsHurting(tgt)
		--if tgt:GetClass() == "npc_manhack" then
			tgt:SetSaveValue("m_flEngineStallTime", 2.0)
		--end
		tgt:SetSaveValue("m_hPhysicsAttacker", self.Owner)
	end
	
	if tgt:IsRagdoll() then
		self:Visual()
		FadeScreen(self.Owner)
		if (SERVER) then
		
			--[[for i = 1, tgt:GetPhysicsObjectCount() do
				local bone = tgt:GetPhysicsObjectNum(i)
				
				if bone and bone.IsValid and bone:IsValid() then
					bone:SetPhysicsAttacker(self.Owner, 4)
					tgt:GetPhysicsObject():SetPhysicsAttacker(self.Owner, 4)
				end
			end--]]
			tgt:SetPhysicsAttacker(self.Owner, 10)
			
			if GetConVar("scgg_zap"):GetBool() then
			tgt:Fire("StartRagdollBoogie","",0) end
			--RagdollVisual(tgt, 1)
			
		if GetConVar("scgg_zap"):GetBool() then
		tgt:SCGG_RagdollZapper()
		end
		tgt:SCGG_RagdollCollideTimer()
			
			for i = 1, tgt:GetPhysicsObjectCount() do
				local bone = tgt:GetPhysicsObjectNum(i)
				
				if bone and bone.IsValid and bone:IsValid() then
				if !GetConVar("scgg_style"):GetBool() then
					bone:AddVelocity(self.Owner:GetAimVector()*(10000/8)) else--/(tgt:GetPhysicsObject():GetMass()/200)) else
					bone:AddVelocity(self.Owner:GetAimVector()*(tgt:GetPhysicsObject():GetMass()*self.PuntMultiply)) 
					end
				end
			end
			
			--timer.Remove( "SCGG_Ragdoll_Collision_Timer"..self:EntIndex() )
			tgt:SetCollisionGroup( self.HPCollideG )
			--[[timer.Create( "SCGG_Ragdoll_Collision_Timer"..self:EntIndex(), 2, 1, function() 
				if IsValid(tgt) then
				tgt:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				end
			end )--]]
		end
	end
	
	if self:AllowedClass(tgt) and !tgt:IsRagdoll() and SERVER then
		local damageinfo = DamageInfo()
		damageinfo:SetDamage( 10 )
		damageinfo:SetDamageForce( self.Owner:GetShootPos() )
		damageinfo:SetDamagePosition( tgt:GetPos() )
		damageinfo:SetDamageType( DMG_PHYSGUN )
		damageinfo:SetAttacker( self.Owner )
		damageinfo:SetInflictor( self.Weapon )
		damageinfo:SetReportedPosition( self.Owner:GetShootPos() )
		tgt:TakeDamageInfo(damageinfo)
	end
	
end
	
function SWEP:DropAndShoot()
	if !IsValid(self) then return end
	self:DropGeneral()
	if !IsValid(self:GetHP()) then self:HPrem() return end
	self:GetHP():Fire("EnablePhyscannonPickup","",1)
	
	local HPHealth = self:GetHP():Health()
	if HPHealth > 0 and self.HPHealth > 0 then
		self:GetHP():SetHealth(self.HPHealth)
		self.HPHealth = -1
	end
	
	if self:GetHP():IsRagdoll() then
		self:GetHP():SetCollisionGroup( COLLISION_GROUP_NONE )
	else
		self:GetHP():SetCollisionGroup( self.HPCollideG )
	end
	self:GetHP():SetPhysicsAttacker(self.Owner, 10)
	
	--self:GetHP():SetNWBool("launched_by_scgg", true)
	self.Owner:SimulateGravGunDrop( self:GetHP() )
	if (self:GetHP():GetClass() == "prop_combine_ball") then
		self:GetHP():SetSaveValue("m_bLaunched", true)
	end
	
	FadeScreen(self.Owner)
	self:HookPhysicsHurting(self:GetHP())
	--if self:GetHP():GetClass() == "npc_manhack" then
		self:GetHP():SetSaveValue("m_flEngineStallTime", 2.0)
	--end
	self:GetHP():SetSaveValue("m_hPhysicsAttacker", self.Owner)
	
	self.Secondary.Automatic = true
	if GetConVar("scgg_style"):GetBool() then
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.5 )
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.55 )
	end
	if SERVER then
		self:RemoveGlow()
	end
	self:Visual()
	
	if IsValid(self:GetHP()) and self:GetHP():IsRagdoll() then
		local tr = self.Owner:GetEyeTrace()
		
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( 500 )
		dmginfo:SetAttacker( self:GetOwner() )
		dmginfo:SetInflictor( self )
		
		if GetConVar("scgg_zap"):GetBool() then
		self:GetHP():Fire("StartRagdollBoogie","",0)
		end
		--RagdollVisual(self:GetHP(), 1)
		
		for i = 1, self:GetHP():GetPhysicsObjectCount() do
			local bone = self:GetHP():GetPhysicsObjectNum(i)
			
			if bone and bone.IsValid and bone:IsValid() then
				if GetConVar("scgg_zap"):GetBool() then
				self:GetHP():SCGG_RagdollZapper()
				end
				self:GetHP():SCGG_RagdollCollideTimer()
				--timer.Simple( 0.02, --function()
					if IsValid(bone) then
						if !GetConVar("scgg_style"):GetBool() then
						bone:AddVelocity(self.Owner:GetAimVector()*(20000/8))--/(self:GetHP():GetPhysicsObject():GetMass()/200)) else
						elseif IsValid(self:GetHP():GetPhysicsObject()) then
						bone:AddVelocity(self.Owner:GetAimVector()*(self:GetHP():GetPhysicsObject():GetMass()*self.PuntMultiply)) 
						end
					end
				--end)
			end
		end
	elseif IsValid(self:GetHP()) and IsValid(self:GetHP():GetPhysicsObject()) then
		local trace = self.Owner:GetEyeTrace()
		local position = trace.HitPos
		
		--local IndexedHP = ents.GetByIndex(self:GetHP():EntIndex())
		--self:GetHP():GetPhysicsObject():SetVelocity(Vector(0,0,0))
		
		local HP_index = self:GetHP():EntIndex()
		timer.Simple(0.01, function()
			local HP_temp = ents.GetByIndex(HP_index)
			if !IsValid(HP_temp) or !IsValid(HP_temp:GetPhysicsObject()) or !IsValid(self) or !IsValid(self.Owner) then return end
			if !GetConVar("scgg_style"):GetBool() and HP_temp:GetClass() == "prop_combine_ball" then --Prop Throwing
				HP_temp:GetPhysicsObject():SetVelocity(Vector(0,0,0))
				HP_temp:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*480000)
				HP_temp:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*480000,position )
				HP_temp:SetOwner(self.Owner)
			elseif HP_temp:GetClass() == "prop_combine_ball" then
				HP_temp:GetPhysicsObject():SetVelocity(Vector(0,0,0))
				HP_temp:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*self.PuntForce/0.125)
				HP_temp:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*self.PuntForce/0.125,position )
				HP_temp:SetOwner(self.Owner)
			elseif !GetConVar("scgg_style"):GetBool() then
				HP_temp:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*(HP_temp:GetPhysicsObject():GetMass()*self.PuntMultiply)) --3500000 --500*( self:GetHP():GetPhysicsObject():GetMass() ) )
				HP_temp:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*(HP_temp:GetPhysicsObject():GetMass()*self.PuntMultiply) ,position ) 
			else
				HP_temp:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*self.PuntForce)
				HP_temp:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*self.PuntForce,position )
			end
		end)
	end
	self:GetHP():Fire("physdamagescale","999",0)
	
	--[[timer.Simple( 0.04, function()
		self:SetHP(nil)
	end)--]]
	
	if self.HPCollideG then
		self.HPCollideG = COLLISION_GROUP_NONE
	end
	if IsValid(self.TP) then
		self:TPrem()
	end
	self:HPrem()
end

function SWEP:SecondaryAttack()
	if self.Fading == true then return end
	if IsValid(self:GetHP()) then
		self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		self:Drop()
		return
	end
	
	local trace = self.Owner:GetEyeTrace()
	local tracetgt = trace.Entity
	local tgt = NULL
	
	if GetConVar("scgg_cone"):GetBool() and !self:PickupCheck(tracetgt) then--and !IsValid(self:GetHP()) then
		tgt = self:GetConeEnt(trace)
		--print(tgt)
	--[[if !IsValid(tgt) then return end
	local utiltrace = util.TraceLine( { 
		start = trace.StartPos,
		endpos = tgt:GetPos(),
		filter = {tgt}
	} )
	if (utiltrace.FractionLeftSolid > 0) then
		return
	end--]]
	else--if !GetConVar("scgg_cone"):GetBool() then
		tgt = tracetgt
	end
	
	--self:CloseClaws( false )
	
	if !IsValid(tgt) then
		return
	end
	local getstyle = GetConVar("scgg_style"):GetInt()
	if ( getstyle <= 0 ) 
	and 
	( ( tgt:IsNPC() or tgt:IsPlayer() ) and tgt:Health() > self:GetMaxTargetHealth() ) 
	or ( tgt:IsNPC() and tgt:GetClass() == "npc_bullseye" )
	or ( (tgt:IsNPC() or tgt:IsPlayer() or tgt:IsRagdoll() ) and !util.IsValidRagdoll(tgt:GetModel()) and !util.IsValidProp(tgt:GetModel()) ) 
	--or ( tgt:IsNPC() or tgt:IsPlayer() or tgt:IsRagdoll() ) and ( getstyle <= 0 and tgt:GetMass() > self.HL2MaxMass or getstyle > 0 and tgt:GetMass() > self.MaxMass ) -- Non-functioning
	then return end
	
	if !self:NotAllowedClass(tgt) and !self:AllowedClass(tgt) then
		local Dist = (tgt:GetPos()-self.Owner:GetPos()):Length()
		if Dist >= self:GetMaxPickupRange() then return end
		if tgt:IsPlayer() and tgt:HasGodMode() == true then return end
		--if tgt:IsPlayer() and server_settings.Int( "sbox_plpldamage" ) == 1 then
			--self.Weapon:EmitSound("Weapon_PhysCannon.TooHeavy")
			--return
		--end
		
		if tgt:IsNPC() and ( GetConVar("scgg_friendly_fire"):GetBool() or !self:FriendlyNPC(tgt) ) or tgt:IsPlayer() then
			
			if tgt:IsPlayer() then
				if tgt:Health() > 0 then
					--tgt:Fire( "AddOutput", "health 0", 0 )
					tgt:SetHealth( 0 )
				end
				local dmg = DamageInfo()
				dmg:SetDamage( tgt:Health() )
				dmg:SetDamageForce( self.Owner:GetShootPos() )
				dmg:SetDamageType( DMG_PHYSGUN )
				dmg:SetAttacker( self.Owner )
				dmg:SetInflictor( self.Weapon )
				dmg:SetReportedPosition( self.Owner:GetShootPos() )
				tgt:TakeDamageInfo( dmg )
				--[[net.Start( "PlayerKilledByPlayer" )
				net.WriteEntity( tgt )
				net.WriteString( "weapon_superphyscannon" )
				net.WriteEntity( self.Owner )
				net.Broadcast()--]]
				elseif tgt:IsNPC() then
				if tgt:GetShouldServerRagdoll() != true then
				tgt:SetShouldServerRagdoll( true )
				end
				if tgt:Health() >= 1 then
					tgt:SetHealth( 0 )
				end
				--if tgt:GetClass() != "npc_antlion_worker" and (tgt:GetClass() != "npc_antlion" or 
				--tgt:GetModel()!="models/antlion_worker.mdl") then
				local dmg = DamageInfo()
				dmg:SetDamage( tgt:Health() )
				dmg:SetDamageForce( self.Owner:GetShootPos() )
				dmg:SetDamageType( DMG_PHYSGUN )
				dmg:SetAttacker( self.Owner )
				dmg:SetInflictor( self.Weapon )
				dmg:SetReportedPosition( self.Owner:GetShootPos() )
				tgt:TakeDamageInfo( dmg )
				--end
				
				for _,rag in pairs( ents.FindInSphere( tgt:GetPos(), tgt:GetModelRadius() ) ) do
					if rag:IsRagdoll() and rag:GetModel() == tgt:GetModel() and rag:GetCreationTime() == CurTime() then
						--rag:Remove()
						ragdoll = rag
						break
					end
				end
			end
			
			if tgt:Health() >= 1 then return end
			
			if !IsValid(ragdoll) 
			and tgt:GetClass() != "npc_antlion_worker" and (tgt:GetClass() != "npc_antlion" or tgt:GetModel() != "models/antlion_worker.mdl")
			then
				local newragdoll = ents.Create( "prop_ragdoll" )
				newragdoll:SetPos( tgt:GetPos())
				newragdoll:SetAngles(tgt:GetAngles()-Angle(tgt:GetAngles().p,0,0))
				newragdoll:SetModel( tgt:GetModel() )
				if tgt:GetSkin() then
					newragdoll:SetSkin( tgt:GetSkin() )
				end
				newragdoll:SetColor( tgt:GetColor() )
				for k,v in pairs(tgt:GetBodyGroups()) do
					newragdoll:SetBodygroup(v.id,tgt:GetBodygroup(v.id))
				end
				newragdoll:SetMaterial( tgt:GetMaterial() )
				newragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				newragdoll:SetKeyValue("spawnflags",8192)
				newragdoll:Spawn()
				ragdoll = newragdoll
				self.SCGGNewRagdollFormed = true
			elseif !IsValid(ragdoll) then
				-- This makes the SCGG grab a part of the 
				for _,rag in pairs( ents.FindInSphere( tgt:GetPos(), tgt:GetModelRadius() ) ) do
					if (rag:IsRagdoll() or rag:GetClass() == "prop_physics") and rag:GetCreationTime() == CurTime() then
						ragdoll = rag
						break
					end
				end
			end
			
			if IsValid(tgt:GetActiveWeapon()) then
				local wep = tgt:GetActiveWeapon()
				--local model = wep:GetModel()
				local wepclass = wep:GetClass()
				
				if tgt:IsNPC() then
					if !GetConVar("scgg_weapon_vaporize"):GetBool() then
						local weaponmodel = ents.Create( wepclass )
						weaponmodel:SetPos( tgt:GetShootPos() )
						weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
						--if IsValid(model) then
						--weaponmodel:SetModel( model )
						--end
						weaponmodel:SetSkin( wep:GetSkin() )
						weaponmodel:SetColor( wep:GetColor() )
						weaponmodel:SetKeyValue("spawnflags","2")
						weaponmodel:Spawn()
						weaponmodel:Fire("Addoutput","spawnflags 0",1)
					elseif GetConVar("scgg_weapon_vaporize"):GetBool() then
						local weaponmodel = ents.Create( "prop_physics_override" )
						weaponmodel:SetPos( tgt:GetShootPos() )
						weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
						weaponmodel:SetModel( wep:GetModel() )
						weaponmodel:SetSkin( wep:GetSkin() )
						weaponmodel:SetColor( wep:GetColor() )
						weaponmodel:SetCollisionGroup( COLLISION_GROUP_WEAPON )
						weaponmodel:Spawn()
						self:SCGGDissolveEntity(weaponmodel)
					end
				end
			end
			
			if self.SCGGNewRagdollFormed == true and IsValid(ragdoll) then
			cleanup.Add (self.Owner, "props", ragdoll)
			undo.Create("Ragdoll")
			undo.AddEntity(ragdoll)
			undo.SetPlayer(self.Owner)
			undo.SetCustomUndoText("Undone Ragdoll")
			undo.Finish()
			
			--[[if !tgt:IsPlayer() and tgt:Health() <= 0 and IsValid(tgt) then
			net.Start( "PlayerKilledNPC" )
			net.WriteString( tgt:GetClass() )
			net.WriteString( self.Weapon:GetClass() )
			net.WriteEntity( self.Owner )
			net.Broadcast()
			end--]]
			end
			
			if tgt:IsPlayer() then
				--tgt:KillSilent()
				--ragdoll:SetColor( tgt:GetPlayerColor()  )
				--tgt:AddDeaths(1)
				--self.Owner:AddFrags(1)
				local dmg = DamageInfo()
				dmg:SetDamage( tgt:Health() )
				dmg:SetDamageForce( self.Owner:GetShootPos() )
				dmg:SetDamageType( DMG_PHYSGUN )
				dmg:SetAttacker( self.Owner )
				dmg:SetInflictor( self.Weapon )
				dmg:SetReportedPosition( self.Owner:GetShootPos() )
				tgt:TakeDamageInfo( dmg )
				if IsValid(tgt:GetRagdollEntity()) then
					tgt:GetRagdollEntity():Remove()
				end
				tgt:SpectateEntity(ragdoll)
				tgt:Spectate(OBS_MODE_CHASE)
			elseif tgt:IsNPC() then
				tgt:Fire("Kill","",0)
			end
			
			--ragdoll:Fire("SetBodygroup","15",0)
			self:SetHP(ragdoll)
			self:SetHP_PickedUp(true)
			
			self.Weapon:SetNextSecondaryFire( CurTime() + 0.2 )
			if GetConVar("scgg_style"):GetBool() then
			self.Weapon:SetNextPrimaryFire( CurTime() + 0.1 ) end
			self.Secondary.Automatic = false
			
			self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
			self.Owner:SetAnimation( PLAYER_ATTACK1 )
			
			if tgt:IsPlayer() then
			net.Start("SCGG_Ragdoll_GetPlayerColor")
			net.WriteInt(ragdoll:EntIndex(),32)
			net.WriteInt(tgt:EntIndex(),32)
			net.WriteVector(tgt:GetPlayerColor())
			net.Send(player.GetAll())
			end
			
			if self.SCGGNewRagdollFormed == true and IsValid(ragdoll) then
			for i = 1, ragdoll:GetPhysicsObjectCount() do
			local bone = ragdoll:GetPhysicsObjectNum(i)
			
				if bone and bone.IsValid and bone:IsValid() then
					local bonepos, boneang = tgt:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
					
					bone:SetPos(bonepos)
					bone:SetAngles(boneang)
				end
			end
			end
			ragdoll = nil
			self.SCGGNewRagdollFormed = nil
			timer.Simple( 0.01, function() 
				self:Pickup() 
			end )
		end
	end
	
	if tgt:GetMoveType() == MOVETYPE_VPHYSICS then
		if self:IsMotionEnabledOrGrabbableFlag(tgt) then
			tgt:GetPhysicsObject():EnableMotion( true )
		end
		local Mass = tgt:GetPhysicsObject():GetMass()
		local Dist = (tgt:GetPos()-self.Owner:GetPos()):Length()
		local vel = self:GetPullForce()/(Dist*0.002)
		local ragvel = self.HL2PullForceRagdoll/(Dist*0.001)
		
		if !GetConVar("scgg_style"):GetBool() then
			if Mass >= (self:GetMaxMass()+1) and tgt:GetClass() != "prop_combine_ball" then
				return
			end
		end
		
		if tgt:IsRagdoll() or self:AllowedClass(tgt) and tgt:GetPhysicsObject():IsMoveable() and ( !constraint.HasConstraints( tgt ) ) then
			if Dist < self:GetMaxPickupRange() then
				self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
				self.Owner:SetAnimation( PLAYER_ATTACK1 )
				self:SetHP(tgt)
				self:SetHP_PickedUp(true)
				self.Owner:SimulateGravGunPickup( self:GetHP() )
				self.HPCollideG = tgt:GetCollisionGroup()
				self:GetHP().EmergencyHPCollide = tgt:GetCollisionGroup()
				tgt:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				
				self:Pickup()
				self.Weapon:SetNextSecondaryFire( CurTime() + 0.2 )
				if GetConVar("scgg_style"):GetBool() then
					self.Weapon:SetNextPrimaryFire( CurTime() + 0.1 )
				end
				self.Secondary.Automatic = false
				
				if self:GetHP():IsRagdoll() then
					self.HPBone = trace.PhysicsBone
				end -- Uncomment out to reenable the buggy self.HPBone code parts
			--[[elseif !GetConVar("scgg_style"):GetBool() and tgt:IsRagdoll() then
				for d = 1, ent:GetPhysicsObjectCount() do
					local bone = ent:GetPhysicsObjectNum(d)
				
					if bone and bone.IsValid and bone:IsValid() then
					tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*-ragvel )
					bone:ApplyForceCenter(self.Owner:GetAimVector()*-ragvel )
					print("bruhto")
					end
				end--]]
			else
				tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*-vel )
			end
		end
	end
end

function SWEP:Pickup()
	if !IsValid(self:GetHP()) then self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) return end
	self.Weapon:EmitSound("Weapon_MegaPhysCannon.Pickup")
	self.Weapon:StopSound("Weapon_PhysCannon.OpenClaws")
	self.Weapon:StopSound("Weapon_PhysCannon.CloseClaws")
	self.Owner:EmitSound(HoldSound, SNDLVL_NORM, 100, 0.05)
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	--self.PropLockTime = CurTime()+1.25
	
	timer.Simple( 0.4,
	function()
		if IsValid(self) and IsValid(self.Owner) and IsValid(self.Owner:GetActiveWeapon()) and 
		self.Owner:Alive() and self.Owner:GetActiveWeapon() == self and 
		self.Fading == false then
			self.Weapon:SendWeaponAnim(ACT_VM_RELOAD)
		end
	end )
	
	local trace = self.Owner:GetEyeTrace()
	
	self:GetHP():Fire("DisablePhyscannonPickup","",0)
	local HPHealth = self:GetHP():Health()
	if HPHealth > 0 then
		self.HPHealth = HPHealth
		self:GetHP():SetHealth(999999999)
	end
	
	if self:GetHP():IsRagdoll() then
		self:GetHP():SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	end
	
	if self:GetHP():GetClass() == "prop_combine_ball" then
		self:GetHP():SetOwner(self.Owner)
		if IsValid(self:GetHP():GetPhysicsObject()) then
			self:GetHP():GetPhysicsObject():AddGameFlag( FVPHYSICS_WAS_THROWN )
		end
	end
end

if SERVER then
function SWEP:Drop(temp_ply)
	if !IsValid(self) then return end
	
	local ply = self.Owner
	if !IsValid(self.Owner) and IsValid(temp_ply) then
		ply = temp_ply
	end
	
	self:DropGeneral()
	if IsValid(self:GetHP()) then
		self:GetHP():Fire("EnablePhyscannonPickup","",1)
		if self:GetHP():IsRagdoll() then
		self:GetHP():SetCollisionGroup(COLLISION_GROUP_WEAPON)
		else
		self:GetHP():SetCollisionGroup( self.HPCollideG )
		end
		
		if self:GetHP():GetClass() == "prop_combine_ball" then
			local HP_index = self:GetHP():EntIndex()
			timer.Simple(0.01, function()
				local HP_temp = ents.GetByIndex(HP_index)
				HP_temp:GetPhysicsObject():SetVelocity(Vector(0,0,0))
				HP_temp:GetPhysicsObject():ApplyForceCenter(Vector(math.random(360), math.random(360), math.random(360))*3000 )
			end )
		end
		
		local HPHealth = self:GetHP():Health()
		if HPHealth > 0 and self.HPHealth > 0 then
			self:GetHP():SetHealth(self.HPHealth)
			self.HPHealth = -1
		end
	end
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	if IsValid(self:GetHP()) and self:GetHP():IsRagdoll() then
		--RagdollVisual(self:GetHP(), 1)
		if GetConVar("scgg_zap"):GetBool() then
		self:GetHP():SCGG_RagdollZapper()
		end
		self:GetHP():SCGG_RagdollCollideTimer()
		if GetConVar("scgg_zap"):GetBool() then
		self:GetHP():Fire("StartRagdollBoogie","",0) 
		end
	end
	
	self.Secondary.Automatic = true
	self.Weapon:EmitSound("Weapon_MegaPhysCannon.Drop")
	self.Weapon:SetNextSecondaryFire( CurTime() + 0.5 )
	--[[if IsValid(self:GetHP()) and self:GetHP():GetClass() == "prop_combine_ball" then
		ply:SimulateGravGunPickup( self:GetHP() )
		timer.Simple( 0.01, function() 
			if IsValid(self:GetHP()) and IsValid(ply) then
			ply:SimulateGravGunDrop( self:GetHP() ) 
			end
		end)
	else--]]if IsValid(self:GetHP()) then
		ply:SimulateGravGunDrop( self:GetHP() )
	end
	
	timer.Simple( 0.4, function()
		if !IsValid( self.Weapon ) then return end
		if IsValid(ply) and IsValid(self) and ply:GetActiveWeapon() == self and self.Fading == false then
			self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
		end
	end)
	
	self:RemoveGlow()
	
	self:TPrem()
	self:HPrem()
	if self.HPCollideG then
		self.HPCollideG = COLLISION_GROUP_NONE
	end
end
end

function SWEP:DropGeneral()
	self.PropLockTime = nil
	self.HPBone = nil
	self.Weapon:StopSound(HoldSound)
end
	
function SWEP:Visual()
	self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self.Weapon:EmitSound( "Weapon_MegaPhysCannon.Launch" )
	if SERVER then
		if GetConVar("scgg_muzzle_flash"):GetBool() then
		local Light = ents.Create("light_dynamic")
		Light:SetKeyValue("brightness", "5")
		Light:SetKeyValue("distance", "200")
		Light:SetLocalPos(self.Owner:GetShootPos())
		Light:SetLocalAngles(self:GetAngles())
		Light:Fire("Color", "255 255 255")
		Light:SetParent(self)
		Light:Spawn()
		Light:Activate()
		Light:Fire("TurnOn", "", 0)
		self:DeleteOnRemove(Light)
		timer.Simple(0.1,function() if IsValid(self) and IsValid(Light) then Light:Remove() end end)
		end
	end
	if !GetConVar("scgg_style"):GetBool() and self.Owner:GetInfoNum("cl_scgg_effects_mode", 0) < 1 then
		self.Owner:ViewPunch( Angle( -5, 2, 0 ) ) 
	--else
	--self.Owner:ViewPunch( Angle( -5, 2, 0 ) ) 
	end
	
	local trace = self.Owner:GetEyeTrace()
	
	local effectdata = EffectData()
	if !IsValid(self:GetHP()) or trace.Entity != self:GetHP() then
		effectdata:SetOrigin( trace.HitPos )
	else
		effectdata:SetOrigin( self:GetHP():GetPos() )
	end
	effectdata:SetStart( self.Owner:GetShootPos() )
	effectdata:SetAttachment( 1 )
	effectdata:SetEntity( self.Weapon )
	util.Effect( "PhyscannonTracer", effectdata )
	--local e = EffectData()
	--e:SetEntity(trace.Entity)
	--e:SetMagnitude(30)
	--e:SetScale(30)
	--e:SetRadius(30)
	--util.Effect("TeslaHitBoxes", e)
	--trace.Entity:EmitSound("Weapon_StunStick.Activate")
	
	if SERVER then
		if GetConVar("scgg_no_effects"):GetBool() then return end
		self:MuzzleEffect()
		
		--[[timer.Simple( 0.12, function() 
			if IsValid(self) then
			self:RemoveMuzzle()
			end
		end)--]]
	end
	
	local e = EffectData()
	e:SetMagnitude(30)
	e:SetScale(30)
	e:SetRadius(30)
	e:SetOrigin(trace.HitPos)
	e:SetNormal(trace.HitNormal)
	--util.Effect("PhyscannonImpact", e)
	util.Effect("ManhackSparks", e)
end
	
--[[function SWEP:DoSparks()
	local trace = self.Owner:GetEyeTrace()
	local e = EffectData()
		e:SetMagnitude(30)
		e:SetScale(30)
		e:SetRadius(30)
		e:SetOrigin(trace.HitPos)
		e:SetNormal(trace.HitNormal)
		util.Effect("PhyscannonImpact", e)
		--util.Effect("ManhackSparks", e)
end--]]
	
--[[function RagdollVisual(ent, val) -- RagdollVisual does not seem to do anything.
if !IsValid(ent) then return end
			if IsValid(ent) then
			
			val = val+1
			
			--local effect = EffectData()
			--effect:SetEntity(ent)
			--effect:SetMagnitude(30)
			--effect:SetScale(30)
			--effect:SetRadius(30)
			--util.Effect("TeslaHitBoxes", effect)
			if GetConVar("scgg_zap_sound"):GetBool() then
			ent:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			
			if val <= 26 then
				timer.Simple((math.random(8,20)/100), RagdollVisual, ent, val)
			end
		end
	end--]]
	
local entmeta = FindMetaTable( "Entity" )
function entmeta:SCGG_RagdollZapper()
	if GetConVar("scgg_zap"):GetBool() then
		local name = "scgg_zapper_"..self:EntIndex()
		local ZapRepeats = 16
		if self.SCGG_IsBeingZapped == true then timer.Adjust(self.SCGG_TimerName,0.3,ZapRepeats) return end
		self.SCGG_IsBeingZapped = true
		self.SCGG_TimerName = name
		
		local effect2  	= EffectData()
		if !IsValid(self) then timer.Remove(name) return end
		effect2:SetOrigin(self:GetPos())
		effect2:SetStart(self:GetPos())
		effect2:SetMagnitude(5)
		effect2:SetEntity(self)
		util.Effect("teslaHitBoxes",effect2)
		if GetConVar("scgg_zap_sound"):GetBool() then
			self:EmitSound("Weapon_StunStick.Activate", 75, math.Rand(99, 101), 0.1)
		end
		
		--[[local function CollisionCheck( ent )
			if !IsValid(ent) then return false end
			local collision = ent:GetCollisionGroup()
			if collision!=COLLISION_GROUP_WEAPON 
			or collision!=COLLISION_GROUP_DEBRIS 
			or collision!=COLLISION_GROUP_DEBRIS_TRIGGER 
			or collision!=COLLISION_GROUP_WORLD 
			then 
			return true
			else
			return false
			end 
		end--]]
		
		timer.Create( name, 0.3, ZapRepeats, function()
			--print(name, timer.RepsLeft(name))
			local effect2  	= EffectData()
			if !IsValid(self) then timer.Remove(name) return end
			effect2:SetOrigin(self:GetPos())
			effect2:SetStart(self:GetPos())
			effect2:SetMagnitude(5)
			effect2:SetEntity(self)
			util.Effect("teslaHitBoxes",effect2)
			if GetConVar("scgg_zap_sound"):GetBool() then
			self:EmitSound("Weapon_StunStick.Activate", 75, math.Rand(99, 101), 0.1)
			end
			if !IsValid(self) then timer.Remove(name) return end
			if timer.RepsLeft(name) <= 0 then 
			
			local collision = self:GetCollisionGroup()
			--if CollisionCheck(self)==true then 
			--self:SetCollisionGroup(COLLISION_GROUP_WEAPON) 
			--end 
			
			self.SCGG_TimerName = nil 
			self.SCGG_IsBeingZapped = nil 
			timer.Remove(name) 
			return end
		end)
	end
end

function entmeta:SCGG_RagdollCollideTimer()
	local name = "scgg_collidecheck_"..self:EntIndex()
	if timer.Exists(name) then timer.Adjust(name,2.0,1) return end
	
	local function CollisionCheck( ent )
		if !IsValid(ent) then return false end
		local collision = ent:GetCollisionGroup()
		if collision!=COLLISION_GROUP_WEAPON 
		or collision!=COLLISION_GROUP_DEBRIS 
		or collision!=COLLISION_GROUP_DEBRIS_TRIGGER 
		or collision!=COLLISION_GROUP_WORLD 
		then 
		return true
		else
		return false
		end 
	end
	
	timer.Create( name, 4.5, 1, function()
		if !IsValid(self) then return end
		local collision = self:GetCollisionGroup()
		--if !GetConVar("scgg_cone"):GetBool() and CollisionCheck(self)==true then 
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON) 
		--end 
	end)
end

if SERVER then
function SWEP:Deploy()
	self:InitChangeableVars()
	
	self.OnDropOwner = self.Owner
	
	--self.Weapon:SetNextPrimaryFire( CurTime() + 5 )
	self.Weapon:SetNextSecondaryFire( CurTime() + 5 )
	--[[if IsValid(self.Owner:GetWeapon("weapon_physcannon")) then
		--print("yeah")
		net.Start("SCGG_Deploy_DisableGrav")
		net.Send( self.Owner )
	end--]]
	self:CoreEffect()
	self:TimerDestroyAll()
	
	--[[local claw_mode_cvar = GetConVar("scgg_claw_mode"):GetInt()
	if claw_mode_cvar <= 0 then
		self:CloseClaws( false )
	elseif (claw_mode_cvar > 0 and claw_mode_cvar < 2) then
		self:OpenClaws( false )
	end--]]
	--if !GetConVar("scgg_style"):GetBool() then
	--self.Weapon:SendWeaponAnim( ACT_VM_DRAW )
	if GetConVar("scgg_equip_sound"):GetBool() and GetConVar("scgg_enabled"):GetInt() > 0 then
		self.Weapon:EmitSound("weapons/physcannon/physcannon_charge.wav") 
	end
	--end
	local vm = self.Owner:GetViewModel()
	local duration = 0
	--if !GetConVar("scgg_style"):GetBool() then
	duration = vm:SequenceDuration()
	--else
	--duration = GetConVar("sv_defaultdeployspeed"):GetInt()
	--end
	timer.Create( "deploy_idle"..self:EntIndex(), duration, 1, function()
		if !IsValid( self.Weapon ) then return true end
		if IsValid(self.Owner) and IsValid(self) and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self 
		and self.Fading == false then
			self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
		end
		--self.Weapon:SetNextPrimaryFire( CurTime() + 0.01 )
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.01 )
	end)
	return true
end

function SWEP:Holster()
	--if SERVER then
		--print(self.Owner:GetInfo("cl_scgg_viewmodel"))
		local info = nil
		info = "models/weapons/shadowysn/c_superphyscannon.mdl"
		if self.Owner:GetInfo("cl_scgg_viewmodel") then
			info = self.Owner:GetInfo("cl_scgg_viewmodel")
		end
		if util.IsValidModel(info) and !IsUselessModel(info) then -- Doesn't work :/
			self.ViewModel = info
		end
	--end
	
	if !GetConVar("scgg_deploy_style"):GetBool() then
		self:SetDeploySpeed(1)
	else
		self:SetDeploySpeed(GetConVar("sv_defaultdeployspeed"):GetInt())
	end
	if IsValid(self:GetHP()) and self.Owner:Health() > 0 then
		return false
	end
	self:TimerDestroyAll()
	--[[if SERVER then
		if IsValid(self.Owner:GetWeapon("weapon_physcannon")) then
			local ply = self.Owner
			--print("yeah2")
			net.Start("SCGG_Holster_EnableGrav")
			net.Send( ply )
		end
	end--]]
	
	if IsValid(self:GetHP()) then
		self:Drop()
	end
	self:SetPoseParameter("active", 0)
	self:SetHP(nil)
	self:RemoveCore()
	self:TPrem()
	self:HPrem()
	
	if IsValid(self.FadeCore) then
		self.FadeCore:Remove()
	end
	
	return true
end
end

function SWEP:OnDrop()
	if SERVER and !GetConVar("scgg_no_effects"):GetBool() then
		self:RemoveCore()
		self:TPrem()
		self:HPrem()
	end
	
	if IsValid(self.OnDropOwner) then
		self:Drop(self.OnDropOwner)
	end
	
	self:Fire("Kill","",0.01)
	local grav_entity = ents.Create("MegaPhyscannon")
	grav_entity:SetPos( self:GetPos() )
	grav_entity:SetAngles( self:GetAngles() )
	grav_entity:SetMaterial(self:GetMaterial())
	grav_entity:SetColor(self:GetColor())
	grav_entity:Spawn()
	grav_entity:Activate()
	grav_entity:GetPhysicsObject():SetVelocity( self:GetPhysicsObject():GetVelocity() )
	grav_entity:GetPhysicsObject():AddAngleVelocity( self:GetPhysicsObject():GetAngleVelocity() )
	grav_entity:GetPhysicsObject():SetInertia( self:GetPhysicsObject():GetInertia() )
	grav_entity.ClawOpenState = self.ClawOpenState
	--grav_entity:GetPhysicsObject():SetVelocity( Vector( 0, 350, 0 ) )
	--grav_entity:GetPhysicsObject():ApplyForceCenter( Vector( 0, 0, -100 ) )
	--grav_entity:GetPhysicsObject():ApplyForceOffset( Vector( 0, 3500, 0 ) , self:GetPos() )
	grav_entity.Planted = false
	
	if self:GetHP() and IsValid(self:GetHP()) then
		self:SetHP(nil)
	end
end

function SWEP:HPrem()
	--if IsValid(self:GetHP()) then
		self:SetHP(nil)
		self.HP_OldAngles = nil
		self:SetHP_PickedUp(nil)
	--end
end

function SWEP:TPrem()
	if IsValid(self.TP) then
		self.TP:Remove()
	end
	if IsValid(self.Const) and (self.Const:IsConstraint() or self.Const:GetClass() == "phys_constraint") then
		self.Const:Remove()
		self.Const = nil
	end
	self.TP = nil
end

function SWEP:CreateTP()
	if !IsValid(self:GetHP()) then return end
	if self:GetHP():GetClass() == "prop_combine_ball" or self:GetHP():GetClass() == "npc_manhack" then
		self.TP = ents.Create("prop_dynamic")
	else
		self.TP = ents.Create("prop_physics")
	end
	--[[if self:AllowedCenterPhysicsClass() or !IsValid(self:GetHP():GetPhysicsObject()) then
		self.TP:SetPos(self:GetHP():LocalToWorld(self:GetHP():OBBCenter())) -- Doesn't affect much
	else
		self.TP:SetPos(self:GetHP():GetPhysicsObject():GetMassCenter())
	end--]]
	
	local phys_obj = nil
	--print(self.HPBone)
	if self:GetHP():IsRagdoll() and self.HPBone != nil and self.HPBone > -1 and constraint.CanConstrain(self:GetHP(), self.HPBone) then
		phys_obj = self:GetHP():GetPhysicsObjectNum(self.HPBone)
		if IsValid(phys_obj) then
			--self.TP:SetPos(self:GetHP():GetBonePosition(self:GetHP():TranslatePhysBoneToBone(self.HPBone)))
			self.TP:SetPos(phys_obj:GetPos())
		else
			self.TP:SetPos(self:GetHP():GetPos())
		end
	else
		self.TP:SetPos(self:GetHP():WorldSpaceCenter())
	end
	--self.TP:SetPos(self:GetHP():GetNetworkOrigin())
	self.TP:SetModel("models/props_junk/PopCan01a.mdl")
	self.TP:Spawn()
	self.TP:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self.TP:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self.TP:SetColor(Color(255, 255, 255, 0))
	self.TP:PointAtEntity(self.Owner)
	if self.TP:GetClass() == "prop_physics" then
		self.TP:GetPhysicsObject():SetMass(50000)
		self.TP:GetPhysicsObject():EnableMotion(false)
	end
	
	if !IsValid(self:GetHP():GetPhysicsObject()) then return end
	local trace = self.Owner:GetEyeTrace()
	
	local bone = math.Clamp(trace.PhysicsBone,0,1)
	if IsValid(phys_obj) then
		bone = self.HPBone
	end
	
	--[[if self:GetHP():IsRagdoll() then
		--self.Const = ents.Create("phys_constraint")
		self.Const:SetKeyValue("attach1", self.TP)
		self.Const:SetKeyValue("attach2", self:GetHP())
		self.Const:SetKeyValue("teleportfollowdistance", 1.0)
		self.Const:Spawn()
	else--]]
		self.Const = constraint.Weld(self.TP, self:GetHP(), 0, bone, 0, false)
	--end
end

--[[function SWEP:GetPuntForce()
	if GetConVar("scgg_style"):GetBool() then
		return self.PuntForce
	else
		return self.HL2PuntForce
	end
end--]]

function SWEP:GetPullForce(ragdoll)
	if !GetConVar("scgg_style"):GetBool() and IsValid(ragdoll) and ragdoll:IsRagdoll() then
		return self.HL2PullForceRagdoll
	elseif GetConVar("scgg_style"):GetBool() then
		return self.PullForce
	else
		return self.HL2PullForce
	end
end

function SWEP:GetMaxMass()
	if GetConVar("scgg_style"):GetBool() then
		return self.MaxMass
	else
		return self.HL2MaxMass
	end
end

function SWEP:GetMaxPuntRange()
	if GetConVar("scgg_style"):GetBool() then
		return self.MaxPuntRange
	else
		return self.HL2MaxPuntRange
	end
end

function SWEP:GetMaxPickupRange()
	if GetConVar("scgg_style"):GetBool() then
		return self.MaxPickupRange
	else
		return self.HL2MaxPickupRange
	end
end

function SWEP:GetMaxTargetHealth()
	if GetConVar("scgg_style"):GetBool() then
		return self.MaxTargetHealth
	else
		return self.HL2MaxTargetHealth
	end
end

function SWEP:MuzzleEffect()
	if IsValid(self.Core) and !self.Muzzle then
		net.Start("SCGG_Core_Muzzle")
		net.WriteEntity(self.Core)
		net.Broadcast()
		--self.Core:SetNWBool("SCGG_Muzzle", true)
		--self.Muzzle = true
		--[[timer.Simple( 0.12, function() 
			if IsValid(self) then
			self:RemoveMuzzle()
			end
		end)--]]
	end
end

--[[function SWEP:RemoveMuzzle()
	if IsValid(self.Core) and self.Muzzle then
		--self.Core:SetNWBool("SCGG_Muzzle", false)
		--self.Muzzle = nil
	end
end--]]

if SERVER then

function SWEP:CoreEffect()
	if GetConVar("scgg_no_effects"):GetBool() then return end
	if !IsValid(self.Core) then
		self.Core = ents.Create("MegaPhyscannonCore")
		self.Core:SetPos( self.Owner:GetShootPos() )
		self.Core:Spawn()
		--self.Core:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
	end
	self.CoreAllowRemove = false
	if !IsValid(self.Core) then return end
	self.Core:SetParent(self.Owner)
	self.Core:SetOwner(self.Owner)
end
	
function SWEP:GlowEffect()
	if GetConVar("scgg_no_effects"):GetBool() then return end
	if !IsValid(self.Core) then
		self:CoreEffect()
	end
	if !IsValid(self.Core) then return end
	self.Core:SetNWBool("SCGG_Glow", true)
	self.Glow = true
end

function SWEP:RemoveCore()
	if !self.Core then return end
	if !IsValid(self.Core) then return end
	self.CoreAllowRemove = true
	self.Core:Remove()
	self.Core = nil
end
	
function SWEP:RemoveGlow()
	if !self.Core then return end
	if !IsValid(self.Core) then return end
	self.Weapon:SetNWBool("Glow", false)
	self.Core:SetNWBool("SCGG_Glow", false)
	self.Glow = nil
end

end