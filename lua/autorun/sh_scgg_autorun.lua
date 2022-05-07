AddCSLuaFile("client/cl_scgg_autorun.lua")
AddCSLuaFile()

if SERVER then
	include("server/sv_scgg_autorun.lua")
end

list.Set("NPCUsableWeapons", "weapon_superphyscannon", {
	title = "Super Gravity Gun",
	class = "weapon_superphyscannon"
})