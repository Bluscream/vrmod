include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")


numpad.Register("ToggleVRCamera", function(ply, ent)
	if g_VR[ply:SteamID()] then
		ply:ConCommand("vrcam_toggle")
	end
end)

--Entity spawn init
function ENT:Initialize()
	if CLIENT then return end
	
	self:SetModel( "models/maxofs2d/camera.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NOCLIP )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow(false)

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
end

function ENT:Think()
end

-- Set the camera's position to the entity
function ENT:Use(act, call)
	call:SetNWInt( "VRCameraENT", self:EntIndex() )
	call:SetNWVector( "VRCameraPos", self:GetPos() )
	call:SetNWVector( "VRCameraAng", self:GetAngles() )
	call:ChatPrint("Camera position has been updated.")
end


-- Keep the vr camera's postion once removed
function ENT:OnRemove()
	self:GetCreator():SetNWInt( "VRCameraENT", 0)
	self:GetCreator():SetNWVector( "VRCameraPos", self:GetPos())
	self:GetCreator():SetNWVector( "VRCameraAng", self:GetAngles())
end

function ENT:SpawnFunction(ply, tr, ClassName)
	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 10
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0

	local ent = ents.Create( ClassName )
	ent:SetCreator( ply )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()
	
	ply:SetNWInt( "VRCameraENT", ent:EntIndex() )
	ply:SetNWVector( "VRCameraPos", ent:GetPos() )
	ply:SetNWVector( "VRCameraAng", ent:GetAngles() )

	if IsValid(ply) then
		ply:AddCleanup("VR Cameras", ent)
	end

	return ent
end

numpad.OnDown(ply, key, "ToggleVRCamera")

hook.Add("PlayerButtonDown", "vrcameramenu_key", function(ply, key)
	if (key == ply:GetInfoNum("vrcam_key", 17) and g_VR[ply:SteamID()]) then
		ply:ConCommand("vrcam_toggle")
		--print("camera toggled")
	end
end)