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
SWEP.PuntMultiply				= 850
SWEP.PullForce					= 8000
SWEP.HL2PullForce				= 4000
SWEP.HL2PullForceRagdoll		= 3500
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

local CORE_STR = "SCGG_Core"

local function DissolveEntity(entity) -- The main dissolve function for dissolving things.
	local hasdissolve = nil
	for _,dissolver in ipairs(ents.FindByName("scgg_addon_global_dissolver")) do -- We check if the dissolver exists.
		if ent:GetClass() == "env_entity_dissolver" then
			ent:Fire("Dissolve", "", 0, entity) -- If it exists, have it dissolve our given entity
			hasdissolve = true -- and set this to true...
			break
		end
	end
	
	if hasdissolve != true then -- ...otherwise we spawn one.
		local dissolver = ents.Create("env_entity_dissolver")
		dissolver:SetPos(Vector(0,0,0))
		dissolver:SetKeyValue( "target", "!activator" ) -- This makes the activator the target so we don't have to rename targeted entities.
		dissolver:SetKeyValue( "dissolvetype", 0 )
		dissolver:SetName("scgg_addon_global_dissolver")
		dissolver:Spawn()
		dissolver:Activate()
		dissolver:Fire("Dissolve", "", 0, entity) -- Have the new one dissolve our given entity.
	end
end

local function DoPlayerOrNPCEyeTrace(swep, owner)
	local trace = nil
	if owner:IsPlayer() then
		trace = owner:GetEyeTrace()
	else
		--[[local endpos_val = owner:EyePos() + owner:GetAimVector() * 32768
		local owner_enemy = nil
		if owner:IsNPC() then
			owner_enemy = owner:GetEnemy()
			if IsValid(owner_enemy) and owner_enemy:Health() > 0 then
				if owner_enemy:IsPlayer() or owner_enemy:IsNPC() then
					endpos_val = owner_enemy:EyePos()
				end
			end
		end--]]
		
		trace = util.TraceHull( {
			start = owner:EyePos(),
			endpos = owner:EyePos() + owner:GetAimVector() * 32768,
			filter = {swep, owner},
			mins = Vector( -10, -10, -10 ),
			maxs = Vector( 10, 10, 10 ),
			mask = MASK_SHOT_HULL
		} )
		--[[trace = util.TraceLine( {
			start = owner:EyePos(),
			endpos = owner:EyePos() + owner:GetAimVector() * 32768,
			filter = {swep, owner},
			mask = MASK_SHOT_HULL
		} )--]]
	end
	return trace
end

local function IsOwnerAlive(owner)
	if owner:IsPlayer() then
		if !owner:Alive() then return false end
	elseif owner:IsNPC() then
		if owner:GetNPCState() == NPC_STATE_DEAD or owner:Health() <= 0 then return false end
	end
	return true
end

--[[local function GetConstrainedOtherEnt(swep, entity)
	local const_tbl = constraint.GetTable(entity)
	
	PrintTable(const_tbl)
	
	for _,val_tbl in ipairs(const_tbl) do
		for key,value in ipairs(val_tbl) do
			if key == "Ent1" or key == "Ent2" and value != entity and value != swep:GetTP() then
				return value
			end
		end
	end
	return nil
end--]]

local function DetermineHoldType(swep)
	if !IsValid(swep.Owner) then return end
	
	if swep.Owner:IsNPC() then
		swep.Weapon:SetHoldType( "shotgun" )
		if SERVER then
			if swep.Owner:Classify() == CLASS_METROPOLICE then
				swep.Weapon:SetHoldType( "smg" )
			end
		end
	else
		swep.Weapon:SetHoldType( swep.HoldType )
	end
end

local function ToggleHoldSound(swep, boolean)
	if boolean == true then
		local snd_ent = ents.Create("ambient_generic")
		
		snd_ent:SetPos( swep:GetPos() )
		snd_ent:SetKeyValue( "message", HoldSound )
		snd_ent:SetKeyValue( "health", "4" )
		snd_ent:SetKeyValue( "spawnflags", "16" )
		snd_ent:SetParent( swep )
		snd_ent:Spawn()
		snd_ent:Activate()
		
		snd_ent:Fire("PlaySound")
	else
		for _, child in ipairs(swep:GetChildren()) do
			if IsValid(child) and child:GetClass() == "ambient_generic" and child:GetInternalVariable( "message" ) == HoldSound then
				child:Fire("StopSound")
				child:Remove()
				break
			end
		end
	end
end

local function IsMotionEnabledOrGrabbableFlag(tgt)
	if IsValid(tgt) and tgt:GetMoveType() == MOVETYPE_VPHYSICS and IsValid(tgt:GetPhysicsObject()) and 
	(
	tgt:GetPhysicsObject():IsMotionEnabled() or
	(!tgt:GetPhysicsObject():IsMotionEnabled() and (tgt:HasSpawnFlags(64) or (tgt:GetClass() == "func_physbox" and tgt:HasSpawnFlags(131072))))
	--or self:AllowedClass(tgt)
	)
	then
		return true
	end
	return false
end

-- Some NPC support.
function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetCapabilities()
	if IsValid(self.Owner) and self.Owner:IsNPC() then
		self.Owner:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_PERFECT)
	end
	return bit.bor( CAP_WEAPON_RANGE_ATTACK2, CAP_INNATE_RANGE_ATTACK1 )
end

local function IsConstrainedToWorld(self, entity)
	--if !IsValid(entity) or !IsValid(self) then return false end
	--return false
	
	--local const_tbl = constraint.GetTable(entity)
	--PrintTable(const_tbl)
	
	--[[local initial_Ent = entity
	for i = 0, 2 do 
		if !initial_Ent or !IsValid(initial_Ent) and !initial_Ent:IsWorld() then break end
		
		--local phys_obj = initial_Ent:GetPhysicsObject()
		--print("testing:")
		--print(phys_obj:IsMotionEnabled())
		if initial_Ent:IsWorld() then
			--print("yes")
			return true
		elseif IsValid(initial_Ent) then
			local temp_ent = GetConstrainedOtherEnt(self, initial_Ent)
			initial_Ent = temp_ent
		else
			break
		end
	end--]]
	--print(IsValid(self.Const))
	--if IsValid(self.Const) then return false end
	
	--local const_tbl = constraint.GetTable(entity)
	--if const_tbl != {} then return true end
	
	--[[local temp_ent = GetConstrainedOtherEnt(self, entity)
	if IsValid(temp_ent) then
		return true
	end--]]
	
	return false
end

local function FadeScreen(ply)
	if IsValid(ply) and ply:IsPlayer() and ply:GetInfoNum("cl_scgg_effects_mode", 0) < 1 then
		ply:ScreenFade( SCREENFADE.IN, Color( 255, 255, 255, 40 ), 0.1, 0 )
	end
end

function SWEP:GetHP()
	return self:GetNWEntity("SCGG_HP", nil)
	--if !SERVER then return nil end
	--return self.HP
end
function SWEP:SetHP(entity)
	self:SetNWEntity("SCGG_HP", entity)
	--if !SERVER then return end
	--self.HP = entity
end
function SWEP:GetTP()
	return self:GetNWEntity("SCGG_TP", nil)
	--if !SERVER then return nil end
end
function SWEP:SetTP(entity)
	self:SetNWEntity("SCGG_TP", entity)
	--if !SERVER then return end
end

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

if SERVER then
	function SWEP:Initialize() -- Initialization stuff.
		DetermineHoldType(self)
		self:SetSkin(1)
		InitChangeableVars(self)
	end
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
					--if frame <= 0 then timer.Remove("scgg_move_claws_close"..self:EntIndex()) return end
					frame = frame-0.05
					ViewModel:SetPoseParameter(active_string, frame)
					ViewModel:InvalidateBoneCache()
				end
				if IsValid(WorldModel) then
					if worldframe < 0 then WorldModel:SetPoseParameter(active_string, 0) end
					--if worldframe <= 0 then timer.Remove("scgg_move_claws_close"..self:EntIndex()) return end
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

local function TimerDestroyAll(self) -- DESTROY ALL TIMERS! DESTROY ALL TIMERS!
	timer.Remove("deploy_idle"..self:EntIndex())
	timer.Remove("attack_idle"..self:EntIndex())
	timer.Remove("scgg_move_claws_open"..self:EntIndex())
	timer.Remove("scgg_move_claws_close"..self:EntIndex())
	timer.Remove("scgg_claw_close_delay"..self:EntIndex())
	--timer.Remove("scgg_primaryfired_timer"..self:EntIndex())
end

function SWEP:OwnerChanged() -- Owner changed. Useful for changing hold type between NPC and Player.
	if SERVER then
		--self:RemoveCore()
		self:TPrem()
		self:HPrem()
	end
	
	DetermineHoldType(self)
