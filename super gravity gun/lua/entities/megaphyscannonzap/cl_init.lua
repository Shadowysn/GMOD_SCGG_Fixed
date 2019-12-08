include('shared.lua')

local Zap = Material( "sprites/physcannon_bluelight1b" )
Zap:SetInt("$spriterendermode",5)

local ZapWorld = Material( "sprites/lgtning" )
ZapWorld:SetInt("$spriterendermode",5)

local Mat = Material( "sprites/blueflare1_noz" )
Mat:SetInt("$spriterendermode",5)

local MatWorld = Material( "sprites/blueflare1" )
MatWorld:SetInt("$spriterendermode",5)

ENT.RenderGroup 	= RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
Zap:SetInt("$spriterendermode",5)
ZapWorld:SetInt("$spriterendermode",5)
Mat:SetInt("$spriterendermode",5)
MatWorld:SetInt("$spriterendermode",5)
end

function ENT:Think()
end

function ENT:Draw()
	local Owner = self.Entity:GetOwner()
	local function CheckDrawSprite(position, width, height, color)
		if position != nil and width != nil and height != nil and color != nil then
		render.DrawSprite( position, width, height, color)
		end
	end
	local function CheckDrawBeam(startPos, endPos, width, textureStart, textureEnd, color)
		if startPos != nil and endPos != nil and width != nil and textureStart != nil and textureEnd != nil and color != nil then
		render.DrawBeam( startPos, endPos, width, textureStart, textureEnd, color)
		end
	end
	local function ColorSet(alpha)
		if Owner:GetNWBool("SCGG_IsColored", false) then
			local getcol = LocalPlayer():GetWeaponColor():ToColor()
			return Color(getcol.r,getcol.g,getcol.b,alpha)
		end
		return nil
	end
	local scale = math.Rand( 8, 10 )
	local scale2 = math.Rand( 25, 27 )
	local scale3 = math.Rand( 3, 5 )
	if !IsValid(self) or !IsValid(Owner) then return end
	
	local StartPos = nil
	local StartPosO = nil
	local ViewModel 	= Owner == LocalPlayer()
	
	if ( ViewModel ) and GetViewEntity() == Owner then
		
		local vm = Owner:GetViewModel()
		if (!vm || vm == NULL) then return end
		if !Owner:Alive() then return end
		if IsValid(Owner:GetActiveWeapon()) then
		if not ( Owner:GetActiveWeapon():GetClass() == "weapon_superphyscannon" ) then return end
		end
		if !IsValid(self) then return end
		
		if self:GetNWInt("tempent_SCGGzapmode", -1) > 0 then -- Zap 3
			
		elseif self:GetNWInt("tempent_SCGGzapmode", -1) == 0 then -- Zap 2
			local attachmentID=vm:LookupAttachment("muzzle")
			if attachmentID > 0 then
			local attachment = vm:GetAttachment(attachmentID)
			StartPos = attachment.Pos
			end
			
			local attachmentID5=vm:LookupAttachment("fork1t")
			if attachmentID5 > 0 then
			local attachment_O = vm:GetAttachment( attachmentID5 )
			StartPosO = attachment_O.Pos
			end
		else -- Zap 1
			local attachmentID=vm:LookupAttachment("muzzle")
			if attachmentID > 0 then
			local attachment = vm:GetAttachment(attachmentID)
			StartPos = attachment.Pos
			end
			
			local attachmentID5=vm:LookupAttachment("fork2t")
			if attachmentID5 > 0 then
			local attachment_LH = vm:GetAttachment( attachmentID5 )
			StartPosO = attachment_LH.Pos
			end
		end
		
	if StartPos != nil and StartPosO != nil then
	render.SetMaterial( Mat )
	self.Length = (StartPosO - StartPos):Length()
	CheckDrawSprite( StartPosO, scale, scale, ColorSet(80) or Color(255,255,255,80))
	render.SetMaterial( Zap )
	
	CheckDrawBeam( StartPosO, StartPos, 3, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + self.Length / 128	, ColorSet(195) or Color( 255, 255, 255, 195 ) ) 
	end
	
	elseif ( (!ViewModel) or GetViewEntity() != Owner ) then
		local vm = Owner:GetActiveWeapon()
		if (!vm || vm == NULL) then return end
		if !IsValid(vm) then return end
		if !Owner:Alive() then return end
		if not ( Owner:GetActiveWeapon():GetClass() == "weapon_superphyscannon" ) then return end
		if !IsValid(self) then return end
		
		if self:GetNWInt("tempent_SCGGzapmode", -1) > 0 then -- Zap 3
			local attachmentID=vm:LookupAttachment("core")
			if attachmentID > 0 then
			local attachment = vm:GetAttachment(attachmentID)
			StartPos = attachment.Pos
			end
			
			local attachmentID2=vm:LookupAttachment("fork3t")
			if attachmentID2 > 0 then
			local attachment_LH = vm:GetAttachment( attachmentID2 )
			StartPosO = attachment_LH.Pos
			end
		elseif self:GetNWInt("tempent_SCGGzapmode", -1) == 0 then -- Zap 2
			local attachmentID=vm:LookupAttachment("core")
			if attachmentID > 0 then
			local attachment = vm:GetAttachment(attachmentID)
			StartPos = attachment.Pos
			end
			
			local attachmentID2=vm:LookupAttachment("fork1t")
			if attachmentID2 > 0 then
			local attachment_O = vm:GetAttachment( attachmentID2 )
			StartPosO = attachment_O.Pos
			end
		else -- Zap 1
			local attachmentID=vm:LookupAttachment("core")
			if attachmentID > 0 then
			local attachment = vm:GetAttachment(attachmentID)
			StartPos = attachment.Pos
			end
			
			local attachmentID2=vm:LookupAttachment("fork2t")
			if attachmentID > 0 then
			local attachment_LH = vm:GetAttachment( attachmentID2 )
			StartPosO = attachment_LH.Pos
			end
		end
		
		render.SetMaterial( MatWorld )
		CheckDrawSprite( StartPos, scale3, scale3, ColorSet(240) or Color(255,255,255,240))
	--local scale = math.Rand( 8, 10 )
	--local scale2 = math.Rand( 25, 27 )
	--local scale3 = math.Rand( 3, 5 )
	render.SetMaterial( MatWorld )
	self.Length = (StartPosO - StartPos):Length()
	CheckDrawSprite( StartPosO, scale, scale, ColorSet(80) or Color(255,255,255,80))
	render.SetMaterial( ZapWorld )
	
	CheckDrawBeam( StartPosO, StartPos, 3, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + self.Length / 128	, ColorSet(255) or Color( 255, 255, 255, 255 ) ) 
	end
end

function ENT:IsTranslucent()
	return true
end
