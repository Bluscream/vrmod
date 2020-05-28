g_VR = g_VR or {}
vrmod = vrmod or {}

if CLIENT then

	g_VR.net = g_VR.net or {}
	
	function vrmod.IsPlayerInVR( ply )
		return g_VR.net[ply and ply:SteamID() or LocalPlayer():SteamID()] ~= nil
	end
	
	function vrmod.GetHMDPos( ply )
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		return t and t.lerpedFrame and t.lerpedFrame.hmdPos or Vector()
	end
	
	function vrmod.GetHMDAng( ply )
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		return t and t.lerpedFrame and t.lerpedFrame.hmdAng or Angle()
	end
	
	function vrmod.GetLeftHandPos( ply )
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		return t and t.lerpedFrame and t.lerpedFrame.lefthandPos or Vector()
	end
	
	function vrmod.GetLeftHandAng( ply )
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		return t and t.lerpedFrame and t.lerpedFrame.lefthandAng or Angle()
	end
	
	function vrmod.GetRightHandPos( ply )
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		return t and t.lerpedFrame and t.lerpedFrame.righthandPos or Vector()
	end
	
	function vrmod.GetRightHandAng( ply )
		local t = ply and g_VR.net[ply:SteamID()] or g_VR.net[LocalPlayer():SteamID()]
		return t and t.lerpedFrame and t.lerpedFrame.righthandAng or Angle()
	end
	
	function vrmod.SetLeftHandPose( pos, ang )
		local t = g_VR.net[LocalPlayer():SteamID()]
		if t and t.lerpedFrame then
			t.lerpedFrame.lefthandPos, t.lerpedFrame.lefthandAng = pos, ang
		end
	end
	
	function vrmod.SetRightHandPose( pos, ang )
		local t = g_VR.net[LocalPlayer():SteamID()]
		if t and t.lerpedFrame then
			t.lerpedFrame.righthandPos, t.lerpedFrame.righthandAng = pos, ang
		end
	end
	
	function vrmod.GetLeftHandOpenFingerAngles()
		local r = {}
		for i = 1,15 do
			r[i] = g_VR.openHandAngles[i]
		end
		return r
	end
	
	function vrmod.GetLeftHandClosedFingerAngles()
		local r = {}
		for i = 1,15 do
			r[i] = g_VR.closedHandAngles[i]
		end
		return r
	end
	
	function vrmod.GetRightHandOpenFingerAngles()
		local r = {}
		for i = 1,15 do
			r[15+i] = g_VR.openHandAngles[i]
		end
		return r
	end
	
	function vrmod.GetRightHandClosedFingerAngles()
		local r = {}
		for i = 1,15 do
			r[15+i] = g_VR.closedHandAngles[i]
		end
		return r
	end
	
	function vrmod.SetLeftHandOpenFingerAngles( tbl )
		for i = 1,15 do
			g_VR.openHandAngles[i] = tbl[i]
		end
	end
	
	function vrmod.SetLeftHandClosedFingerAngles( tbl )
		for i = 1,15 do
			g_VR.closedHandAngles[i] = tbl[i]
		end
	end
	
	function vrmod.SetRightHandOpenFingerAngles( tbl )
		for i = 1,15 do
			g_VR.openHandAngles[15+i] = tbl[i]
		end
	end
	
	function vrmod.SetRightHandClosedFingerAngles( tbl )
		for i = 1,15 do
			g_VR.closedHandAngles[15+i] = tbl[i]
		end
	end
	
	function vrmod.GetInput( name )
		return g_VR.input[name]
	end
	
	vrmod.MenuCreate = function() end
	vrmod.MenuClose = function() end
	vrmod.MenuExists = function() end
	vrmod.MenuRenderStart = function() end
	vrmod.MenuRenderEnd = function() end
	
	vrmod.MenuCursorPos = function() 
		return g_VR.menuCursorX, g_VR.menuCursorY
	end
	
	vrmod.MenuFocused = function()
		return g_VR.menuFocus
	end

	timer.Simple(0,function()
		vrmod.MenuCreate = VRUtilMenuOpen
		vrmod.MenuClose = VRUtilMenuClose
		vrmod.MenuExists = VRUtilIsMenuOpen
		vrmod.MenuRenderStart = VRUtilMenuRenderStart
		vrmod.MenuRenderEnd = VRUtilMenuRenderEnd
	end)

else --server ********************************************************************************************************************************

	function vrmod.IsPlayerInVR( ply )
		return g_VR[ply:SteamID()] ~= nil
	end
	
	local function UpdateWorldPoses( ply, playerTable )
		if not playerTable.latestFrameWorld or playerTable.latestFrameWorld.tick ~= engine.TickCount() then
			playerTable.latestFrameWorld = playerTable.latestFrameWorld or {}
			local lf = playerTable.latestFrame
			local lfw = playerTable.latestFrameWorld
			lfw.tick = engine.TickCount()
			local refPos, refAng = ply:GetPos(), (ply:InVehicle() and ply:GetVehicle():GetAngles() or Angle())
			lfw.hmdPos, lfw.hmdAng = LocalToWorld( lf.hmdPos, lf.hmdAng, refPos, refAng )
			lfw.lefthandPos, lfw.lefthandAng = LocalToWorld( lf.lefthandPos, lf.lefthandAng, refPos, refAng )
			lfw.righthandPos, lfw.righthandAng = LocalToWorld( lf.righthandPos, lf.righthandAng, refPos, refAng )
		end
	end
	
	function vrmod.GetHMDPos( ply )
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector() end
		UpdateWorldPoses( ply, playerTable )
		return playerTable.latestFrameWorld.hmdPos
	end
	
	function vrmod.GetHMDAng( ply )
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Angle() end
		UpdateWorldPoses( ply, playerTable )
		return playerTable.latestFrameWorld.hmdAng
	end
	
	function vrmod.GetLeftHandPos( ply )
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector() end
		UpdateWorldPoses( ply, playerTable )
		return playerTable.latestFrameWorld.lefthandPos
	end
	
	function vrmod.GetLeftHandAng( ply )
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Angle() end
		UpdateWorldPoses( ply, playerTable )
		return playerTable.latestFrameWorld.lefthandAng
	end
	
	function vrmod.GetRightHandPos( ply )
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Vector() end
		UpdateWorldPoses( ply, playerTable )
		return playerTable.latestFrameWorld.righthandPos
	end
	
	function vrmod.GetRightHandAng( ply )
		local playerTable = g_VR[ply:SteamID()]
		if not (playerTable and playerTable.latestFrame) then return Angle() end
		UpdateWorldPoses( ply, playerTable )
		return playerTable.latestFrameWorld.righthandAng
	end

end



	