end

local function DirectCheck(self, tgt) -- Check if can be punted/grabbed, but without distance checking. - DirectCheck(self, entity)
	--print(tgt:GetMoveType())
	
	-- v I sincerely apologize for this mess of a check, but it gets the job done.
	if IsValid(tgt) and self.Fading != true and
	(
		(
			(
				(
					self:AllowedClass(tgt)
					and
					tgt:GetMoveType() == MOVETYPE_VPHYSICS
				)
				and
				(
					IsValid(tgt:GetPhysicsObject())
					and
					tgt:GetPhysicsObject():GetMass() < (self:GetMaxMass())
					and
					IsMotionEnabledOrGrabbableFlag(tgt)
					or
					CLIENT -- Physics objects don't exist on client, so we don't check for them else it just doesn't work
				)
			)
			or
			(
				(
					(
						tgt:IsNPC()
						or
						tgt:IsNextBot()
					)
					and
					(
						(!ConVarExists("scgg_friendly_fire") or GetConVar("scgg_friendly_fire"):GetBool())
						or
						!self:FriendlyNPC( tgt )
					)
					and
					tgt:Health() <= self:GetMaxTargetHealth()
				)
				or
				tgt:IsPlayer()
				or
				tgt:IsRagdoll()
			)
		)
		and
		!self:NotAllowedClass(tgt)
	)
	then
		return true
	end
	return false
end

local function PuntCheck(self, tgt) -- Punting check, use this as if it were something like IsValid() - PuntCheck(self, entity)
	local DistancePunt_Test = 0
	if IsValid(tgt) then
		--DistancePunt_Test = (tgt:GetPos()-self.Owner:GetPos()):Length()
		DistancePunt_Test = ((tgt:GetPos()-self.Owner:GetPos()):LengthSqr()) / self:GetMaxPuntRange()
	else
		DistancePunt_Test = self:GetMaxPuntRange()+10
	end
	
	if (DirectCheck(self, tgt) and 
	DistancePunt_Test < self:GetMaxPuntRange() )
	--and !self.Owner:KeyDown(IN_ATTACK) -- Don't know why I commented this out, but I must've did it for a reason. Glitch, maybe?
	then
		return true
	end
	return false
end

function SWEP:PickupCheck(tgt) -- Pickup check. Like beforehand, use this as if it were something like IsValid() - self:PickupCheck(entity)
	local Distance_Test = 0
	if IsValid(tgt) then
		--Distance_Test = (tgt:GetPos()-self.Owner:GetPos()):Length()
		Distance_Test = ((tgt:GetPos()-self.Owner:GetPos()):LengthSqr()) / self:GetMaxPickupRange()
	else
		Distance_Test = self:GetMaxPickupRange()+10
	end
	
	if DirectCheck(self, tgt) and 
	( Distance_Test < self:GetMaxPickupRange() )
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
		for T,ent in ipairs( cone_tbl ) do
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
					local temp_tbl = { {ent, ((ent:GetPos()-self.Owner:EyePos()):LengthSqr()) / self:GetMaxPickupRange()} }
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
		for _,tbl in ipairs(cone_dist_table) do
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
	for T,ent in ipairs( cone ) do -- This sets up the tables for the decision of the winner entity.
		if DirectCheck(self, ent) and ent != self and ent != self.Owner then
			if ent:GetClass() == "prop_combine_ball" then
				local temp_tbl = { ent }
				table.Add(combineball_cone_tbl, temp_tbl)
			elseif ((ent:IsNPC() or ent:IsNextBot()) and 
			((!ConVarExists("scgg_friendly_fire") or GetConVar("scgg_friendly_fire"):GetBool()) or !self:FriendlyNPC(ent) )) 
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

local function SpawnNormalGrav(swep)
	local pos_temp = swep:GetPos()
	if IsValid(swep.Owner) then
		pos_temp = swep.Owner:EyePos()
	end
	
	local normalgrav = ents.Create("weapon_physcannon")
	normalgrav:SetPos( pos_temp )
	normalgrav:SetAngles( swep:GetAngles() )
	normalgrav:Spawn()
	normalgrav:Activate()
	if IsValid(swep.FadeCore) then
		swep.FadeCore:SetParent( normalgrav )
	end
	local phys_obj = swep:GetPhysicsObject()
	local phys_obj_2 = normalgrav:GetPhysicsObject()
	if IsValid(phys_obj) and IsValid(phys_obj_2) then
		phys_obj_2:SetVelocity( phys_obj:GetVelocity() )
		phys_obj_2:AddAngleVelocity(phys_obj:GetAngleVelocity())
	end
	
	cleanup.ReplaceEntity( swep, normalgrav )
	undo.ReplaceEntity( swep, normalgrav )
	undo.Finish()
	
	return normalgrav
end

if SERVER then
	function SWEP:Discharge() -- Revert-to-normal effect of the SCGG. Think of HL2:EP1's Direct Intervention chapter, after you've stabilized the core.
		if self.Fading == true or IsValid(self.FadeCore) then return end
		self.Fading = true
		
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
		local model_base = self
		local model_attachstr = "core"
		if IsValid(self.Owner) and self.Owner:IsPlayer() then
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
			if !IsValid(self) or !IsValid(self.Weapon) or !IsValid(self.Owner) or !self.Owner:IsPlayer() then return end
			self.Weapon:SendWeaponAnim(ACT_VM_HOLSTER)
		end)
		timer.Simple(0.90, function()
			if !IsValid(self) then return end
			if IsValid(self.FadeCore) then
				self.FadeCore:Remove()
			end
			
			--[[if IsValid(self.Owner) and self.Owner:Alive() then
				if !self.Owner:HasWeapon( "weapon_physcannon" ) then -- Give the old, cranky version of this energetic weapon.
					self.Owner:Give("weapon_physcannon")
				end
				if self.Owner:HasWeapon( "weapon_physcannon" ) and self.Owner:GetActiveWeapon() == self then
					self.Owner:SelectWeapon("weapon_physcannon") -- Switch to the Mr. CrankyWeak version.
				end
			end--]]
			local weak_grav = SpawnNormalGrav(self)
			if IsValid(self.Owner) and self.Owner:IsPlayer() then
				if self.Owner:HasWeapon( "weapon_physcannon" ) and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self then
					self.Owner:SelectWeapon("weapon_physcannon") -- Switch to the Mr. CrankyWeak version.
				end
			end
			local class = self:GetClass()
			if IsValid(self.Owner) and self.Owner:IsPlayer() and self.Owner:HasWeapon(class) and self.Owner:GetWeapon(class) == self then
				self.Owner:StripWeapon(class)
			else
				if IsValid(self.Owner) and self.Owner:IsNPC() then
					self.Owner:DropWeapon(self)
					--self.Owner:PickupWeapon(weak_grav)
				end
				self:Remove()
			end
		end)
	end
end

