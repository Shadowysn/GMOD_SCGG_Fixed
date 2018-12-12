SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true
SWEP.ViewModel			= "models/weapons/errolliamp/c_superphyscannon.mdl"
--SWEP.ViewModel			= "models/weapons/c_superphyscannon.mdl"
SWEP.WorldModel		= "models/weapons/errolliamp/w_superphyscannon.mdl"
--SWEP.WorldModel		= "models/weapons/w_physics.mdl"
SWEP.UseHands = true
SWEP.ViewModelFlip		= false
SWEP.ViewModelFOV		= 53
SWEP.Weight 			= 42
SWEP.AutoSwitchTo 		= true
SWEP.AutoSwitchFrom 		= true
SWEP.HoldType			= "physgun"
	
SWEP.PuntForce			= 280000
--SWEP.HL2PuntForce		= 80000
SWEP.PullForce			= 8000
SWEP.HL2PullForce		= 800
SWEP.HL2PullForceRagdoll	= 100000
SWEP.MaxMass			= 15000
SWEP.HL2MaxMass			= 5500
SWEP.MaxPuntRange		= 5000
SWEP.HL2MaxPuntRange	= 550
SWEP.MaxPickupRange		= 850
SWEP.MaxTargetHealth	= 250
SWEP.Distance			= 55 -- 35
	
SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic	= true
SWEP.Primary.Ammo		= ""
	
SWEP.Secondary.ClipSize	= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo		= ""

if (CLIENT) then
	SWEP.PrintName			= "SUPER GRAVITY GUN"
	SWEP.Author			= "ErrolLiamP, Î¤yler Blu, QuentinDylanP"
	SWEP.Slot			= 1
	SWEP.SlotPos			= 9
	SWEP.IconLetter			= "k"
end
	
local HoldSound			= Sound("Weapon_MegaPhysCannon.HoldSound")

util.PrecacheModel("models/weapons/errolliamp/v_megaphyscannon.mdl")
util.PrecacheModel("models/weapons/errolliamp/w_megaphyscannon.mdl")
util.PrecacheModel("models/props_junk/PopCan01a.mdl")

function SWEP:Initialize()
		self:SetWeaponHoldType( self.HoldType )
		self:SetSkin(1)
		self.Fade = true
		self.RagdollRemoved = false
		--self.CoreAllowRemove = true
		--self.GlowAllowRemove = true
		self.HPCollideG = COLLISION_GROUP_NONE
		if SERVER then
			util.AddNetworkString( "PlayerKilledNPC" )
			util.AddNetworkString( "PlayerKilledByPlayer" )
			util.AddNetworkString( "SCGG_Open_Claws" )
		end
	end
	
function SWEP:OwnerChanged()
		self:SetSkin(1)
		self:TPrem()
		if self.HP then
			self.HP = nil
		end
	end

function SWEP:Think()
if GetConVar("scgg_style"):GetInt() <= 0 then
	self.SwayScale 	= 3
	self.BobScale 	= 1
	else
	self.SwayScale 	= 1
	self.BobScale 	= 1
