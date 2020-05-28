if SERVER then return end

local open = false
local BUTTON_2TIER = {Color(80, 0, 51), Color(51, 120, 51)}
local BUTTON_3TIER = {Color(80, 0, 51), Color(142, 111, 48), Color(51, 120, 51)}

function VREVRModMenuToggle()
    if !open then
        VREVRModMenuOpen()
    else
        VRUtilMenuClose("vremenu_vrmod")
    end
end


function VREVRModMenuOpen()
	if open then return end
	open = true
    
    local needsrestart = false

    local cv_altHead = GetConVar("vrutil_althead"):GetInt() or 0
    local cv_autoStart = GetConVar("vrutil_autostart"):GetInt() or 0
    local cv_hideCharacter = GetConVar("vrutil_hidecharacter"):GetInt() or 0
    local cv_desktopView = GetConVar("vrutil_desktopview"):GetInt() or 0
    local cv_useWorldModels = GetConVar("vrutil_useworldmodels"):GetInt() or 0
    local cv_laserPointer = GetConVar("vrutil_laserpointer"):GetInt() or 0
    local cv_controllerOriented = GetConVar("vrutil_controlleroriented"):GetInt() or 0
    local cv_smoothTurn = GetConVar("vrutil_smoothturn"):GetInt() or 0
    local cv_znear = GetConVar("vrutil_znear", "6"):GetInt() or 0

    local vreVRModPanel = vgui.Create( "DPanel" )
    vreVRModPanel:SetPos( 0, 0 )
    vreVRModPanel:SetSize( 600, 650 )
    function vreVRModPanel:GetSize()
        return 450,310
    end

    -- Menu code starts here

    local restarthint = vgui.Create("DPanel", vreVRModPanel)
    function restarthint:Paint(w, h)
        if needsrestart then
            draw.DrawText("Restart VR to apply these changes.", "Trebuchet18", 35, 275, Color(220,220,220,220), TEXT_ALIGN_LEFT)
        end
    end

    local settingsgrid = vgui.Create("DGrid", vreVRModPanel)
    settingsgrid:SetPos( 10, 30 )
    settingsgrid:SetCols( 4 )
    settingsgrid:SetColWide( 150 )
    settingsgrid:SetRowHeight( 80 )

    local backbutton = vgui.Create("DButton", vreVRModPanel)

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

    local button1 = vgui.Create("DButton", vreVRModPanel)
    settingsgrid:AddItem(button1)
    button1:SetText("Restart VR")
    button1:SetSize(120, 60)
    button1:SetTextColor(Color(255, 255, 255))
    button1.DoClick = function()
        VRUtilClientExit()
        timer.Simple(1, function() VRUtilClientStart() end)
    end

    function button1:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end

    
    local button5 = vgui.Create("DButton", vreVRModPanel)
    settingsgrid:AddItem(button5)
    button5:SetText("Exit VR")
    button5:SetSize(120, 60)
    button5:SetTextColor(Color(255, 255, 255))
    button5:SetConsoleCommand( "vrmod_exit" )

    function button5:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end

    local button2 = vgui.Create("DButton", vreVRModPanel)
    settingsgrid:AddItem(button2)
    button2:SetText("Calibrate Height")
    button2:SetSize(120, 60)
    button2:SetTextColor(Color(255, 255, 255))
    button2:SetConsoleCommand("vre_callibrateheight")

    function button2:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end

    if hook.Run("PlayerNoClip", LocalPlayer(), true) == true then
        local button6 = vgui.Create("DButton", vreVRModPanel)
        settingsgrid:AddItem(button6)
        button6:SetText("Teleport Tool")
        button6:SetSize(120, 60)
        button6:SetTextColor(Color(255, 255, 255))
        button6:SetConsoleCommand("gmod_toolmode vr_teleport")

        button6.DoClick = function()
            input.SelectWeapon(LocalPlayer():GetWeapon("gmod_tool"))
        end

        function button6:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
        end 
    end

    local button3 = vgui.Create("DButton", vreVRModPanel)
    local button3on = cv_hideCharacter or 0
    settingsgrid:AddItem(button3)
    button3:SetText("Hide Avatar")
    button3:SetSize(120, 60)
    button3:SetTextColor(Color(255, 255, 255))
    button3.DoClick = function()
        if button3on == 1 then
            button3on = 0
        else
            button3on = 1
        end
        LocalPlayer():ConCommand("vrutil_hidecharacter "..button3on)
        needsrestart = true
    end

    function button3:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[button3on+1])
    end

    local button4 = vgui.Create("DButton", vreVRModPanel)
    local button4on = cv_useWorldModels or 0
    settingsgrid:AddItem(button4)
    button4:SetText("Weapon Worldmodels")
    button4:SetSize(120, 60)
    button4:SetTextColor(Color(255, 255, 255))
    button4.DoClick = function()
        if button4on == 1 then
            button4on = 0
        else
            button4on = 1
        end
        LocalPlayer():ConCommand("vrutil_useworldmodels "..button4on)
        needsrestart = true
    end

    function button4:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[button4on+1])
    end

    local button7 = vgui.Create("DButton", vreVRModPanel)
    local button7on = cv_autoStart or 0
    settingsgrid:AddItem(button7)
    button7:SetText("Autostart")
    button7:SetSize(120, 60)
    button7:SetTextColor(Color(255, 255, 255))
    button7.DoClick = function()
        if button7on == 1 then
            button7on = 0
        else
            button7on = 1
        end
        LocalPlayer():ConCommand("vrutil_autostart "..button7on)
    end

    function button7:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[button7on+1])
    end

    local button8 = vgui.Create("DButton", vreVRModPanel)
    local button8on = cv_smoothTurn or 0
    settingsgrid:AddItem(button8)
    button8:SetText("Smooth Turning")
    button8:SetSize(120, 60)
    button8:SetTextColor(Color(255, 255, 255))
    button8.DoClick = function()
        if button8on == 1 then
            button8on = 0
        else
            button8on = 1
        end
        LocalPlayer():ConCommand("vrutil_smoothturn "..button8on)
        needsrestart = true
    end

    function button8:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[button8on+1])
    end

    local button9 = vgui.Create("DButton", vreVRModPanel)
    local button9on = cv_desktopView or 0
    local desktopviewval = {"Off", "Left eye", "Right eye"}
    settingsgrid:AddItem(button9)
    button9:SetText("Mirror:")
    button9:SetSize(120, 60)
    button9:SetTextColor(Color(255, 255, 255))
    button9.DoClick = function()
        if button9on == 0 then
            button9on = 1
        elseif button9on == 1 then
            button9on = 2
        else
            button9on = 0
        end
        LocalPlayer():ConCommand("vrutil_desktopview "..button9on)
        needsrestart = true
    end

    function button9:Paint(w, h)
        button9:SetText("Mirror: "..desktopviewval[button9on+1])
        draw.RoundedBox(8, 0, 0, w, h, BUTTON_3TIER[button9on+1])
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

    VRUtilMenuOpen("vremenu_vrmod", 600, 310, vreVRModPanel, mode, pos, ang, 0.03, true, function()
        vreVRModPanel:Remove()
        vreVRModPanel = nil
         hook.Remove("PreRender","vre_rendervrmodmenu")
		 open = false
	end)
	
    hook.Add("PreRender","vre_rendervrmodmenu",function()
        if VRUtilIsMenuOpen("chat") or VRUtilIsMenuOpen("vremenu") then
            VRUtilMenuClose("vremenu_vrmod")
        elseif IsValid(vreVRModPanel) then
            function vreVRModPanel:Paint( w, h )
                surface.SetDrawColor( Color( 51, 51, 51, 200 ) )
                surface.DrawRect(0,0,w,h)
            end
            VRUtilMenuRenderPanel("vremenu_vrmod")
        end
	end)
	
end
