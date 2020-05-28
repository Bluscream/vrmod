--***************************************** SHARED SIDE ******************************************
g_VR = g_VR or {}

local cv_tickrate = CreateConVar("vrutil_net_tickrate", game.SinglePlayer() and "30" or "10", FCVAR_REPLICATED)

local function netReadFrame()
	local frame = {
	
		ts = net.ReadFloat(),
		
		characterYaw = net.ReadUInt(7) * 2.85714,
		
		finger1 = net.ReadUInt(7) / 100,
		finger2 = net.ReadUInt(7) / 100,
		finger3 = net.ReadUInt(7) / 100,
		finger4 = net.ReadUInt(7) / 100,
		finger5 = net.ReadUInt(7) / 100,
		finger6 = net.ReadUInt(7) / 100,
		finger7 = net.ReadUInt(7) / 100,
		finger8 = net.ReadUInt(7) / 100,
		finger9 = net.ReadUInt(7) / 100,
		finger10 = net.ReadUInt(7) / 100,
		
		hmdPos = net.ReadVector(),
		lefthandPos =net.ReadVector(),
		righthandPos = net.ReadVector(),
		
		hmdAng = net.ReadAngle(),
		lefthandAng = net.ReadAngle(),
		righthandAng = net.ReadAngle(),
		
	}
	return frame
end

local function buildClientFrame(relative)

	local frame = {
		characterYaw = LocalPlayer():InVehicle() and LocalPlayer():GetAngles().yaw or g_VR.characterYaw,
		hmdPos = g_VR.tracking.hmd.pos,
		hmdAng = g_VR.tracking.hmd.ang,
		lefthandPos = g_VR.tracking.pose_lefthand.pos,
		lefthandAng = g_VR.tracking.pose_lefthand.ang,
		righthandPos = g_VR.tracking.pose_righthand.pos,
		righthandAng = g_VR.tracking.pose_righthand.ang,
		finger1 = g_VR.input.skeleton_lefthand.fingerCurls[1],
		finger2 = g_VR.input.skeleton_lefthand.fingerCurls[2],
		finger3 = g_VR.input.skeleton_lefthand.fingerCurls[3],
		finger4 = g_VR.input.skeleton_lefthand.fingerCurls[4],
		finger5 = g_VR.input.skeleton_lefthand.fingerCurls[5],
		finger6 = g_VR.input.skeleton_righthand.fingerCurls[1],
		finger7 = g_VR.input.skeleton_righthand.fingerCurls[2],
		finger8 = g_VR.input.skeleton_righthand.fingerCurls[3],
		finger9 = g_VR.input.skeleton_righthand.fingerCurls[4],
		finger10 = g_VR.input.skeleton_righthand.fingerCurls[5],
	}

	if IsValid(g_VR.viewModel) and g_VR.viewModel:GetClass() == "viewmodel" then
		g_VR.viewModel:SetPos(g_VR.viewModelPos)
		g_VR.viewModel:SetAngles(g_VR.viewModelAng)
		g_VR.viewModel:SetupBones()
		local b = g_VR.viewModel:LookupBone("ValveBiped.Bip01_R_Hand")
		if b then
			local mtx = g_VR.viewModel:GetBoneMatrix(b)
			frame.righthandPos = mtx:GetTranslation()
			frame.righthandAng = mtx:GetAngles() - Angle(0,0,180)
		end
	end

	if relative then
		local plyPos, plyAng = LocalPlayer():GetPos(), (LocalPlayer():InVehicle() and LocalPlayer():GetVehicle():GetAngles() or Angle())
		frame.hmdPos, frame.hmdAng = WorldToLocal(frame.hmdPos, frame.hmdAng, plyPos, plyAng)
		frame.lefthandPos, frame.lefthandAng = WorldToLocal(frame.lefthandPos, frame.lefthandAng, plyPos, plyAng)
		frame.righthandPos, frame.righthandAng = WorldToLocal(frame.righthandPos, frame.righthandAng, plyPos, plyAng)
	end
	
	return frame
end