end
	if CLIENT then
	if GetConVar("scgg_light"):GetInt() <= 0 then return end
	if !self.Weapon:GetNWBool("Glow") then
		if !self.Owner:LookupBone("ValveBiped.Bip01_R_Hand") then return end
		local dlight = DynamicLight("lantern_"..self:EntIndex())
		if dlight then
		dlight.Pos = self.Owner:GetBonePosition(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"))
		dlight.r = 200
		dlight.g = 255
		dlight.b = 255
		dlight.Brightness = 0.1
		dlight.Size = 70
		dlight.DieTime = CurTime() + .0001
		--dlight.Style = 0
		end
		else
		if !self.Owner:LookupBone("ValveBiped.Bip01_R_Hand") then return end
		local dlight = DynamicLight("lantern_"..self:EntIndex())
		if dlight then
		dlight.Pos = self.Owner:GetBonePosition(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand"))
		dlight.r = 255
		dlight.g = 255
		dlight.b = 255
		dlight.Brightness = 0.3
		dlight.Size = 100
		dlight.DieTime = CurTime() + .0001
		--dlight.Style = 0
		end
		end
		end
		if GetConVar("scgg_enabled"):GetInt() <= 0 and self.Fade == true then
			self.Fade = false
			self.Fading = true
			self.Weapon:EmitSound("Weapon_Physgun.Off", 75, 100, 1)
			
			timer.Simple( 0.70, function()
			if !IsValid(self) then return end
			if !self.Owner:HasWeapon( "weapon_physcannon" ) then
				self.Owner:Give("weapon_physcannon")
			end
			self.Owner:SelectWeapon("weapon_physcannon")
			self:Remove()
			end )
		end
		
		if IsValid(self.Core) then
			self.Core:SetPos( self.Owner:GetShootPos() )
		end
		if !IsValid(self.Core) and self.CoreAllowRemove == false then
			-- Required to directly include the code, not as a function or else it becomes a lua-error minigun.
			self.Core = ents.Create("PhyscannonCore")
			self.Core:SetPos( self.Owner:GetShootPos() )
			self.Core:Spawn()
			self.Core:SetParent(self.Owner)
			self.Core:SetOwner(self.Owner)
		end
		if IsValid(self.Glow) then
			self.Glow:SetPos( self.Owner:GetShootPos() )
		end
		if !IsValid(self.Glow) and self.GlowAllowRemove == false then
			-- Required to directly include the code, not as a function or else it becomes a lua-error minigun.
			self.Glow = ents.Create("PhyscannonGlow")
			self.Weapon:SetNetworkedBool("Glow", true)
			self.Glow:SetPos( self.Owner:GetShootPos() )
			self.Glow:Spawn()
			self.Glow:SetParent(self.Owner)
			self.Glow:SetOwner(self.Owner)
		end
		
		local trace = self.Owner:GetEyeTrace()
		local tgt = trace.Entity
		
		if math.random(  6,  98 ) == 16 and !self.TP and !self.Owner:KeyDown(IN_ATTACK2) and !self.Owner:KeyDown(IN_ATTACK) then
			if self.Fading == true then return end
			self:ZapEffect()
		end
		
		if self.Owner:KeyPressed(IN_ATTACK2) then
			if self.Fading == true then return end
			self:GlowEffect()
			self:RemoveCore()
		elseif self.Owner:KeyReleased(IN_ATTACK2) and !self.TP then
			if self.Fading == true then return end
			self:RemoveGlow()
			self:RemoveCore()
			self:CoreEffect()
		end
		
		if !self.Owner:KeyDown(IN_ATTACK) then
		if GetConVar("scgg_style"):GetInt() >= 1 then
			self.Weapon:SetNextPrimaryFire( CurTime() - 0.55 ); end
		end
		
		if self.Owner:KeyPressed(IN_ATTACK2) then
			if self.Fading == true then return end
			--if self.HP then return end   This fixes the secondary dryfire not playing
			
			if !tgt or !tgt:IsValid() then
				--self.Weapon:EmitSound("Weapon_PhysCannon.TooHeavy", 75, 100, 1)
				self.Weapon:EmitSound("Weapon_PhysCannon.TooHeavy")
				return
			end
			
			if (SERVER) then
				if tgt:GetMoveType() == MOVETYPE_VPHYSICS then
					local getstyle = GetConVar("scgg_style"):GetInt()
					local Mass = tgt:GetPhysicsObject():GetMass()
					if ( getstyle == 0 and Mass >= (self.HL2MaxMass+1) ) or ( getstyle != 0 and Mass >= (self.MaxMass+1) ) then
						--if GetConVar("scgg_style"):GetInt() <= 0 then
						self.Weapon:EmitSound("Weapon_PhysCannon.TooHeavy")
						return
						--end 
					end
				else 
					self.Weapon:EmitSound("Weapon_PhysCannon.TooHeavy")
					return
				end
			end
		end
		
		if self.TP then
			if self.HP and self.HP != NULL and IsValid(self.HP) then
				if (SERVER) then
				if !IsValid(self.HP) then self.HP = nil self.Drop() return end
					HPrad = self.HP:BoundingRadius()
					if !IsValid(self.Owner) then return end
					if !IsValid(self.TP) then return end
					self.TP:SetPos(self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.Distance+HPrad))
					
					self.TP:PointAtEntity(self.Owner)
				--if self.HP:GetPhysicsObject() == nil then return end
				--if IsValid(phys) then
					if IsValid(self.HP) and IsValid(self.HP:GetPhysicsObject()) then
					self.HP:GetPhysicsObject():Wake()
					end
				end --end
			else
				self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
				self.Owner:SetAnimation( PLAYER_ATTACK1 )
				
				self.Secondary.Automatic = true
				self.Weapon:SetNextSecondaryFire( CurTime() + 0.5 );
				self.Weapon:EmitSound("Weapon_MegaPhysCannon.Drop")
				
				timer.Simple( 0.4, 
				function()
					if self.Owner:GetActiveWeapon():GetClass() == "weapon_superphyscannon" then
					self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
					end
				end )
				
				self:CoreEffect()
				self:RemoveGlow()
				
				if self.TP then
					self.TP:Remove()
					self.TP = nil
				end
				if self.HP then
					self.HP = nil
				end
				
				self.Weapon:StopSound(HoldSound)
			end
			
			if CurTime() >= PropLockTime then
			if !IsValid(self.HP) then self.HP = nil return end
				if (self.HP:GetPos()-(self.Owner:GetShootPos()+self.Owner:GetAimVector()*(self.Distance+HPrad))):Length() >= 80 then
					self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
					self.Owner:SetAnimation( PLAYER_ATTACK1 )
					self:Drop()
				end
			end
			if !IsValid(self.TP) then return end
				for _, child in pairs(self.TP:GetChildren()) do
					if child:GetClass() == "env_entity_dissolver" then
						child:Remove()
					end
				end
		end
	end
	
function SWEP:ZapEffect()
	if self.Fading == true then return end
		if SERVER then
			if GetConVar("scgg_no_effects"):GetInt() >= 1 then return end
			--if GetConVar("scgg_style"):GetInt() <= 1 then return end
			local zap_math = table.Random( { 1, 2, 3 } )
			if zap_math == 1 then
				self.Zap =  ents.Create("PhyscannonZap1")
				else
			if zap_math == 2 then
				self.Zap =  ents.Create("PhyscannonZap2")
				else
			if zap_math == 3 then
				self.Zap =  ents.Create("PhyscannonZap3")
				else
			end
			end
			end
			self.Zap:SetPos( self.Owner:GetShootPos() )
			self.Zap:Spawn()
			self.Zap:SetParent(self.Owner)
			self.Zap:SetOwner(self.Owner)
		end
	end

function SWEP:NotAllowedClass()
		local trace = self.Owner:GetEyeTrace()
		local class = trace.Entity:GetClass()
		if class == "npc_strider"
			or class == "npc_helicopter"
			or class == "npc_combinedropship"
			or class == "npc_barnacle"
			or class == "npc_antliongrub"
			or class == "npc_turret_ceiling"
			or class == "npc_combine_camera"
			or class == "npc_combinegunship" then
			--or class == "prop_vehicle_prisoner_pod"	then
		return true
		else
		return false
		end
	end
	
function SWEP:AllowedClass()
		local trace = self.Owner:GetEyeTrace()
		local class = trace.Entity:GetClass()
		--[[for _,child in pairs(trace.Entity:GetChildren()) do
			if child:GetClass() == "env_entity_dissolver" then
				return false
			end
		end--]] -- Not yet fully tested
		--if trace.Entity:GetMoveType() == MOVETYPE_VPHYSICS then
		if class == "npc_manhack"
			or class == "npc_turret_floor"
			or class == "npc_sscanner"
			or class == "npc_cscanner"
			or class == "npc_clawscanner"
			or class == "npc_rollermine"
			or class == "npc_grenade_frag"
			or class == "item_ammo_357"
			or class == "item_ammo_ar2_altfire"
			or class == "item_ammo_crossbow"
			or class == "item_ammo_pistol"
			or class == "item_ammo_smg1"
			or class == "item_ammo_smg1_grenade"
			or class == "item_battery"
			or class == "item_box_buckshot"
			or class == "item_healthvial"
			or class == "item_healthkit"
			or class == "item_rpg_round"
			or class == "item_ammo_ar2"
			or class == "item_item_crate"
			or trace.Entity:IsWeapon()
			--[[or class == "weapon_357"
			or class == "weapon_annabelle"
			or class == "weapon_alyxgun"
			or class == "weapon_ar2"
			or class == "weapon_bugbait"
			or class == "weapon_crossbow"
			or class == "weapon_crowbar"
			or class == "weapon_physcannon"
			or class == "weapon_frag"
			or class == "weapon_physgun"
			or class == "weapon_pistol"
			or class == "weapon_rpg"
			or class == "weapon_shotgun"
			or class == "weapon_slam"
			or class == "weapon_smg1"
			or class == "weapon_stunstick"]]
			or class == "weapon_striderbuster"
			or class == "combine_mine"
			--[[or class == "gmod_tool"
			or class == "gmod_camera"]]
			or class == "gmod_camera"
			or class == "gmod_cameraprop"
			or class == "helicopter_chunk"
			or class == "func_physbox"
			or class == "grenade_helicopter"
			or class == "prop_combine_ball"
			or class == "prop_wheel"
			or class == "prop_vehicle_prisoner_pod"
			or class == "prop_physics_multiplayer"
			or class == "prop_physics"
			or class == "prop_dynamic"
			or class == "func_brush"	then
		return true
		else
		return false
		end
	end
	
function SWEP:FriendlyNPC( npc )
	if SERVER then
	if !IsValid(npc) then return false end
	if !npc:IsNPC() then return false end
	
	if npc:Disposition( self.Owner ) == D_LI then
		return true
	else
		return false
	end
end
end
	
--[[function SWEP:OpenClaws() -- Does not function
	--self.Weapon:EmitSound("Weapon_MegaPhysCannon.Charge")
	if CLIENT then
		local function BeginOpen()
			local Open = GetViewEntity():LookupSequence("ProngsOpen")
			GetViewEntity():SetSequence(Open)
			net.Receive( "SCGG_Open_Claws", BeginOpen )
		end
	end
	if SERVER then
		net.Start( "SCGG_Open_Claws" )
		net.Send( self.Owner )
	end
	--local Open = self.Owner:GetViewModel():LookupSequence("ProngsOpen")
	--self.Owner:GetViewModel():SetSequence(Open)
	--local Open = self.Weapon:LookupSequence("ProngsShut")
end--]]
	
function SWEP:PrimaryAttack()
	if self.Fading == true then return end
		if GetConVar("scgg_style"):GetInt() <= 0 then
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.5 ) end
		self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		if GetConVar("scgg_style"):GetInt() >= 1 then
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.55 ); end
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.3 );
		
		local vm = self.Owner:GetViewModel()
		timer.Create( "attack_idle" .. self:EntIndex(), 0.4, 1, function()
		if !IsValid( self.Weapon ) then return end
		if self.Owner:GetActiveWeapon():GetClass() == "weapon_superphyscannon" then
			self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
		end
		end)
		
		if self.TP then
			self:DropAndShoot()
			return
		end
		
		local trace = self.Owner:GetEyeTrace()
		local tgt = trace.Entity
		
		local getstyle = GetConVar("scgg_style"):GetInt()
		if !tgt or !tgt:IsValid() or 
		( getstyle == 0 and (self.Owner:GetShootPos()-tgt:GetPos()):Length() > self.HL2MaxPuntRange )
		or 
		( getstyle != 0 and (self.Owner:GetShootPos()-tgt:GetPos()):Length() > self.MaxPuntRange )
		or self:NotAllowedClass() 
		or ( tgt:IsNPC() and GetConVar("scgg_friendly_fire"):GetInt()<=0 and self:FriendlyNPC(tgt) ) then
			self.Weapon:EmitSound("Weapon_MegaPhysCannon.DryFire")
			return
		end
		
		if tgt:IsNPC() and !self:AllowedClass() and !self:NotAllowedClass() or tgt:IsPlayer() then
			if (SERVER) then
				if tgt:IsPlayer() and tgt:HasGodMode() == true then return end
				--if (tgt:IsPlayer() and server_settings.Int( "sbox_plpldamage" ) == 1) then
					--self.Weapon:EmitSound("Weapon_MegaPhysCannon.DryFire")
					--return
				--end
				if ( GetConVar("scgg_style"):GetInt() <= 0 and tgt:Health() > self.MaxTargetHealth ) or !util.IsValidRagdoll(tgt:GetModel()) then
					local dmginfo = DamageInfo()
					dmginfo:SetDamage( self.MaxTargetHealth )
					dmginfo:SetAttacker( self.Owner )
					dmginfo:SetInflictor( self.Weapon )
					tgt:TakeDamageInfo( dmginfo )
				else
				
				if tgt:IsPlayer() then
					net.Start( "PlayerKilledByPlayer" )
					net.WriteEntity( tgt )
					net.WriteString( "weapon_superphyscannon" )
					net.WriteEntity( self.Owner )
					net.Broadcast()
				elseif tgt:IsNPC() then
					if tgt:GetShouldServerRagdoll() != true then
					tgt:SetShouldServerRagdoll( true )
					end
					if tgt:Health() >= 1 then
						--tgt:Fire( "AddOutput", "health 0", 0 )
						tgt:SetHealth( 0 )
					end
					local dmg = DamageInfo()
					dmg:SetDamage( tgt:Health() )
					dmg:SetDamageForce( Vector( 0, 0, 0 ) )
					dmg:SetDamageType( DMG_SHOCK )
					dmg:SetAttacker( self.Owner )
					dmg:SetInflictor( self.Weapon )
					dmg:SetReportedPosition( self.Owner:GetShootPos() )
					tgt:TakeDamageInfo( dmg )
					
					
					for _,rag in pairs( ents.FindInSphere( tgt:GetPos(), tgt:GetModelRadius() ) ) do
						if rag:IsRagdoll() and rag:GetModel() == tgt:GetModel() and rag:GetCreationTime() == CurTime() and self.RagdollRemoved == false then
							self.RagdollRemoved = true
							rag:Remove()
						end
					end
					
					self.RagdollRemoved = false
					--[[net.Start( "PlayerKilledNPC" )
					net.WriteString( tgt:GetClass() )
					net.WriteString( "weapon_superphyscannon" )
					net.WriteEntity( self.Owner )
					net.Broadcast()--]]
				end
				
				local ragdoll = ents.Create( "prop_ragdoll" )
				ragdoll:SetPos( tgt:GetPos())
				ragdoll:SetAngles(tgt:GetAngles()-Angle(tgt:GetAngles().p,0,0))
				ragdoll:SetModel( tgt:GetModel() )
				ragdoll:SetSkin( tgt:GetSkin() )
				ragdoll:SetColor( tgt:GetColor() )
				ragdoll:SetName( pickedupragdoll )
				for k,v in pairs(tgt:GetBodyGroups()) do
					ragdoll:SetBodygroup(v.id,tgt:GetBodygroup(v.id))
				end
				ragdoll:SetMaterial( tgt:GetMaterial() )
				
				--[[if tgt:GetActiveWeapon():IsValid() then
				local wep = trace.Entity:GetActiveWeapon()
				--local model = wep:GetModel()
				local wepclass = wep:GetClass()
				
					if tgt:IsNPC() then
				if GetConVar("scgg_weapon_vaporize"):GetInt() <= 0 then
				local weaponmodel = ents.Create( wepclass )
				weaponmodel:SetPos( tgt:GetShootPos() )
				weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
				weaponmodel:SetSkin( wep:GetSkin() )
				weaponmodel:SetColor( wep:GetColor() )
				weaponmodel:SetKeyValue("spawnflags","2")
				weaponmodel:Spawn()
				weaponmodel:Fire("Addoutput","spawnflags 0",1)
				elseif GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
				local weaponmodel = ents.Create( "prop_physics_override" )
				weaponmodel:SetPos( tgt:GetShootPos() )
				weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
				weaponmodel:SetModel( wep:GetModel() )
				weaponmodel:SetSkin( wep:GetSkin() )
				weaponmodel:SetColor( wep:GetColor() )
				weaponmodel:SetCollisionGroup( COLLISION_GROUP_WEAPON )
				weaponmodel:Spawn()
				
				
				local dissolver = ents.Create( "env_entity_dissolver" )
				dissolver:SetPos( weaponmodel:LocalToWorld(weaponmodel:OBBCenter()) )
				dissolver:SetKeyValue( "dissolvetype", 0 )
				dissolver:Spawn()
				dissolver:Activate()
				local name = "Dissolving_"..math.random()
				weaponmodel:SetName( name )
				dissolver:Fire( "Dissolve", name, 0 )
				dissolver:Fire( "Kill", name, 0.10 )
				end
				
					end
				end--]]
				
			if GetConVar("scgg_zap"):GetInt() >= 1 then
			local effect  	= EffectData()
			if !IsValid(ragdoll) then return end
			effect:SetOrigin(ragdoll:GetPos())
			effect:SetStart(ragdoll:GetPos())
			effect:SetMagnitude(5)
			effect:SetEntity(ragdoll)
			util.Effect("teslaHitBoxes",effect)
			if GetConVar("scgg_zap_sound"):GetInt() >= 1 then
			ragdoll:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			timer.Create( "zapper", 0.3, 16, function()
			local effect2  	= EffectData()
			if !IsValid(ragdoll) then return end
			effect2:SetOrigin(ragdoll:GetPos())
			effect2:SetStart(ragdoll:GetPos())
			effect2:SetMagnitude(5)
			effect2:SetEntity(ragdoll)
			util.Effect("teslaHitBoxes",effect2)
			if !IsValid(ragdoll) then return end
			if GetConVar("scgg_zap_sound"):GetInt() >= 1 then
			ragdoll:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			end) end
	
				--tgt:DropWeapon( tgt:GetActiveWeapon() )
				--if tgt:HasWeapon()
				ragdoll:SetMaterial( tgt:GetMaterial() )
				
				--if server_settings.Int( "ai_keepragdolls" ) == 0 then
					--ragdoll.Entity:Fire("FadeAndRemove","",0.3)
				--else
					ragdoll:Fire("FadeAndRemove","",120)
				--end
				
				cleanup.Add (self.Owner, "props", ragdoll);
				undo.Create ("ragdoll");
				undo.AddEntity (ragdoll);
				undo.SetPlayer (self.Owner);
				undo.Finish();
				
				if tgt:IsPlayer() then
					tgt:KillSilent()
					--ragdoll:SetPlayerColor( tgt:GetPlayerColor() )
					tgt:AddDeaths(1)
					tgt:SpectateEntity(ragdoll)
					tgt:Spectate(OBS_MODE_CHASE)

				elseif tgt:IsNPC() then
					--if tgt:Health() >= 1 then
					tgt:Fire("Kill","",0)
					--net.Start( "PlayerKilledNPC" )
					--net.WriteString( tgt:GetClass() )
					--net.WriteString( "weapon_superphyscannon" )
					--net.WriteEntity( self.Owner )
					--net.Broadcast()
					--end
				end
				
				self.Owner:AddFrags(1)
				
				ragdoll:Spawn()
				if GetConVar("scgg_zap"):GetInt() >= 1 then
				ragdoll:Fire("StartRagdollBoogie","",0) end
				--ragdoll:Fire("SetBodygroup","15",0)
				--timer.Remove( "SCGG_Ragdoll_Collision_Timer" )
				ragdoll:SetCollisionGroup( self.HPCollideG )
				--timer.Create( "SCGG_Ragdoll_Collision_Timer", 2, 1, function() 
					--if ragdoll:IsValid() then
						--ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
					--end
				--end )
				
				RagdollVisual(ragdoll, 1)
				
				for i = 1, ragdoll:GetPhysicsObjectCount() do
					local bone = ragdoll:GetPhysicsObjectNum(i)
					
					if bone and bone.IsValid and bone:IsValid() then
						local bonepos, boneang = tgt:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
						
						bone:SetPos(bonepos)
						bone:SetAngles(boneang)
						timer.Simple( 0.01, 
						function()
							if IsValid(bone) then
							if GetConVar("scgg_style"):GetInt() <= 0 then --Ragdoll Thrown
							
							bone:AddVelocity(self.Owner:GetAimVector()*13000/8) 
							else
							bone:AddVelocity(self.Owner:GetAimVector()*self.PuntForce/8) 
							end
							end
						end )
					end
				end
			end
			
			end
			self:Visual()
			--self:DoSparks()
		end
		
		--if self:AllowedClass() or tgt:GetClass() == "prop_vehicle_airboat" or tgt:GetClass() == "prop_vehicle_jeep" and tgt:GetPhysicsObject():IsMoveable() then
		if self:AllowedClass() or tgt:GetClass() == "prop_vehicle_airboat" or tgt:GetClass() == "prop_vehicle_jeep" then
			self:Visual()
			if tgt:GetClass() == "prop_combine_ball" then
				self.Owner:SimulateGravGunPickup( tgt )
				timer.Simple( 0.01, function() 
				if IsValid(tgt) then
				self.Owner:SimulateGravGunDrop( tgt ) 
				end
				end)
			end
			if (SERVER) then
				local position = trace.HitPos
				if GetConVar("scgg_style"):GetInt() <= 0 then --Prop Punting
				
				if tgt:GetClass() == "prop_combine_ball" then
				tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*800000) -- 100
				tgt:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*800000, position ) 
				tgt:SetOwner(self.Owner)
				else
				
				tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*1000000) --1000000
				tgt:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*1000000, position )
				end
				
				else
				
				if tgt:GetClass() == "prop_combine_ball" then
				tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector())
				tgt:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector(), position )
				tgt:SetOwner(self.Owner)
				else
				tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*self.PuntForce)
				tgt:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*self.PuntForce, position )
				end
				
				end 
			tgt:SetPhysicsAttacker(self.Owner, 2)
			tgt:Fire("physdamagescale","99999",0)
			
			end
		end
		
		if tgt:IsRagdoll() then
			self:Visual()
			if (SERVER) then
			
				--[[for i = 1, tgt:GetPhysicsObjectCount() do
					local bone = tgt:GetPhysicsObjectNum(i)
					
					if bone and bone.IsValid and bone:IsValid() then
						bone:SetPhysicsAttacker(self.Owner, 2)
						tgt:GetPhysicsObject():SetPhysicsAttacker(self.Owner, 2)
					end
				end--]]
				tgt:SetPhysicsAttacker(self.Owner, 2)
				
				if GetConVar("scgg_zap"):GetInt() >= 1 then
				tgt:Fire("StartRagdollBoogie","",0) end
				RagdollVisual(tgt, 1)
				
			if GetConVar("scgg_zap"):GetInt() >= 1 then
			local effect  	= EffectData()
			if !IsValid(tgt) then return end
			effect:SetOrigin(tgt:GetPos())
			effect:SetStart(tgt:GetPos())
			effect:SetMagnitude(5)
			effect:SetEntity(tgt)
			util.Effect("teslaHitBoxes",effect)
			if GetConVar("scgg_zap_sound"):GetInt() >= 1 then
			tgt:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			timer.Create( "zapper", 0.3, 16, function()
			if IsValid(tgt) then
			local effect2  	= EffectData()
			effect2:SetOrigin(tgt:GetPos())
			effect2:SetStart(tgt:GetPos())
			effect2:SetMagnitude(5)
			effect2:SetEntity(tgt)
			util.Effect("teslaHitBoxes",effect2)
			end
			if !IsValid(tgt) then return end
			if GetConVar("scgg_zap_sound"):GetInt() >= 1 then
			tgt:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			end) end
				
				for i = 1, tgt:GetPhysicsObjectCount() do
					local bone = tgt:GetPhysicsObjectNum(i)
					
					if bone and bone.IsValid and bone:IsValid() then
					if GetConVar("scgg_style"):GetInt() <= 0 then
						bone:AddVelocity(self.Owner:GetAimVector()*10000/8) else
						bone:AddVelocity(self.Owner:GetAimVector()*self.PuntForce/8) 
						end
					end
				end
				
				--timer.Remove( "SCGG_Ragdoll_Collision_Timer" )
				tgt:SetCollisionGroup( self.HPCollideG )
				--[[timer.Create( "SCGG_Ragdoll_Collision_Timer", 2, 1, function() 
					if tgt:IsValid() then
					tgt:SetCollisionGroup(COLLISION_GROUP_WEAPON)
					end
				end )--]]
			end
		end
	end
	