function SWEP:Think() -- Think function for the weapon.
	local HP = self:GetHP()
	
	local styleCvar = false
	if ConVarExists("scgg_style") then
		styleCvar = GetConVar("scgg_style"):GetBool()
	end
	if !styleCvar then -- Sway scales for scgg_style
		self.SwayScale 	= 3
		self.BobScale 	= 1
	else
		self.SwayScale 	= 1
		self.BobScale 	= 1
	end
	
	if SERVER and ConVarExists("scgg_enabled") and GetConVar("scgg_enabled"):GetInt() <= 0 and !self.Fading then
		self:Discharge()
	end
		
	if SERVER then
		--if !GetConVar("scgg_cone"):GetBool() then
		--[[for _,ent in pairs(ents.FindInSphere( self.Owner:GetShootPos(), self:GetMaxPickupRange() )) do
			if IsValid(ent) and ent:IsRagdoll() and ent:GetCollisionGroup() == COLLISION_GROUP_DEBRIS then
				-- For some reason, ragdolls/props that are debris cannot be targeted by the weapon, so this converts them to a targetable version.
				ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
			end
		end--]]
		--end
		if IsValid(self.Core) then
			self.Core:SetPos( self.Owner:GetShootPos() )
		end
	end
	
	--local trace = self.Owner:GetEyeTrace()
	--local tracetgt = trace.Entity
	local tgt = nil
	
	--[[if GetConVar("scgg_cone"):GetBool() and !self:PickupCheck(tracetgt) then--and (!IsValid(HP)) then
		tgt = self:GetConeEnt(trace)
		--print(tgt)
	else
		tgt = tracetgt
	end--]]
	
	--[[if SERVER then
		if bit.band(GetConVar("scgg_primary_extra"):GetInt(), 2) == 2 and PuntCheck(self, tracetgt) and tracetgt != self.oldHP then
			self.Weapon:SetNextPrimaryFire( CurTime() )
		end
	end--]]
	
	--[[if SERVER then
		local clawcvar = GetConVar("scgg_claw_mode"):GetInt()
		if clawcvar >= 2 then
			if self:PickupCheck(tgt) then
				self:OpenClaws( true )
			elseif IsValid(HP) and self.Fading != true then
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
	
	--[[if math.random(  6,  98 ) == 16 and !IsValid(HP) and !self.Owner:KeyDown(IN_ATTACK2) and !self.Owner:KeyDown(IN_ATTACK) 
	--and !IsValid(self.Zap1) and !IsValid(self.Zap2) and !IsValid(self.Zap3) 
	then
		if self.Fading == true then return end
		self:ZapEffect()
	end--]]
	
	if SERVER then
		if IsValid(HP) and !self.Fading then
			self:GlowEffect()
		else
			self:RemoveGlow()
		end
	end
	
	if IsValid(self.Owner) and self.Owner:IsPlayer() then
		if !self.Owner:KeyDown(IN_ATTACK) then
			--if GetConVar("scgg_style"):GetBool() then
			if ConVarExists("scgg_primary_extra") and bit.band(GetConVar("scgg_primary_extra"):GetInt(), 1) == 1 then
				self.Weapon:SetNextPrimaryFire( CurTime() - 0.55 ) 
			end
		end
		
		if SERVER then
			if self.Owner:KeyPressed(IN_ATTACK2) and !self.Fading then
			--if HP then return end   This fixes the secondary dryfire not playing
			
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
	end
	
	if IsValid(self:GetTP()) then
		for _, child in ipairs(self:GetTP():GetChildren()) do
			if child:GetClass() == "env_entity_dissolver" then
				child:Remove()
				break
			end
		end
	end
	if IsValid(HP) then
		if !IsValid(self.Owner) or !IsOwnerAlive(self.Owner) or !IsValid(HP:GetPhysicsObject()) then
			self:Drop()
		end
		if SERVER then
			--if !IsValid(self:GetTP()) then self:TPrem() return end
			
			local phys_obj = nil
			if HP:IsRagdoll() and self.HPBone != nil and util.IsValidPhysicsObject(HP, self.HPBone) then
				phys_obj = HP:GetPhysicsObjectNum(self.HPBone)
			end
			if !IsValid(phys_obj) then
				if IsValid(HP:GetPhysicsObject()) then
					phys_obj = HP:GetPhysicsObject()
					--print("Changed:")
					--print(phys_obj)
				else
					phys_obj = HP
					--print("Changed to HP!!!")
				end
			end
			
			--[[if self.HP_OldAngles == nil then
				self.HP_OldAngles = phys_obj:GetAngles()
			end--]]
			if !IsValid(self.Owner) then return end
			
			local HPrad = HP:BoundingRadius()--/1.5
			local grabpos = self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistance+HPrad)
			local grabragpos = self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistanceRagdoll+HPrad)
			--local HPpos = HP:GetPos()
			
			local function FindHP(entity)
				local grabpos_sphere = ents.FindInSphere(grabpos, 5)
				local shootpos_sphere = ents.FindInSphere(self.Owner:GetShootPos(), 15)
				for _,ent in ipairs(grabpos_sphere) do
					if IsValid(ent) and ent == entity then return true end
				end
				for _,ent in ipairs(shootpos_sphere) do
					if IsValid(ent) and ent == entity then return true end
				end
				return false
			end
			
			local pullDir = self.Owner:GetShootPos() - HP:WorldSpaceCenter()
			pullDir:Normalize()
			pullDir = pullDir*self:GetPullForce(HP)
			
			local mass = 50.0
			if phys_obj != HP then
				mass = phys_obj:GetMass()
			end
			
			pullDir = pullDir* (mass + 0.5) * (1/5.0)
			if !FindHP(HP) and !IsValid(self:GetTP()) or IsConstrainedToWorld(self, HP) then
				if phys_obj != HP then
					phys_obj:SetVelocityInstantaneous(Vector(0,0,0))
					phys_obj:AddAngleVelocity(phys_obj:GetAngleVelocity()*-1)
					--local phys_vel = phys_obj:GetVelocity()
					phys_obj:ApplyForceCenter(pullDir)
				else
					phys_obj:SetVelocity(Vector(0,0,0))
				end
			elseif IsValid(self:GetTP()) then
				if HP:IsRagdoll() then
					self:GetTP():SetPos(grabragpos)
				else
					self:GetTP():SetPos(grabpos)
				end
				self:GetTP():PointAtEntity(self.Owner)
			else
				self:CreateTP()
			end
			
			local prev_angles = HP:GetAngles()
			HP:SetAngles(Angle(0, prev_angles.y, prev_angles.r))
			if IsValid(phys_obj) then
				if phys_obj != HP then
					phys_obj:Wake()
				else
					phys_obj:Fire("Wake")
				end
			end
		end
		
		if self.PropLockTime == nil then
			self.PropLockTime = CurTime()+1.75
		end
		if !styleCvar and CurTime() >= self.PropLockTime then
			if !IsValid(HP) then self:SetHP(nil) return end
			local HPrad = HP:BoundingRadius()--/1.5
			if ((HP:GetPos()-(self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistance+HPrad))):LengthSqr()) / 80 >= 80 then
				self:Drop()
			end
		end
	elseif self.HP_PickedUp then
		self:Drop()
		--self.HP_OldAngles = nil
		self.HP_PickedUp = nil -- GARRY'S MOD JUST CAN'T DO THIS WITH HPREM OMFG
	end
end

--[[function SWEP:ZapEffect() -- The random zap effects of the SCGG.
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
end--]]

function SWEP:NotAllowedClass(ent)
	if !IsValid(ent) then return false end
	if ConVarExists("scgg_affect_players") and !GetConVar("scgg_affect_players"):GetBool() and IsValid(self.Owner) and self.Owner:IsPlayer() and ent:IsPlayer() then return true end
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
	for _,child in ipairs(ent:GetChildren()) do
		if child:GetClass() == "env_entity_dissolver" then
			return false
		end
	end -- Not yet fully tested
	if ConVarExists("scgg_affect_players") and !GetConVar("scgg_affect_players"):GetBool() and IsValid(self.Owner) and self.Owner:IsPlayer() and ent:IsPlayer() then return false end
	
	if !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and !ent:IsRagdoll() and ConVarExists("scgg_allow_others") and GetConVar("scgg_allow_others"):GetBool() and !self:NotAllowedClass(ent) then
		return true
	end
	
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
		or class == "func_pushable"
		or class == "grenade_helicopter"
		or class == "prop_combine_ball"
		or class == "gmod_wheel"
		or class == "prop_vehicle_prisoner_pod"
		or class == "prop_physics_respawnable"
		or class == "prop_physics_multiplayer"
		or class == "prop_physics_override"
		or class == "prop_physics"
		or class == "prop_dynamic"
		then return true
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
	else
		return false
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

local function HookPhysicsHurting(self, entity)
	if !IsValid(entity) then return end
	local class = entity:GetClass()
	if class != "npc_manhack" then return end
	entity.SCGG_HurtByHookPhys = nil
	
	local function SCGG_Collide_Damage( entity, data )
		--local distance = data.OurOldVelocity:Length()
		local distance = data.OurOldVelocity:LengthSqr() / 1550
		if !entity.SCGG_HurtByHookPhys and distance > 250 then
			entity.SCGG_HurtByHookPhys = true
			local dmginfo = DamageInfo()
			dmginfo:SetDamage( distance/10 )
			--print(dmginfo:GetDamage())
			dmginfo:SetDamageForce( self.Owner:GetPos() )
			dmginfo:SetReportedPosition( self.Owner:GetPos() )
			dmginfo:SetAttacker( self.Owner )
			dmginfo:SetInflictor( self.Weapon )
			--print("damage: "..dmginfo:GetDamage())
			entity:TakeDamageInfo(dmginfo)
			if IsValid(data.HitEntity) and data.HitEntity:Health() > 0 and 
			((!ConVarExists("scgg_friendly_fire") or GetConVar("scgg_friendly_fire"):GetBool()) or !self:FriendlyNPC(data.HitEntity)) then
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

local function AttackDoDamage(self, tgt, traceHitPos, isPunt)
	if !SERVER then return end
	
	if isPunt == nil then isPunt = true end
	
	local dmginfo = DamageInfo()
	dmginfo:SetDamageForce( self.Owner:GetShootPos() )
	dmginfo:SetDamageType( DMG_PHYSGUN )
	dmginfo:SetAttacker( self.Owner )
	dmginfo:SetInflictor( self.Weapon )
	dmginfo:SetReportedPosition( self.Owner:GetShootPos() )
	if isPunt then
		dmginfo:SetDamage( self:GetMaxTargetHealth() )
		dmginfo:SetDamagePosition( traceHitPos )
	else
		dmginfo:SetDamage( tgt:Health() )
	end
	
	if tgt:IsPlayer() then
		tgt:TakeDamageInfo( dmginfo )
	elseif tgt:IsNPC() or tgt:IsNextBot() then
		if tgt:GetShouldServerRagdoll() != true then
			tgt:SetShouldServerRagdoll( true )
		end
		
		tgt:TakeDamageInfo( dmginfo )
	end
