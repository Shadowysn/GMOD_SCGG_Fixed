include('shared.lua')

local Mat = Material( "sprites/blueflare1_noz" )
Mat:SetInt("$spriterendermode",5)
local MatWorld = Material( "sprites/blueflare1" )
MatWorld:SetInt("$spriterendermode",5)
local Zap = Material( "sprites/physcannon_bluelight1b" )
Zap:SetInt("$spriterendermode",5)
--local ZapWorld = Material( "sprites/bluelight1" )
local ZapWorld = Material( "sprites/lgtning" )
ZapWorld:SetInt("$spriterendermode",5)
local Main = Material( "effects/fluttercore" )
Main:SetInt("$spriterendermode",5)
ENT.RenderGroup 	= RENDERGROUP_TRANSLUCENT --RENDERGROUP_BOTH

function ENT:Initialize()
Mat:SetInt("$spriterendermode",5)
Zap:SetInt("$spriterendermode",5)
ZapWorld:SetInt("$spriterendermode",5)
Main:SetInt("$spriterendermode",9)
MatWorld:SetInt("$spriterendermode",5)
end

function ENT:Think()
end

function ENT:Draw()
	local Owner = self.Entity:GetOwner()
	local vm = Owner:GetViewModel()
	local wm = Owner:GetActiveWeapon()
	if !IsValid(vm) or !IsValid(wm) or !Owner:Alive() then return end
	if not (wm:GetClass() == "weapon_superphyscannon") then return end
	local function CheckDrawSprite(position, width, height, color)
		if position != nil and width != nil and height != nil and color != nil then
		render.DrawSprite(position, width, height, color)
		end
	end
	local function CheckDrawBeam(startPos, endPos, width, textureStart, textureEnd, color)
		if startPos != nil and endPos != nil and width != nil and textureStart != nil and textureEnd != nil and color != nil then
		render.DrawBeam(startPos, endPos, width, textureStart, textureEnd, color)
		end
	end
	local function ColorSet(alpha)
		if Owner:GetNWBool("SCGG_IsColored", false) then
			local getcol = LocalPlayer():GetWeaponColor():ToColor()
			return Color(getcol.r,getcol.g,getcol.b,alpha)
		end
		return nil
	end
	local function GetAttachment(attach, mdl)
		local attachmentID=mdl:LookupAttachment(attach)
		if attachmentID > 0 then
		local attachment = mdl:GetAttachment(attachmentID)
		return attachment.Pos
		else
		return nil
		end
	end
	local scale = math.Rand( 8, 10 )
	
	local scalecore = math.Rand( 20, 24 ) -- Normal
	if GetConVar("cl_scgg_effects_mode"):GetInt() >= 1 then
		scalecore = math.Rand( 21, 26 ) -- A bit bigger
	end
	
	local scale3 = math.Rand( 3, 4 )
	local scale4 = math.Rand( 45, 47 )
	local scale5 = math.Rand( 34, 36 )
	
	local scaleglow = math.Rand( 31, 39 ) -- Half-Life 2
	if GetConVar("cl_scgg_effects_mode"):GetInt() >= 1 then
		scaleglow = math.Rand( 34, 45 ) -- Half-Life 2 Survivor
	end
	
	local scale7 = math.Rand( 12, 14 )
	if !IsValid(self) or !IsValid(Owner) then return end
	
	local ViewModelCheck = (Owner == LocalPlayer())
	local ViewEntityCheck = (GetViewEntity() == Owner)
	
	--[[if ViewModelCheck and ViewEntityCheck then
		print("view")
	elseif !ViewModelCheck or !ViewEntityCheck then
		print("world")
	end--]]
	
	if self.Muzzle then
		if ViewModelCheck and ViewEntityCheck and GetConVar("cl_scgg_effects_mode"):GetInt() < 1 then
			StartPos = GetAttachment("muzzle", vm)
			
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPos, scale4, scale4, ColorSet(240) or Color(255,255,255,240))
		elseif !ViewModelCheck or !ViewEntityCheck then
			if GetViewEntity() == Owner then return end
			
			StartPos = GetAttachment("core", wm)
			
			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPos, scale5, scale5, ColorSet(240) or Color(255,255,255,240))
		end
	end
	
	if !self:GetNWBool("SCGG_Glow", false) then
		-- Idle Core
		if ViewModelCheck and ViewEntityCheck then
			StartPos = GetAttachment("muzzle", vm)
			StartPosO = GetAttachment("fork1t", vm)
			StartPosL = GetAttachment("fork2t", vm)
			StartPosOH = GetAttachment("fork1b", vm)
			StartPosLH = GetAttachment("fork2b", vm)
			
			render.SetMaterial( Main )
			--CheckDrawSprite( StartPos, scalecore, scalecore, ColorSet(240) or Color(255,255,255,240))
			CheckDrawSprite( StartPos, scalecore, scalecore, ColorSet(90) or Color(255,255,255,90))
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPosO, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale, scale, ColorSet(80) or Color(255,255,255,80))
		elseif !ViewModelCheck or !ViewEntityCheck then
			StartPos = GetAttachment("core", wm)
			StartPosO = GetAttachment("fork1t", wm)
			StartPosL = GetAttachment("fork2t", wm)
			StartPosR = GetAttachment("fork3t", wm)
			StartPosOH = GetAttachment("fork1m", wm)
			StartPosLH = GetAttachment("fork2m", wm)
			StartPosRH = GetAttachment("fork3m", wm)
			