function SWEP:DropAndShoot()
		if !IsValid(self.HP) then self.HP = nil return end
		self.HP:Fire("EnablePhyscannonPickup","",1)
		if self.HP:IsRagdoll() then
		self.HP:SetCollisionGroup( COLLISION_GROUP_NONE )
		else
		self.HP:SetCollisionGroup( self.HPCollideG )
		end
		self.HP:SetPhysicsAttacker(self.Owner, 2)
		self.HP:SetNWBool("launched_by_scgg", true)
		self.Owner:SimulateGravGunDrop( self.HP )
		
		self.Secondary.Automatic = true
		if GetConVar("scgg_style"):GetInt() >= 1 then
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.5 );
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.55 ); end
		
		self:CoreEffect()
		self:RemoveGlow()
		self:Visual()
		self:TPrem()
		
		self.Weapon:StopSound(HoldSound)
		
		if self.HP:IsRagdoll() then
		
		--timer.Create( "zap2", 0.1, 5, function()
		--local e = EffectData()
		--local trace = self.Owner:GetEyeTrace()
		--e:SetEntity(trace.Entity)
		--e:SetMagnitude(30)
		--e:SetScale(30)
		--e:SetRadius(30)
		--util.Effect("TeslaHitBoxes", e)
		--trace.Entity:EmitSound("Weapon_StunStick.Activate") end)
			local tr = self.Owner:GetEyeTrace()
			
			--timer.Remove( "SCGG_Ragdoll_Collision_Timer" )
			--[[timer.Create( "SCGG_Ragdoll_Collision_Timer", 2, 1, function() 
				if self.HP == nil then
					
				else
					self.HP:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				end
			end )--]]
	
	local dmginfo = DamageInfo();
	dmginfo:SetDamage( 500 );
	dmginfo:SetAttacker( self:GetOwner() );
	dmginfo:SetInflictor( self );
		
		
			--local dissolver = ents.Create("env_entity_dissolver")
	--dissolver:SetKeyValue("magnitude",0)
	--local trace = self.Owner:GetEyeTrace()
	--local tgt = trace.Entity
	--dissolver:SetPos(tgt)
	--dissolver:SetKeyValue("target",targname)
	--dissolver:Spawn()
			--dmginfo:SetDamageType( DMG_SHOCK )
		--dmginfo:SetDamagePosition( tr.HitPos )

			if GetConVar("scgg_zap"):GetInt() >= 1 then
			self.HP:Fire("StartRagdollBoogie","",0) end
			RagdollVisual(self.HP, 1)
			
			for i = 1, self.HP:GetPhysicsObjectCount() do
				local bone = self.HP:GetPhysicsObjectNum(i)
				
				if bone and bone.IsValid and bone:IsValid() then
			if GetConVar("scgg_zap"):GetInt() >= 1 then
			local effect  	= EffectData()
			if !IsValid(self.HP) then return end
			effect:SetOrigin(self.HP:GetPos())
			effect:SetStart(self.HP:GetPos())
			effect:SetMagnitude(5)
			effect:SetEntity(self.HP)
			util.Effect("teslaHitBoxes",effect)
			--self.HP:EmitSound("Weapon_StunStick.Activate")
			timer.Create( "zapper", 0.3, 16, function()
			util.Effect("teslaHitBoxes",effect)
			if !IsValid(self.HP) then self.HP = nil return end
			if GetConVar("scgg_zap_sound"):GetInt() >= 1 then
			self.HP:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			end) end
					timer.Simple( 0.02, 
				function()
						if GetConVar("scgg_style"):GetInt() <= 0 then
						bone:AddVelocity(self.Owner:GetAimVector()*20000/8) else
						bone:AddVelocity(self.Owner:GetAimVector()*self.PuntForce/8) 
						end
					end )
				end
			end
		else
			local trace = self.Owner:GetEyeTrace()
			local position = trace.HitPos
			
		timer.Simple( 0.02,	
			function()
				if GetConVar("scgg_style"):GetInt() <= 0 then --Prop Throwing
					
					if self.HP:GetClass() == "prop_combine_ball" then
					self.HP:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*800000)
					self.HP:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*800000,position ) 
					self.HP:SetOwner(self.Owner)
					else
					self.HP:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*3500000) --3500000 --500*( self.HP:GetPhysicsObject():GetMass() ) )
					self.HP:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*3500000 ,position ) 
					end
					
					else
					
					if self.HP:GetClass() == "prop_combine_ball" then
					self.HP:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*self.PuntForce/0.25)
					self.HP:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*self.PuntForce/0.25,position )
					self.HP:SetOwner(self.Owner)
					else
					self.HP:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*self.PuntForce)
					self.HP:GetPhysicsObject():ApplyForceOffset(self.Owner:GetAimVector()*self.PuntForce,position )
					end
					
				end
			end )
		end
			
			self.HP:Fire("physdamagescale","999",0)
		
		timer.Simple( 0.04, 
	function()
			--self.HP = nil
		end )
		
		if self.HPCollideG then
			self.HPCollideG = COLLISION_GROUP_NONE
		end
		
	end