end

local function AttackAffectTarget(self, tgt, isPunt)
	if !SERVER then return nil end
	
	local ragdoll = nil
	
	if isPunt == nil then isPunt = true end
	
	for _,rag in ipairs( ents.FindInSphere( tgt:GetPos(), tgt:GetModelRadius() ) ) do
		if rag:IsRagdoll() and rag:GetCreationTime() == CurTime() then
			ragdoll = rag
			break
		end
	end
	
	local NewRagdollFormed = false
	if !IsValid(ragdoll) 
	and tgt:GetClass() != "npc_antlion_worker" and 
	(tgt:GetClass() != "npc_antlion" or tgt:GetModel() != "models/antlion_worker.mdl")
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
		if !isPunt then
			newragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		end
		newragdoll:SetKeyValue("spawnflags",8192)
		newragdoll:Spawn()
		ragdoll = newragdoll
		NewRagdollFormed = true
	elseif !isPunt and !IsValid(ragdoll) then
		-- This makes the SCGG grab a potential gib nearby
		for _,rag in ipairs( ents.FindInSphere( tgt:GetPos(), tgt:GetModelRadius() ) ) do
			if (rag:IsRagdoll() or rag:GetClass() == "prop_physics") and rag:GetCreationTime() == CurTime() then
				ragdoll = rag
				break
			end
		end
	end
	
	-- Just in case the NPC is scripted like VJ Base
	if (tgt:IsNPC() or tgt:IsPlayer()) and IsValid(tgt:GetActiveWeapon()) then
		local wep = tgt:GetActiveWeapon()
		local wepclass = wep:GetClass()
		
		if tgt:IsNPC() then
			local vaporCvar = false
			if ConVarExists("scgg_weapon_vaporize") then
				vaporCvar = GetConVar("scgg_weapon_vaporize"):GetBool()
			end
			if !vaporCvar then
				local weaponmodel = ents.Create( wepclass )
				if IsValid(weaponmodel) then
					weaponmodel:SetPos( tgt:GetShootPos() )
					weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
					weaponmodel:SetSkin( wep:GetSkin() )
					weaponmodel:SetColor( wep:GetColor() )
					weaponmodel:SetKeyValue("spawnflags","2")
					weaponmodel:Spawn()
					weaponmodel:Fire("Addoutput","spawnflags 0",1)
				end
			elseif vaporCvar then
				if IsValid(weaponmodel) then
					local weaponmodel = ents.Create( "prop_physics_override" )
					weaponmodel:SetPos( tgt:GetShootPos() )
					weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
					weaponmodel:SetModel( wep:GetModel() )
					weaponmodel:SetSkin( wep:GetSkin() )
					weaponmodel:SetColor( wep:GetColor() )
					weaponmodel:SetCollisionGroup( COLLISION_GROUP_WEAPON )
					weaponmodel:Spawn()
					DissolveEntity(weaponmodel)
				end
			end
		end
	end
	
	if self.Owner:IsPlayer() and NewRagdollFormed == true and IsValid(ragdoll) then
		cleanup.Add(self.Owner, "props", ragdoll)
		undo.Create("Ragdoll")
		undo.AddEntity(ragdoll)
		undo.SetPlayer(self.Owner)
		undo.Finish()
	end
	
	if tgt:IsPlayer() then
		if IsValid(tgt:GetRagdollEntity()) and tgt:GetRagdollEntity() != ragdoll then
			tgt:GetRagdollEntity():Remove()
			tgt:SpectateEntity(ragdoll)
			tgt:Spectate(OBS_MODE_CHASE)
		end
		net.Start("SCGG_Ragdoll_GetPlayerColor")
		net.WriteInt(ragdoll:EntIndex(),32)
		net.WriteInt(tgt:EntIndex(),32)
		net.WriteVector(tgt:GetPlayerColor())
		net.Send(player.GetAll())
	elseif tgt:IsNPC() or tgt:IsNextBot() then
		tgt:Fire("Kill","",0)
	end
	
	if (isPunt or NewRagdollFormed == true) and IsValid(ragdoll) then -- if is punting or new ragdoll is formed for non-punting
		for i = 1, ragdoll:GetPhysicsObjectCount() - 1 do
			local bone = ragdoll:GetPhysicsObjectNum(i)
			
			if bone and IsValid(bone) then
				if NewRagdollFormed == true then -- Set positions for any new formed ragdolls. Found ragdolls shouldn't need this.
					local bonepos, boneang = tgt:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
					
					bone:SetPos(bonepos)
					bone:SetAngles(boneang)
				end
				
				if isPunt then -- Throw force only for punting
					timer.Simple(0.01, function()
						if IsValid(self) and IsValid(self.Owner) and IsValid(bone) then
							if !styleCvar then --Ragdoll Thrown
								bone:AddVelocity(self.Owner:GetAimVector()*(13000/8))--/(ragdoll:GetPhysicsObject():GetMass()/200)) 
							else
								bone:AddVelocity(self.Owner:GetAimVector()*(bone:GetMass()*self.PuntMultiply)) 
							end
						end
					end)
				end
			end
		end
	end
	return ragdoll
end