--			render.SetMaterial( Main )
			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPos, scale7, scale7, ColorSet(240) or Color(255,255,255,240))
--			CheckDrawSprite( StartPos, scale7, scale7, ColorSet(130) or Color(255,255,255,130))
--			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPosO, scale3, scale3, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale3, scale3, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosR, scale3, scale3, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale3, scale3, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale3, scale3, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosRH, scale3, scale3, ColorSet(80) or Color(255,255,255,80))
		end
	else
		-- Active Core (Glowing)
		if ViewModelCheck and ViewEntityCheck then
			StartPos = GetAttachment("muzzle", vm)
			render.SetMaterial( Mat )
			StartPosR = StartPos
			StartPosO = GetAttachment("fork1t", vm)
			StartPosL = GetAttachment("fork2t", vm)
			StartPosOH = GetAttachment("fork1b", vm)
			StartPosLH = GetAttachment("fork2b", vm)
			
			render.SetMaterial( Main )
			--CheckDrawSprite( StartPos, scaleglow, scaleglow, ColorSet(240) or Color(255,255,255,240))
			if GetConVar("cl_scgg_effects_mode"):GetInt() >= 1 then
			CheckDrawSprite( StartPos, scaleglow, scaleglow, ColorSet(50, true) or Color(255,255,255,35)) -- Half-Life 2 Survivor
			CheckDrawSprite( StartPos, scalecore, scalecore, ColorSet(90) or Color(255,255,255,90)) -- Half-Life 2 Survivor
			else
			CheckDrawSprite( StartPos, scaleglow, scaleglow, ColorSet(80, true) or Color(255,255,255,80)) -- Half-Life 2
			end
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPosO, scale, scale, ColorSet(160, true) or Color(255,255,255,160))
			CheckDrawSprite( StartPosL, scale, scale, ColorSet(160, true) or Color(255,255,255,160))
			CheckDrawSprite( StartPosOH, scale, scale, ColorSet(80, true) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale, scale, ColorSet(80, true) or Color(255,255,255,80))
			--CheckDrawSprite( StartPos, 35, 35, ColorSet(240) or Color(255,255,255,240))
			CheckDrawSprite( StartPosO, scale, scale, ColorSet(80, true) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale, scale, ColorSet(80, true) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale, scale, ColorSet(80, true) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale, scale, ColorSet(80, true) or Color(255,255,255,80))
		elseif !ViewModelCheck or !ViewEntityCheck then
			StartPos = GetAttachment("core", wm)
			StartPosO = GetAttachment("fork1t", wm)
			StartPosL = GetAttachment("fork2t", wm)
			StartPosR = GetAttachment("fork3t", wm)
			StartPosOH = GetAttachment("fork1m", wm)
			StartPosLH = GetAttachment("fork2m", wm)
			StartPosRH = GetAttachment("fork3m", wm)
			
--			render.SetMaterial( Main )
			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPos, scale7, scale7, ColorSet(120, false) or Color(255,255,255,120))
--			CheckDrawSprite( StartPos, scale7, scale7, ColorSet(140, false) Color(255,255,255,140))
--			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPosO, scale3, scale3, ColorSet(160, false) or Color(255,255,255,160))
			CheckDrawSprite( StartPosL, scale3, scale3, ColorSet(160, false) or Color(255,255,255,160))
			CheckDrawSprite( StartPosR, scale3, scale3, ColorSet(160, false) or Color(255,255,255,160))
			CheckDrawSprite( StartPosOH, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosRH, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPos, scale7, scale7, ColorSet(100, false) or Color(255,255,255,100))
			CheckDrawSprite( StartPos, scale7, scale7, ColorSet(240, false) or Color(255,255,255,240))
			CheckDrawSprite( StartPosO, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosR, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosRH, scale3, scale3, ColorSet(80, false) or Color(255,255,255,80))
		end
		self.Length = 10
		self.Length2 = 10
		self.Length3 = 10
		if StartPosO != nil and StartPos != nil then
		self.Length = (StartPosO - StartPos):Length()
		end
		if StartPosL != nil and StartPos != nil then
		self.Length2 = (StartPosL - StartPos):Length()
		end
		if StartPosR != nil and StartPos != nil then
		self.Length3 = (StartPosR - StartPos):Length()
		end
		
		if ViewModelCheck and ViewEntityCheck then
		render.SetMaterial( Zap )
		CheckDrawBeam( StartPosO, StartPos, 5, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + self.Length / 128, 
		ColorSet(195, false) or Color(205,255,195,195) ) 
		CheckDrawBeam( StartPosL, StartPos, 5, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + self.Length2 / 128, 
		ColorSet(195, false) or Color(205,255,195,195) ) 
		CheckDrawBeam( StartPosR, StartPos, 5, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + self.Length2 / 128, 
		ColorSet(195, false) or Color(205,255,195,195) ) 
		else
		render.SetMaterial( ZapWorld )
		CheckDrawBeam( StartPosO, StartPos, 2, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + self.Length / 128, 
		ColorSet(255, false) or Color(255,255,255,255) ) 
		CheckDrawBeam( StartPosL, StartPos, 2, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + self.Length2 / 128, 
		ColorSet(255, false) or Color(255,255,255,255) ) 
		CheckDrawBeam( StartPosR, StartPos, 2, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + self.Length2 / 128, 
		ColorSet(255, false) or Color(255,255,255,255) ) 
		end
	end
end

function ENT:IsTranslucent()
	return true
end
