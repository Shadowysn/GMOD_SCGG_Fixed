
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()

	self.Entity:DrawShadow( false )
	self.Entity:SetSolid( SOLID_NONE )
	
end

function ENT:Think()
	local Owner = self.Entity:GetOwner()
	if !IsValid(Owner) or !Owner:Alive() or (IsValid(Owner:GetActiveWeapon()) and 
	Owner:GetActiveWeapon():GetClass() != "weapon_superphyscannon") then
		self.Entity:Remove()
		--[[for k,v in pairs(player.GetAll()) do
			v:ConCommand("stopsounds") -- fix for holdsound bug
		end--]]
	return end
	
	if Owner:GetInfoNum("cl_scgg_physgun_color", 0) > 0 and !Owner:GetNWBool("SCGG_IsColored", false) then
		Owner:SetNWBool("SCGG_IsColored", true)
	elseif Owner:GetInfoNum("cl_scgg_physgun_color", 0) <= 0 and Owner:GetNWBool("SCGG_IsColored", false) then
		Owner:SetNWBool("SCGG_IsColored", false)
	end
	
	--[[if Owner:GetViewEntity():GetClass() != Owner:GetClass() then
		Owner:SetNWBool(	"SCGG_NotFirstPerson",			true)
	else
		Owner:SetNWBool(	"SCGG_NotFirstPerson",			false)
	end--]]
	 -- ^ This system of NW Bools is replaced with a direct check on the ViewEntities.
	 -- It is much faster and safer to directly check on the client than wait for a serversided boolean.
	
end

