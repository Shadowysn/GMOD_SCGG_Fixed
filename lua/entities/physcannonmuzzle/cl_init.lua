include('shared.lua')

local Mat = Material( "sprites/blueflare1" )
Mat:SetInt("$spriterendermode",5)


function ENT:Initialize()
Mat:SetInt("$spriterendermode",5)
end

function ENT:Think()
end

function ENT:Draw()
	local scale4 = math.Rand( 45, 47 )
	local scale5 = math.Rand( 20, 22 )
	local Owner = self.Entity:GetOwner()
	if (!Owner || Owner == NULL) then return end
	local StartPos 		= self.Entity:GetPos()
	local ViewModel 	= Owner == LocalPlayer()
	
	render.SetMaterial( Mat )
	
	if ( ViewModel ) and Owner:GetNWBool("Camera") == false then
		
		local vm = Owner:GetViewModel()
		if (!vm || vm == NULL) then return end
		
		local attachmentID=vm:LookupAttachment("muzzle")
		local attachment = vm:GetAttachment(attachmentID)
		StartPos = attachment.Pos
		
		render.DrawSprite( StartPos, scale4, scale4, Color(255,255,255,240))
	else
		
		local vm = Owner:GetActiveWeapon()
		if (!vm || vm == NULL) then return end
		
		local attachmentID=vm:LookupAttachment("core")
		local attachment = vm:GetAttachment(attachmentID)
		StartPos = attachment.Pos
		
		render.DrawSprite( StartPos, scale5, scale5, Color(255,255,255,240))
	end
end

function ENT:IsTranslucent()
	return true
end
