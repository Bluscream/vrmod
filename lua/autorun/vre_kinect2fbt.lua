-- if CLIENT then

    -- function VRE_GetKinectFBT()
        -- if !motionsensor.IsAvailable() then 
            -- print("Kinect sensor unavaliable.")
            -- hook.Remove("Think", "VRERequestKinect")
        -- return end
        -- if motionsensor.IsActive() then
            -- hook.Add("Think", "VRERequestKinect", function()
                -- net.Start("vre_requestkinectfbt")
                    -- net.WriteBool(motionsensor.IsActive())
                -- net.SendToServer()
            -- end)
        -- else
            -- motionsensor.Start()
        -- end
    -- end

    -- net.Receive("vre_kinectfbtvalues", function(len, ply)
        -- if true then
            -- local kinectLeftfoot = net.ReadVector()
            -- local kinectRightfoot = net.ReadVector()

            -- local plyLeftfoot = LocalPlayer():LookupBone("ValveBiped.Bip01_L_Foot")
            -- local plyRightfoot = LocalPlayer():LookupBone("ValveBiped.Bip01_R_Foot")

            -- print(kinectLeftfoot)
            -- LocalPlayer():ManipulateBonePosition(plyLeftfoot, Vector(kinectLeftfoot.x*255,kinectLeftfoot.y*255,kinectLeftfoot.z*255 ))
            -- LocalPlayer():ManipulateBonePosition(plyRightfoot, kinectRightfoot)
        -- end
    -- end)

-- elseif SERVER then
    -- util.AddNetworkString("vre_requestkinectfbt")
    -- util.AddNetworkString("vre_kinectfbtvalues")

    -- net.Receive( "vre_requestkinectfbt", function( len, ply )
        -- local KinectActive = net.ReadBool()
        -- if KinectActive and game.SinglePlayer() then
            -- local kinectLeftfoot = ply:MotionSensorPos(SENSORBONE.FOOT_LEFT)
            -- local kinectRightfoot = ply:MotionSensorPos(SENSORBONE.FOOT_RIGHT)
            -- if kinectLeftfoot + kinectRightfoot != Vector(0, 0, 0) then
                -- net.Start("vre_kinectfbtvalues")
                    -- net.WriteVector(kinectLeftfoot)
                    -- net.WriteVector(kinectRightfoot)
                -- net.Send(ply)
            -- end
        -- end
    -- end)

-- end