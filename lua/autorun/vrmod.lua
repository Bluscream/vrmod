g_VR = g_VR or {}

if game.SinglePlayer() then
	player_manager.AddValidModel("VR Hands","models/player/vr_hands.mdl")
end

if CLIENT then

	local cv_configVersion = CreateClientConVar("vrutil_configversion", "0", true, false)
	local cv_altHead = CreateClientConVar("vrutil_althead", "0", true, false)
	local cv_autoStart = CreateClientConVar("vrutil_autostart", "0", true, false)
	local cv_scale = CreateClientConVar("vrutil_scale", "38.7", true, false)
	local cv_heightMenu = CreateClientConVar("vrutil_heightmenu", "1", true, false)
	local cv_hideCharacter = CreateClientConVar("vrutil_hidecharacter", "0", true, false)
	local cv_desktopView = CreateClientConVar("vrutil_desktopview", "0", true, false)
	local cv_useWorldModels = CreateClientConVar("vrutil_useworldmodels", "0", true, false)
	local cv_laserPointer = CreateClientConVar("vrutil_laserpointer", "0", true, false)
	local cv_controllerOriented = CreateClientConVar("vrutil_controlleroriented", "0", true, false)
	local cv_smoothTurn = CreateClientConVar("vrutil_smoothturn", "0", true, false)
	local cv_smoothTurnRate = CreateClientConVar("vrutil_smoothturnrate", "180", true, false)
	local cv_znear = CreateClientConVar("vrutil_znear", "1", true, false)
	local cv_oldCharacterYaw = CreateClientConVar("vrutil_oldcharacteryaw", "0", true, false)
	
	--todo combine into single convar?
	local cv_controllerOffsetX = CreateClientConVar("vrutil_controlleroffset_x", "0", true, false)
	local cv_controllerOffsetY = CreateClientConVar("vrutil_controlleroffset_y", "0", true, false)
	local cv_controllerOffsetZ = CreateClientConVar("vrutil_controlleroffset_z", "0", true, false)
	local cv_controllerOffsetPitch = CreateClientConVar("vrutil_controlleroffset_pitch", "0", true, false)
	local cv_controllerOffsetYaw = CreateClientConVar("vrutil_controlleroffset_yaw", "0", true, false)
	local cv_controllerOffsetRoll = CreateClientConVar("vrutil_controlleroffset_roll", "0", true, false)

	g_VR.scale = cv_scale:GetFloat()
	g_VR.origin = Vector(0,0,0)
	g_VR.originAngle = Angle(0,0,0)
	g_VR.viewModel = nil --this will point to either the viewmodel, worldmodel or nil
	g_VR.viewModelMuzzle = nil
	g_VR.viewModelPos = Vector(0,0,0)
	g_VR.viewModelAng = Angle(0,0,0)
	g_VR.usingWorldModels = false
	g_VR.active = false
	g_VR.threePoints = false --just a quick way of checking if both controllers and hmd are tracking
	g_VR.tracking = {}
	g_VR.input = {}
	g_VR.previousInput = {}
	g_VR.errorText = ""
		
	concommand.Add( "vrmod_start", function( ply, cmd, args )
		VRUtilClientStart()
	end )
	
	concommand.Add( "vrmod_exit", function( ply, cmd, args )
		VRUtilClientExit()
	end )
	
	concommand.Add( "vrmod_update", function( ply, cmd, args )
		local updateScriptPath = util.RelativePathToFull("lua\\bin\\update_vrmod.bat")
		print("Update script path: "..(updateScriptPath == "lua\\bin\\update_vrmod.bat" and "not found" or updateScriptPath))
		print("You must exit gmod completely before running the script.")
	end )
	
	if cv_configVersion:GetInt() < 4 then
		cv_configVersion:SetInt(4)
		cv_controllerOffsetX:SetFloat(-15)
		cv_controllerOffsetY:SetFloat(-1)
		cv_controllerOffsetZ:SetFloat(5)
		cv_controllerOffsetPitch:SetFloat(50)
		cv_controllerOffsetYaw:SetFloat(0)
		cv_controllerOffsetRoll:SetFloat(0)
		cv_znear:SetFloat(1)
		cv_heightMenu:SetBool(true)
	end
	
	local moduleLoaded = false
	local moduleVersion = 0
	if file.Exists("lua/bin/gmcl_vrmod_win32.dll", "GAME") then
		moduleLoaded = pcall(function() require("vrmod") end)
		moduleVersion = moduleLoaded and VRMOD_GetVersion and VRMOD_GetVersion() or 0
	end
	
	local mcoreOriginalValue = GetConVar("gmod_mcore_test"):GetString()
	local viewModelFovOriginalValue = GetConVar("viewmodel_fov"):GetString()
	
	g_VR.rightControllerOffsetPos  = Vector(cv_controllerOffsetX:GetFloat(), cv_controllerOffsetY:GetFloat(), cv_controllerOffsetZ:GetFloat())
	g_VR.leftControllerOffsetPos  = g_VR.rightControllerOffsetPos * Vector(1,-1,1)

	g_VR.rightControllerOffsetAng = Angle(cv_controllerOffsetPitch:GetFloat(), cv_controllerOffsetYaw:GetFloat(), cv_controllerOffsetRoll:GetFloat())
	g_VR.leftControllerOffsetAng = g_VR.rightControllerOffsetAng
	
	hook.Add( "PopulateToolMenu", "vrutil_hook_populatetoolmenu", function()
		spawnmenu.AddToolMenuOption( "Utilities", "Virtual Reality", "vr_util", "VRMod", "", "", function( panel )
		
			panel:SetName("VRMod [Experimental] v95.1")
			
			local dlabel = vgui.Create( "DLabel", Panel )
			panel:AddItem(dlabel)
			dlabel:SetWrap(true)
			dlabel:SetAutoStretchVertical(true)
			dlabel:SetText( "Note: Most settings take effect upon re-entering VR." )
			dlabel:SetColor(Color(0,0,0))
		
			local dcheckbox1 = vgui.Create("DCheckBoxLabel")
			panel:AddItem(dcheckbox1)
			dcheckbox1:SetDark(true)
			dcheckbox1:SetText("Hide player model")
			panel:ControlHelp("Note: if you want floating hands, switch to the \"VR Hands\" player model instead")
			dcheckbox1:SetChecked(cv_hideCharacter:GetBool())
			function dcheckbox1:OnChange(val)
				cv_hideCharacter:SetBool(val)
			end
			
			local dcheckbox1 = vgui.Create("DCheckBoxLabel")
			panel:AddItem(dcheckbox1)
			dcheckbox1:SetDark(true)
			dcheckbox1:SetText("Use weapon world models")
			dcheckbox1:SetChecked(cv_useWorldModels:GetBool())
			function dcheckbox1:OnChange(val)
				cv_useWorldModels:SetBool(val)
			end
			
			local dcheckbox1 = vgui.Create("DCheckBoxLabel")
			panel:AddItem(dcheckbox1)
			dcheckbox1:SetDark(true)
			dcheckbox1:SetText("Add laser pointer to tools/weapons")
			dcheckbox1:SetChecked(cv_laserPointer:GetBool())
			function dcheckbox1:OnChange(val)
				cv_laserPointer:SetBool(val)
			end
			
			local dcheckbox1 = vgui.Create("DCheckBoxLabel")
			panel:AddItem(dcheckbox1)
			dcheckbox1:SetDark(true)
			dcheckbox1:SetText("Controller oriented locomotion")
			dcheckbox1:SetChecked(cv_controllerOriented:GetBool())
			function dcheckbox1:OnChange(val)
				cv_controllerOriented:SetBool(val)
			end
			
			local dcheckbox1 = vgui.Create("DCheckBoxLabel")
			panel:AddItem(dcheckbox1)
			dcheckbox1:SetDark(true)
			dcheckbox1:SetText("Smooth turning")
			dcheckbox1:SetChecked(cv_smoothTurn:GetBool())
			function dcheckbox1:OnChange(val)
				cv_smoothTurn:SetBool(val)
			end
			
			local dnumslider1 = vgui.Create("DNumSlider")
			panel:AddItem(dnumslider1)
			dnumslider1:SetMin(1)
			dnumslider1:SetMax(360)
			dnumslider1:SetDecimals(0)
			dnumslider1:SetValue(cv_smoothTurnRate:GetInt())
			dnumslider1:SetDark(true)
			dnumslider1:SetText("Smooth turn rate")
			function dnumslider1:OnValueChanged(val)
				cv_smoothTurnRate:SetInt(dnumslider1:GetValue())
			end
			
			local dcheckbox1 = vgui.Create("DCheckBoxLabel")
			panel:AddItem(dcheckbox1)
			dcheckbox1:SetDark(true)
			dcheckbox1:SetText("Show height adjustment menu")
			dcheckbox1:SetChecked(cv_heightMenu:GetBool())
			function dcheckbox1:OnChange(val)
				cv_heightMenu:SetBool(val)
				if val then
					VRUtilOpenHeightMenu()
				else
					VRUtilMenuClose("heightmenu")
				end
			end
			
			local dcheckbox1 = vgui.Create("DCheckBoxLabel")
			panel:AddItem(dcheckbox1)
			dcheckbox1:SetDark(true)
			dcheckbox1:SetText("Alternative head angle manipulation method")
			panel:ControlHelp("Less precise but compatible with more playermodels")
			dcheckbox1:SetChecked(cv_altHead:GetBool())
			function dcheckbox1:OnChange(val)
				cv_altHead:SetBool(val)
			end
			
			local dcheckbox1 = vgui.Create("DCheckBoxLabel")
			panel:AddItem(dcheckbox1)
			dcheckbox1:SetDark(true)
			dcheckbox1:SetText("Automatically start VR after map loads")
			dcheckbox1:SetChecked(cv_autoStart:GetBool())
			function dcheckbox1:OnChange(val)
				cv_autoStart:SetBool(val)
			end
			
			local frame = vgui.Create( "DPanel" )
			frame:SetSize( 300, 30 )
			frame.Paint = function() end			
			local dlabel = vgui.Create( "DLabel", frame )
			dlabel:SetSize(100,30)
			dlabel:SetPos(0,0)
			dlabel:SetText( "Desktop view:" )
			dlabel:SetColor(Color(0,0,0))
			local DComboBox = vgui.Create( "DComboBox",frame )
			DComboBox:SetPos( 80, 5 )
			DComboBox:SetSize( 150, 20 )
			DComboBox:AddChoice( "none" )
			DComboBox:AddChoice( "left eye" )
			DComboBox:AddChoice( "right eye" )
			DComboBox:ChooseOptionID(cv_desktopView:GetInt()+1)
			DComboBox.OnSelect = function( self, index, value )
				cv_desktopView:SetInt(index-1)
			end
			panel:AddItem(frame)
			
			local dbutton = vgui.Create("DButton")
			panel:AddItem(dbutton)
			dbutton:SetText("Edit custom controller input actions")
			dbutton.DoClick = function() 
				VRUtilOpenActionEditor()
			end
			
			--******************************************
			-- 		controller offsets
			--******************************************
			local dcollapsiblecategory1 = vgui.Create( "DCollapsibleCategory")
			panel:AddItem(dcollapsiblecategory1)
			dcollapsiblecategory1:SetExpanded( 0 )
			dcollapsiblecategory1:SetLabel( "Controller offsets" )
			
			local dpanellist1 = vgui.Create( "DPanelList" )
			dpanellist1:SetSpacing( 0 )
			dpanellist1:EnableHorizontal( false )
			dpanellist1:EnableVerticalScrollbar( true )
			dcollapsiblecategory1:SetContents( dpanellist1 )
			
			local names = {"x","y","z","pitch","yaw","roll"}
			for i = 1,#names do
				local cv = GetConVar("vrutil_controlleroffset_"..names[i])
				local dnumslider1 = vgui.Create("DNumSlider")
				dpanellist1:AddItem(dnumslider1)
				dnumslider1:SetMin(i < 4 and -30 or -180)
				dnumslider1:SetMax(i < 4 and 30 or 180)
				dnumslider1:SetDecimals(2)
				dnumslider1:SetValue(cv:GetFloat())
				dnumslider1:SetDark(true)
				dnumslider1:SetText(names[i])
				function dnumslider1:OnValueChanged(val)
					cv:SetFloat(dnumslider1:GetValue())
				end
			end
			
			local dbutton1 = vgui.Create("DButton")
			dpanellist1:AddItem(dbutton1)
			dbutton1:SetText("Apply offsets")
			dbutton1.DoClick = function() 
				g_VR.rightControllerOffsetPos  = Vector(cv_controllerOffsetX:GetFloat(), cv_controllerOffsetY:GetFloat(), cv_controllerOffsetZ:GetFloat())
				g_VR.leftControllerOffsetPos  = g_VR.rightControllerOffsetPos * Vector(1,-1,1)
				g_VR.rightControllerOffsetAng = Angle(cv_controllerOffsetPitch:GetFloat(), cv_controllerOffsetYaw:GetFloat(), cv_controllerOffsetRoll:GetFloat())
				g_VR.leftControllerOffsetAng = g_VR.rightControllerOffsetAng
			end
			
			--******************************************
			
			local dbutton1 = vgui.Create("DButton")
			panel:AddItem(dbutton1)
			dbutton1:SetText("Start VR")
			dbutton1.DoClick = function() 
				if not g_VR.active then
					VRUtilClientStart()
				else
					VRUtilClientExit()
				end
			end
			
			local dbutton2 = vgui.Create("DButton")
			panel:AddItem(dbutton2)
			dbutton2:SetText("Restart VR")
			dbutton2:SetVisible(false)
			dbutton2.DoClick = function() 
				VRUtilClientExit()
				timer.Simple(1,function()
					VRUtilClientStart()
				end)
			end
			
			local errorlabel = vgui.Create("DLabel")
			panel:AddItem(errorlabel)
			errorlabel:SetWrap(true)
			errorlabel:SetAutoStretchVertical(true)
			errorlabel:SetColor(Color(255,0,0))
			
			local dlabel1 = vgui.Create("DLabel")
			panel:AddItem(dlabel1)
			dlabel1:SetWrap(true)
			dlabel1:SetAutoStretchVertical(true)
			dlabel1:SetText( "Installed module version: "..moduleVersion )
			dlabel1:SetColor(Color(0,0,0))
			
			local dlabel1 = vgui.Create("DLabel")
			panel:AddItem(dlabel1)
			dlabel1:SetWrap(true)
			dlabel1:SetAutoStretchVertical(true)
			dlabel1:SetText( "Latest module version: 15" )
			dlabel1:SetColor(Color(0,0,0))
			
			local errorCheckTime = 0
			panel.Think = function() 
				if SysTime() > errorCheckTime+1 then
					errorCheckTime = SysTime()
					local errors = ""
					local warnings = ""
					if not moduleLoaded then
						errors = errors .. "Error: Module not installed. Read the workshop description for instructions.\n"
					elseif VRMOD_IsHMDPresent and not VRMOD_IsHMDPresent() then
						errors = errors .. "Error: VR headset not detected\n"
					elseif moduleVersion < 14 then
						errors = errors .. "Error: Module update required. Enter \"vrmod_update\" into the console for details\n"
					elseif moduleVersion < 15 then
						warnings = warnings .. "Module update available. Enter \"vrmod_update\" into the console for details\n"
					end
					dbutton1:SetEnabled(#errors == 0)
					errorlabel:SetText(errors .. warnings)
					--
					if not g_VR.active then
						dbutton1:SetText("Start VR")
						dbutton2:SetVisible(false)
					else
						dbutton1:SetText("Exit VR")
						dbutton2:SetVisible(true)
					end
				end
			end

		end )
	end )
	
	--set vr origin so that hmd will be at given pos
	function VRUtilSetOrigin(pos)
		g_VR.origin = pos + ( g_VR.origin - g_VR.tracking.hmd.pos )
	end
	
	--rotates origin while maintaining hmd pos
	function VRUtilSetOriginAngle(ang)
		local raw = WorldToLocal(g_VR.tracking.hmd.pos, Angle(0,0,0), g_VR.origin, g_VR.originAngle)
		g_VR.originAngle = ang
		local newPos = LocalToWorld(raw, Angle(0,0,0), g_VR.origin, g_VR.originAngle)
		g_VR.origin = g_VR.origin + ( g_VR.tracking.hmd.pos - newPos )
	end
	
	function VRUtilHandleTracking()
	
		local tracking = VRMOD_GetPoses()

		--convert to world positions and apply scale
		for k,v in pairs(tracking) do
			v.pos, v.ang = LocalToWorld(v.pos * g_VR.scale, v.ang, g_VR.origin, g_VR.originAngle)
			v.vel = LocalToWorld(v.vel, Angle(0,0,0), Vector(0,0,0), g_VR.originAngle)
			--v.angvel = LocalToWorld(Vector(v.angvel.pitch, v.angvel.yaw, v.angvel.roll), Angle(0,0,0), Vector(0,0,0), g_VR.originAngle)
			if k == "pose_righthand" then
				v.pos, v.ang = LocalToWorld(g_VR.rightControllerOffsetPos * 0.01 * g_VR.scale, g_VR.rightControllerOffsetAng, v.pos, v.ang)
			elseif k == "pose_lefthand" then
				v.pos, v.ang = LocalToWorld(g_VR.leftControllerOffsetPos * 0.01 * g_VR.scale, g_VR.leftControllerOffsetAng, v.pos, v.ang)
			end
			g_VR.tracking[k] = v
		end
		
		g_VR.threePoints = g_VR.tracking.hmd and g_VR.tracking.pose_lefthand and g_VR.tracking.pose_righthand
		
		hook.Call("VRUtilEventTracking")
	end
	
	function VRUtilHandleInput()
		g_VR.input = VRMOD_GetActions()
		if g_VR.input.vector2_walkdirection.x == 0 and g_VR.input.vector2_walkdirection.y == 0 then
			g_VR.input.boolean_walk = false
		end
		local changes = false
		for k,v in pairs(g_VR.input) do
			if isbool(v) and v ~= g_VR.previousInput[k] then
				hook.Call("VRUtilEventInput",nil,k,v)
			end
		end
		g_VR.previousInput = g_VR.input
	end
	
	function VRUtilClientStart()
		RunConsoleCommand("gmod_mcore_test", "0")
		
		if moduleVersion >= 12 then
			VRMOD_Shutdown() --in case we're retrying after an error and shutdown wasn't called
		end
		
		if VRMOD_Init() == false then
			print("vr init failed")
			return
		end
		
		local vrViewParams = VRMOD_GetViewParameters()
		
		rtWidth, rtHeight = vrViewParams.recommendedWidth*2, vrViewParams.recommendedHeight

		
		VRMOD_ShareTextureBegin()
		g_VR.rt = GetRenderTarget( "vrmod_rt".. tostring(SysTime()), rtWidth, rtHeight)
		VRMOD_ShareTextureFinish()
		
		
		--set up active bindings
		VRMOD_SetActionManifest("vrmod/vrmod_action_manifest.txt")
		VRMOD_SetActiveActionSets("/actions/base", "/actions/main")
		
		VRUtilLoadCustomActions()
		
		--start transmit loop and send join msg to server
		VRUtilNetworkInit() 
		
		VRUtilLocomotionInit()
		
		--set initial origin
		g_VR.origin = LocalPlayer():GetPos()
		
		--dont call the input changed hook on the first run
		g_VR.input = VRMOD_GetActions()
		g_VR.previousInput = g_VR.input
		
		g_VR.active = true
		
		hook.Run( "VRUtilStart", LocalPlayer() )
		
		--3D audio fix
		hook.Add("CalcView","vrutil_hook_calcview",function(ply, pos, ang, fv)
			if g_VR.threePoints then
				return {origin = g_VR.tracking.hmd.pos, angles = g_VR.tracking.hmd.ang, fov = fv} 
			end
		end)
		
		--******************************************
		--			rendering
		--******************************************
		
		
		local hfovLeft, hfovRight, aspectLeft, aspectRight = vrViewParams.horizontalFOVLeft, vrViewParams.horizontalFOVRight, vrViewParams.aspectRatioLeft, vrViewParams.aspectRatioRight

		g_VR.view = {
				x = 0, y = 0,
				w = rtWidth/2, h = rtHeight,
				--aspectratio = aspect,
				--fov = hfov,
				drawmonitors = true,
				drawviewmodel = false,
				znear = cv_znear:GetFloat()
			}
			

		local	ipd, eyez = vrViewParams.eyeToHeadTransformPosRight.x*2, vrViewParams.eyeToHeadTransformPosRight.z
		

		
		local desktopView = cv_desktopView:GetInt()
		local cropVerticalMargin = (1 - (ScrH()/ScrW() * (rtWidth/2) / rtHeight)) / 2
		local cropHorizontalOffset = (desktopView==2) and 0.5 or 0
		local mat_rt = CreateMaterial("vrmod_mat_rt"..tostring(SysTime()), "UnlitGeneric",{ ["$basetexture"] = g_VR.rt:GetName() })
			
		local localply = LocalPlayer()
		local currentViewEnt = localply
		local pos1, ang1
			
		hook.Add("RenderScene","vrutil_hook_renderscene",function()
			
			VRMOD_SubmitSharedTexture()
			VRMOD_UpdatePosesAndActions()

			VRUtilHandleTracking()
			VRUtilHandleInput()
			
			if not g_VR.threePoints or not system.HasFocus() or #g_VR.errorText > 0 then
				render.Clear(0,0,0,255,true,true)
				cam.Start2D()
				local text = not system.HasFocus() and "Please focus the game window" or not g_VR.tracking.hmd and "Waiting for HMD tracking..." or not g_VR.tracking.pose_righthand and "Waiting for right hand tracking..." or not g_VR.tracking.pose_lefthand and "Waiting for left hand tracking..." or g_VR.errorText
				draw.DrawText( text, "DermaLarge", ScrW() / 2, ScrH() / 2, Color( 47,149,241, 255 ), TEXT_ALIGN_CENTER )
				cam.End2D()
				return true
			end
			
			--update viewmodel position
			if g_VR.currentvmi then
				local pos, ang = LocalToWorld(g_VR.currentvmi.offsetPos,g_VR.currentvmi.offsetAng,g_VR.tracking.pose_righthand.pos,g_VR.tracking.pose_righthand.ang)
				g_VR.viewModelPos = pos
				g_VR.viewModelAng = ang
			end
			if IsValid(g_VR.viewModel) then
				if not g_VR.usingWorldModels then
					g_VR.viewModel:SetPos(g_VR.viewModelPos)
					g_VR.viewModel:SetAngles(g_VR.viewModelAng)
					g_VR.viewModel:SetupBones()
				end
				g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
			end
			
			--update local player net frame (information used for rendering the player)
			VRUtilNetUpdateLocalPly()
			
			--set view according to viewentity
			local viewEnt = localply:GetViewEntity()
			if viewEnt ~= localply then
				local rawPos, rawAng = WorldToLocal(g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang, g_VR.origin, g_VR.originAngle)
				if viewEnt ~= currentViewEnt then
					local pos,ang = LocalToWorld(rawPos,rawAng,viewEnt:GetPos(),viewEnt:GetAngles())
					pos1, ang1 = WorldToLocal(viewEnt:GetPos(),viewEnt:GetAngles(),pos,ang)
				end
				rawPos, rawAng = LocalToWorld(rawPos, rawAng, pos1, ang1)
				g_VR.view.origin, g_VR.view.angles = LocalToWorld(rawPos,rawAng,viewEnt:GetPos(),viewEnt:GetAngles())
			else
				g_VR.view.origin, g_VR.view.angles = g_VR.tracking.hmd.pos, g_VR.tracking.hmd.ang
			end
			currentViewEnt = viewEnt
			
			--
			g_VR.view.origin = g_VR.view.origin + g_VR.view.angles:Forward()*-(eyez*g_VR.scale)
			g_VR.eyePosLeft = g_VR.view.origin + g_VR.view.angles:Right()*-(ipd*0.5*g_VR.scale)
			g_VR.eyePosRight = g_VR.view.origin + g_VR.view.angles:Right()*(ipd*0.5*g_VR.scale)

			render.PushRenderTarget( g_VR.rt )

				-- left
				g_VR.view.origin = g_VR.eyePosLeft
				g_VR.view.x = 0
				g_VR.view.fov = hfovLeft
				g_VR.view.aspectratio = aspectLeft
				hook.Call("VRUtilEventPreRender")
				render.RenderView(g_VR.view)
				-- right
				
				g_VR.view.origin = g_VR.eyePosRight
				g_VR.view.x = rtWidth/2
				g_VR.view.fov = hfovRight
				g_VR.view.aspectratio = aspectRight
				hook.Call("VRUtilEventPreRenderRight")
				render.RenderView(g_VR.view)
				--
				if not LocalPlayer():Alive() then
					cam.Start2D()
					surface.SetDrawColor( 255, 0, 0, 128 )
					surface.DrawRect( 0, 0, rtWidth, rtHeight )
					cam.End2D()
				end
			

			render.PopRenderTarget( g_VR.rt )
			
			if desktopView > 0 then
				surface.SetDrawColor(255,255,255,255)
				surface.SetMaterial(mat_rt)
				render.CullMode(1)
				surface.DrawTexturedRectUV(-1, -1, 2, 2, cropHorizontalOffset, 1-cropVerticalMargin, 0.5+cropHorizontalOffset, cropVerticalMargin)
				render.CullMode(0)
			end
			
			hook.Call("VRUtilEventPostRender")
			
			--return true to override default scene rendering
			return true
		end)
		
		--******************************************
		
		g_VR.usingWorldModels = cv_useWorldModels:GetBool()
		
		if not g_VR.usingWorldModels then
			RunConsoleCommand("viewmodel_fov", "90")
	
			hook.Add("CalcViewModelView","vrutil_hook_calcviewmodelview",function(wep, vm, oldPos, oldAng, pos, ang)
				return g_VR.viewModelPos, g_VR.viewModelAng
			end)
	
			local blockViewModelDraw = true
			g_VR.allowPlayerDraw = false
			local hideplayer = cv_hideCharacter:GetBool()
			hook.Add("PostDrawTranslucentRenderables","vrutil_hook_drawplayerandviewmodel",function( bDrawingDepth, bDrawingSkybox )
				if bDrawingSkybox or not LocalPlayer():Alive() or not (EyePos()==g_VR.eyePosLeft or EyePos()==g_VR.eyePosRight) then return end
				--draw viewmodel
				if IsValid(g_VR.viewModel) then
					blockViewModelDraw = false
					g_VR.viewModel:DrawModel()
					blockViewModelDraw = true
				end
				--draw playermodel
				if not hideplayer then
					g_VR.allowPlayerDraw = true
					cam.Start3D() cam.End3D() --this invalidates ShouldDrawLocalPlayer cache
					local tmp = render.GetBlend()
					render.SetBlend(1) --without this the despawning bullet casing effect gets applied to the player???
					LocalPlayer():DrawModel()
					render.SetBlend(tmp)
					cam.Start3D() cam.End3D()
					g_VR.allowPlayerDraw = false
				end
				--draw menus
				VRUtilRenderMenuSystem()
			end)
	
			hook.Add("PreDrawPlayerHands","vrutil_hook_predrawplayerhands",function()
				return true
			end)
	
			hook.Add("PreDrawViewModel","vrutil_hook_predrawviewmodel",function(vm, ply, wep)
				return blockViewModelDraw
			end)
			
			hook.Add("ShouldDrawLocalPlayer","vrutil_hook_shoulddrawlocalplayer",function(ply)
				return g_VR.allowPlayerDraw
			end)

		end
		
		-- add laser pointer
		if cv_laserPointer:GetBool() then
			local mat = Material("cable/redlaser")
			hook.Add("PostDrawTranslucentRenderables","vr_laserpointer",function( bDrawingDepth, bDrawingSkybox )
				if bDrawingSkybox then return end
				if g_VR.viewModelMuzzle and not g_VR.menuFocus then
					render.SetMaterial(mat)
					render.DrawBeam(g_VR.viewModelMuzzle.Pos, g_VR.viewModelMuzzle.Pos + g_VR.viewModelMuzzle.Ang:Forward()*10000, 1, 0, 1, Color(255,255,255,255))
				end
			end)
		end
		
	end
	
	function VRUtilClientExit()
		RunConsoleCommand("gmod_mcore_test", mcoreOriginalValue)
		RunConsoleCommand("viewmodel_fov", viewModelFovOriginalValue)
		
		VRUtilMenuClose()
		
		VRUtilNetworkCleanup()
		
		VRUtilLocomotionCleanup()
		
		if IsValid(g_VR.viewModel) and g_VR.viewModel:GetClass() == "class C_BaseFlex" then
			g_VR.viewModel:Remove()
		end
		g_VR.viewModel = nil
		g_VR.viewModelMuzzle = nil
		
		LocalPlayer():GetViewModel().RenderOverride = nil
		LocalPlayer():GetViewModel():RemoveEffects(EF_NODRAW)
		
		hook.Remove("RenderScene","vrutil_hook_renderscene")
		hook.Remove("PreDrawViewModel","vrutil_hook_predrawviewmodel")
		hook.Remove( "DrawPhysgunBeam", "vrutil_hook_drawphysgunbeam")
		hook.Remove( "PreDrawHalos", "vrutil_hook_predrawhalos")
		hook.Remove("EntityFireBullets","vrutil_hook_entityfirebullets")
		hook.Remove("Tick","vrutil_hook_tick")
		hook.Remove("PostDrawSkyBox","vrutil_hook_postdrawskybox")
		hook.Remove("CalcView","vrutil_hook_calcview")
		hook.Remove("PostDrawTranslucentRenderables","vr_laserpointer")
		hook.Remove("CalcViewModelView","vrutil_hook_calcviewmodelview")
		hook.Remove("PostDrawTranslucentRenderables","vrutil_hook_drawplayerandviewmodel")
		hook.Remove("PreDrawPlayerHands","vrutil_hook_predrawplayerhands")
		hook.Remove("PreDrawViewModel","vrutil_hook_predrawviewmodel")
		hook.Remove("ShouldDrawLocalPlayer","vrutil_hook_shoulddrawlocalplayer")
		
		g_VR.tracking = {}
		g_VR.threePoints = false
		

		

		VRMOD_Shutdown()
		
		g_VR.active = false
		
		hook.Run( "VRUtilExit", LocalPlayer() )
		
	end
	
	hook.Add("ShutDown","vrutil_hook_shutdown",function()
		if g_VR.net[LocalPlayer():SteamID()] then
			VRUtilClientExit()
		end
	end)
	
	
else
	--***************************************** SERVER SIDE ******************************************
	
	hook.Add("AllowPlayerPickup","vrutil_hook_allowplayerpickup",function(ply)
		if g_VR[ply:SteamID()] ~= nil then
			return false
		end
	end)
	
end