function SWEP:PrimaryAttack()
	--local PrimaryFired = self:GetNWBool("SCGG_PrimaryFired", false)
	--if self.Fading or self.PrimaryFired then return end
	if self.Fading or PrimaryFired then return end
	
	local HP = self:GetHP()
	
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	local styleCvar = false
	if ConVarExists("scgg_style") then
		styleCvar = GetConVar("scgg_style"):GetBool()
	end
	local primaryfire_delay = 0
	if !styleCvar then
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.5 )
		primaryfire_delay = 0.5
	elseif styleCvar then
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.55 )
		primaryfire_delay = 0.55
	end
	--[[if bit.band(GetConVar("scgg_primary_extra"):GetInt(), 2) == 2 then
		if PuntCheck(self, self.Owner:GetEyeTrace().Entity) or IsValid(HP) then
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
		timer.Create( "attack_idle"..self:EntIndex(), 0.4, 1, function()
			if !IsValid( self.Weapon ) then return end
			if IsValid(self.Owner) and IsValid(self) and self.Owner:GetActiveWeapon() == self and self.Fading == false then
				self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
			end
		end)
	end
	
	if IsValid(HP) then
		local HPrad = HP:BoundingRadius()
		--print((HP:GetPos()-(self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistance+HPrad))):Length() >= 80)
		if ((HP:GetPos()-(self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.GrabDistance+HPrad))):LengthSqr()) / 80 >= 80 then
			return
		else
			self:DropAndShoot()
			return
		end
	end
	
	local trace = DoPlayerOrNPCEyeTrace(self, self.Owner)
	local tgt = trace.Entity
	
	if !PuntCheck(self, tgt) then
		--if self.Owner:IsNPC() then -- Secondary attack is very buggy for NPCs for now, because the Think function does not work on NPCs
		--	self:SecondaryAttack()
		--else
			self.Weapon:EmitSound("Weapon_MegaPhysCannon.DryFire")
		--end
		return
	end
	
	--self.oldHP = tgt
	
	self:Visual(trace)
	FadeScreen(self.Owner)
	
	local styleCvar = false
	if ConVarExists("scgg_style") then
		styleCvar = GetConVar("scgg_style"):GetBool()
	end
	local zapCvar = true
	if ConVarExists("scgg_zap") then
		zapCvar = GetConVar("scgg_zap"):GetBool()
	end
	
	if SERVER then
		if ((tgt:IsNPC() or tgt:IsNextBot()) and !self:AllowedClass(tgt) and !self:NotAllowedClass(tgt) or tgt:IsPlayer()) then
			--if tgt:IsPlayer() and tgt:HasGodMode() == true then return end
			--if (tgt:IsPlayer() and server_settings.Int( "sbox_plpldamage" ) == 1) then
				--self.Weapon:EmitSound("Weapon_MegaPhysCannon.DryFire")
				--return
			--end
			
			AttackDoDamage(self, tgt, trace.HitPos, true)
			
			--if tgt:GetClass() == "npc_antlion_worker" then return end
			if tgt:Health() > 0 then
				tgt:SetVelocity(self.Owner:GetAimVector() * Vector( 2500, 2500, 0 ))
				return 
			end
			
			local ragdoll = AttackAffectTarget(self, tgt, true)
			
			if zapCvar and IsValid(ragdoll) then
				ragdoll:SCGG_RagdollZapper()
			end
			if IsValid(ragdoll) then
				ragdoll:SCGG_RagdollCollideTimer()
		
				ragdoll:SetPhysicsAttacker(self.Owner, 10)
				ragdoll:SetCollisionGroup( self.HPCollideG )
		
				--tgt:DropWeapon( tgt:GetActiveWeapon() )
				--if tgt:HasWeapon()
				ragdoll:SetMaterial( tgt:GetMaterial() )
		
				ragdoll:Fire("FadeAndRemove","",120)
			end
			
			if self.Owner:IsPlayer() then
				self.Owner:AddFrags(1)
			end
			
			if zapCvar and IsValid(ragdoll) then
				ragdoll:Fire("StartRagdollBoogie","",0)
			end
			
			--self:DoSparks()
		elseif tgt:GetMoveType() != MOVETYPE_VPHYSICS and tgt:Health() > 0 then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage( self:GetMaxTargetHealth() )
			dmginfo:SetDamageForce( self.Owner:GetShootPos() )
			dmginfo:SetDamagePosition( trace.HitPos )
			dmginfo:SetDamageType( DMG_PHYSGUN )
			dmginfo:SetAttacker( self.Owner )
			dmginfo:SetInflictor( self.Weapon )
			dmginfo:SetReportedPosition( self.Owner:GetShootPos() )
			tgt:TakeDamageInfo( dmginfo )
		end
	end
	
	if IsMotionEnabledOrGrabbableFlag(tgt) then
		tgt:GetPhysicsObject():EnableMotion( true )
	end
	
	--if self:AllowedClass(tgt) or tgt:GetClass() == "prop_vehicle_airboat" or tgt:GetClass() == "prop_vehicle_jeep" and tgt:GetPhysicsObject():IsMoveable() then
	if self:AllowedClass(tgt) or tgt:GetClass() == "prop_vehicle_airboat" or tgt:GetClass() == "prop_vehicle_jeep" or (!self:NotAllowedClass() and IsValid(tgt:GetPhysicsObject())) then
		if tgt:GetClass() == "prop_combine_ball" and IsValid(self.Owner) and self.Owner:IsPlayer() then
			self.Owner:SimulateGravGunPickup( tgt )
			timer.Simple( 0.01, function() 
				if IsValid(tgt) and IsValid(self) and IsValid(self.Owner) and self.Owner:IsPlayer() then
					self.Owner:SimulateGravGunDrop( tgt ) 
				end
			end)
		end
		if (SERVER) then
			if !IsValid(tgt) or !IsValid(tgt:GetPhysicsObject()) then return end
			local position = trace.HitPos
			local phys = tgt:GetPhysicsObject()
			if !styleCvar then --Prop Punting
				if tgt:GetClass() == "prop_combine_ball" or tgt:GetClass() == "npc_grenade_frag" then
					phys:ApplyForceCenter(self.Owner:GetAimVector()*480000) -- 100
					phys:ApplyForceOffset(self.Owner:GetAimVector()*480000, position ) 
					tgt:SetOwner(self.Owner)
				else
					phys:ApplyForceCenter(self.Owner:GetAimVector()*(phys:GetMass()*self.PuntMultiply)) --1000000
					phys:ApplyForceOffset(self.Owner:GetAimVector()*(phys:GetMass()*self.PuntMultiply), position )
				end
			else
				if tgt:GetClass() == "prop_combine_ball" then
					phys:ApplyForceCenter(self.Owner:GetAimVector())
					phys:ApplyForceOffset(self.Owner:GetAimVector(), position )
					tgt:SetOwner(self.Owner)
				else
					phys:ApplyForceCenter(self.Owner:GetAimVector()*(phys:GetMass()*self.PuntMultiply))
					phys:ApplyForceOffset(self.Owner:GetAimVector()*(phys:GetMass()*self.PuntMultiply), position )
				end
			end 
			tgt:SetPhysicsAttacker(self.Owner, 10)
			--tgt:Fire("physdamagescale","99999",0)
		end
		
		HookPhysicsHurting(self, tgt)
		--if tgt:GetClass() == "npc_manhack" then
			tgt:SetSaveValue("m_flEngineStallTime", 2.0)
		--end
		tgt:SetSaveValue("m_hPhysicsAttacker", self.Owner)
	end
	
	if tgt:IsRagdoll() then
		if SERVER then
			--[[for i = 1, tgt:GetPhysicsObjectCount() - 1 do
				local bone = tgt:GetPhysicsObjectNum(i)
				
				if bone and bone.IsValid and bone:IsValid() then
					bone:SetPhysicsAttacker(self.Owner, 4)
					tgt:GetPhysicsObject():SetPhysicsAttacker(self.Owner, 4)
				end
			end--]]
			tgt:SetPhysicsAttacker(self.Owner, 10)
			
			if zapCvar then
				tgt:Fire("StartRagdollBoogie","",0)
			end
		end
		--RagdollVisual(tgt, 1)
		tgt:SCGG_RagdollZapper()
		tgt:SCGG_RagdollCollideTimer()
		
		for i = 1, tgt:GetPhysicsObjectCount() - 1 do
			local bone = tgt:GetPhysicsObjectNum(i)
			
			if bone and bone.IsValid and bone:IsValid() then
				if !styleCvar then
					bone:AddVelocity(self.Owner:GetAimVector()*(10000/8))
				else--/(tgt:GetPhysicsObject():GetMass()/200)) else
					bone:AddVelocity(self.Owner:GetAimVector()*(tgt:GetPhysicsObject():GetMass()*self.PuntMultiply)) 
				end
			end
		end
		
		if SERVER then
			tgt:SetCollisionGroup( self.HPCollideG )
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
	
	local HP = self:GetHP()
	if !IsValid(HP) then self:HPrem() return end
	if SERVER then HP:Fire("EnablePhyscannonPickup","",1) end
	
	local HPHealth = HP:Health()
	if HPHealth != nil and HPHealth > 0 and self.HPHealth != nil and self.HPHealth > 0 then
		HP:SetHealth(self.HPHealth)
		self.HPHealth = -1
	end
	
	if SERVER then
		if HP:IsRagdoll() then
			HP:SetCollisionGroup( COLLISION_GROUP_NONE )
		else
			HP:SetCollisionGroup( self.HPCollideG )
		end
		HP:SetPhysicsAttacker(self.Owner, 10)
		--HP:SetNWBool("launched_by_scgg", true)
		self.Owner:SimulateGravGunDrop( HP )
	end
	
	if (HP:GetClass() == "prop_combine_ball") then
		HP:SetSaveValue("m_bLaunched", true)
	end
	
	FadeScreen(self.Owner)
	HookPhysicsHurting(self, HP)
	--if HP:GetClass() == "npc_manhack" then
		HP:SetSaveValue("m_flEngineStallTime", 2.0)
	--end
	HP:SetSaveValue("m_hPhysicsAttacker", self.Owner)
	
	local styleCvar = false
	if ConVarExists("scgg_style") then
		styleCvar = GetConVar("scgg_style"):GetBool()
	end
	local zapCvar = true
	if ConVarExists("scgg_zap") then
		zapCvar = GetConVar("scgg_zap"):GetBool()
	end
	
	self.Secondary.Automatic = true
	if styleCvar then
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.5 )
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.55 )
	end
	
	local trace = DoPlayerOrNPCEyeTrace(self, self.Owner)
	self:Visual(trace)
	
	if IsValid(HP) and HP:IsRagdoll() then
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( 500 )
		dmginfo:SetAttacker( self:GetOwner() )
		dmginfo:SetInflictor( self )
		
		if SERVER and zapCvar then
			HP:Fire("StartRagdollBoogie","",0)
		end
		--RagdollVisual(HP, 1)
		
		for i = 1, HP:GetPhysicsObjectCount() - 1 do
			local bone = HP:GetPhysicsObjectNum(i)
			
			if bone and bone.IsValid and bone:IsValid() then
				if zapCvar then
					HP:SCGG_RagdollZapper()
				end
				HP:SCGG_RagdollCollideTimer()
				--timer.Simple( 0.02, --function()
					if IsValid(bone) then
						if !styleCvar then
							bone:AddVelocity(self.Owner:GetAimVector()*(20000/8))--/(HP:GetPhysicsObject():GetMass()/200)) else
						elseif IsValid(HP:GetPhysicsObject()) then
							bone:AddVelocity(self.Owner:GetAimVector()*(HP:GetPhysicsObject():GetMass()*self.PuntMultiply)) 
						end
					end
				--end)
			end
		end
	elseif IsValid(HP) and IsValid(HP:GetPhysicsObject()) then
		local position = trace.HitPos
		
		--local IndexedHP = ents.GetByIndex(HP:EntIndex())
		--HP:GetPhysicsObject():SetVelocity(Vector(0,0,0))
		
		local HP_temp = HP
		timer.Simple(0.01, function()
			if !IsValid(HP_temp) or !IsValid(HP_temp:GetPhysicsObject()) or !IsValid(self) or !IsValid(self.Owner) then return end
			local phys = HP_temp:GetPhysicsObject()
			if !styleCvar and HP_temp:GetClass() == "prop_combine_ball" then --Prop Throwing
				phys:SetVelocity(Vector(0,0,0))
				phys:ApplyForceCenter(self.Owner:GetAimVector()*480000)
				phys:ApplyForceOffset(self.Owner:GetAimVector()*480000,position )
				HP_temp:SetOwner(self.Owner)
			elseif HP_temp:GetClass() == "prop_combine_ball" then
				phys:SetVelocity(Vector(0,0,0))
				phys:ApplyForceCenter(self.Owner:GetAimVector()*self.PuntForce/0.125)
				phys:ApplyForceOffset(self.Owner:GetAimVector()*self.PuntForce/0.125,position )
				HP_temp:SetOwner(self.Owner)
			elseif !styleCvar then
				phys:ApplyForceCenter(self.Owner:GetAimVector()*(phys:GetMass()*self.PuntMultiply)) --3500000 --500*( HP:GetPhysicsObject():GetMass() ) )
				phys:ApplyForceOffset(self.Owner:GetAimVector()*(phys:GetMass()*self.PuntMultiply) ,position ) 
			else
				phys:ApplyForceCenter(self.Owner:GetAimVector()*self.PuntForce)
				phys:ApplyForceOffset(self.Owner:GetAimVector()*self.PuntForce,position )
			end
			phys:AddAngleVelocity(phys:GetAngleVelocity()*-1)
		end)
	end
	--HP:Fire("physdamagescale","999",0)
	
	--[[timer.Simple( 0.04, function()
		self:SetHP(nil)
	end)--]]
	
	if self.HPCollideG then
		self.HPCollideG = COLLISION_GROUP_NONE
	end
	if IsValid(self:GetTP()) then
		self:TPrem()
	end
	self:HPrem()