function SWEP:SecondaryAttack()
	if self.Fading == true then return end
		if self.TP then
			self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
			self.Owner:SetAnimation( PLAYER_ATTACK1 )
			self:Drop()
			return
		end
		
		local trace = self.Owner:GetEyeTrace()
		local tgt = trace.Entity
		
		if !tgt or !tgt:IsValid() then
			return
		end
		if ( GetConVar("scgg_style"):GetInt() <= 0 ) 
		and 
		( ( tgt:IsNPC() or tgt:IsPlayer() ) and tgt:Health() > self.MaxTargetHealth ) 
		--or !util.IsValidRagdoll(tgt:GetModel()) 
		then return end
		
		if !self:NotAllowedClass() and !self:AllowedClass() then
			if (SERVER) then
				local Dist = (tgt:GetPos()-self.Owner:GetPos()):Length()
				if Dist >= self.MaxPickupRange then return end
				if tgt:IsPlayer() and tgt:HasGodMode() == true then return end
				--if tgt:IsPlayer() and server_settings.Int( "sbox_plpldamage" ) == 1 then
					--self.Weapon:EmitSound("Weapon_PhysCannon.TooHeavy")
					--return
				--end
				
				if tgt:IsNPC() and ( GetConVar("scgg_friendly_fire"):GetInt()>=1 or !self:FriendlyNPC(tgt) ) or tgt:IsPlayer() then
					
					if tgt:IsPlayer() then
					net.Start( "PlayerKilledByPlayer" )
					net.WriteEntity( tgt )
					net.WriteString( "weapon_superphyscannon" )
					net.WriteEntity( self.Owner )
					net.Broadcast()
					elseif tgt:IsNPC() then
					if tgt:GetShouldServerRagdoll() != true then
					tgt:SetShouldServerRagdoll( true )
					end
					if tgt:Health() >= 1 then
						--tgt:Fire( "AddOutput", "health 0", 0 )
						tgt:SetHealth( 0 )
					end
					local dmg = DamageInfo()
					dmg:SetDamage( tgt:Health() )
					dmg:SetDamageForce( Vector( 0, 0, 0 ) )
					dmg:SetDamageType( DMG_SHOCK )
					dmg:SetAttacker( self.Owner )
					dmg:SetInflictor( self.Weapon )
					dmg:SetReportedPosition( self.Owner:GetShootPos() )
					tgt:TakeDamageInfo( dmg )
					
					for _,rag in pairs( ents.FindInSphere( tgt:GetPos(), tgt:GetModelRadius() ) ) do
						if rag:IsRagdoll() and rag:GetModel() == tgt:GetModel() and rag:GetCreationTime() == CurTime() and self.RagdollRemoved == false then
							self.RagdollRemoved = true
							rag:Remove()
						end
					end
					
					self.RagdollRemoved = false
					
					--[[net.Start( "PlayerKilledNPC" )
					net.WriteString( tgt:GetClass() )
					net.WriteString( "weapon_superphyscannon" )
					net.WriteEntity( self.Owner )
					net.Broadcast()--]]
					end
					
					if tgt:IsNPC() and tgt:Health() >= 1 then return end
					local ragdoll = ents.Create( "prop_ragdoll" )
					ragdoll:SetPos( tgt:GetPos())
					ragdoll:SetAngles(tgt:GetAngles()-Angle(tgt:GetAngles().p,0,0))
					ragdoll:SetModel( tgt:GetModel() )
					ragdoll:SetSkin( tgt:GetSkin() )
					ragdoll:SetColor( tgt:GetColor() )
					for k,v in pairs(tgt:GetBodyGroups()) do
						ragdoll:SetBodygroup(v.id,tgt:GetBodygroup(v.id))
					end
					ragdoll:SetMaterial( tgt:GetMaterial() )
					ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
					
					--[[if tgt:GetActiveWeapon():IsValid() then
						local wep = trace.Entity:GetActiveWeapon()
						--local model = wep:GetModel()
						local wepclass = wep:GetClass()
						
							if tgt:IsNPC() then
						if GetConVar("scgg_weapon_vaporize"):GetInt() <= 0 then
						local weaponmodel = ents.Create( wepclass )
						weaponmodel:SetPos( tgt:GetShootPos() )
						weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
						--if model:IsValid() then
						--weaponmodel:SetModel( model )
						--end
						weaponmodel:SetSkin( wep:GetSkin() )
						weaponmodel:SetColor( wep:GetColor() )
						weaponmodel:SetKeyValue("spawnflags","2")
						weaponmodel:Spawn()
						weaponmodel:Fire("Addoutput","spawnflags 0",1)
						
						elseif GetConVar("scgg_weapon_vaporize"):GetInt() >= 1 then
						local weaponmodel = ents.Create( "prop_physics_override" )
						weaponmodel:SetPos( tgt:GetShootPos() )
						weaponmodel:SetAngles(wep:GetAngles()-Angle(wep:GetAngles().p,0,0))
						weaponmodel:SetModel( wep:GetModel() )
						weaponmodel:SetSkin( wep:GetSkin() )
						weaponmodel:SetColor( wep:GetColor() )
						weaponmodel:SetCollisionGroup( COLLISION_GROUP_WEAPON )
						weaponmodel:Spawn()
						
						local dissolver = ents.Create( "env_entity_dissolver" )
						dissolver:SetPos( weaponmodel:LocalToWorld(weaponmodel:OBBCenter()) )
						dissolver:SetKeyValue( "dissolvetype", 0 )
						dissolver:Spawn()
						dissolver:Activate()
						local name = "Dissolving_"..math.random()
						weaponmodel:SetName( name )
						dissolver:Fire( "Dissolve", name, 0 )
						dissolver:Fire( "Kill", name, 0.10 )
						end
					end
							end--]]
					
					cleanup.Add (self.Owner, "props", ragdoll);
					undo.Create ("ragdoll");
					undo.AddEntity (ragdoll);
					undo.SetPlayer (self.Owner);
					undo.Finish();
					
					if tgt:IsPlayer() then
						tgt:KillSilent()
						--ragdoll:SetColor( tgt:GetPlayerColor()  )
						tgt:AddDeaths(1)
						self.Owner:AddFrags(1)
						tgt:SpectateEntity(ragdoll)
						tgt:Spectate(OBS_MODE_CHASE)
					elseif tgt:IsNPC() then
						tgt:Fire("Kill","",0)
					end
					
					ragdoll:Spawn()
					--ragdoll:Fire("SetBodygroup","15",0)
					self.HP = ragdoll
					
					self.Weapon:SetNextSecondaryFire( CurTime() + 0.2 );
					if GetConVar("scgg_style"):GetInt() >= 1 then
					self.Weapon:SetNextPrimaryFire( CurTime() + 0.1 ); end
					self.Secondary.Automatic = false
					
					self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
					self.Owner:SetAnimation( PLAYER_ATTACK1 )
					
					for i = 1, ragdoll:GetPhysicsObjectCount() do
					local bone = ragdoll:GetPhysicsObjectNum(i)
					
						if bone and bone.IsValid and bone:IsValid() then
							local bonepos, boneang = tgt:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
							
							bone:SetPos(bonepos)
							bone:SetAngles(boneang)
						end
					end
					timer.Simple( 0.01, 
				function() 
						self:Pickup() 
					end )
				end
			end
		end
		
		if tgt:GetMoveType() == MOVETYPE_VPHYSICS then
			if (SERVER) then
				local Mass = tgt:GetPhysicsObject():GetMass()
				local Dist = (tgt:GetPos()-self.Owner:GetPos()):Length()
				local GetPullForce = {}
				if GetConVar("scgg_style"):GetInt() <= 0 then
				GetPullForce = self.HL2PullForce
				else
				GetPullForce = self.PullForce
				end
				local vel = GetPullForce/(Dist*0.002)
				local ragvel = self.HL2PullForceRagdoll/(Dist*0.001)
				
				if GetConVar("scgg_style"):GetInt() <= 0 then
				local getstyle = GetConVar("scgg_style"):GetInt()
				if ( ( getstyle == 0 and Mass >= (self.HL2MaxMass+1) ) or ( getstyle != 0 and Mass >= (self.MaxMass+1) ) ) and tgt:GetClass() != "prop_combine_ball" then
					return
				end end
				
				if tgt:IsRagdoll() or self:AllowedClass() and tgt:GetPhysicsObject():IsMoveable() and ( !constraint.HasConstraints( tgt ) ) then
					if Dist < self.MaxPickupRange then
						self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
						self.Owner:SetAnimation( PLAYER_ATTACK1 )
						self.HP = tgt
						self.Owner:SimulateGravGunPickup( self.HP )
						self.HPCollideG = tgt:GetCollisionGroup()
						tgt:SetCollisionGroup(COLLISION_GROUP_WEAPON)
						
						self:Pickup()
						self.Weapon:SetNextSecondaryFire( CurTime() + 0.2 );
						if GetConVar("scgg_style"):GetInt() >= 1 then
						self.Weapon:SetNextPrimaryFire( CurTime() + 0.1 ); end
						self.Secondary.Automatic = false
					--[[elseif GetConVar("scgg_style"):GetInt() <= 0 and tgt:IsRagdoll() then
						for d = 1, ent:GetPhysicsObjectCount() do
							local bone = ent:GetPhysicsObjectNum(d)
						
							if bone and bone.IsValid and bone:IsValid() then
							tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*-ragvel )
							bone:ApplyForceCenter(self.Owner:GetAimVector()*-ragvel )
							print("bruhto")
							end
						end--]]
					else
						tgt:GetPhysicsObject():ApplyForceCenter(self.Owner:GetAimVector()*-vel )
					end
				end
			end
		else
			
		end
	end
	
