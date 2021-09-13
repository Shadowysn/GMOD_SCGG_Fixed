local Mat = Material( "sprites/blueflare1_noz" )
local MatWorld = Material( "sprites/blueflare1" )
local Zap = Material( "sprites/physcannon_bluelight1b" )
local ZapWorld = Material( "sprites/lgtning" )
local Main = Material( "effects/fluttercore" )

local function InitGlowSprites()
	Mat:SetInt("$spriterendermode",5)
	MatWorld:SetInt("$spriterendermode",5)
	Zap:SetInt("$spriterendermode",5)
	--local ZapWorld = Material( "sprites/bluelight1" )
	ZapWorld:SetInt("$spriterendermode",5)
	Main:SetInt("$spriterendermode",9)
end

local function GetFOV(wep_ent)
	local nFOV = wep_ent.ViewModelFOV
	if !isnumber(nFOV) then nFOV = 62 end
	return nFOV
end

-- FIXME: The nFOV parameter should be replaced with ViewModelFOV() when it's binded
local function FormatViewModelAttachment(nFOV, vOrigin, bInverse --[[= false]])
	local vEyePos = EyePos()
	local aEyesRot = EyeAngles()
	local vOffset = vOrigin - vEyePos
	local vForward = aEyesRot:Forward()

	local nViewX = math.tan(nFOV * math.pi / 360)

	if (nViewX == 0) then
		vForward:Mul(vForward:Dot(vOffset))
		vEyePos:Add(vForward)
		
		return vEyePos
	end

	-- FIXME: LocalPlayer():GetFOV() should be replaced with EyeFOV() when it's binded
	local nWorldX = math.tan(LocalPlayer():GetFOV() * math.pi / 360)

	if (nWorldX == 0) then
		vForward:Mul(vForward:Dot(vOffset))
		vEyePos:Add(vForward)
		
		return vEyePos
	end

	local nFactor = nWorldX / nViewX
	local vRight = aEyesRot:Right()
	local vUp = aEyesRot:Up()

	if (bInverse) then
		vRight:Mul(vRight:Dot(vOffset) / nFactor)
		vUp:Mul(vUp:Dot(vOffset) / nFactor)
	else
		vRight:Mul(vRight:Dot(vOffset) * nFactor)
		vUp:Mul(vUp:Dot(vOffset) * nFactor)
	end

	vForward:Mul(vForward:Dot(vOffset))

	vEyePos:Add(vRight)
	vEyePos:Add(vUp)
	vEyePos:Add(vForward)

	return vEyePos
end

local function CheckDrawSprite(position, width, height, color)
	if position != nil and width != nil and height != nil and color != nil then
		render.DrawSprite( position, width, height, color)
	end
end
local function CheckDrawBeam(startPos, endPos, width, textureStart, textureEnd, color)
	if startPos != nil and endPos != nil and width != nil and textureStart != nil and textureEnd != nil and color != nil then
		render.DrawBeam(startPos, endPos, width, textureStart, textureEnd, color)
	end
end
local function ColorSet(wep_ent, alpha)
	local cvar_num = GetConVar("cl_scgg_physgun_color"):GetInt()
	if IsValid(wep_ent) and IsValid(wep_ent:GetOwner()) and cvar_num > 0 then
		local getcol = wep_ent:GetOwner():GetWeaponColor():ToColor()
		if cvar_num > 1 then
			getcol = wep_ent:GetOwner():GetPlayerColor():ToColor()
		end
		return Color(getcol.r,getcol.g,getcol.b,alpha)
	end
	return nil
end
local function GetAttachment(attach, mdl, nFOV, isView)
	if isView == nil then
		isView = true
	end
	local attachmentID = mdl:LookupAttachment(attach)
	if attachmentID > 0 then
		local attachment = mdl:GetAttachment(attachmentID)
		if isView then
			return FormatViewModelAttachment(nFOV, attachment.Pos, true)
		else
			return attachment.Pos
		end
	end
	return nil
end