end

function SWEP:SecondaryAttack()
	if self.Fading == true then return end
	
	if IsValid(self:GetHP()) and self.Owner:IsPlayer() and self.Owner:KeyPressed(IN_ATTACK2) then
		self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		self:Drop()
		return
	end
	
	local trace = DoPlayerOrNPCEyeTrace(self, self.Owner)
	local tracetgt = trace.Entity
	local tgt = nil
	
	if (!ConVarExists("scgg_cone") or GetConVar("scgg_cone"):GetBool()) and !self:PickupCheck(tracetgt) then--and !IsValid(HP) then
		tgt = self:GetConeEnt(trace)
	else
		tgt = tracetgt
	end
	
	--self:CloseClaws( false )
	
	if !IsValid(tgt) then
		return
	end
	local styleCvar = false
	if ConVarExists("scgg_style") then
		styleCvar = GetConVar("scgg_style"):GetBool()
	end
	
	if ( !styleCvar ) 
	and 
	( ( tgt:IsNPC() or tgt:IsNextBot() or tgt:IsPlayer() ) and tgt:Health() > self:GetMaxTargetHealth() ) 
	or ( tgt:IsNPC() and tgt:GetClass() == "npc_bullseye" )
	or ( (tgt:IsNPC() or tgt:IsNextBot() or tgt:IsPlayer() or tgt:IsRagdoll() ) and !util.IsValidRagdoll(tgt:GetModel()) and !util.IsValidProp(tgt:GetModel()) ) 
	--or ( tgt:IsNPC() or tgt:IsPlayer() or tgt:IsRagdoll() ) and ( styleCvar <= 0 and tgt:GetMass() > self.HL2MaxMass or styleCvar > 0 and tgt:GetMass() > self.MaxMass ) -- Non-functioning
	then return end
	
	local maxPickupRange = self:GetMaxPickupRange()
	local Dist = ((tgt:GetPos()-self.Owner:GetPos()):LengthSqr()) / maxPickupRange
	local HasPickedUp = false
	
	local function DoPickup(target)
		if HasPickedUp == true then return end
		HasPickedUp = true
		self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		
		self:SetHP(target)
		
		self.HP_PickedUp = true
		if self.Owner:IsPlayer() then
			self.Owner:SimulateGravGunPickup(target)
		end
		self.HPCollideG = target:GetCollisionGroup()
		target.EmergencyHPCollide = target:GetCollisionGroup()
		target:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		
		self:Pickup()
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.2 )
		if styleCvar then
			self.Weapon:SetNextPrimaryFire( CurTime() + 0.1 )
		end
		self.Secondary.Automatic = false
		
		if target:IsRagdoll() then
			if trace.Entity == target then 
				self.HPBone = trace.PhysicsBone
			--[[else
				local oldTgt = trace.Entity
				local tPos = trace.HitPos
				local setBone = -1
				local tempDist = 32767
				print("fired else, bonecount: "..target:GetBoneCount())
				
				for i = 1, target:GetBoneCount() - 1 do
					local bonePos = target:GetBonePosition(i)
					
					local distance = (bonePos-tPos):LengthSqr()
					--local dist2 = (bonePos-tPos):Length()
					--print("Distance of bone "..i.." of SCGG's target: "..dist2)
					print("Sqr Distance of bone "..i.." of SCGG's target: "..distance)
					if distance < tempDist then
						tempDist = distance
						setBone = i
					end
				end
				
				print("setBone: "..setBone)
				if setBone > -1 then
					self.HPBone = setBone
				end--]]
			end
		end -- Uncomment out to reenable the buggy self.HPBone code parts
	--[[elseif !styleCvar and target:IsRagdoll() then
		for d = 1, ent:GetPhysicsObjectCount() - 1 do
			local bone = ent:GetPhysicsObjectNum(d)
		
			if bone and bone.IsValid and bone:IsValid() then
				target:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*-ragvel )
				bone:ApplyForceCenter(self.Owner:GetAimVector()*-ragvel )
			end
		end--]]
	end
	
	if SERVER and !self:NotAllowedClass(tgt) and !self:AllowedClass(tgt) and Dist < maxPickupRange then
		if tgt:IsPlayer() and tgt:HasGodMode() == true then return end
		
		if tgt:IsNPC() or tgt:IsNextBot() and (
		(!ConVarExists("scgg_friendly_fire") or GetConVar("scgg_friendly_fire"):GetBool()) or !self:FriendlyNPC(tgt) ) 
		or tgt:IsPlayer() then
			AttackDoDamage(self, tgt, trace.HitPos, false)
			
			if tgt:Health() >= 1 then return end
			
			local ragdoll = AttackAffectTarget(self, tgt, false)
			
			DoPickup(ragdoll)
		end
	end
	
	if SERVER and !HasPickedUp and IsValid(tgt:GetPhysicsObject()) and tgt:GetMoveType() == MOVETYPE_VPHYSICS then
		if IsMotionEnabledOrGrabbableFlag(tgt) then
			tgt:GetPhysicsObject():EnableMotion( true )
		end
		local Mass = tgt:GetPhysicsObject():GetMass()
		local vel = self:GetPullForce()/(Dist*0.002)
		local ragvel = self.HL2PullForceRagdoll/(Dist*0.001)
		
		if !styleCvar then
			if Mass >= (self:GetMaxMass()+1) and tgt:GetClass() != "prop_combine_ball" then
				return
			end
		end
		
		--if tgt:IsRagdoll() or self:AllowedClass(tgt) and tgt:GetPhysicsObject():IsMoveable() then--and !IsConstrainedToWorld(self, tgt) then
			if Dist < maxPickupRange then
				DoPickup(tgt)
			else
				--print("gay")
				tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*-vel )
			end
		--end
	end
end

function SWEP:Pickup()
	local HP = self:GetHP()
	
	if !IsValid(HP) then self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) return end
	
	self.Weapon:StopSound("Weapon_PhysCannon.OpenClaws")
	self.Weapon:StopSound("Weapon_PhysCannon.CloseClaws")
	self.Weapon:EmitSound("Weapon_MegaPhysCannon.Pickup")
	ToggleHoldSound(self, true)
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	--self.PropLockTime = CurTime()+1.25
	self.PropLockTime = nil
	
	timer.Simple( 0.4,
	function()
		if IsValid(self) and IsValid(self.Owner) and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:IsPlayer() and 
		IsOwnerAlive(self.Owner) and self.Owner:GetActiveWeapon() == self and 
		self.Fading == false then
			self.Weapon:SendWeaponAnim(ACT_VM_RELOAD)
		end
	end )
	
	local trace = DoPlayerOrNPCEyeTrace(self, self.Owner)
	
	HP:Fire("DisablePhyscannonPickup","",0)
	local HPHealth = HP:Health()
	if HPHealth > 0 then
		self.HPHealth = HPHealth
		HP:SetHealth(999999999)
	end
	
	if HP:IsRagdoll() then
		HP:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		if !ConVarExists("scgg_zap") or GetConVar("scgg_zap"):GetBool() then
			HP:SCGG_RagdollZapper(true)
		end
	end
	
	if HP:GetClass() == "prop_combine_ball" then
		HP:SetOwner(self.Owner)
		if IsValid(HP:GetPhysicsObject()) then
			HP:GetPhysicsObject():AddGameFlag( FVPHYSICS_WAS_THROWN )
		end
	end
