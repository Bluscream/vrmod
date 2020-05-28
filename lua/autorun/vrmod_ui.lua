if CLIENT then
	g_VR = g_VR or {}
	g_VR.menuFocus = false
	g_VR.menuCursorX = 0
	g_VR.menuCursorY = 0
	
	local rt_beam = GetRenderTarget("vrmod_rt_beam",64,64,false)
	local mat_beam = CreateMaterial("vrmod_mat_beam", "UnlitGeneric",{ ["$basetexture"] = rt_beam:GetName() })
	render.PushRenderTarget(rt_beam)
	render.Clear(0,0,255,255)
	render.PopRenderTarget()
	
	g_VR.menus = {}
	local menus = g_VR.menus
	local menusExist = false
	
	function VRUtilMenuRenderPanel(uid)
		timer.Simple(0.1,function()
			if menus[uid] == nil or menus[uid].panel == nil or not menus[uid].panel:IsValid() then return end
			render.PushRenderTarget(menus[uid].rt)
			cam.Start2D()
			render.ClearDepth()
			render.Clear(0,0,0,0)
			menus[uid].panel:PaintManual()
			cam.End2D()
			render.PopRenderTarget()
		end)
	end
	
	function VRUtilMenuRenderStart(uid)
		render.PushRenderTarget(menus[uid].rt)
		cam.Start2D()
		render.ClearDepth()
		render.Clear(0,0,0,0)
	end
	
	function VRUtilMenuRenderEnd()
		cam.End2D()
		render.PopRenderTarget()
	end
	
	function VRUtilIsMenuOpen(uid)
		return menus[uid] ~= nil
	end
	
	function VRUtilRenderMenuSystem()
		if menusExist == false then return end
		render.DepthRange(0,0.001)
		g_VR.menuFocus = false
		for k,v in pairs(menus) do
			local pos, ang = v.pos, v.ang
			if v.attachment == 1 then
				pos, ang = LocalToWorld(pos, ang, g_VR.tracking.pose_lefthand.pos, g_VR.tracking.pose_lefthand.ang)
			elseif v.attachment == 2 then
				pos, ang = LocalToWorld(pos, ang, g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_righthand.ang)
			elseif v.attachment == 3 then
				pos, ang = LocalToWorld(pos, ang, g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang)
			elseif v.attachment == 4 then
				pos, ang = LocalToWorld(pos, ang, g_VR.origin, g_VR.originAngle)
			end
			cam.Start3D2D( pos, ang, v.scale )
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(v.mat)
				surface.DrawTexturedRect(0,0,v.width,v.height)
				--debug outline
				--surface.SetDrawColor(255,0,0,255)
				--surface.DrawOutlinedRect(0,0,v.width,v.height)
			cam.End3D2D()
			if v.cursorEnabled then
				local cursorX, cursorY = -1,-1
				local cursorWorldPos = Vector(0,0,0)
				local start = g_VR.tracking.pose_righthand.pos
				local dir = g_VR.tracking.pose_righthand.ang:Forward()
				local normal = ang:Up()
				local A = normal:Dot(dir)
				if A < 0 then
					local B = normal:Dot(pos-start)
					if B <  0 then
						cursorWorldPos = start+dir*(B/A)
						local tp, unused = WorldToLocal( cursorWorldPos, Angle(0,0,0), pos, ang)
						cursorX = tp.x*(1/v.scale)
						cursorY = -tp.y*(1/v.scale)
					end
				end
				if cursorX > 0 and cursorY > 0 and cursorX < v.width and cursorY < v.height then
					g_VR.menuFocus = k
					g_VR.menuCursorX = cursorX
					g_VR.menuCursorY = cursorY
					render.SetMaterial(mat_beam)
					render.DrawBeam(g_VR.tracking.pose_righthand.pos, cursorWorldPos, 0.1, 0, 0, Color(255,255,255,255))
					input.SetCursorPos(g_VR.menuCursorX,g_VR.menuCursorY)
					if v.panel and (not v.panel:IsMouseInputEnabled() or not v.panel:HasFocus()) then
						v.panel:MakePopup()
						v.panel:SetMouseInputEnabled(true)
					end
				elseif v.panel and v.panel:IsMouseInputEnabled() then
					v.panel:SetMouseInputEnabled(false)
				end
			end
		end
		render.DepthRange(0,1)
	end
	
	function VRUtilMenuOpen(uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc)
		if menus[uid] then
			return
		end
		
		menus[uid] = {
			panel = panel,
			closeFunc = closeFunc,
			attachment = attachment,
			pos = pos,
			ang = ang,
			scale = scale,
			cursorEnabled = cursorEnabled,
			rt = GetRenderTarget("vrmod_rt_ui_"..uid, width, height, false),
			width = width,
			height = height,
		}
		
		local mat = Material("!vrmod_mat_ui_"..uid)
		menus[uid].mat = not mat:IsError() and mat or CreateMaterial("vrmod_mat_ui_"..uid, "UnlitGeneric",{ ["$basetexture"] = menus[uid].rt:GetName(), ["$translucent"] = 1 })
		
		if panel then
			panel:SetPaintedManually( true )
			VRUtilMenuRenderPanel(uid)
		end
		
		render.PushRenderTarget(menus[uid].rt)
		render.Clear(0,0,0,0)
		render.PopRenderTarget()

		if GetConVar("vrutil_useworldmodels"):GetBool() then
			hook.Add( "PostDrawTranslucentRenderables", "vrutil_hook_drawmenus", function( bDrawingDepth, bDrawingSkybox )
				if bDrawingSkybox then return end
				VRUtilRenderMenuSystem()
			end)
		end
		
		menusExist = true
		
	end
	
	function VRUtilMenuClose(uid)
		for k,v in pairs(menus) do
			if k == uid or not uid then
				if v.panel then
					v.panel:SetPaintedManually(false)
				end
				if v.closeFunc then
					v.closeFunc()
				end
				menus[k] = nil
			end
		end
		if table.Count(menus) == 0 then
			hook.Remove( "PostDrawTranslucentRenderables", "vrutil_hook_drawmenus")
			g_VR.menuFocus = false
			menusExist = false
		end
	end
	
	hook.Add("VRUtilEventInput","vrutil_hook_ui_input",function()
		if g_VR.menuFocus then
			if g_VR.input.boolean_primaryfire ~= g_VR.previousInput.boolean_primaryfire then
				if g_VR.input.boolean_primaryfire then
					gui.InternalMousePressed(MOUSE_LEFT)
				else 
					gui.InternalMouseReleased(MOUSE_LEFT)
				end
				VRUtilMenuRenderPanel(g_VR.menuFocus)
			end
		end
	end)

	
end