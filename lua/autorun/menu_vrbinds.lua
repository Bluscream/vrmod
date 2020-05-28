if SERVER then return end

local open = false

function VREKeybindMenuToggle()
    if !open then
        VREKeybindMenuOpen()
    else
        VREKeybindMenuClose()
    end
end

function VREKeybindMenuOpen()
	if open then return end
	open = true
    
    vreKeybindMenu = vgui.Create( "DPanel" )
    vreKeybindMenu:SetPos( 0, 0 )
    vreKeybindMenu:SetSize( 600, 650 )
    function vreKeybindMenu:GetSize()
        return 450,310
    end

    -- Menu code starts here

    local backbutton = vgui.Create("DButton", vreKeybindMenu)
    backbutton:SetText("<---")
    backbutton:SetSize(60, 30)
    backbutton:SetPos(260, 270)
    backbutton:SetTextColor(Color(255, 255, 255))
    backbutton.DoClick = function()
        if VRUtilIsMenuOpen("vrmod_keyboard") then VRUtilMenuClose("vrmod_keyboard") end
        VRUtilMenuClose("vremenu_keybinds")
        VREMenuToggle()
    end

    function backbutton:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0,122,204))
    end

    local bindgrid = vgui.Create("DGrid", vreKeybindMenu)
    bindgrid:SetPos(10, 30)
    bindgrid:SetCols(4)
    bindgrid:SetColWide(150)
    bindgrid:SetRowHeight(80)

    local button1 = vgui.Create("DButton")
    button1:SetText("boolean_chat (held)")
    button1:SetSize(150, 60)
    button1:SetTextColor(Color(255, 255, 255))
    bindgrid:AddItem(button1)
    button1.DoClick = function()
        VREMenuClose()
        ChatHeldKeyBind()
    end

    function button1:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end


    
    --End of bind selection
    function ChatHeldKeyBind()

        bindgrid:Remove()


        local settingsform = vgui.Create("DForm", vreKeybindMenu)
        settingsform:SetLabel("Chat button (Long press)")
        settingsform:Dock(FILL)

        local chatheldkey = vgui.Create("DBinder", vreKeybindMenu)
        settingsform:AddItem(chatheldkey)
        chatheldkey:SetSize(100, 100)
        chatheldkey:SetValue(vre_binding_key_chathold:GetInt("vre_key_chat_held", 100))
    
        function chatheldkey:UpdateText()
            return false
        end

        function chatheldkey:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(200,200,200))
            chatheldkey:SetText("")
            if input.IsKeyTrapping() then
                draw.DrawText("Press any key...", "DermaLarge", 60, 28, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT)
            else
                draw.DrawText("Click here to listen for a real key press.", "DermaLarge", 60, 28, Color(0, 0, 0, 255), TEXT_ALIGN_LEFT)
            end
        end
        

        local displaykey = vgui.Create("DPanel", vreKeybindMenu)
        function displaykey:Paint(w, h)
            local displaykeytext = input.GetKeyName(vre_binding_key_chathold:GetInt("vre_key_chat_held", 100)) or "None"
            draw.DrawText("Emulated Key: "..displaykeytext, "DermaLarge", 0, 150, Color(255,255,255,255), TEXT_ALIGN_LEFT)
        end

        local displaykey = vgui.Create("DPanel", vreKeybindMenu)
        function displaykey:Paint(w, h)
            if GetConVar("vre_binds_concommands"):GetInt() == 1 then
                local thiscmd = input.LookupKeyBinding(vre_binding_key_chathold:GetInt("vre_key_chat_held", 100))
                local returnedcmd = thiscmd or "No commands"
                draw.DrawText("Runs: "..returnedcmd, "DermaLarge", 0, 180, Color(255,255,255,255), TEXT_ALIGN_LEFT)
            end
        end

        local button3 = vgui.Create("DButton", vreKeybindMenu)
        local button3on = GetConVar("vre_binds_concommands"):GetInt() or 1
        button3:SetText("Run console commands?")
        button3:SetSize(170, 60)
        button3:SetPos(35, 220)
        button3:SetTextColor(Color(255, 255, 255))
        button3.DoClick = function()
            if button3on == 1 then
                button3on = 0
            else
                button3on = 1
            end
            LocalPlayer():ConCommand("vre_binds_concommands "..button3on)
        end

        function button3:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(51,120 * button3on,51))
        end

        VREKeyboardToggle()

        hook.Add("VREKeyboardOnPress", "VREKeybindMenuPressKey", function(key)
            if key then
                chatheldkey:SetValue(input.GetKeyCode(key))
            end
        end)
        
        function chatheldkey:OnChange( num )
            vre_binding_key_chathold:SetInt( num )
        end
    end

    -- Menu code ends here
	
	local ply = LocalPlayer()
	
	local renderCount = 0
	
	local tmp = Angle(0,g_VR.tracking.hmd.ang.yaw-90,45) --Forward() = right, Right() = back, Up() = up (relative to panel, panel forward is looking at top of panel from middle of panel, up is normal)
    local pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
    --uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc
    VRUtilMenuOpen("vremenu_keybinds", 600, 310, vreKeybindMenu, 1, Vector(10,6,13), Angle(0,-90,50), 0.03, true, function()
        vreKeybindMenu:Remove()
        vreKeybindMenu = nil
         hook.Remove("PreRender","vre_renderkeybinds")
		 open = false
	end)
	
    hook.Add("PreRender","vre_renderkeybinds",function()
        if VRUtilIsMenuOpen("chat") or VRUtilIsMenuOpen("vremenu") then
            VRUtilMenuClose("vremenu_keybinds")
            if VRUtilIsMenuOpen("vrmod_keyboard") then VRUtilMenuClose("vrmod_keyboard") end
        elseif IsValid(vreKeybindMenu) then
            function vreKeybindMenu:Paint( w, h )
                surface.SetDrawColor( Color( 51, 51, 51, 200 ) )
                surface.DrawRect(0,0,w,h)
            end
            VRUtilMenuRenderPanel("vremenu_keybinds")
        end
	end)
end

function vreKeybindMenuClose()
	VRUtilMenuClose("vremenu_keybinds")
end