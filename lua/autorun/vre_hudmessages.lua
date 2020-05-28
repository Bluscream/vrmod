if CLIENT then

    local curtext = ""
    local lastthree = string.Explode("%c", curtext, true)
    local cc_enabled = CreateClientConVar("vre_closedcaptions", "0", true, false, "0: No Captions, 1: Dialogue only, 2: Full Captions", 0, 2)

    function VREHUD_DisplayMessage(hudmessage, holdtime, type)
        if hudmessage != nil and hudmessage != "" and g_VR.active then
            -- local VRHUDPanel = vgui.Create( "DPanel" )
            -- VRHUDPanel:SetPos( 0, 0 )
            -- VRHUDPanel:SetSize( 600, 650 )
            -- function VRHUDPanel:GetSize()
            --     return 450,310
            -- end
            
            if GetConVar("vre_closedcaptions"):GetInt() == 0 and (string.sub(type, 1, 7) == "caption") then return end
            if (type == "caption_npc" and string.find(language.GetPhrase(hudmessage), "[", 1, true) != nil ) or (string.sub(type, 1, 7) == "caption" and language.GetPhrase(hudmessage) == nil)  then return end
            
            local ccparams = string.Explode(">", language.GetPhrase(hudmessage))
            local parsedmessage = ccparams[#ccparams]
            local messagecol = Color(200,200,200,255)
            local messagefont = "CloseCaption_Bold"
            

            for i = 1, #ccparams do
                local param = ccparams[i]

                if string.find(language.GetPhrase(hudmessage), "<I>", 1, true) != nil then
                    messagefont = "CloseCaption_BoldItalic"
                    type = "caption_npc"
                end

                if string.StartWith(param, "<clr:") then
                    messagecol = string.ToColor(string.Replace(string.sub(param, 6)..",255", ",", " "))
                    --print(string.sub(param, 6)..",255")
                end
            end

            if (type == "caption" and GetConVar("vre_closedcaptions"):GetInt() != 2) then return end

            if string.StartWith(parsedmessage, "#") then return end

            lastthree = string.Explode("%c", curtext, true)

            curtext = curtext.."\n"..string.Replace(parsedmessage, ". ", ".\n")

            timer.Simple(holdtime, function() curtext = (lastthree[#lastthree] or "").."\n"..(lastthree[#lastthree-1] or "") end)
            
            VRUtilMenuOpen("vrehud", 600, 310, nil, 3, Vector(22,8,7), Angle(0,-90,90), 0.03, false, function()
            end)

            -- hook.Run( "VREGetHUD", VRHUDPanel)

            hook.Add("PreRender","vre_renderhud",function()
                if !g_VR.active then hook.Remove("PreRender","vre_renderhud") return end
                VRUtilMenuRenderStart("vrehud")
                    if string.sub(type, 1, 7) != "caption" then
                        draw.DrawText(timer.RepsLeft("VREHUDFix_DelTime"), "CloseCaption_Normal", 300, 100, Color(255,255,255,255), TEXT_ALIGN_CENTER)
                        messagefont = "DermaLarge"
                    end
                    draw.DrawText(curtext, messagefont, 300, 150, messagecol, TEXT_ALIGN_CENTER)
                    lastthree = string.Explode("%c", curtext, true)
                    if #lastthree > 12 then
                        curtext = "\n"..lastthree[2].."\n"..lastthree[3]
                    end
                VRUtilMenuRenderEnd()
            VRUtilMenuRenderPanel("vrehud")
            end)
            
            if !timer.Exists("VREHUDFix_DelTime") then
                timer.Create("VREHUDFix_DelTime", 1, holdtime + 1, function()
                    if timer.RepsLeft("VREHUDFix_DelTime") == 0 then
                        curtext = ""
                        -- VRHUDPanel:Remove()
                        -- VRHUDPanel = nil
                        hook.Remove("PreRender","vre_renderhud")
                        VRUtilMenuClose("vrehud")
                    end
                end)
            else
                local preaddtime = timer.RepsLeft("VREHUDFix_DelTime")
                timer.Adjust( "VREHUDFix_DelTime",  1, holdtime + 1, function()
                    if timer.RepsLeft("VREHUDFix_DelTime") == 0 then
                        curtext = ""
                        -- VRHUDPanel:Remove()
                        -- VRHUDPanel = nil
                        hook.Remove("PreRender","vre_renderhud")
                        VRUtilMenuClose("vrehud")
                    end
                end)
            end

        end
    end

elseif SERVER then

    -- Map text/chapter titles
    hook.Add("AcceptInput", "VREHUDFixTextTrigger", function(gtent, input, activator, caller, data)
        if (gtent:GetClass() == "game_text" and input == "Display") or (gtent:GetClass() == "env_message" and input == "ShowMessage") then
            local htext = string.JavascriptSafe(gtent:GetKeyValues().message)
            local hholdtime = gtent:GetKeyValues().holdtime or 5
            if activator:IsPlayer() then
                activator:SendLua("VREHUD_DisplayMessage('"..htext.."', "..hholdtime..", 'generic')")
            end
        elseif gtent:GetKeyValues().message != nil then
            local htext = string.JavascriptSafe(gtent:GetKeyValues().message)
            local hholdtime = gtent:GetKeyValues().holdtime or 5
            if activator:IsPlayer() then
                activator:SendLua("VREHUD_DisplayMessage('"..htext.."', "..hholdtime..", 'generic')")
            end
        end

    end)

    -- Closed captions
    hook.Add("EntityEmitSound", "VREHUDClosedCaptions", function(data)
        if data.SoundName != data.OriginalSoundName and data.Entity:GetClass() != "npc_combine_camera" then
            --print("#"..data.OriginalSoundName)
            local htext = string.JavascriptSafe("#"..data.OriginalSoundName)
            local hholdtime = 15
            if data.Entity:IsNPC() then
                BroadcastLua("VREHUD_DisplayMessage('"..htext.."', 15, 'caption_npc')")
            else
                BroadcastLua("VREHUD_DisplayMessage('"..htext.."', 15, 'caption')")
            end
        end
    end)

    -- Old I/O based captioning system
    -- hook.Add("AcceptInput", "VREHUDClosedCaptions", function(gtent, input, activator, caller, data)
    --     if (gtent:GetClass() == "ambient_generic" and input == "PlaySound") then
    --         -- for i = 1, #table.GetKeys(gtent:GetKeyValues()) do
    --         --     print(table.GetKeys(gtent:GetKeyValues())[i])
    --         -- end
    --         print(gtent:GetKeyValues().ResponseContext)
    --         local htext = string.JavascriptSafe(gtent:GetKeyValues().ResponseContext)
    --         local hholdtime = gtent:GetKeyValues().ltime or 5
    --         if activator:IsPlayer() then
    --             print(htext)
    --             activator:SendLua("VREHUD_DisplayMessage('"..htext.."', "..hholdtime..")")
    --         end
    --     end
    -- end)
end