local function DoZap(wep_ent, nFOV, viewM, zapMode)
	local isView = false
	local mdl = wep_ent
	if IsValid(viewM) then
		isView = true
		mdl = viewM
	end
	if !IsValid(mdl) then return end
	if !IsValid(wep_ent) then return end
	
	local scale = math.Rand( 8, 10 )
	local scale2 = math.Rand( 25, 27 )
	local scale3 = math.Rand( 3, 5 )
	
	local StartPos = nil
	local StartPosO = nil
	
	if isView then
		StartPos = GetAttachment("muzzle", mdl, nFOV)
		if zapMode > 0 then -- Zap 3
			
		elseif zapMode == 0 then -- Zap 2
			StartPosO = GetAttachment("fork1t", mdl, nFOV)
		else -- Zap 1
			StartPosO = GetAttachment("fork2t", mdl, nFOV)
		end
		
		if StartPos != nil and StartPosO != nil then
			local zLength = (StartPosO - StartPos):Length()
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPosO, scale, scale, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			render.SetMaterial( Zap )
			
			CheckDrawBeam( StartPosO, StartPos, 3, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + zLength / 128	, ColorSet(wep_ent, 195) or Color( 255, 255, 255, 195 ) ) 
		end
	else
		StartPos = GetAttachment("core", mdl, nFOV, false)
		if zapMode > 0 then -- Zap 3
			StartPosO = GetAttachment("fork3t", mdl, nFOV, false)
		elseif zapMode == 0 then -- Zap 2
			StartPosO = GetAttachment("fork1t", mdl, nFOV, false)
		else -- Zap 1
			StartPosO = GetAttachment("fork2t", mdl, nFOV, false)
		end
		
		if StartPos != nil and StartPosO != nil then
			local zLength = (StartPosO - StartPos):Length()
			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPos, scale3, scale3, ColorSet(wep_ent, 240) or Color(255,255,255,240))
			--local scale = math.Rand( 8, 10 )
			--local scale2 = math.Rand( 25, 27 )
			--local scale3 = math.Rand( 3, 5 )
			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPosO, scale, scale, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			render.SetMaterial( ZapWorld )
			
			CheckDrawBeam( StartPosO, StartPos, 3, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + zLength / 128	, ColorSet(wep_ent, 255) or Color( 255, 255, 255, 255 ) ) 
		end
	end
end

local function BeginZap(wep_ent, num)
	--print(string.format("zappers: %i", num))
	wep_ent:EmitSound("Weapon_MegaPhysCannon.ChargeZap")
	if num < 2 then
		wep_ent.Zap1_T = 30
	elseif num == 2 then
		wep_ent.Zap2_T = 30
	elseif num > 2 then
		wep_ent.Zap3_T = 30
	end
end

local function DoEffect(wep_ent, nFOV, viewM)
	if !wep_ent.sprInitialized then
		InitGlowSprites()
		wep_ent.sprInitialized = true
	end
	
	local isView = false
	local mdl = wep_ent
	if viewM and IsValid(viewM) then
		isView = true
		mdl = viewM
	end
	
	if !IsValid(mdl) then return end
	if !IsValid(wep_ent) then return end
	
	--print(string.format("isView: %s", tostring(isView)))
	local scale_prong_view = math.Rand( 4, 6 ) -- Originally 8, 10
	local scale_muzzle_view = math.Rand( 39, 41 ) -- Originally 45, 47
	
	local scale_core_view = math.Rand( 12, 16 ) -- Normal  -- Originally 20, 24
	if GetConVar("cl_scgg_effects_mode"):GetInt() >= 1 then
		scale_core_view = math.Rand( 13, 18 ) -- A bit bigger  -- Originally 21, 26
	end
	local scale_glow_view = math.Rand( 21, 28 ) -- Half-Life 2  -- Originally 31, 39
	if GetConVar("cl_scgg_effects_mode"):GetInt() >= 1 then
		scale_glow_view = math.Rand( 24, 34 ) -- Half-Life 2 Survivor  -- Originally 34, 45
	end
	
	local scale_prong_world = math.Rand( 3, 4 )
	local scale_muzzle_world = math.Rand( 34, 36 )
	
	local scale_glow_world = math.Rand( 12, 14 )
	
	if wep_ent.Muzzle then
		if isView and GetConVar("cl_scgg_effects_mode"):GetInt() < 1 then
			StartPos = GetAttachment("muzzle", mdl, nFOV)
			
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPos, scale_muzzle_view, scale_muzzle_view, ColorSet(wep_ent, 240) or Color(255,255,255,240))
		elseif !isView then
			StartPos = GetAttachment("core", mdl, nFOV, false)
			
			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPos, scale_muzzle_world, scale_muzzle_world, ColorSet(wep_ent, 240) or Color(255,255,255,240))
		end
	end
	
	local glow_bool = wep_ent:GetNWBool("SCGG_Glow", false)
	if glow_bool or IsValid(wep_ent.Owner) and wep_ent.Owner:IsPlayer() and wep_ent.Owner:KeyDown(IN_ATTACK2) then
		-- Active Core (Glowing)
		if isView then
			StartPos = GetAttachment("muzzle", mdl, nFOV)
			render.SetMaterial( Mat )
			StartPosR = StartPos
			StartPosO = GetAttachment("fork1t", mdl, nFOV)
			StartPosL = GetAttachment("fork2t", mdl, nFOV)
			StartPosOH = GetAttachment("fork1b", mdl, nFOV)
			StartPosLH = GetAttachment("fork2b", mdl, nFOV)
			
			render.SetMaterial( Main )
			--CheckDrawSprite( StartPos, scale_glow_view, scale_glow_view, ColorSet(wep_ent, 240) or Color(255,255,255,240))
			if GetConVar("cl_scgg_effects_mode"):GetInt() >= 1 then
				CheckDrawSprite( StartPos, scale_glow_view, scale_glow_view, ColorSet(wep_ent, 50, true) or Color(255,255,255,35)) -- Half-Life 2 Survivor
				CheckDrawSprite( StartPos, scale_core_view, scale_core_view, ColorSet(wep_ent, 90) or Color(255,255,255,90)) -- Half-Life 2 Survivor
			else
				CheckDrawSprite( StartPos, scale_glow_view, scale_glow_view, ColorSet(wep_ent, 80, true) or Color(255,255,255,80)) -- Half-Life 2
			end
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPosO, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 160, true) or Color(255,255,255,160))
			CheckDrawSprite( StartPosL, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 160, true) or Color(255,255,255,160))
			CheckDrawSprite( StartPosOH, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80, true) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80, true) or Color(255,255,255,80))
			--CheckDrawSprite( StartPos, 35, 35, ColorSet(wep_ent, 240) or Color(255,255,255,240))
			CheckDrawSprite( StartPosO, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80, true) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80, true) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80, true) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80, true) or Color(255,255,255,80))
		else
			StartPos = GetAttachment("core", mdl, nFOV, false)
			StartPosO = GetAttachment("fork1t", mdl, nFOV, false)
			StartPosL = GetAttachment("fork2t", mdl, nFOV, false)
			StartPosR = GetAttachment("fork3t", mdl, nFOV, false)
			StartPosOH = GetAttachment("fork1m", mdl, nFOV, false)
			StartPosLH = GetAttachment("fork2m", mdl, nFOV, false)
			StartPosRH = GetAttachment("fork3m", mdl, nFOV, false)
			