function SWEP:Pickup()
		self.Weapon:EmitSound("Weapon_MegaPhysCannon.Pickup")
		self.Owner:EmitSound(HoldSound)
		self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		
		PropLockTime = CurTime()+1
		
		timer.Simple( 0.4,
	function()
			self.Weapon:SendWeaponAnim(ACT_VM_RELOAD)
		end )
		
		local trace = self.Owner:GetEyeTrace()
		
		self.HP:Fire("DisablePhyscannonPickup","",0)
		
		if self.HP:GetClass() == "prop_combine_ball" then
		self.TP = ents.Create("prop_dynamic")
		else
		self.TP = ents.Create("prop_physics")
		end
		self.TP:SetPos(self.HP:GetPhysicsObject():GetMassCenter())
		if !IsValid(self.HP) then self.HP = nil return end
		if IsValid(self.HP:GetPhysicsObject()) then
		self.TP:SetPos(self.HP:GetPhysicsObject():GetPos())
		self.TP:SetModel("models/props_junk/PopCan01a.mdl")
		self.TP:Spawn()
		self.TP:SetCollisionGroup(COLLISION_GROUP_WORLD)
		self.TP:SetColor(Color(255,255,255,1))
		self.TP:SetRenderMode(RENDERMODE_TRANSCOLOR)
		self.TP:PointAtEntity(self.Owner)
		if self.TP:GetClass() == "prop_physics" then
		self.TP:GetPhysicsObject():SetMass(50000)
		self.TP:GetPhysicsObject():EnableMotion(false)
		end
		
		local bone = math.Clamp(trace.PhysicsBone,0,1)
		--[[if self.HP:IsRagdoll() then
		--self.Const = constraint.Ballsocket(self.TP, self.HP, 0, bone,trace.HitNormal, 0, 0,1)
		self.Const = constraint.AdvBallsocket(self.TP, self.HP, 0, bone,trace.HitNormal, self.TP:GetPos(), 
		0, -- Break Limit
		0, -- Torque Break Limit
		0, -- X Min
		0, -- Y Min
		0, -- Z Min
		500, -- X Max
		500, -- Y Max
		500, -- Z Max
		10, -- X Friction
		10, -- Y Friction
		10, -- Z Friction
		0, -- Don't Limit Rotation Only
		1) -- No Collide
		else--]]
		self.Const = constraint.Weld(self.TP, self.HP, 0, bone,0,1)
		--end
		
		if self.HP:IsRagdoll() then
			self.HP:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		end
		
		if self.HP:GetClass() == "prop_combine_ball" then
			self.HP:SetOwner(self.Owner)
			self.HP:GetPhysicsObject():AddGameFlag( FVPHYSICS_WAS_THROWN )
		end
		
		--self.Weapon:EmitSound(HoldSound)
	end
