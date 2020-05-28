AddCSLuaFile("shared.lua")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
 
ENT.PrintName		= "VR Camera"
ENT.Spawnable = true
ENT.Category = "VR"

-- VGUI stuff
overlay = {}

local cameratoggle = true
	function overlay:Init()
	self:SetSize( ScrW(), ScrH() )
	self:Center()
	self:MouseCapture(true)
end

function VRCameraMenuInit()
	if overlay.CameraActive == true then
		CloseVRCamera()
		overlay.CameraActive = false
		--print("hide camera")
	else
		overlay.CameraActive = true
		StartVRCameraGui()
		--print("show camera")
	end
end

function CloseVRCamera()
	if IsValid(camerascreen) then
		camerascreen:Close()
		hook.Remove("ShouldDrawLocalPlayer","vrcamera_shoulddrawlocalplayer")
		hook.Remove("VRUtilEventPreRender","vrcamera_prerender")
		hook.Remove("VRUtilEventPreRenderRight","vrcamera_prerenderright")
		hook.Remove("VRUtilEventPostRender", "vrcamera_vrpostrender")
	end
end

function ENT:Draw()
	if ( GetConVar("cl_drawcameras"):GetInt() == 0 ) then return end
	self:DrawModel()
end

function overlay:Paint( w, h )
	draw.RoundedBox( 0, 0, 0, w, h, Color(0,0,0,0) )
	overlay:RequestFocus()
end

local function VRCamHideWModels(val)
	if val == true and GetConVar("vrutil_useworldmodels"):GetString("vrutil_useworldmodels", 0) == 1 then return end
	local weps = LocalPlayer().GetWeapons and LocalPlayer():GetWeapons()
	if weps then
		for i=1, #weps do
			weps[i]:SetNoDraw(val)
		end
	end
end

function StartVRCameraGui()
	local wmOn = GetConVar("vrutil_useworldmodels"):GetString("vrutil_useworldmodels", 0)
	local pmHide = GetConVar("vrutil_hidecharacter"):GetString("vrutil_hidecharacter", 0)
	vgui.Register( "VRCameraOverlay", overlay, "Panel" )
	hook.Add("VRUtilEventPreRenderRight","vrcamera_prerenderright", function() VRCamHideWModels(wmOn) end)
	hook.Add("VRUtilEventPreRender","vrcamera_vrprerender", function()
		if wmOn == 1 then return end
		VRCamHideWModels(wmOn)
		hook.Remove("ShouldDrawLocalPlayer", "vrutil_hook_shoulddrawlocalplayer")
		hook.Add("ShouldDrawLocalPlayer","vrcamera_shoulddrawlocalplayer", function() return (g_VR.active) end)
		hook.Add("VRUtilEventPostRender", "vrcamera_vrpostrender", function() VRCamHideWModels(false) end)	
	end)
	camerascreen = vgui.Create( "DFrame", overlay )
	camerascreen:SetSize( ScrW(), ScrH() )
	camerascreen:SetScreenLock(true)
	camerascreen:SetDraggable(false)
	camerascreen:ShowCloseButton(false)
	camerascreen:Dock(FILL)
	camerascreen:SetTitle("")
	
	--[[function VRUtilClientExit()
		if overlay.CameraActive == false then
			CloseVRCamera()
			camerascreen:Close()
		end
	end]]

	--[[net.Receive("vrutil_net_exit",function(len)
		local steamid = net.ReadString()
		if game.SinglePlayer() then
			steamid = LocalPlayer():SteamID()
		end
		local ply = player.GetBySteamID(steamid)
		CloseVRCamera()
	end)]]

	function camerascreen:Paint( w, h )
		if !g_VR.active then CloseVRCamera() end
		local x, y = self:GetPos()
		local vrcam_fov = vrcamera_fov:GetInt("vrcam_fov", 100)
		local vrcam_device = GetConVar("vrcam_device"):GetString("vrcam_device", "None")
		-- A messy way of getting the camera's entity postion
		if (g_VR.tracking[vrcam_device] == nil) and ( ents.GetByIndex(LocalPlayer():GetNWInt("VRCameraENT")):IsValid() ) then
			render.RenderView( {
				origin = ents.GetByIndex(LocalPlayer():GetNWInt("VRCameraENT")):GetPos(),
				angles = ents.GetByIndex(LocalPlayer():GetNWInt("VRCameraENT")):GetAngles(),
				fov = vrcam_fov,
				znear = 5,
				x = x, y = y,
				w = w, h = h
			} )
		elseif (g_VR.tracking[vrcam_device] != nil) and (g_VR.tracking[vrcam_device].pos:DistToSqr(LocalPlayer():GetPos()) < 65536)  then
			render.RenderView( {
				origin = g_VR.tracking[vrcam_device].pos,
				angles = g_VR.tracking[vrcam_device].ang,
				fov = vrcamera_fov,
				znear = 5,
				x = x, y = y,
				w = w, h = h
			} )
		elseif LocalPlayer():GetNWVector("VRCameraPos") != Vector(0, 0, 0) then
			render.RenderView( {
				origin = LocalPlayer():GetNWVector("VRCameraPos"),
				angles = LocalPlayer():GetNWVector("VRCameraAng"),
				fov = vrcamera_fov,
				znear = 5,
				x = x, y = y,
				w = w, h = h
			} )
		else
			local blackmat = Material("black_outline")
			render.SetMaterial(blackmat)
			render.DrawScreenQuad()
			draw.DrawText( "No cameras found", "DermaLarge", ScrW() / 2, ScrH() / 2, Color( 255,255,255, 255 ), TEXT_ALIGN_CENTER )
		end
	end
end

-- Hooks
hook.Add("OnPlayerChat","vrcameramenu_open",function(ply, text)
if string.lower(text) == "!vrcam" then
	if g_VR.net[LocalPlayer():SteamID()] then
		VRCameraMenuInit()
		--print("camera menu toggled")
		end
	end
end)

hook.Add("VRUtilExit","vrcamera_exitvr",function()
	if overlay.CameraActive == true then
		CloseVRCamera()
	end
end)

hook.Add("ToggleVRCamera", "vrcamera_togglecam", function()
	if g_VR.net[LocalPlayer():SteamID()] then
		VRCameraMenuInit()
	end
end)