--			render.SetMaterial( Main )
			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPos, scale_glow_world, scale_glow_world, ColorSet(wep_ent, 120, false) or Color(255,255,255,120))
--			CheckDrawSprite( StartPos, scale_glow_world, scale_glow_world, ColorSet(wep_ent, 140, false) Color(255,255,255,140))
--			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPosO, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 160, false) or Color(255,255,255,160))
			CheckDrawSprite( StartPosL, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 160, false) or Color(255,255,255,160))
			CheckDrawSprite( StartPosR, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 160, false) or Color(255,255,255,160))
			CheckDrawSprite( StartPosOH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosRH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPos, scale_glow_world, scale_glow_world, ColorSet(wep_ent, 100, false) or Color(255,255,255,100))
			CheckDrawSprite( StartPos, scale_glow_world, scale_glow_world, ColorSet(wep_ent, 240, false) or Color(255,255,255,240))
			CheckDrawSprite( StartPosO, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosR, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
			CheckDrawSprite( StartPosRH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80, false) or Color(255,255,255,80))
		end
		wep_ent.Length = 10
		wep_ent.Length2 = 10
		wep_ent.Length3 = 10
		if StartPosO != nil and StartPos != nil then
			wep_ent.Length = (StartPosO - StartPos):Length()
		end
		if StartPosL != nil and StartPos != nil then
			wep_ent.Length2 = (StartPosL - StartPos):Length()
		end
		if StartPosR != nil and StartPos != nil then
			wep_ent.Length3 = (StartPosR - StartPos):Length()
		end
		
		if isView then
			render.SetMaterial( Zap )
			CheckDrawBeam( StartPosO, StartPos, 5, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + wep_ent.Length / 128, 
			ColorSet(wep_ent, 195, false) or Color(205,255,195,195) ) 
			CheckDrawBeam( StartPosL, StartPos, 5, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + wep_ent.Length2 / 128, 
			ColorSet(wep_ent, 195, false) or Color(205,255,195,195) ) 
			CheckDrawBeam( StartPosR, StartPos, 5, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + wep_ent.Length2 / 128, 
			ColorSet(wep_ent, 195, false) or Color(205,255,195,195) ) 
		else
			render.SetMaterial( ZapWorld )
			CheckDrawBeam( StartPosO, StartPos, 2, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + wep_ent.Length / 128, 
			ColorSet(wep_ent, 255, false) or Color(255,255,255,255) ) 
			CheckDrawBeam( StartPosL, StartPos, 2, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + wep_ent.Length2 / 128, 
			ColorSet(wep_ent, 255, false) or Color(255,255,255,255) ) 
			CheckDrawBeam( StartPosR, StartPos, 2, math.Rand( 0, 1 ), math.Rand( 0, 1 ) + wep_ent.Length2 / 128, 
			ColorSet(wep_ent, 255, false) or Color(255,255,255,255) ) 
		end
	else
		-- Idle Core
		if isView then
			StartPos = GetAttachment("muzzle", mdl, nFOV)
			StartPosO = GetAttachment("fork1t", mdl, nFOV)
			StartPosL = GetAttachment("fork2t", mdl, nFOV)
			StartPosOH = GetAttachment("fork1b", mdl, nFOV)
			StartPosLH = GetAttachment("fork2b", mdl, nFOV)
			
			render.SetMaterial( Main )
			--CheckDrawSprite( StartPos, scale_core_view, scale_core_view, ColorSet(wep_ent, 240) or Color(255,255,255,240))
			CheckDrawSprite( StartPos, scale_core_view, scale_core_view, ColorSet(wep_ent, 90) or Color(255,255,255,90))
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPosO, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale_prong_view, scale_prong_view, ColorSet(wep_ent, 80) or Color(255,255,255,80))
		else
			StartPos = GetAttachment("core", mdl, nFOV, false)
			StartPosO = GetAttachment("fork1t", mdl, nFOV, false)
			StartPosL = GetAttachment("fork2t", mdl, nFOV, false)
			StartPosR = GetAttachment("fork3t", mdl, nFOV, false)
			StartPosOH = GetAttachment("fork1m", mdl, nFOV, false)
			StartPosLH = GetAttachment("fork2m", mdl, nFOV, false)
			StartPosRH = GetAttachment("fork3m", mdl, nFOV, false)
			