end

--if SERVER then
function SWEP:Drop(temp_ply, no_snd)
	if !IsValid(self) then return end
	
	local HP = self:GetHP()
	
	local ply = self.Owner
	if !IsValid(self.Owner) and IsValid(temp_ply) then
		ply = temp_ply
	end
	
	self:DropGeneral()
	if SERVER and IsValid(HP) then
		HP:Fire("EnablePhyscannonPickup","",1)
		if HP:IsRagdoll() then
			HP:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		else
			HP:SetCollisionGroup( self.HPCollideG )
		end
		
		local HP_temp = HP
		timer.Simple(0.01, function()
			if !IsValid(HP_temp) or !IsValid(HP_temp:GetPhysicsObject()) then return end
			local phys_obj = HP_temp:GetPhysicsObject()
			if HP_temp:GetClass() == "prop_combine_ball" then
				phys_obj:SetVelocity(Vector(0,0,0))
				phys_obj:ApplyForceCenter(Vector(math.random(360), math.random(360), math.random(360))*3000 )
			else
				phys_obj:AddAngleVelocity(phys_obj:GetAngleVelocity()*-1)
			end
		end)
		
		local HPHealth = HP:Health()
		if HPHealth > 0 and self.HPHealth > 0 then
			HP:SetHealth(self.HPHealth)
			self.HPHealth = -1
		end
	end
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	
	if SERVER and IsValid(HP) and HP:IsRagdoll() then
		--RagdollVisual(HP, 1)
		local zapCvar = true
		if ConVarExists("scgg_zap") then
			zapCvar = GetConVar("scgg_zap"):GetBool()
		end
		if zapCvar then
			HP:SCGG_RagdollZapper()
		end
		HP:SCGG_RagdollCollideTimer()
		if zapCvar then
			HP:Fire("StartRagdollBoogie","",0) 
		end
	end
	
	self.Secondary.Automatic = true
	if !no_snd or no_snd == false then
		self.Weapon:EmitSound("Weapon_MegaPhysCannon.Drop")
	end
	self.Weapon:SetNextSecondaryFire( CurTime() + 0.5 )
	--[[if IsValid(HP) and HP:GetClass() == "prop_combine_ball" then
		ply:SimulateGravGunPickup( HP )
		timer.Simple( 0.01, function() 
			if IsValid(HP) and IsValid(ply) then
			ply:SimulateGravGunDrop( HP ) 
			end
		end)
	else--]]if SERVER and IsValid(HP) then
		ply:SimulateGravGunDrop( HP )
	end
	
	timer.Simple( 0.4, function()
		if !IsValid(self) or !IsValid( self.Weapon ) then return end
		if IsValid(ply) and ply:GetActiveWeapon() == self and self.Fading == false then
			self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
		end
	end)
	
	self:TPrem()
	self:HPrem()
	if self.HPCollideG then
		self.HPCollideG = COLLISION_GROUP_NONE
	end
end
--end

function SWEP:DropGeneral()
	self.PropLockTime = nil
	self.HPBone = nil
	ToggleHoldSound(self, false)
	if SERVER then
		self:RemoveGlow()
	end
	local HP = self:GetHP()
	if IsValid(HP) then
		local phys = HP:GetPhysicsObject()
		
		local vel_limit = 150.0
		local vel = Vector(0, 0, 0)
		if IsValid(phys) then
			vel = phys:GetVelocity()
		else
			vel = HP:GetVelocity()
		end
		if vel.x > vel_limit then
			vel.x = vel_limit
		elseif vel.x < -vel_limit then
			vel.x = -vel_limit
		end
		if vel.y > vel_limit then
			vel.y = vel_limit
		elseif vel.y < -vel_limit then
			vel.y = -vel_limit
		end
		vel.z = 0
		
		if HP:IsRagdoll() then
			for d = 1, HP:GetPhysicsObjectCount() - 1 do
				local bone = HP:GetPhysicsObjectNum(d)
			
				if bone and bone.IsValid and IsValid(bone) then
					bone:SetVelocity(vel)
				end
			end
		end
		
		--[[if vel.z > vel_limit then
			vel.z = vel_limit
		elseif vel.z < -vel_limit then
			vel.z = -vel_limit
		end--]]
		
		if IsValid(phys) then
			phys:SetVelocity(vel)
		else
			HP:SetVelocity(vel)
		end
	end
end
	