local function netWriteFrame(frame)

	net.WriteFloat(SysTime())
	
	local tmp = frame.characterYaw + math.ceil(math.abs(frame.characterYaw)/360)*360 --normalize and convert characterYaw to 0-360
	tmp = tmp - math.floor(tmp/360)*360
	net.WriteUInt(frame.characterYaw*0.35,7) --crush from 0-360 to 0-127
	
	net.WriteUInt(frame.finger1*100,7)
	net.WriteUInt(frame.finger2*100,7)
	net.WriteUInt(frame.finger3*100,7)
	net.WriteUInt(frame.finger4*100,7)
	net.WriteUInt(frame.finger5*100,7)
	net.WriteUInt(frame.finger6*100,7)
	net.WriteUInt(frame.finger7*100,7)
	net.WriteUInt(frame.finger8*100,7)
	net.WriteUInt(frame.finger9*100,7)
	net.WriteUInt(frame.finger10*100,7)
	
	net.WriteVector(frame.hmdPos)
	net.WriteVector(frame.lefthandPos)
	net.WriteVector(frame.righthandPos)
	
	net.WriteAngle(frame.hmdAng)
	net.WriteAngle(frame.lefthandAng)
	net.WriteAngle(frame.righthandAng)

end

--***************************************** CLIENT SIDE ******************************************
if CLIENT then

	local cv_delay = CreateClientConVar("vrutil_net_delay", "0.3", true, false)
	local cv_delaymax = CreateClientConVar("vrutil_net_delaymax", "0.6", true, false)
	local cv_storedframes = CreateClientConVar("vrutil_net_storedframes", "10", true, false)
	
	g_VR.net = {
	--[[
	
		"steamid" = {
			
			frames = {
				1 = {
					ts = Float
					characterYaw = Float
					characterWalkX = Float
					characterWalkY = Float
					originHeight = Float
					hmdPos = Vector
					hmdAng = Angle
					lefthandPos = Vector
					lefthandAng = Angle
					righthandPos = Vector
					righthandAng = Angle
					finger1..10 = Float
				}
				2 = ...
				3 = ...
				...
			},
			latestFrameIndex = Int
			lerpedFrame = Table
			playbackTime = Float (playhead position in frame timestamp space)
			sysTime = Float (used to determine dt from previous lerp for advancing playhead position)
			buffering = Bool
			
			debugState = String
			debugNextFrame = Int
			debugPreviousFrame = Int
			debugFraction = Float
			
			characterAltHead = Bool
			dontHideBullets = Bool
		}
		
	]]
	}
	
	--[[ for testing net_debug
	g_VR.net["STEAM_0:1:47301228"] = {
		frames = {
			{ts=1},
			{ts=2},
			{ts=3},
			{ts=4},
			{ts=5},
			{ts=6},
			{ts=7},
			{ts=8},
			{ts=9.8},
			{ts=10},
		},
		
		playbackTime = 9,
		
		debugState = "buffering (reached end)",
		debugNextFrame = 2,
		debugPreviousFrame = 1,
		debugFraction = 0.5,
	}
	--]]

	local debugToggle = false
	concommand.Add( "vrutil_net_debug", function( ply, cmd, args )
		if debugToggle then
			hook.Remove("PostRender","vrutil_netdebug")
			debugToggle = false
			return
		end
		debugToggle = true
		hook.Add("PostRender","vrutil_netdebug",function()
			cam.Start2D()
			
			surface.SetFont( "ChatFont" )
			surface.SetTextColor( 255, 255, 255 )
			surface.SetTextPos( 128, 100) 
			surface.DrawText( "vrutil_net_debug" )
			
			local leftSide, rightSide = 140, 628
			local verticalSpacing = 100
			
			local iply = 0
			for k,v in pairs(g_VR.net) do
				if not v.playbackTime then
					continue
				end
			
				if not v.debugTps then
					v.debugTps, v.debugTps2, v.debugTpsT, v.debugTpsLF = 0, 0, 0, 0
				end
				
				if v.debugTpsLF ~= v.latestFrameIndex then
					v.debugTps2 = v.debugTps2 + 1
					v.debugTpsLF = v.latestFrameIndex
				end
				if SysTime()-v.debugTpsT > 1 then
					v.debugTps = v.debugTps2
					v.debugTpsT = SysTime()
					v.debugTps2 = 0
				end
			
				local mints, maxts = 9999999,0
				for i = 1,#v.frames do
					mints = v.frames[i].ts<mints and v.frames[i].ts or mints
					maxts = v.frames[i].ts>maxts and v.frames[i].ts or maxts
				end
			
				surface.SetDrawColor(0,0,0,200)
				surface.DrawRect(128, 128+iply*verticalSpacing, 512, 90)

				surface.SetFont( "ChatFont" )
				surface.SetTextColor( 255, 255, 255 )
				surface.SetTextPos( 140, 140 + iply*verticalSpacing ) 
				surface.DrawText( k.. " | "..v.debugState.. " | "..v.debugTps.." | "..math.floor((maxts-v.playbackTime)*1000) )
				
				surface.SetDrawColor(0,0,0,200)
				surface.DrawRect(leftSide, 160+iply*verticalSpacing, rightSide-leftSide, 20)
				local tileWidth = (rightSide-leftSide)/#v.frames
				for i = 1,#v.frames do
					tsfraction = (v.frames[i].ts - mints) / (maxts - mints)
					surface.SetDrawColor(255-tsfraction*255,0,tsfraction*255,255)
					surface.DrawRect(leftSide + tileWidth*(i-1), 160+iply*verticalSpacing, 2, 20)
					if i == v.debugPreviousFrame or i == v.debugNextFrame then
						surface.SetDrawColor(0,255,0)
						surface.DrawRect(leftSide + tileWidth*(i-1), 160+iply*verticalSpacing+(i==v.debugNextFrame and 18 or 0), 2, 2)
						if i == v.debugPreviousFrame then
							surface.DrawRect(leftSide + tileWidth*(i-1 + v.debugFraction), 159+iply*verticalSpacing, 2, 22)
						end
					end
				end
				
				surface.SetDrawColor(0,0,0,200)
				surface.DrawRect(leftSide, 185+iply*verticalSpacing, rightSide-leftSide, 20)
				for i = 1,#v.frames do
					tsfraction = (v.frames[i].ts - mints) / (maxts - mints)
					surface.SetDrawColor(255-tsfraction*255,0,tsfraction*255,255)
					
					surface.DrawRect(leftSide + tsfraction*(rightSide-leftSide-2), 185+iply*verticalSpacing, 2, 20)
				end
				surface.SetDrawColor(0,255,0,255)
				surface.DrawRect(leftSide + ((v.playbackTime - mints) / (maxts - mints))*(rightSide-leftSide-2), 185+iply*verticalSpacing, 2, 20)
				
				iply = iply + 1
			end
			
			cam.End2D()
		end)
	end )

	function VRUtilNetworkInit() --called by localplayer when they enter vr
	
		-- transmit loop
		timer.Create("vrutil_timer_network", 1/cv_tickrate:GetInt(), 0,function()
			if g_VR.threePoints then
				net.Start("vrutil_net_tick",true)
				--write viewHackPos
				net.WriteVector(g_VR.viewModelMuzzle and g_VR.viewModelMuzzle.Pos or Vector(0,0,0))
				--write frame
				netWriteFrame(buildClientFrame(true))
				net.SendToServer()
			end
		end)
		
		net.Start("vrutil_net_join")
		--send some stuff here that doesnt need to be in every frame
		net.WriteBool(GetConVar("vrutil_althead"):GetBool())
		net.WriteBool(GetConVar("vrutil_hidecharacter"):GetBool())
		net.SendToServer()
		
	end
	
	-- update all lerpedFrames, except for the local player (this function will be hooked to PreRender)
	local function LerpOtherVRPlayers()
		local lerpDelay = cv_delay:GetFloat()
		local lerpDelayMax = cv_delaymax:GetFloat()
		for k,v in pairs(g_VR.net) do
			if #v.frames < 2 then --this also discards the localplayer
				continue
			end
			if v.buffering then
				if v.playbackTime > v.frames[v.latestFrameIndex].ts - lerpDelay then
					continue
				else
					v.buffering = false
					v.sysTime = SysTime()
					v.debugState = "playing"
				end
			end
			--advance playhead
			v.playbackTime = v.playbackTime + (SysTime()-v.sysTime)
			v.sysTime = SysTime()
			--check if we reached the end
			if v.playbackTime > v.frames[v.latestFrameIndex].ts then 
				v.buffering = true
				v.debugState = "buffering (reached end)"
				continue
			end
			--check if we're too far behind
			if (v.frames[v.latestFrameIndex].ts - v.playbackTime) > lerpDelayMax then
				v.buffering = true
				v.playbackTime = v.frames[v.latestFrameIndex].ts
				v.debugState = "buffering (catching up)"
				continue
			end
			--lerp according to current playhead pos
			for i = 1,#v.frames do
				local nextFrame = i
				local previousFrame = i-1
				if previousFrame == 0 then
					previousFrame = #v.frames
				end
				if v.frames[nextFrame].ts >= v.playbackTime and v.frames[previousFrame].ts <= v.playbackTime  then
					local fraction = (v.playbackTime - v.frames[previousFrame].ts) / (v.frames[nextFrame].ts - v.frames[previousFrame].ts)
					--
					v.debugNextFrame = nextFrame
					v.debugPreviousFrame = previousFrame
					v.debugFraction = fraction
					--
					v.lerpedFrame = {}
					for k2,v2 in pairs(v.frames[previousFrame]) do
						if k2 == "characterYaw" then
							v.lerpedFrame[k2] = LerpAngle(fraction, Angle(0,v2,0), Angle(0,v.frames[nextFrame][k2],0)).yaw
						elseif isnumber(v2) then
							v.lerpedFrame[k2] = Lerp(fraction, v2, v.frames[nextFrame][k2])
						elseif isvector(v2) then
							v.lerpedFrame[k2] = LerpVector(fraction, v2, v.frames[nextFrame][k2])
						elseif isangle(v2) then
							v.lerpedFrame[k2] = LerpAngle(fraction, v2, v.frames[nextFrame][k2])
						end
					end
					--
					local ply = player.GetBySteamID(k)
					local plyPos, plyAng = ply:GetPos(), Angle()
					if ply:InVehicle() then
						plyAng = ply:GetVehicle():GetAngles()
						local _, forwardAng = LocalToWorld(Vector(),Angle(0,90,0),Vector(), plyAng)
						v.lerpedFrame.characterYaw = forwardAng.yaw
					end
					v.lerpedFrame.hmdPos, v.lerpedFrame.hmdAng = LocalToWorld(v.lerpedFrame.hmdPos,v.lerpedFrame.hmdAng,plyPos,plyAng)
					v.lerpedFrame.lefthandPos, v.lerpedFrame.lefthandAng = LocalToWorld(v.lerpedFrame.lefthandPos,v.lerpedFrame.lefthandAng,plyPos,plyAng)
					v.lerpedFrame.righthandPos, v.lerpedFrame.righthandAng = LocalToWorld(v.lerpedFrame.righthandPos,v.lerpedFrame.righthandAng,plyPos,plyAng)
					--
					break
				end
			end
			
		end
	end
	
	function VRUtilNetUpdateLocalPly()
		if g_VR.threePoints and g_VR.net[LocalPlayer():SteamID()] then
			g_VR.net[LocalPlayer():SteamID()].lerpedFrame = buildClientFrame()
		end
	end
	
	function VRUtilNetworkCleanup() --called by localplayer when they exit vr
		timer.Remove("vrutil_timer_network")
		net.Start("vrutil_net_exit")
		net.SendToServer()
	end
	
	net.Receive("vrutil_net_tick",function(len)
		local ply = net.ReadEntity()
		if not IsValid(ply) then return end
		local steamid = ply:SteamID()
		if not g_VR.net[steamid] then return end
		local frame = netReadFrame()
		if g_VR.net[steamid].latestFrameIndex == 0 then
			g_VR.net[steamid].playbackTime = frame.ts
		elseif frame.ts <= g_VR.net[steamid].frames[g_VR.net[steamid].latestFrameIndex].ts then
			return
		end
		local index = g_VR.net[steamid].latestFrameIndex + 1
		if index > cv_storedframes:GetInt() then
			index = 1
		end
		g_VR.net[steamid].frames[index] = frame
		g_VR.net[steamid].latestFrameIndex = index
	end)
	
	net.Receive("vrutil_net_join",function(len)
		local ply = net.ReadEntity()
		g_VR.net[ply:SteamID()] = {
			characterAltHead = net.ReadBool(),
			dontHideBullets = net.ReadBool(),
			frames = {},
			latestFrameIndex = 0,
			buffering = true,
			debugState = "buffering (initial)",
		}
		
		hook.Add("PreRender","vrutil_hook_netlerp",LerpOtherVRPlayers)
		
		VRUtilCharacterInit(ply)
	end)
	
	net.Receive("vrutil_net_exit",function(len)
		local steamid = net.ReadString()
		if game.SinglePlayer() then
			steamid = LocalPlayer():SteamID()
		end
		local ply = player.GetBySteamID(steamid)
		g_VR.net[steamid] = nil
		VRUtilCharacterCleanup(steamid)
		if table.Count(g_VR.net) == 0 then
			hook.Remove("PreRender","vrutil_hook_netlerp")
		end
		if ply == LocalPlayer() then
			hook.Remove("VRUtilEventPreRender","vrutil_hook_netlerplocalply")
		end
	end)
	
	net.Receive("vrutil_net_switchweapon",function(len)
		local class = net.ReadString()
		local vm = net.ReadString()
		
		if class == "" or vm == "" or vm == "models/weapons/c_arms.mdl" or g_VR.characterInfo[LocalPlayer():SteamID()] == nil then
			--print("switching to nil viewmodel")
			g_VR.viewModel = nil
			g_VR.openHandAngles = g_VR.defaultOpenHandAngles
			g_VR.closedHandAngles = g_VR.defaultClosedHandAngles
			g_VR.currentvmi = nil
			g_VR.viewModelMuzzle = nil
			return
		end
		
		-----------------------
		
		if GetConVar("vrutil_useworldmodels"):GetBool() then
			--print("world model change")
			g_VR.openHandAngles = {}
			g_VR.closedHandAngles = {}
			for i = 1,30 do
				g_VR.openHandAngles[i] = i <= 15 and g_VR.defaultOpenHandAngles[i] or g_VR.zeroHandAngles[i]
				g_VR.closedHandAngles[i] =  i <= 15 and g_VR.defaultClosedHandAngles[i] or g_VR.zeroHandAngles[i]
			end
			timer.Create("vrutil_waitforwm",0,0,function()
				if IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == class then
					timer.Remove("vrutil_waitforwm")
					g_VR.viewModel = LocalPlayer():GetActiveWeapon()
					--print("vm set")
				end
			end)
			return
		end
		
		-------------------------
		
		local vmi = g_VR.viewModelInfo[class] or {}
		local model = vmi.modelOverride ~= nil and vmi.modelOverride or vm
		
		--print("view model change, class: "..class.." vm: "..vm)
		
		g_VR.viewModel = LocalPlayer():GetViewModel()
		
		--create offsets if they don't exist
		if vmi.offsetPos == nil or vmi.offsetAng == nil then
			vmi.offsetPos, vmi.offsetAng = Vector(0,0,0), Angle(0,0,0)
			local cm = ClientsideModel(model)
			if IsValid(cm) then
				cm:SetupBones()
				local bone = cm:LookupBone("ValveBiped.Bip01_R_Hand")
				if bone then
					local boneMat = cm:GetBoneMatrix(bone)
					local bonePos, boneAng = boneMat:GetTranslation(), boneMat:GetAngles()
					boneAng:RotateAroundAxis(boneAng:Forward(),180)
					vmi.offsetPos, vmi.offsetAng = WorldToLocal(Vector(0,0,0),Angle(0,0,0),bonePos,boneAng)
					vmi.offsetPos = vmi.offsetPos + g_VR.viewModelInfo.autoOffsetAddPos
				end
				cm:Remove()
			end
		end
		
		--create hand poses if they don't exist
		if vmi.closedHandAngles == nil then
			local pmdl = ClientsideModel(LocalPlayer():GetModel())
			pmdl:SetupBones()
			
			local vmdl = ClientsideModel(model)
			vmdl:SetupBones()
			
			local pfingers = g_VR.characterInfo[LocalPlayer():SteamID()].bones.fingers
			
			local vfingers = {
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger0") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger01") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger02") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger1") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger11") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger12") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger2") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger21") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger22") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger3") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger31") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger32") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger4") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger41") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_L_Finger42") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger0") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger01") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger02") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger1") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger11") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger12") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger2") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger21") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger22") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger3") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger31") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger32") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger4") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger41") or -1,
				vmdl:LookupBone("ValveBiped.Bip01_R_Finger42") or -1,
			}
			
			local ok = true
			for i = 1,#vfingers do
				if vfingers[i] == -1 then
					ok = false
					break
				end
			end
			
			if ok then
				--print("ok")
				pmoffsets = {} --player model finger bone angles relative to parent bone
				for i = 1,30 do
					if pmdl:GetBoneMatrix(pfingers[i]) then
						_, pmoffsets[i] = WorldToLocal(Vector(0,0,0),pmdl:GetBoneMatrix(pfingers[i]):GetAngles(),Vector(0,0,0),pmdl:GetBoneMatrix(pmdl:GetBoneParent(pfingers[i])):GetAngles())
					else
						pmoffsets[i] = Angle(0,0,0)
					end
				end
			
				vmoffsets = {} --viewmodel finger bone angles relative to parent bone
				for i = 1,30 do
					_, vmoffsets[i] = WorldToLocal(Vector(0,0,0),vmdl:GetBoneMatrix(vfingers[i]):GetAngles(),Vector(0,0,0),vmdl:GetBoneMatrix(vmdl:GetBoneParent(vfingers[i])):GetAngles())
				end
			
				--create pose based on difference
				vmi.closedHandAngles = {}
				for i = 1,30 do
					vmi.closedHandAngles[i] = vmoffsets[i]-pmoffsets[i]
				end
				
			else
				--print("not ok")
				vmi.closedHandAngles = g_VR.zeroHandAngles
			end
			
			pmdl:Remove()
			vmdl:Remove()
			
		end
		
		g_VR.openHandAngles = {}
		g_VR.closedHandAngles = {}
		for i = 1,30 do
			g_VR.openHandAngles[i] = i <= 15 and g_VR.defaultOpenHandAngles[i] or vmi.closedHandAngles[i]
			g_VR.closedHandAngles[i] =  i <= 15 and g_VR.defaultClosedHandAngles[i] or vmi.closedHandAngles[i]
		end
		
		g_VR.viewModelInfo[class] = vmi
		g_VR.currentvmi = vmi
		
	end)
	
	hook.Add("CreateMove","vrutil_hook_joincreatemove",function(cmd)
		hook.Remove("CreateMove","vrutil_hook_joincreatemove")
		timer.Simple(2,function()
			net.Start("vrutil_net_requestvrplayers")
			net.SendToServer()
		end)
		timer.Simple(2,function()
			if SysTime() < 120 then
				GetConVar("vrutil_autostart"):SetBool(false)
			end
			if GetConVar("vrutil_autostart"):GetBool() then
				timer.Create("vrutil_timer_tryautostart",1,0,function()
					local pm = LocalPlayer():GetModel()
					if pm ~= nil and pm ~= "models/player.mdl" and pm ~= "" then
						VRUtilClientStart()
						timer.Remove("vrutil_timer_tryautostart")
					end
				end)
			end
		end)
	end)
	
	net.Receive("vrutil_net_pickup",function(len)
		local ply = net.ReadEntity()
		local ent = net.ReadEntity()
		local leftHand = net.ReadBool()
		local localPos = net.ReadVector()
		local localAng = net.ReadAngle()
		local steamid = ply:SteamID()
		if g_VR.net[steamid] == nil then return end
		ent.RenderOverride = function()
			if g_VR.net[steamid] == nil then return end
			local wpos, wang
			if leftHand then
				wpos, wang = LocalToWorld(localPos, localAng, g_VR.net[steamid].lerpedFrame.lefthandPos, g_VR.net[steamid].lerpedFrame.lefthandAng)
			else
				wpos, wang = LocalToWorld(localPos, localAng, g_VR.net[steamid].lerpedFrame.righthandPos, g_VR.net[steamid].lerpedFrame.righthandAng)
			end
			ent:SetPos(wpos)
			ent:SetAngles(wang)
			ent:SetupBones()
			ent:DrawModel()
		end
		ent.VRPickupRenderOverride = ent.RenderOverride
		if ply == LocalPlayer() then
			if leftHand then
				g_VR.heldEntityLeft = ent
			else
				g_VR.heldEntityRight = ent
			end
		end
		hook.Call("VRUtilEventPickup", nil, ply, ent)
	end)
	
	net.Receive("vrutil_net_drop",function(len)
		local ply = net.ReadEntity()
		local ent = net.ReadEntity()
		if IsValid(ent) and ent.RenderOverride == ent.VRPickupRenderOverride then
			ent.RenderOverride = nil
		end
		hook.Call("VRUtilEventDrop", nil, ply, ent)
	end)

