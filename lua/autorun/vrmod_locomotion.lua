


if CLIENT then
	
	local vehicleOffsetsReady = false
	local vehicleYawOffset = 0
	
	local moveParent = nil
	local originOffset = Vector(0,0,0)
	
	local blockTeleport = false
	local delayRelease = false
	
	function VRUtilLocomotionInit()
		
		local localPlayer = LocalPlayer()
		local steamid = localPlayer:SteamID()
		local controllerOriented = GetConVar("vrutil_controlleroriented"):GetBool()
		local smoothTurn = GetConVar("vrutil_smoothturn"):GetBool()
		local smoothTurnRate = GetConVar("vrutil_smoothturnrate"):GetInt()
	
		hook.Add("PreRender","vrutil_hook_locomotion",function()
			if not g_VR.threePoints or g_VR.characterInfo[steamid] == nil then return end
			--**************
			--    in-vehicle 
			--**************
			if localPlayer:InVehicle() then
				local v = localPlayer:GetVehicle()
				--get offsets
				if not vehicleOffsetsReady then
					if not timer.Exists("vrutil_timer_vehicleoffsets") then
						timer.Create("vrutil_timer_vehicleoffsets",1,1,function()
							local unused, properVehicleAngle = LocalToWorld(Vector(0,0,0),Angle(0,90,0),Vector(0,0,0),v:GetAngles()) --all vehicles (except prisoner pod) seem to have 90 deg yaw offset
							vehicleYawOffset = math.AngleDifference(properVehicleAngle.yaw, g_VR.tracking.hmd.ang.yaw) - (properVehicleAngle.yaw) + 90 + g_VR.originAngle.yaw
							local wpos, wang = LocalToWorld(Vector(0,0,0),Angle(0,vehicleYawOffset,0),Vector(0,0,0),v:GetAngles())
							VRUtilSetOriginAngle(wang)
							local attach = localPlayer:GetAttachment(localPlayer:LookupAttachment("eyes"))
							VRUtilSetOrigin(attach.Pos + properVehicleAngle:Forward()*g_VR.characterInfo[steamid].characterHeadToHmdDist)
							originOffset = WorldToLocal(g_VR.origin,Angle(0,0,0),v:GetPos(), v:GetAngles())
							vehicleOffsetsReady = true
						end)
					end
					return
				end
				--offsets ready
				local wpos, wang = LocalToWorld(Vector(0,0,0),Angle(0,vehicleYawOffset,0),Vector(0,0,0),v:GetAngles())
				VRUtilSetOriginAngle(wang)
				g_VR.origin = LocalToWorld(originOffset,Angle(0,0,0),v:GetPos(), v:GetAngles())
				return
			end
			if vehicleOffsetsReady then
				vehicleOffsetsReady = false
				VRUtilSetOriginAngle(Angle(0,0,0))
				originOffset = Vector(0,0,0)
				vehicleYawOffset = 0
			end
			--**************
			--  not in vehicle
			--**************
			
			--figure out movement parent
			local newMoveParent = (g_VR.input.boolean_walk or not localPlayer:IsFlagSet(FL_ONGROUND) or delayRelease) and localPlayer or localPlayer:GetGroundEntity()
			if newMoveParent ~= moveParent then
				moveParent = newMoveParent
				if IsValid(moveParent) then
					originOffset = WorldToLocal(g_VR.origin,Angle(0,0,0),moveParent:GetPos(), moveParent == localPlayer and Angle(0,0,0) or moveParent:GetAngles())
				end
			end
			--move
			if IsValid(moveParent) then
				g_VR.origin = LocalToWorld(originOffset,Angle(0,0,0),moveParent:GetPos(), moveParent == localPlayer and Angle(0,0,0) or moveParent:GetAngles())
			elseif not blockTeleport and math.Distance(g_VR.characterInfo[steamid].renderPos.x, g_VR.characterInfo[steamid].renderPos.y, localPlayer:GetPos().x, localPlayer:GetPos().y) > 16 then
				g_VR.origin = localPlayer:GetPos() + Vector(g_VR.origin.x - g_VR.characterInfo[steamid].renderPos.x, g_VR.origin.y - g_VR.characterInfo[steamid].renderPos.y,0)
				blockTeleport = true
				timer.Simple(1,function() if not g_VR.input.boolean_walk then blockTeleport = false end end)
			end
			g_VR.origin.z = localPlayer:GetPos().z
			
			if smoothTurn then
				if g_VR.input.vector2_smoothturn.x ~= 0 and math.abs(g_VR.input.vector2_smoothturn.x) > math.abs(g_VR.input.vector2_smoothturn.y) then
					VRUtilSetOriginAngle(g_VR.originAngle - Angle(0, g_VR.input.vector2_smoothturn.x * smoothTurnRate * RealFrameTime(), 0))
					if IsValid(moveParent) then
						originOffset = WorldToLocal(g_VR.origin,Angle(0,0,0),moveParent:GetPos(), moveParent == localPlayer and Angle(0,0,0) or moveParent:GetAngles())
					end
				end
			end
		end)
	
	
		hook.Add("VRUtilEventInput","vrutil_hook_locomotioninput",function( action, pressed )
			if localPlayer:InVehicle() then return end
			
			if hook.Call("VRUtilAllowDefaultAction", nil, action) == false then return end

			if not smoothTurn and (action == "boolean_turnleft" or action == "boolean_turnright") and pressed then
				if action == "boolean_turnright" then
					VRUtilSetOriginAngle(g_VR.originAngle - Angle(0, 360/12, 0))
				else
					VRUtilSetOriginAngle(g_VR.originAngle + Angle(0, 360/12, 0))
				end
				if IsValid(moveParent) then
					originOffset = WorldToLocal(g_VR.origin,Angle(0,0,0),moveParent:GetPos(), moveParent == localPlayer and Angle(0,0,0) or moveParent:GetAngles())
				end
			end
			
			if action == "boolean_jump" then
				if pressed then
					localPlayer:ConCommand("+jump")
					if localPlayer:IsFlagSet(FL_ONGROUND) then
						localPlayer:ConCommand("+duck")
					end
				else
					localPlayer:ConCommand("-jump")
					localPlayer:ConCommand("-duck")
				end
			end
			
			if action == "boolean_walk" then
				if pressed then
					blockTeleport = true
					delayRelease = true
				else
					timer.Simple(0.5,function()
						if not g_VR.input.boolean_walk then 
							delayRelease = false 
							timer.Simple(0.5,function() if not g_VR.input.boolean_walk then blockTeleport = false end end)
						end
					end)
					
				end
			end
		end)
	
		hook.Add("CreateMove","vrutil_hook_createmove",function(cmd)
			if not g_VR.threePoints or g_VR.characterInfo[steamid] == nil then return end
			
			--in vehicle
			if localPlayer:InVehicle() then
				cmd:SetForwardMove((g_VR.input.vector1_forward-g_VR.input.vector1_reverse)*400)
				cmd:SetSideMove(g_VR.input.vector2_steer.x*400)
				local _,relativeAng = WorldToLocal(Vector(0,0,0),g_VR.tracking.hmd.ang,Vector(0,0,0),localPlayer:GetVehicle():GetAngles())
				cmd:SetViewAngles(relativeAng)
				cmd:SetButtons( bit.bor(cmd:GetButtons(), g_VR.input.boolean_turbo and IN_SPEED or 0, g_VR.input.boolean_handbrake and IN_JUMP or 0) )
				return
			end
			
			--handle player (not vr) view angles
			local viewAngles = g_VR.currentvmi and g_VR.currentvmi.wrongMuzzleAng and g_VR.tracking.pose_righthand.ang or g_VR.viewModelMuzzle and g_VR.viewModelMuzzle.Ang or g_VR.tracking.hmd.ang
			viewAngles = viewAngles:Forward():Angle()
			cmd:SetViewAngles(viewAngles)
			
			--handle player movement
			if g_VR.input.boolean_walk or not localPlayer:IsFlagSet(FL_ONGROUND) or delayRelease then
				local walkDirectionWorld = LocalToWorld(Vector(g_VR.input.vector2_walkdirection.y * math.abs(g_VR.input.vector2_walkdirection.y), (-g_VR.input.vector2_walkdirection.x) * math.abs(g_VR.input.vector2_walkdirection.x), 0)*localPlayer:GetMaxSpeed(), Angle(0,0,0), Vector(0,0,0), Angle(0, controllerOriented and g_VR.tracking.pose_lefthand.ang.yaw or g_VR.tracking.hmd.ang.yaw, 0))
				local walkDirViewAngRelative = WorldToLocal(Vector( walkDirectionWorld.x , walkDirectionWorld.y,0), Angle(), Vector(), Angle(0,viewAngles.yaw,0))
				cmd:SetForwardMove( walkDirViewAngRelative.x )
				cmd:SetSideMove( -walkDirViewAngRelative.y )
				if localPlayer:IsFlagSet(FL_INWATER) then
					cmd:SetUpMove( (controllerOriented and g_VR.tracking.pose_lefthand.ang.pitch or g_VR.tracking.hmd.ang.pitch)*-4 )
				end
				cmd:SetButtons( bit.bor(cmd:GetButtons(), g_VR.input.boolean_sprint and IN_SPEED or 0, localPlayer:GetMoveType() == MOVETYPE_LADDER and IN_FORWARD or 0, (g_VR.tracking.hmd.pos.z < ( g_VR.origin.z + g_VR.characterInfo[localPlayer:SteamID()].characterEyeHeight*0.7 )) and IN_DUCK or 0 ) )
			else --make the player follow the hmd
				local walkDirViewAngRelative = WorldToLocal(Vector( (g_VR.characterInfo[steamid].renderPos.x - localPlayer:GetPos().x) * 8 , (localPlayer:GetPos().y - g_VR.characterInfo[steamid].renderPos.y) * -8,0), Angle(), Vector(), Angle(0,viewAngles.yaw,0))
				cmd:SetForwardMove( walkDirViewAngRelative.x )
				cmd:SetSideMove( -walkDirViewAngRelative.y )
			end
		end)
		
	end
	
	function VRUtilLocomotionCleanup()
		hook.Remove("CreateMove","vrutil_hook_createmove")
		hook.Remove("VRUtilEventInput","vrutil_hook_locomotioninput")
		hook.Remove("PreRender","vrutil_hook_locomotion")
		LocalPlayer():SetEyeAngles(Angle(0,0,0))
	end
	
end