--			render.SetMaterial( Main )
			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPos, scale_glow_world, scale_glow_world, ColorSet(wep_ent, 240) or Color(255,255,255,240))
--			CheckDrawSprite( StartPos, scale_glow_world, scale_glow_world, ColorSet(wep_ent, 130) or Color(255,255,255,130))
--			render.SetMaterial( MatWorld )
			CheckDrawSprite( StartPosO, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosR, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosRH, scale_prong_world, scale_prong_world, ColorSet(wep_ent, 80) or Color(255,255,255,80))
		end
	end
	
	if wep_ent.Zap1_T == nil then
		wep_ent.Zap1_T = 0
	end
	if wep_ent.Zap2_T == nil then
		wep_ent.Zap2_T = 0
	end
	if wep_ent.Zap3_T == nil then
		wep_ent.Zap3_T = 0
	end
	
	if wep_ent.Zap1_T > 0 then
		wep_ent.Zap1_T = wep_ent.Zap1_T-1
		if isView then
			DoZap(wep_ent, nFOV, viewM, -1)
		else
			DoZap(wep_ent, nFOV, nil, -1)
		end
	end
	if wep_ent.Zap2_T > 0 then
		wep_ent.Zap2_T = wep_ent.Zap2_T-1
		if isView then
			DoZap(wep_ent, nFOV, viewM, 0)
		else
			DoZap(wep_ent, nFOV, nil, 0)
		end
	end
	if wep_ent.Zap3_T > 0 then
		wep_ent.Zap3_T = wep_ent.Zap3_T-1
		if isView then
			DoZap(wep_ent, nFOV, viewM, 1)
		else
			DoZap(wep_ent, nFOV, nil, 1)
		end
	end
	
	if math.random( 1,  500 ) == 1 and !IsValid(wep_ent:GetTP()) and !glow_bool and 
	(!IsValid(wep_ent.Owner) or !wep_ent.Owner:IsPlayer() or (wep_ent.Owner:IsPlayer() and !wep_ent.Owner:KeyDown(IN_ATTACK2) and !wep_ent.Owner:KeyDown(IN_ATTACK))) then
		BeginZap(wep_ent, math.random(1, 3))
	end
end

function SWEP:PreDrawViewModel(vm)
	--Mat:SetInt("$spriterendermode",5)
	--Main:SetInt("$spriterendermode",9)
	--MatWorld:SetInt("$spriterendermode",5)
	
	if !GetConVar("scgg_no_effects"):GetBool() then
		DoEffect(self, GetFOV(self), vm)
		--DoEffect(vm, GetFOV(self), 1, false)
	end
end

function SWEP:DrawWorldModel()
	self:DrawModel()
	
	if !GetConVar("scgg_no_effects"):GetBool() then
		DoEffect(self, GetFOV(self))
	end
end