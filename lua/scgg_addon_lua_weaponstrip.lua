if CLIENT then return end

local phys_mdl = "models/weapons/w_physics.mdl"
local superphys_mdl = "models/weapons/shadowysn/w_superphyscannon.mdl"

local GetEnts = ents.GetAll()

local function EnableGrabFunction(name, ent)
	local temp = ents.Create("prop_physics_override") -- Not only does it allow me to change how it looks, it also fixes the grab functionality!
	temp:SetPos(ent:GetPos())
	temp:SetAngles(ent:GetAngles())
	temp:SetParent(ent)
	temp:SetKeyValue( "spawnflags", "10" )
	temp:SetName(name)
	temp:SetModel(superphys_mdl)
	temp:Spawn()
	temp:Activate()
	return temp
end

for _,ent in pairs(GetEnts) do
	if IsValid(ent) and ent:GetClass() == "weapon_physcannon" then
		if ConVarExists("scgg_enabled") and 
		(!ConVarExists("scgg_allow_enablecvar_modify") or GetConVar("scgg_allow_enablecvar_modify"):GetInt() > 0)
		then
			GetConVar("scgg_enabled"):SetInt(2)
		end
		
		ent:SetNoDraw(true)
		
		local core_name = "scgg_addon_core_"..ent:EntIndex()
		local trig_name = "scgg_addon_grab_"..ent:EntIndex()
		
		local coreattachmentID = ent:LookupAttachment("core")
		local coreattachment = ent:GetAttachment(coreattachmentID)
		local core = ents.Create("env_citadel_energy_core")
		core:SetPos( coreattachment.Pos )
		core:SetAngles( ent:GetAngles() )
		core:SetParent( ent )
		core:SetName(core_name)
		core:Spawn()
		core:Fire( "SetParentAttachment", "core", 0 )
		core:Fire( "AddOutput","scale 0.5",0 )
		core:Fire( "StartCharge","1.0``",0.1 )
		ent:Fire("AddOutput", string.format("OnPlayerPickup %s,Kill", core_name))
		ent:Fire("AddOutput", string.format("OnPlayerPickup %s,Kill", trig_name))
		ent:Fire("AddOutput", "OnPlayerPickup !self,Skin,0")
		EnableGrabFunction(trig_name, ent)
	end
end