function SWEP:Visual(trace)
	self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self.Weapon:EmitSound( "Weapon_MegaPhysCannon.Launch" )
	
	if SERVER then
		if !ConVarExists("scgg_muzzle_flash") or GetConVar("scgg_muzzle_flash"):GetBool() then
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
			timer.Simple(0.1, function() if IsValid(Light) then Light:Remove() end end)
		end
	end
	if IsValid(self.Owner) and self.Owner:IsPlayer() and ConVarExists("scgg_style") and !GetConVar("scgg_style"):GetBool() and self.Owner:GetInfoNum("cl_scgg_effects_mode", 0) < 1 then
		self.Owner:ViewPunch( Angle( -5, 2, 0 ) ) 
	end
	
	local HP = self:GetHP()
	
	local effectdata = EffectData()
	if !IsValid(HP) or trace.Entity != HP then
		effectdata:SetOrigin( trace.HitPos )
	else
		effectdata:SetOrigin( HP:GetPos() )
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
		if ConVarExists("scgg_no_effects") and GetConVar("scgg_no_effects"):GetBool() then return end
		self:MuzzleEffect()
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
function entmeta:SCGG_RagdollZapper(isStop)
	if !ConVarExists("scgg_zap") or GetConVar("scgg_zap"):GetBool() then
		local name = "scgg_zapper_"..self:EntIndex()
		
		if isStop != nil and isStop == true then
			timer.Remove(name)
			return
		end
		
		local ZapDelay = 0.2
		local ZapRepeats = 24
		if timer.Exists(name) then timer.Adjust(name,ZapDelay,ZapRepeats) return end
		
		local function DoZap()
			local effect2 = EffectData()
			if !IsValid(self) then timer.Remove(name) return end
			effect2:SetOrigin(self:GetPos())
			effect2:SetStart(self:GetPos())
			effect2:SetMagnitude(5)
			effect2:SetEntity(self)
			util.Effect("teslaHitBoxes", effect2)
			if ConVarExists("scgg_zap_sound") and GetConVar("scgg_zap_sound"):GetBool() then
				self:EmitSound("Weapon_StunStick.Activate", 75, math.Rand(99, 101), 0.1, SNDLVL_45dB)
			end
		end
		
		DoZap()
		
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
		
		timer.Create( name, ZapDelay, ZapRepeats, function()
			--print(name, timer.RepsLeft(name))
			DoZap()
			if !IsValid(self) then timer.Remove(name) return end
			if timer.RepsLeft(name) <= 0 then 
				local collision = self:GetCollisionGroup()
				--if CollisionCheck(self)==true then 
				--self:SetCollisionGroup(COLLISION_GROUP_WEAPON) 
				--end 
				
				timer.Remove(name) 
				return
			end
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
	InitChangeableVars(self)
	
	self.OnDropOwner = self.Owner
	
	--self.Weapon:SetNextPrimaryFire( CurTime() + 5 )
	self.Weapon:SetNextSecondaryFire( CurTime() + 5 )
	--[[if IsValid(self.Owner:GetWeapon("weapon_physcannon")) then
		--print("yeah")
		net.Start("SCGG_Deploy_DisableGrav")
		net.Send( self.Owner )
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
	--self.Weapon:SendWeaponAnim( ACT_VM_DRAW )
	if ConVarExists("scgg_equip_sound") and GetConVar("scgg_equip_sound"):GetBool() and 
	ConVarExists("scgg_enabled") and GetConVar("scgg_enabled"):GetInt() > 0 then
		self.Weapon:EmitSound("weapons/physcannon/physcannon_charge.wav") 
	end
	--end
	
	if IsValid(self.Owner) then
		if self.Owner:IsPlayer() then
			local vm = self.Owner:GetViewModel()
			local duration = 0
			duration = vm:SequenceDuration()
			
			timer.Create( "deploy_idle"..self:EntIndex(), duration, 1, function()
				if !IsValid( self.Weapon ) then return true end
				if IsValid(self) and IsValid(self.Owner) and IsValid(self.Owner:GetActiveWeapon()) and self.Owner:GetActiveWeapon() == self 
				and self.Fading == false then
					self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
				end
				--self.Weapon:SetNextPrimaryFire( CurTime() + 0.01 )
				self.Weapon:SetNextSecondaryFire( CurTime() + 0.01 )
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
		--print(self.Owner:GetInfo("cl_scgg_viewmodel"))
		local newview_info = nil
		newview_info = "models/weapons/shadowysn/c_superphyscannon.mdl"
		if IsValid(self.Owner) and self.Owner:IsPlayer() and self.Owner:GetInfo("cl_scgg_viewmodel") then
			newview_info = self.Owner:GetInfo("cl_scgg_viewmodel")
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
	if IsValid(HP) and self.Owner:Health() > 0 then
		return false
	end
	TimerDestroyAll(self)
	--[[if SERVER then
		if IsValid(self.Owner:GetWeapon("weapon_physcannon")) then
			local ply = self.Owner
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
end

function SWEP:OnDrop()
	local HP = self:GetHP()
	
	if SERVER then
		--self:RemoveCore()
		self:TPrem()
		self:HPrem()
		
		if ConVarExists("scgg_enabled") and GetConVar("scgg_enabled"):GetInt() <= 0 and !self.Fading then
			self:Discharge()
		end
	end
	
	if IsValid(self.OnDropOwner) then
		self:Drop(self.OnDropOwner, true)
	end
	
	--[[self:Fire("Kill","",0.01)
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
	--grav_entity.ClawOpenState = self.ClawOpenState
	--grav_entity:GetPhysicsObject():SetVelocity( Vector( 0, 350, 0 ) )
	--grav_entity:GetPhysicsObject():ApplyForceCenter( Vector( 0, 0, -100 ) )
	--grav_entity:GetPhysicsObject():ApplyForceOffset( Vector( 0, 3500, 0 ) , self:GetPos() )
	grav_entity.Planted = false--]]
	
	if IsValid(HP) then
		self:SetHP(nil)
	end
end

function SWEP:HPrem()
	--if IsValid(self:GetHP()) then
		self:SetHP(nil)
		--self.HP_OldAngles = nil
		self.HP_PickedUp = nil
	--end
end

function SWEP:TPrem()
	if SERVER and IsValid(self:GetTP()) then
		self:GetTP():Remove()
	end
	if IsValid(self.Const) and (self.Const:IsConstraint() or self.Const:GetClass() == "phys_ragdollconstraint") then
		if SERVER then self.Const:Remove() end
		self.Const = nil
	end
	self:SetTP(nil)
end

function SWEP:CreateTP()
	local HP = self:GetHP()
	
	if !IsValid(HP) then return end
	local temp_tp = nil
	if HP:GetClass() == "prop_combine_ball" or HP:GetClass() == "npc_manhack" then
		temp_tp = ents.Create("prop_dynamic")
	else
		temp_tp = ents.Create("prop_physics")
	end
	self:SetTP(temp_tp)
	--[[if self:AllowedCenterPhysicsClass() or !IsValid(HP:GetPhysicsObject()) then
		temp_tp:SetPos(HP:LocalToWorld(HP:OBBCenter())) -- Doesn't affect much
	else
		temp_tp:SetPos(HP:GetPhysicsObject():GetMassCenter())
	end--]]
	
	local phys_obj = nil
	if HP:IsRagdoll() and self.HPBone != nil and util.IsValidPhysicsObject(HP, self.HPBone) then
		phys_obj = HP:GetPhysicsObjectNum(self.HPBone)
	end
	if !IsValid(phys_obj) then
		if IsValid(HP:GetPhysicsObject()) then
			phys_obj = HP:GetPhysicsObject()
		end
	end
	
	if IsValid(phys_obj) and HP:IsRagdoll() then
		--temp_tp:SetPos(HP:GetBonePosition(HP:TranslatePhysBoneToBone(self.HPBone)))
		temp_tp:SetPos(phys_obj:GetPos())
	elseif !HP:WorldSpaceCenter():IsZero() then
		temp_tp:SetPos(HP:WorldSpaceCenter())
	else
		temp_tp:SetPos(HP:GetPos())
	end
	
	--temp_tp:SetPos(HP:GetNetworkOrigin())
	temp_tp:SetModel("models/props_junk/PopCan01a.mdl")
	temp_tp:Spawn()
	temp_tp:SetCollisionGroup(COLLISION_GROUP_WORLD)
	temp_tp:SetRenderMode(RENDERMODE_TRANSCOLOR)
	temp_tp:SetColor(Color(255, 255, 255, 0))
	temp_tp:PointAtEntity(self.Owner)
	
	if temp_tp:GetClass() == "prop_physics" then
		temp_tp:GetPhysicsObject():SetMass(50000)
		temp_tp:GetPhysicsObject():EnableMotion(false)
	end
	
	local trace = DoPlayerOrNPCEyeTrace(self, self.Owner)
	
	local bone = math.Clamp(trace.PhysicsBone, 0, 1)
	if IsValid(phys_obj) and HP:IsRagdoll() then
		bone = self.HPBone
	end
	
	if HP:IsRagdoll() and IsValid(temp_tp:GetPhysicsObject()) and IsValid(phys_obj) then
		local temp_const = ents.Create("phys_ragdollconstraint")
		self.Const = temp_const
		temp_const:SetPhysConstraintObjects(phys_obj, temp_tp:GetPhysicsObject())
		temp_const:SetKeyValue("teleportfollowdistance", 1.0)
		
		local val_minmax = 180.0
		temp_const:SetKeyValue("xmin", -val_minmax)
		temp_const:SetKeyValue("xmax", val_minmax)
		temp_const:SetKeyValue("ymin", -val_minmax)
		temp_const:SetKeyValue("ymax", val_minmax)
		temp_const:SetKeyValue("zmin", -val_minmax)
		temp_const:SetKeyValue("zmax", val_minmax)
		
		local val_friction = 15.0
		temp_const:SetKeyValue("xfriction", val_friction)
		temp_const:SetKeyValue("yfriction", val_friction)
		temp_const:SetKeyValue("zfriction", val_friction)
		
		temp_const:SetPos(temp_tp:GetPos())
		temp_const:Spawn()
		temp_const:Activate()
	else
		self.Const = constraint.Weld(temp_tp, HP, 0, bone, 0, false)
	end
end

--[[function SWEP:GetPuntForce()
	if GetConVar("scgg_style"):GetBool() then
		return self.PuntForce
	else
		return self.HL2PuntForce
	end
end--]]

function SWEP:GetPullForce(ragdoll)
	if ConVarExists("scgg_style") and GetConVar("scgg_style"):GetBool() then
		return self.PullForce
	else
		if IsValid(ragdoll) and ragdoll:IsRagdoll() then
			return self.HL2PullForceRagdoll
		else
			return self.HL2PullForce
		end
	end
end

function SWEP:GetMaxMass()
	if ConVarExists("scgg_style") and GetConVar("scgg_style"):GetBool() then
		return self.MaxMass
	else
		return self.HL2MaxMass
	end
end

function SWEP:GetMaxPuntRange()
	if ConVarExists("scgg_style") and GetConVar("scgg_style"):GetBool() then
		return self.MaxPuntRange
	else
		return self.HL2MaxPuntRange
	end
end

function SWEP:GetMaxPickupRange()
	if ConVarExists("scgg_style") and GetConVar("scgg_style"):GetBool() then
		return self.MaxPickupRange
	else
		return self.HL2MaxPickupRange
	end
end

function SWEP:GetMaxTargetHealth()
	if ConVarExists("scgg_style") and GetConVar("scgg_style"):GetBool() then
		return self.MaxTargetHealth
	else
		return self.HL2MaxTargetHealth
	end
end

if SERVER then

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
	if ConVarExists("scgg_no_effects") and GetConVar("scgg_no_effects"):GetBool() then return end
	self:SetNWBool("SCGG_Glow", true)
	--[[if !IsValid(self.Core) then
		self:CoreEffect()
	end
	if !IsValid(self.Core) then return end
	self.Core:SetNWBool("SCGG_Glow", true)
	self.Glow = true--]]
end

function SWEP:RemoveCore()
	if !self.Core then return end
	if !IsValid(self.Core) then return end
	self.CoreAllowRemove = true
	self.Core:Remove()
	self.Core = nil
end

function SWEP:RemoveGlow()
	self:SetNWBool("SCGG_Glow", false)
	--[[if !self.Core then return end
	if !IsValid(self.Core) then return end
	self.Weapon:SetNWBool("Glow", false)
	self.Core:SetNWBool("SCGG_Glow", false)
	self.Glow = nil--]]
end

end