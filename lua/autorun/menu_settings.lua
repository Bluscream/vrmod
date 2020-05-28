if SERVER then return end

local open = false
local BUTTON_2TIER = {Color(80, 0, 51), Color(51, 120, 51)}
local BUTTON_3TIER = {Color(80, 0, 51), Color(142, 111, 48), Color(51, 120, 51)}

function VRESettingsMenuToggle()
    if !open then
        VRESettingsMenuOpen()
    else
        VRUtilMenuClose("vremenu_settings")
    end
end


function VRESettingsMenuOpen()
	if open then return end
    open = true

    local cc_enabled = GetConVar("vre_closedcaptions"):GetInt() or 0

    local vreSettingsPanel = vgui.Create( "DPanel" )
    vreSettingsPanel:SetPos( 0, 0 )
    vreSettingsPanel:SetSize( 600, 650 )
    function vreSettingsPanel:GetSize()
        return 450,310
    end

    -- Menu code starts here

    local settingsgrid = vgui.Create("DGrid", vreSettingsPanel)
    settingsgrid:SetPos( 10, 30 )
    settingsgrid:SetCols( 4 )
    settingsgrid:SetColWide( 150 )
    settingsgrid:SetRowHeight( 80 )


    local backbutton = vgui.Create("DButton", vreSettingsPanel)

    backbutton:SetText("<---")
    backbutton:SetSize(60, 30)
    backbutton:SetPos(260, 270)
    backbutton:SetTextColor(Color(255, 255, 255))
    backbutton.DoClick = function()
        VRUtilMenuClose("vremenu_vrmod")
        VREMenuToggle()
    end


    function backbutton:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0,122,204))
    end

    local button1 = vgui.Create("DButton", settingsgrid)
    local button1on = vre_menuguiattachment:GetInt("vre_ui_attachtohand") or 0
    settingsgrid:AddItem(button1)
    button1:SetText("Attach UI to hand")
    button1:SetSize(120, 60)
    button1:SetTextColor(Color(255, 255, 255))
    button1.DoClick = function()
        if button1on == 1 then
            button1on = 0
        else
            button1on = 1
        end
        LocalPlayer():ConCommand("vre_ui_attachtohand "..button1on)
        timer.Simple(0.2, function() VRUtilMenuClose("vremenu_settings") VRESettingsMenuToggle() end)
    end

    function button1:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[button1on+1])
    end

    local button2 = vgui.Create("DButton", settingsgrid)
    local button2on = GetConVar("vre_hidehint"):GetInt() or 0
    settingsgrid:AddItem(button2)
    button2:SetText("Hide Startup Hint")
    button2:SetSize(120, 60)
    button2:SetTextColor(Color(255, 255, 255))
    button2.DoClick = function()
        if button2on == 1 then
            button2on = 0
        else
            button2on = 1
        end
        LocalPlayer():ConCommand("vre_hidehint "..button2on)
    end

    function button2:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[button2on+1])
    end

    local button3 = vgui.Create("DButton", vreVRModPanel)
    local button3on = cc_enabled or 0
    local ccval = {"Off", "NPC Only", "Full"}
    settingsgrid:AddItem(button3)
    button3:SetText("Captions:")
    button3:SetSize(120, 60)
    button3:SetTextColor(Color(255, 255, 255))
    button3.DoClick = function()
        if button3on == 0 then
            button3on = 1
        elseif button3on == 1 then
            button3on = 2
        else
            button3on = 0
        end
        LocalPlayer():ConCommand("vre_closedcaptions "..button3on)
    end

    function button3:Paint(w, h)
        button3:SetText("Captions: "..ccval[button3on+1])
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_3TIER[button3on+1])
    end

    local button4 = vgui.Create("DButton", settingsgrid)
    local button4on = GetConVar("vre_binds_concommands"):GetInt() or 1
    settingsgrid:AddItem(button4)
    button4:SetText("Disable all keybind concommands")
    button4:SetSize(170, 60)
    button4:SetTextColor(Color(255, 255, 255))
    button4.DoClick = function()
        if button4on == 1 then
            button4on = 0
        else
            button4on = 1
        end
        LocalPlayer():ConCommand("vre_binds_concommands "..button4on)
    end

    function button4:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button4on -2)])
    end

    -- Menu code ends here
	
	local ply = LocalPlayer()
	
	local renderCount = 0
	
	local tmp = Angle(0,g_VR.tracking.hmd.ang.yaw-90,45) --Forward() = right, Right() = back, Up() = up (relative to panel, panel forward is looking at top of panel from middle of panel, up is normal)
    local pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
    local mode = 4
    --uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc
    
    if vre_menuguiattachment:GetInt("vre_ui_attachtohand") == 1 then
        pos, ang = Vector(10,6,13), Angle(0,-90,50)
        mode = 1
    else
        pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
        mode = 4
    end

    VRUtilMenuOpen("vremenu_settings", 600, 310, vreSettingsPanel, mode, pos, ang, 0.03, true, function()
        vreSettingsPanel:Remove()
        vreSettingsPanel = nil
         hook.Remove("PreRender","vre_rendersettingsmenu")
		 open = false
	end)
	
    hook.Add("PreRender","vre_rendersettingsmenu",function()
        if VRUtilIsMenuOpen("chat") or VRUtilIsMenuOpen("vremenu") then
            VRUtilMenuClose("vremenu_settings")
        elseif IsValid(vreSettingsPanel) then
            function vreSettingsPanel:Paint( w, h )
                surface.SetDrawColor( Color( 51, 51, 51, 200 ) )
                surface.DrawRect(0,0,w,h)
            end
            VRUtilMenuRenderPanel("vremenu_settings")
        end
	end)
	
end