else
	--***************************************** SERVER SIDE ******************************************
	util.AddNetworkString("vrutil_net_join")
	util.AddNetworkString("vrutil_net_exit")
	util.AddNetworkString("vrutil_net_switchweapon")
	util.AddNetworkString("vrutil_net_tick")
	util.AddNetworkString("vrutil_net_requestvrplayers")
	util.AddNetworkString("vrutil_net_entervehicle")
	util.AddNetworkString("vrutil_net_exitvehicle")
	util.AddNetworkString("vrutil_net_pickup")
	util.AddNetworkString("vrutil_net_drop")
	
	local function drop(ply, leftHand, handPos, handAng)
		for k, v in pairs(g_VR[ply:SteamID()].heldItems) do
			if v.left == leftHand then
				if IsValid(v.ent) and v.ent:GetPhysicsObject():IsMoveable() then
					local vel = v.ent:GetVelocity()
					local angvel = v.ent:GetPhysicsObject():GetAngleVelocity()
					if handPos and handAng then
						local wPos, wAng = LocalToWorld(v.localPos, v.localAng, handPos, handAng)
						v.ent:SetPos(wPos)
						v.ent:SetAngles(wAng)
					end
					v.ent:SetCollisionGroup(v.ent.originalCollisionGroup)
					v.ent:PhysicsInit(SOLID_VPHYSICS)
					v.ent:PhysWake()
					v.ent:GetPhysicsObject():SetVelocity(vel)
					v.ent:GetPhysicsObject():AddAngleVelocity(angvel)
				end
				net.Start("vrutil_net_drop")
				net.WriteEntity(ply)
				net.WriteEntity(v.ent)
				net.Broadcast()
				hook.Call("VRUtilEventDrop", nil, ply, v.ent)
				table.remove(g_VR[ply:SteamID()].heldItems, k)
			end
		end
	end
	
	net.Receive("vrutil_net_tick",function(len, ply)
		--print("sv received net_tick, len: "..len)
		if g_VR[ply:SteamID()] == nil then
			return
		end
		local viewHackPos = net.ReadVector()
		local frame = netReadFrame()
		g_VR[ply:SteamID()].latestFrame = frame
		if not viewHackPos:IsZero() and util.IsInWorld(viewHackPos) then
			ply.viewOffset = viewHackPos-ply:EyePos()+ply.viewOffset
			ply:SetCurrentViewOffset(ply.viewOffset)
			ply:SetViewOffset(Vector(0,0,ply.viewOffset.z))
		else
			ply:SetCurrentViewOffset(ply.originalViewOffset)
			ply:SetViewOffset(ply.originalViewOffset)
		end
		--relay frame to everyone except sender
		net.Start("vrutil_net_tick",true)
		net.WriteEntity(ply)
		netWriteFrame(frame)
		net.SendOmit(ply)
		--update picked up item positions
		for k,v in pairs(g_VR[ply:SteamID()].heldItems) do
			if IsValid(v.ent) and v.ent:GetPos():Distance(v.targetPos) < 2 then
				v.targetReached = SysTime()
			end
			if not IsValid(v.ent) or not v.ent:GetPhysicsObject():IsMoveable() or not ply:Alive() or (SysTime()-v.targetReached) > 0.2 then
				drop(ply, v.left)
				continue
			end
			local handPos = LocalToWorld( v.left and frame.lefthandPos or frame.righthandPos, Angle(),ply:GetPos(),Angle())
			local handAng = v.left and frame.lefthandAng or frame.righthandAng
			local wPos, wAng = LocalToWorld(v.localPos, v.localAng, handPos, handAng)
			v.targetPos = wPos
			v.ent:GetPhysicsObject():UpdateShadow(wPos,wAng, 1/cv_tickrate:GetInt())
		end
	end)
	
	net.Receive("vrutil_net_join",function(len, ply)
		if g_VR[ply:SteamID()] ~= nil then 
			return 
		end
		ply:DrawShadow(false)
		ply.originalViewOffset = ply:GetCurrentViewOffset()
		ply.viewOffset = Vector(0,0,0)
		--add gt entry
		g_VR[ply:SteamID()] = {
			--store join values so we can re-send joins to players that connect later
			characterAltHead = net.ReadBool(),
			dontHideBullets = net.ReadBool(),
			--stuff for prop pickup system
			heldItems = {}
		}
		
		ply:Give("weapon_vrmod_empty")
		ply:SelectWeapon("weapon_vrmod_empty")
		ply:ConCommand("gmod_toolmode vr_teleport")
		
		--relay join message to everyone
		net.Start("vrutil_net_join")
		net.WriteEntity(ply)
		net.WriteBool(g_VR[ply:SteamID()].characterAltHead)
		net.WriteBool(g_VR[ply:SteamID()].dontHideBullets)
		net.Broadcast()
		
		hook.Run( "VRUtilStart", ply )
	end)
	
	local function net_exit(steamid)
		if g_VR[steamid] ~= nil then
			g_VR[steamid] = nil
			local ply = player.GetBySteamID(steamid)
			ply:SetCurrentViewOffset(ply.originalViewOffset)
			ply:SetViewOffset(ply.originalViewOffset)
			ply:StripWeapon("weapon_vrmod_empty")
			
			--relay exit message to everyone
			net.Start("vrutil_net_exit")
			net.WriteString(steamid)
			net.Broadcast()
			
			hook.Run( "VRUtilExit", ply )
		end
	end
	
	net.Receive("vrutil_net_exit",function(len, ply)
		net_exit(ply:SteamID())
	end)
	
	hook.Add("PlayerDisconnected","vrutil_hook_playerdisconnected",function(ply)
		net_exit(ply:SteamID())
	end)
	
	net.Receive("vrutil_net_requestvrplayers",function(len, ply)
		for k,v in pairs(g_VR) do
			net.Start("vrutil_net_join")
			net.WriteEntity(player.GetBySteamID(k))
			net.WriteBool(g_VR[k].characterAltHead)
			net.WriteBool(g_VR[k].dontHideBullets)
			net.Send(ply)
		end
	end)
	
	hook.Add("PlayerDeath","vrutil_hook_playerdeath",function(ply, inflictor, attacker)
		if g_VR[ply:SteamID()] ~= nil then
			net.Start("vrutil_net_exit")
			net.WriteString(ply:SteamID())
			net.Broadcast()
		end
	end)
	
	hook.Add("PlayerSpawn","vrutil_hook_playerspawn",function(ply)
		if g_VR[ply:SteamID()] ~= nil then
			ply:Give("weapon_vrmod_empty")

			net.Start("vrutil_net_join")
			net.WriteEntity(ply)
			net.WriteBool(g_VR[ply:SteamID()].characterAltHead)
			net.WriteBool(g_VR[ply:SteamID()].dontHideBullets)
			net.Broadcast()
		end
	end)
	
	hook.Add("PlayerSwitchWeapon","vrutil_hook_playerswitchweapon",function(ply, old, new)
		if g_VR[ply:SteamID()] ~= nil then
			net.Start("vrutil_net_switchweapon")
			if IsValid(new) then
				net.WriteString(new:GetClass())
				net.WriteString(new:GetWeaponViewModel())
			else
				net.WriteString("")
				net.WriteString("")
			end
			net.Send(ply)
			timer.Simple(0,function()
				--new:AddEffects(EF_NODRAW) 
			end)
		end
	end)
	
	hook.Add("PlayerEnteredVehicle","vrutil_hook_playerenteredvehicle",function(ply, veh)
		if g_VR[ply:SteamID()] ~= nil then
			ply:SelectWeapon("weapon_vrmod_empty")
			ply:SetActiveWeapon(ply:GetWeapon("weapon_vrmod_empty"))
			net.Start("vrutil_net_entervehicle")
			net.Send(ply)
		end
	end)
	
	hook.Add("PlayerLeaveVehicle","vrutil_hook_playerleavevehicle",function(ply, veh)
		if g_VR[ply:SteamID()] ~= nil then
			net.Start("vrutil_net_exitvehicle")
			net.Send(ply)
		end
	end)
	
	
	net.Receive("vrutil_net_pickup",function(len, ply)
		local leftHand = net.ReadBool()
		local handPos = net.ReadVector()
		local handAng = net.ReadAngle()
		local handOffsetPos = leftHand and LocalToWorld(Vector(3,-1.5,0), Angle(0,0,0), handPos, handAng) or LocalToWorld(Vector(3,1.5,0), Angle(0,0,0), handPos, handAng)

		local entities = ents.FindInSphere(handOffsetPos,100)
		for k,v in pairs(entities) do
			if not IsValid(v) or not IsValid(v:GetPhysicsObject()) or not v:GetPhysicsObject():IsMoveable() or v:GetPhysicsObject():GetMass() > 35 or v:GetPhysicsObject():HasGameFlag(FVPHYSICS_MULTIOBJECT_ENTITY) or ( v.CPPICanPickup ~= nil and not v:CPPICanPickup(ply) ) then continue end
			local tmp = WorldToLocal(handOffsetPos - v:GetPos(), Angle(0,0,0), Vector(0,0,0), v:GetAngles())
			if tmp:WithinAABox(v:OBBMins(), v:OBBMaxs()) then
				if hook.Call("VRUtilEventPickup", nil, ply, v) == false then
					break
				end
				local locPos, locAng = WorldToLocal(v:GetPos(), v:GetAngles(), handPos, handAng)
				local found = false
				for k2,v2 in pairs(g_VR[ply:SteamID()].heldItems) do
					if v2.ent == v then table.remove(g_VR[ply:SteamID()].heldItems, k2) found = true end
				end
				if not found then
					ply:PickupObject(v)
					timer.Simple(0,function() ply:DropObject() end)
				end
				v.originalCollisionGroup = v:GetCollisionGroup()
				v:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
				v:MakePhysicsObjectAShadow(true,true)
				g_VR[ply:SteamID()].heldItems[#g_VR[ply:SteamID()].heldItems+1] = {ent = v, left = leftHand, localPos = locPos, localAng = locAng, targetPos = Vector(0,0,0), targetReached = SysTime()}
				net.Start("vrutil_net_pickup")
				net.WriteEntity(ply)
				net.WriteEntity(v)
				net.WriteBool(leftHand)
				net.WriteVector(locPos)
				net.WriteAngle(locAng)
				net.Broadcast()
				break
			end
		end
	end)
	
	net.Receive("vrutil_net_drop",function(len, ply)
		local leftHand = net.ReadBool()
		local handPos = net.ReadVector()
		local handAng = net.ReadAngle()
		drop(ply, leftHand, handPos, handAng)
	end)
end