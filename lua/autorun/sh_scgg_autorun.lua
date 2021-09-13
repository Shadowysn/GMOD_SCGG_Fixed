AddCSLuaFile("client/cl_scgg_autorun.lua")
AddCSLuaFile()

include("server/sv_scgg_autorun.lua")

list.Set("NPCUsableWeapons", "weapon_superphyscannon", {
	title = "Super Gravity Gun",
	class = "weapon_superphyscannon"
})