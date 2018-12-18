
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()

	self.Entity:DrawShadow( false )
	self.Entity:SetSolid( SOLID_NONE )
	self.Entity:EmitSound("Weapon_MegaPhysCannon.ChargeZap")
	timer.Simple( 0.1, function() if IsValid(self.Entity) then self.Entity:Remove() end end )
	
end

function ENT:Think()
	local Owner = self.Entity:GetOwner()
	if !IsValid(Owner) then self.Entity:Remove() return end
	
	if Owner:GetViewEntity():GetClass() == "gmod_cameraprop" then
		Owner:SetNWBool(	"Camera",			true)
	else
		Owner:SetNWBool(	"Camera",			false)
	end
	
	if !Owner:Alive() then
		self.Entity:Remove()
	return end
end