end
	
function SWEP:Drop()
		if !IsValid(self) then return end
		if !IsValid(self.HP) then return end
		self.HP:Fire("EnablePhyscannonPickup","",1)
		if self.HP:IsRagdoll() then
			self.HP:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		else
		self.HP:SetCollisionGroup( self.HPCollideG )
		end
		self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		
		if self.HP:IsRagdoll() then
			RagdollVisual(self.HP, 1)
					if GetConVar("scgg_zap"):GetInt() <= 1 then
			local effect  	= EffectData()
			if !IsValid(self.HP) then return end
			effect:SetOrigin(self.HP:GetPos())
			effect:SetStart(self.HP:GetPos())
			effect:SetMagnitude(5)
			effect:SetEntity(self.HP)
			util.Effect("teslaHitBoxes",effect)
			if GetConVar("scgg_zap_sound"):GetInt() >= 1 then
			self.HP:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			timer.Create( "zapper", 0.3, 16, function()
			util.Effect("teslaHitBoxes",effect)
			if !IsValid(self.HP) then self.HP = nil return end
			if GetConVar("scgg_zap_sound"):GetInt() >= 1 then
			self.HP:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			end) end
			if GetConVar("scgg_zap"):GetInt() >= 1 then
			self.HP:Fire("StartRagdollBoogie","",0) end
		end
		
		self.Secondary.Automatic = true
		self.Weapon:EmitSound("Weapon_MegaPhysCannon.Drop")
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.5 );
		if self.HP:GetClass() == "prop_combine_ball" then
		self.Owner:SimulateGravGunPickup( self.HP )
		timer.Simple( 0.01, function() 
		if IsValid(self.HP) then
		self.Owner:SimulateGravGunDrop( self.HP ) 
		end
		end)
		else
		self.Owner:SimulateGravGunDrop( self.HP )
		end
		
		timer.Simple( 0.4,
		function()
			if !IsValid( self.Weapon ) then return end
			if self.Owner:GetActiveWeapon():GetClass() == "weapon_superphyscannon" then
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
			end
		end )
		
		self:CoreEffect()
		self:RemoveGlow()
		
		self:TPrem()
		if self.HP then
			--self.HP = nil
		end
		if self.HPCollideG then
			self.HPCollideG = COLLISION_GROUP_NONE
		end
		
		self.Weapon:StopSound(HoldSound)
		
	end
	
