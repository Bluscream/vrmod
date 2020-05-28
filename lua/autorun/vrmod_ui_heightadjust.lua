if SERVER then return end

function VRUtilOpenHeightMenu()
	if not g_VR.threePoints or VRUtilIsMenuOpen("heightmenu") then return end
	
	--create mirror
	
	rt_mirror = GetRenderTarget( "rt_vrmod_heightcalmirror", 2048, 2048)
	mat_mirror = CreateMaterial("mat_vrmod_heightcalmirror", "Core_DX90", {["$basetexture"] = "rt_vrmod_heightcalmirror", ["$model"] = "1"})
	
	local mirrorYaw = 0
	
	hook.Add( "PreDrawTranslucentRenderables", "vrmodheightmirror", function(depth, skybox) 
		if depth or skybox then return end
	
		local ad = math.AngleDifference(EyeAngles().yaw, mirrorYaw)
		if math.abs(ad) > 45 then
			mirrorYaw = mirrorYaw + (ad > 0 and 45 or -45)
		end
	
		local mirrorPos = Vector(g_VR.tracking.hmd.pos.x, g_VR.tracking.hmd.pos.y, g_VR.origin.z + 45) + Angle(0,mirrorYaw,0):Forward()*50
		local mirrorAng = Angle(0,mirrorYaw-90,90)
		
		g_VR.menus.heightmenu.pos = mirrorPos + Vector(0,0,30) + mirrorAng:Forward()*-15
		g_VR.menus.heightmenu.ang = mirrorAng
		
		local camPos = LocalToWorld( WorldToLocal( EyePos(), Angle(), mirrorPos, mirrorAng) * Vector(1,1,-1), Angle(), mirrorPos, mirrorAng)
		local camAng = EyeAngles()
		camAng = Angle(camAng.pitch, mirrorAng.yaw + (mirrorAng.yaw - camAng.yaw), 180-camAng.roll)
	
		cam.Start({x = 0, y = 0, w = 2048, h = 2048, type = "3D", fov = g_VR.view.fov, aspect = -g_VR.view.aspectratio, origin = camPos, angles = camAng})
			render.PushRenderTarget(rt_mirror)
				render.Clear(200,230,255,0,true,true)
				render.CullMode(1)
					local alloworig = g_VR.allowPlayerDraw
					g_VR.allowPlayerDraw = true
					cam.Start3D() cam.End3D()
					local og = EyePos
					EyePos = function() return Vector(0,0,0) end
					LocalPlayer():DrawModel()
					EyePos = og
					g_VR.allowPlayerDraw = alloworig
					cam.Start3D() cam.End3D()
				render.CullMode(0)
			render.PopRenderTarget()
		cam.End3D()
	
		render.SetMaterial(mat_mirror)
		render.DrawQuadEasy(mirrorPos,mirrorAng:Up(),30,60,Color(255,255,255,255),0)

	end )

	--create controls
	
	VRUtilMenuOpen("heightmenu", 300, 512, nil, 0, Vector(), Angle(), 0.1, true, function()
		hook.Remove("PreDrawTranslucentRenderables", "vrmodheightmirror")
		hook.Remove("VRUtilEventInput","vrmodheightmenuinput")
	end)
	
	VRUtilMenuRenderStart("heightmenu")
		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect(250,0,50,50)
		surface.DrawRect(250,200,50,50)
		surface.DrawRect(250,255,50,50)
		surface.DrawRect(250,310,50,50)
		draw.SimpleText( "X", "Trebuchet24", 275, 25, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "+", "Trebuchet24", 275, 225, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Auto", "Trebuchet24", 275, 280, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "-", "Trebuchet24", 275, 335, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	VRUtilMenuRenderEnd()
	
	hook.Add("VRUtilEventInput","vrmodheightmenuinput",function(action, pressed)
		if g_VR.menuFocus == "heightmenu" and action == "boolean_primaryfire" and pressed and g_VR.menuCursorX > 250 then
			if g_VR.menuCursorY < 50 then
				VRUtilMenuClose("heightmenu")
			elseif g_VR.menuCursorY > 200 and g_VR.menuCursorY < 250 then
				g_VR.scale = g_VR.scale + 0.5
			elseif g_VR.menuCursorY > 255 and g_VR.menuCursorY < 305 then
				g_VR.scale = g_VR.characterInfo[LocalPlayer():SteamID()].characterEyeHeight / ((g_VR.tracking.hmd.pos.z-g_VR.origin.z)/g_VR.scale)
			elseif g_VR.menuCursorY > 310 and g_VR.menuCursorY < 360 then
				g_VR.scale = g_VR.scale - 0.5
			end
			GetConVar("vrutil_scale"):SetFloat(g_VR.scale)
		end
	end)

end

hook.Add("VRUtilStart","vrmod_OpenHeightMenuOnStartup",function(ply)
	if ply == LocalPlayer() and GetConVar("vrutil_heightmenu"):GetBool() then
		timer.Create("vrmod_HeightMenuStartupWait",1,0,function()
			if g_VR.threePoints then
				timer.Remove("vrmod_HeightMenuStartupWait")
				VRUtilOpenHeightMenu()
			end
		end)
	end
end)
