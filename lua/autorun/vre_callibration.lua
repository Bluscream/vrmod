if CLIENT then

	local rawheight = 0
    local lowervalue = 0
	concommand.Add( "vre_callibrateheight", function( ply, cmd, args )
        if g_VR.net[ply:SteamID()] then
            
            local CalibrationPanel = vgui.Create( "DPanel" )
            CalibrationPanel:SetPos( 0, 0 )
            CalibrationPanel:SetSize( 600, 650 )
            function CalibrationPanel:GetSize()
                return 450,310
            end
            local ang = math.abs(g_VR.tracking.hmd.ang.x)

            local cpanellabel = vgui.Create("DLabel", CalibrationPanel)
            cpanellabel:Center()

            VRUtilMenuOpen("vrecalibration", 600, 310, nil, 3, Vector(12,8,7), Angle(0,-90,90), 0.03, true, function()
            end)

            hook.Add("PreRender","vre_rendercalibration",function()
                VRUtilMenuRenderStart("vrecalibration")
                    ang = math.abs(g_VR.tracking.hmd.ang.x)
                    rawheight = (g_VR.tracking.hmd.pos.z - g_VR.origin.z + 2)
                    -- if g_VR.tracking.pose_righthand.pos > g_VR.tracking.pose_lefthand.pos then
                    --     lowervalue = g_VR.tracking.pose_righthand.pos
                    -- else
                    --     lowervalue = g_VR.tracking.pose_lefthand.pos
                    -- end
                    surface.SetDrawColor( (ang * 2), (255 - ang * 2), 0, 200 ) 
                    surface.DrawRect(0,0,600,310)
                    draw.DrawText(timer.RepsLeft("VREHeightCalibration"), "CloseCaption_Normal", 300, 100, Color(255,255,255,255), TEXT_ALIGN_CENTER)
                    draw.DrawText("Calibrating...", "DermaLarge", 300, 150, Color(255,255,255,255), TEXT_ALIGN_CENTER)
                    draw.DrawText("Keep your head straight.", "CloseCaption_Normal", 300, 180, Color(255,255,255,255), TEXT_ALIGN_CENTER)
                    draw.DrawText("Estimated height: "..math.Round(math.abs(rawheight * 2.6), 2).."cm", "CloseCaption_Normal", 300, 220, Color(255,255,255,255), TEXT_ALIGN_CENTER)
                    VRUtilMenuRenderEnd()
                VRUtilMenuRenderPanel("vrecalibration")
            end)

			if !timer.Exists("VREHeightCalibration") then
				timer.Create("VREHeightCalibration", 1, 4, function()
                    if timer.RepsLeft("VREHeightCalibration") == 0 then
                        CalibrationPanel:Remove()
                        CalibrationPanel = nil
                        hook.Remove("PreRender","vre_rendercalibration")
						rawheight = (g_VR.tracking.hmd.pos.z - g_VR.origin.z + 2)
						EmitSound( "garrysmod/balloon_pop_cute.wav", LocalPlayer():GetPos(), -1, CHAN_AUTO, 1, 75, 0, 150 )
                        ply:ConCommand( "vrutil_userheight ".. (((math.Round(math.abs(rawheight * 2.6), 3) ))))
						VRUtilClientExit()
						timer.Simple(1, function() VRUtilClientStart() end)
					else
						EmitSound( "garrysmod/balloon_pop_cute.wav", LocalPlayer():GetPos(), -1, CHAN_AUTO, 1, 75, 0, 100 )
					end
				end)
			end
		end
	end)
	
end