function SWEP:Visual()
		self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		self.Weapon:EmitSound( "Weapon_MegaPhysCannon.Launch" )
		if SERVER then
		if GetConVar("scgg_muzzle_flash"):GetInt() >= 1 then
		local Light = ents.Create("light_dynamic")
		Light:SetKeyValue("brightness", "5")
		Light:SetKeyValue("distance", "200")
		Light:SetLocalPos(self.Owner:GetShootPos())
		Light:SetLocalAngles(self:GetAngles())
		Light:Fire("Color", "255 255 255")
		Light:SetParent(self)
		Light:Spawn()
		Light:Activate()
		Light:Fire("TurnOn", "", 0)
		self:DeleteOnRemove(Light)
		timer.Simple(0.1,function() if self:IsValid() then Light:Remove() end end)
		end
		end
		if GetConVar("scgg_style"):GetInt() <= 0 then
		self.Owner:ViewPunch( Angle( -5, 2, 0 ) ) 
		else
		self.Owner:ViewPunch( Angle( -5, 2, 0 ) ) 
		end
		
		local trace = self.Owner:GetEyeTrace()
		
		local effectdata = EffectData()
		effectdata:SetOrigin( trace.HitPos )
		effectdata:SetStart( self.Owner:GetShootPos() )
		effectdata:SetAttachment( 1 )
		effectdata:SetEntity( self.Weapon )
		util.Effect( "PhyscannonTracer", effectdata )
		--local e = EffectData()
		--e:SetEntity(trace.Entity)
		--e:SetMagnitude(30)
		--e:SetScale(30)
		--e:SetRadius(30)
		--util.Effect("TeslaHitBoxes", e)
		--trace.Entity:EmitSound("Weapon_StunStick.Activate")
		
		if (SERVER) then
			if GetConVar("scgg_no_effects"):GetInt() >= 1 then return end
			if !self.Muzzle then
				self.Muzzle = ents.Create("PhyscannonMuzzle")
				self.Muzzle:SetPos( self.Owner:GetShootPos() )
				self.Muzzle:Spawn()
			end
			
			self.Muzzle:SetParent(self.Owner)
			self.Muzzle:SetOwner(self.Owner)
			
			timer.Simple( 0.12,
		function() 
				self:RemoveMuzzle()
			end )
		end
		
		local e = EffectData()
		e:SetMagnitude(30)
		e:SetScale(30)
		e:SetRadius(30)
		e:SetOrigin(trace.HitPos)
		e:SetNormal(trace.HitNormal)
		--util.Effect("PhyscannonImpact", e)
		util.Effect("ManhackSparks", e)
	end
	
