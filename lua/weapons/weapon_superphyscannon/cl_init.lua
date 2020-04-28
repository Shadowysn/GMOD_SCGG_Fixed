include ("shared.lua")

SWEP.Category			= "Half-Life 2"

	SWEP.PrintName			= "SUPER GRAVITY GUN"
	SWEP.Author			= "ErrolLiamP, Î¤yler Blu, QuentinDylanP, pillow, Shadowysn"
	SWEP.Slot			= 1
	SWEP.SlotPos			= 0
	SWEP.IconLetter			= "k"
	SWEP.ViewModelFOV =		GetConVar("viewmodel_fov"):GetFloat()

SWEP.Slot				= 0
SWEP.SlotPos 			= 0
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair 		= true

SWEP.Author			= "ErrolLiamP, Î¤yler Blu, pillow, Shadowysn"
SWEP.Purpose			= ""
SWEP.Instructions		= ""
SWEP.BounceWeaponIcon	= false
SWEP.DrawWeaponInfoBox	= false

SWEP.WepSelectIcon = surface.GetTextureID("weapons/Megaphyscannon")

if CLIENT then

local GetRag = {}

net.Receive( "SCGG_Ragdoll_GetPlayerColor", function() 
	local rag = net.ReadInt(32)
	local ply = net.ReadInt(32)
	local col = net.ReadVector()
	if !ply or ply == nil then return end
	if !col or col == nil then return end
	GetRag = {rag=rag,ply=ply,col=col}
end )

hook.Add("NetworkEntityCreated","SCGG_Ragdoll_SetPlayerColor",function(ent)
	if not GetRag.rag then return end
	if GetRag.rag==ent:EntIndex() then
		local getcol = GetRag.col
		Entity(GetRag.rag).GetPlayerColor = function(self) return getcol end
		GetRag = {}
	end
end)

function SWEP:DrawWorldModel()
	self.SCGG_IsWorldModelDrawn = true
	self:DrawModel()
end

local Mat = Material( "sprites/blueflare1_noz" )
Mat:SetInt("$spriterendermode",5)
local MatWorld = Material( "sprites/blueflare1" )
MatWorld:SetInt("$spriterendermode",5)
local Main = Material( "effects/fluttercore" )
Main:SetInt("$spriterendermode",9)

--[[function SWEP:PreDrawViewModel(vm)
	--Mat:SetInt("$spriterendermode",5)
	--Main:SetInt("$spriterendermode",9)
	--MatWorld:SetInt("$spriterendermode",5)
	local function CheckDrawSprite(position, width, height, color)
		if position != nil and width != nil and height != nil and color != nil then
			render.DrawSprite( position, width, height, color)
		end
	end
	local function ColorSet(alpha)
		if GetConVar("cl_scgg_physgun_color"):GetInt() > 0 then
			local getcol = LocalPlayer():GetPlayerColor():ToColor()
			return Color(getcol.r,getcol.g,getcol.b,alpha)
		end
	return nil
	end
	
	local StartPos = nil
	local StartPosO = nil
	local StartPosL = nil
	local StartPosOH = nil
	local StartPosLH = nil
	local function DoCoreEffect(active)
		local scale = math.Rand( 8, 10 )
		--local scale2 = math.Rand( 25, 27 )
		local scale2 = math.Rand( 20, 24 )
		local scale3 = math.Rand( 3, 4 )
		local scale7 = math.Rand( 12, 14 )
		if IsValid(vm) then
			local attachmentID=vm:LookupAttachment("muzzle")
			if attachmentID > 0 then
			local attachment = vm:GetAttachment(attachmentID)
			StartPos = LocalToWorld( Vector(0, 0, 0), Angle(), attachment.Pos, attachment.Ang )
			StartPos = attachment.Pos
			end
			
			local attachmentID2=vm:LookupAttachment("fork1t")
			if attachmentID2 > 0 then
			local attachment_O = vm:GetAttachment( attachmentID2 )
			StartPosO = attachment_O.Pos
			end
			
			local attachmentID3=vm:LookupAttachment("fork2t")
			if attachmentID3 > 0 then
			local attachment_L = vm:GetAttachment( attachmentID3 )
			StartPosL = attachment_L.Pos
			end
			
			local attachmentID4=vm:LookupAttachment("fork1b")
			if attachmentID4 > 0 then
			local attachment_OH = vm:GetAttachment( attachmentID4)
			StartPosOH = attachment_OH.Pos
			end
			
			local attachmentID5=vm:LookupAttachment("fork2b")
			if attachmentID5 > 0 then
			local attachment_LH = vm:GetAttachment( attachmentID5 )
			StartPosLH = attachment_LH.Pos
			end
			render.SetMaterial( Main )
			--CheckDrawSprite( StartPos, scale2, scale2, Color(255,255,255,240))
			CheckDrawSprite( StartPos, scale2, scale2, ColorSet(90) or Color(255,255,255,90))
			render.SetMaterial( Mat )
			CheckDrawSprite( StartPosO, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosL, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosOH, scale, scale, ColorSet(80) or Color(255,255,255,80))
			CheckDrawSprite( StartPosLH, scale, scale, ColorSet(80) or Color(255,255,255,80))
		end
	end
	
	DoCoreEffect(false)
end--]]

-- Easier to not use this, as if you holster your weapon as it got it's viewmodel set, when you deploy it it'll glitch back to the old model
--[[function SWEP:Think()
	local VModel = self.Owner:GetViewModel()
	local cvar = GetConVar("cl_scgg_viewmodel"):GetString()
	if VModel:GetModel() != cvar then
		self.ViewModel = cvar
		VModel:SetModel(cvar)
	end
end--]]

end