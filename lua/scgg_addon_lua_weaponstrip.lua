if CLIENT then return end

local phys_mdl = "models/weapons/w_physics.mdl"
local superphys_mdl = "models/weapons/shadowysn/w_superphyscannon.mdl"

local GetEnts = ents.GetAll()

local function DoParticleEffects(entity)
	net.Start("SCGG_Charging_Particles")
	net.WriteEntity(entity)
	net.Broadcast()
end

local function EnableGrabFunction(name, ent)
	local temp = ents.Create("prop_physics_override")
	-- ^ Not only does it allow me to change how it looks, it also fixes the grab functionality!
	temp:SetPos(ent:GetPos())
	temp:SetAngles(ent:GetAngles())
	temp:SetSkin(1)
	--if str_compare != nil then
	--	temp:SetModel(superphys_mdl)
	--else
		temp:SetModel(ent:GetModel())
	--end
	temp:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	--temp:SetKeyValue( "spawnflags", "8" )
	temp:SetName(name)
	temp:SetKeyValue( "gmod_allowphysgun", 0 )
	temp:Spawn()
	temp:Activate()
	
	temp:PhysicsDestroy()
	--[[
	^ However, we need to destroy it's physics first before parenting it to the weapon, because otherwise, when the map is restarted 
	enough times and the confiscation field supercharges the grav gun enough times, the physics of EVERYTHING suddenly goes HAYWIRE
	and they all fall through the map!! It's definitely a fatal bug, alright.
	And we can't use prop_dynamic, weld, or func_button either. I tried, and only prop_physics seems to be able to fix the pick up
	functionality.
	--]]
	temp:SetParent(ent)
end

for _,ent in pairs(GetEnts) do
	if IsValid(ent) and ent:GetClass() == "weapon_physcannon"  and !ent.SCGG_IsUpgrading then
		ent.SCGG_IsUpgrading = true
		if ConVarExists("scgg_enabled") and 
		(!ConVarExists("scgg_allow_enablecvar_modify") or GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0)
		then
			GetConVar("scgg_enabled"):SetInt(2)
		end
		if ConVarExists("scgg_weapon_vaporize") and GetConVar("scgg_weapon_vaporize"):GetInt() <= 0 and 
		(ConVarExists("scgg_allow_enablecvar_modify") and GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0) then
			GetConVar("scgg_weapon_vaporize"):SetInt(1)
		end
		
		--local str_compare = string.find(ent:GetModel(), "phys", 1, false)
		
		--if str_compare != nil then
			ent:SetNoDraw(true)
		--end
		
		local core_name = "scgg_addon_core_"..ent:EntIndex()
		local trig_name = "scgg_addon_grab_"..ent:EntIndex()
		
		local coreattachmentID = ent:LookupAttachment("core")
		if !coreattachmentID or coreattachmentID <= 0 then
			coreattachmentID = ent:LookupAttachment("muzzle")
		end
		--[[if !coreattachmentID or coreattachmentID <= 0 then
			coreattachmentID = -1
		end--]]
		--[[if coreattachmentID and coreattachmentID > 0 then
			coreattachment = ent:GetAttachment(coreattachmentID)
		else
			coreattachmentID = -1
			coreattachment = { Ang = ent:GetAngles(), Pos = ent:GetPos() }
		end--]]
		
		local core = ents.Create("env_citadel_energy_core")
		--core:SetPos( coreattachment.Pos )
		--core:SetAngles( coreattachment.Ang )
		if coreattachmentID > 0 then
			core:SetParent( ent, coreattachmentID )
		else
			core:SetPos( ent:GetPos() )
			core:SetAngles( ent:GetAngles() )
		end
		core:SetName(core_name)
		core:SetKeyValue( "spawnflags", 1 )
		core:SetKeyValue( "scale", 1.25 )
		core:Spawn()
		core:Fire( "SetParentAttachment", "core", 0 )
		core:Fire( "StartCharge","1.00",0.01 )
		
		--[[local core2 = ents.Create("env_citadel_energy_core")
		core2:SetPos( coreattachment.Pos )
		core2:SetAngles( ent:GetAngles() )
		core2:SetParent( ent )
		core2:SetName(core_name)
		core2:Spawn()
		core2:Fire( "SetParentAttachment", "core", 0 )
		core2:Fire( "AddOutput","scale 0",0 )
		core2:Fire( "StartCharge","2.0",0.01 )
		
		core2:Fire( "Stop","2.0",5.0 )--]]
		
		ent:Fire("AddOutput", string.format("OnPlayerPickup %s,Kill", core_name))
		ent:Fire("AddOutput", string.format("OnPlayerPickup %s,Kill", trig_name))
		ent:Fire("AddOutput", "OnPlayerPickup !self,Skin,0")

		EnableGrabFunction(trig_name, ent)
		
		DoParticleEffects(ent)
	end
end
timer.Simple(0, function()
	for _,ent in pairs(GetEnts) do
		if IsValid(ent) and ent.SCGG_IsUpgrading then
			ent.SCGG_IsUpgrading = nil
		end
	end
end)