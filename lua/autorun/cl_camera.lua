if CLIENT then


	-- Create convars & concommands
	concommand.Add( "vrcam_toggle", function( ply, cmd, args )
		if g_VR.net[ply:SteamID()] then
			hook.Run("ToggleVRCamera", ply)
		end
	end )

	concommand.Add( "vrcam_resetpos", function( ply, cmd, args )
		ply:SetNWInt("VRCameraENT", 0)
		ply:SetNWVector("VRCameraPos", Vector(0, 0, 0))
		ply:SetNWVector("VRCameraAng", Vector(0, 0, 0))
		ply:ChatPrint("Camera position has been reset.")
	end )

	local vrcamera_device = CreateClientConVar("vrcam_device", "None", true, true)
	vrcamera_fov = CreateClientConVar("vrcam_fov", "100", true, false)
	vrcamera_key = CreateClientConVar("vrcam_key", "17", true, true)
	vrcamera_preview = CreateClientConVar("vrcam_preview", "0", false, false)

		-- Add catergory to utilities panel
	hook.Add( "PopulateToolMenu", "VRCamera_populatetoolmenu", function()
		spawnmenu.AddToolMenuOption( "Utilities", "Virtual Reality", "vrcam", "VR Camera", "", "", function( panel )

			local camfovslider = vgui.Create("DNumSlider", Panel)
			panel:AddItem(camfovslider)
			camfovslider:SetText("Camera FOV")
			camfovslider:SetDark(true)
			camfovslider:SetMin(60)
			camfovslider:SetMax(100)
			camfovslider:SetDecimals(0)	
			camfovslider:SetConVar("vrcam_fov")		

			local numlabel = vgui.Create("DLabel", Panel)
			panel:AddItem(numlabel)
			numlabel:SetText("Camera key")
			numlabel:SetDark(true)
			numlabel:SetWrap(true)
			numlabel:SetAutoStretchVertical(true)
			local vrnum = vgui.Create("DBinder", Panel)
			panel:AddItem(vrnum)
			vrnum:SetValue(vrcamera_key:GetInt("vrcam_fov", 100))
			function vrnum:OnChange( num )
				vrcamera_key:SetInt( num )
			end

			local camtoggle = vgui.Create("DButton", Panel)
			panel:AddItem(camtoggle)
			camtoggle:SetText("Toggle Camera")
			camtoggle:SetConsoleCommand("vrcam_toggle")
			panel:ControlHelp("You must enter VR before enabling the camera.")

			local drawcams = vgui.Create("DCheckBoxLabel", Panel)
			panel:AddItem(drawcams)
			drawcams:SetText("Draw camera guides")
			drawcams:SetValue( tobool(GetConVar("cl_drawcameras"):GetInt()))
			drawcams:SetDark(true)
			drawcams:SetConVar("cl_drawcameras")

			local drawpreview = vgui.Create("DCheckBoxLabel", Panel)
			panel:AddItem(drawpreview)
			drawpreview:SetText("Enable camera preview")
			drawpreview:SetValue( tobool(vrcamera_preview:GetInt()))
			drawpreview:SetDark(true)
			drawpreview:SetConVar("vrcam_preview")
			function drawpreview:OnChange( ispreview )
				if ispreview and !g_VR.net[LocalPlayer():SteamID()] then 
					CameraPreview()
				elseif IsValid(preview) then
					preview:Close()
				end
			end
				

			local camreset = vgui.Create("DButton", Panel)
			panel:AddItem(camreset)
			camreset:SetText("Reset Position")
			camreset:SetConsoleCommand("vrcam_resetpos")

			local trackerlist = vgui.Create("DListView", Panel)
			panel:AddItem(trackerlist)
			panel:ControlHelp("For additional devices, add another pose to data/vrmod/vrmod_action_manifest.txt and bind a tracker to it in SteamVR.")
			trackerlist:SetSize(140, 120)
			trackerlist:SetMultiSelect(false)
			trackerlist:AddColumn("Attach to Device:")
			trackerlist:AddLine("None")

			trackerlist.OnRowSelected = function( panel, num, row )
				vrcamera_device:SetString(row:GetColumnText(1))
			end

			local actionman = util.JSONToTable(file.Read("vrmod/vrmod_action_manifest.txt", "DATA"))
			for i=1, #actionman.actions do
				if actionman.actions[i].type != "pose" then return end
				local friendlyName = string.Replace(actionman.actions[i].name, "/actions/base/in/", "")
				trackerlist:AddLine(friendlyName)
			end

		end)
	end)

	-- Display a preview of the camera
	function CameraPreview()
		if !IsValid(preview) then
			preview = vgui.Create("DFrame")
			preview:SetSize( ScrW() * 0.3, ScrH() * 0.3 )
			preview:SetPos( 40, 20 )
			preview:ParentToHUD(true)
			preview:SetScreenLock(true)
			preview:ShowCloseButton(false)
			preview:SetPaintBorderEnabled( true )
			preview:SetTitle("VR Camera Preview")

			function preview:Paint( w, h )
				local x, y = self:GetPos()
				local vrcam_fov = vrcamera_fov:GetInt("vrcam_fov", 100)
				if ( ents.GetByIndex(LocalPlayer():GetNWInt("VRCameraENT")):IsValid() ) then
					render.RenderView( {
						origin = ents.GetByIndex(LocalPlayer():GetNWInt("VRCameraENT")):GetPos(),
						angles = ents.GetByIndex(LocalPlayer():GetNWInt("VRCameraENT")):GetAngles(),
						fov = vrcam_fov,
						znear = 5,
						x = x, y = y,
						w = w, h = h
					} )
				else
					render.RenderView( {
						origin = LocalPlayer():GetNWVector("VRCameraPos"),
						angles = LocalPlayer():GetNWVector("VRCameraAng"),
						fov = vrcamera_fov,
						near = 5,
						x = x, y = y,
						w = w, h = h
					} )
				
				end
			end
		end
	end
end