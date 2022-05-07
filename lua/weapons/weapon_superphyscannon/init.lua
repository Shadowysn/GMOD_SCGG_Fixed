AddCSLuaFile("cl_glow_spr.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

if SERVER then
	include("shared.lua")
end