--[[function SWEP:DoSparks()
	local trace = self.Owner:GetEyeTrace()
	local e = EffectData()
		e:SetMagnitude(30)
		e:SetScale(30)
		e:SetRadius(30)
		e:SetOrigin(trace.HitPos)
		e:SetNormal(trace.HitNormal)
		util.Effect("PhyscannonImpact", e)
		--util.Effect("ManhackSparks", e)
end--]]
	
function RagdollVisual(ent, val)
if !IsValid(ent) then return end
			if ent:IsValid() then
			
			val = val+1
			
			--local effect = EffectData()
			--effect:SetEntity(ent)
			--effect:SetMagnitude(30)
			--effect:SetScale(30)
			--effect:SetRadius(30)
			--util.Effect("TeslaHitBoxes", effect)
			if GetConVar("scgg_zap_sound"):GetInt() >= 1 then
			ent:EmitSound("Weapon_StunStick.Activate", 75, 100, 0.3)
			end
			
			if val <= 26 then
				timer.Simple((math.random(8,20)/100), RagdollVisual, ent, val)
			end
		end
	end

function SWEP:Deploy()
		--self.Weapon:SetNextPrimaryFire( CurTime() + 5 )
		self.Weapon:SetNextSecondaryFire( CurTime() + 5 )
		self:CoreEffect()
		--self:OpenClaws()
		if GetConVar("scgg_style"):GetInt() <= 0 then
		self.Weapon:SendWeaponAnim( ACT_VM_DRAW )
		if ( GetConVar("scgg_equip_sound"):GetInt() >= 1 ) and not ( GetConVar("scgg_enabled"):GetInt() <= 0 ) then
		self.Weapon:EmitSound("weapons/physcannon/physcannon_charge.wav") 
		end
		end
		local vm = self.Owner:GetViewModel()
		timer.Create( "deploy_idle" .. self:EntIndex(), vm:SequenceDuration(), 1, function()
		if !IsValid( self.Weapon ) then return end
		if self.Owner:GetActiveWeapon():GetClass() == "weapon_superphyscannon" then
			self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
		end
		--self.Weapon:SetNextPrimaryFire( CurTime() + 0.01 )
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.01 )
		end)
	end

function SWEP:Holster()
timer.Destroy("deploy_idle")
timer.Destroy("attack_idle")
self.Weapon:StopSound(HoldSound)
self.Weapon:Drop()
self.HP = nil
		if self.TP then
			return false
		else
			self:RemoveFX()
			self:TPrem()
			if self.HP then
				self.HP = nil
			end
			return true
		end
end
	
function SWEP:OnDrop()
	if GetConVar("scgg_no_effects"):GetInt() >= 1 then return end
		self:RemoveFX()
		self:TPrem()
		timer.Simple( 0.02, function()
		self:Remove()
		end )
		local grav_entity = ents.Create("MegaPhyscannon")
			grav_entity:SetPos( self:GetPos() )
			grav_entity:SetAngles( self:GetAngles() )
			grav_entity:Spawn()
			grav_entity:Activate()
			grav_entity:GetPhysicsObject():SetVelocity( self:GetPhysicsObject():GetVelocity() )
			grav_entity:GetPhysicsObject():SetInertia( self:GetPhysicsObject():GetInertia() )
			--grav_entity:GetPhysicsObject():SetVelocity( Vector( 0, 350, 0 ) )
			--grav_entity:GetPhysicsObject():ApplyForceCenter( Vector( 0, 0, -100 ) )
			--grav_entity:GetPhysicsObject():ApplyForceOffset( Vector( 0, 3500, 0 ) , self:GetPos() )
			grav_entity.Planted = false
		if self.HP then
			self.HP = nil
		end
	end
	
function SWEP:TPrem()
		if self.TP then
			if !IsValid(self.TP) then return end
			self.TP:Remove()
			self.TP = nil
		end
		
		if self.Const then
		if !IsValid(self.Const) then return end
			self.Const:Remove()
			self.Const = nil
		end
	end
	
function SWEP:RemoveMuzzle()
		if self.Muzzle then
			self.Muzzle:Remove()
			self.Muzzle = nil
		end
	end
	
function SWEP:RemoveFX()
		if self.Core then
			if !IsValid(self.Core) then return end
			self.CoreAllowRemove = true
			self.Core:Remove()
			self.Core = nil
		end
		if self.Glow then
			self.GlowAllowRemove = true
			self.Glow:Remove()
			self.Glow = nil
		end
	end
	
function SWEP:CoreEffect()
		if SERVER then
		if GetConVar("scgg_no_effects"):GetInt() >= 1 then return end
			if !IsValid(self.Core) then
				self.Core = ents.Create("PhyscannonCore")
				self.Core:SetPos( self.Owner:GetShootPos() )
				self.Core:Spawn()
				--self.Core:AddEFlags(EFL_KEEP_ON_RECREATE_ENTITIES)
			end
			self.CoreAllowRemove = false
			if !IsValid(self.Core) then return end
			self.Core:SetParent(self.Owner)
			self.Core:SetOwner(self.Owner)
		end
	end
	
function SWEP:GlowEffect()
		if SERVER then
		if GetConVar("scgg_no_effects"):GetInt() >= 1 then return end
			if !IsValid(self.Glow) then
				self.Glow = ents.Create("PhyscannonGlow")
				self.Weapon:SetNetworkedBool("Glow", true)
				self.Glow:SetPos( self.Owner:GetShootPos() )
				self.Glow:Spawn()
			end
			self.GlowAllowRemove = false
			self.Glow:SetParent(self.Owner)
			self.Glow:SetOwner(self.Owner)
		end
	end
	
function SWEP:RemoveCore()
		if CLIENT then return end
		if !self.Core then return end
		if !IsValid(self.Core) then return end
		self.CoreAllowRemove = true
		self.Core:Remove()
		self.Core = nil
	end
	
function SWEP:RemoveGlow()
		if CLIENT then return end
		if !self.Glow then return end
		if !IsValid(self.Glow) then return end
		self.GlowAllowRemove = true
		self.Weapon:SetNetworkedBool("Glow", false)
		self.Glow:Remove()
		self.Glow = nil
	end
	