if SERVER then return end

vre_menuguiattachment = CreateClientConVar("vre_ui_attachtohand", "0", true, false, "\nShould the menu be parented to the user's left hand?")
local open = false
local menuPressAmount = 0

hook.Add("VRUtilEventInput","vremenueventinput",function( action, pressed)
    if action == "boolean_chat" and pressed then
	if not timer.Exists( "VREMenuResetClicks" ) then
		timer.Create("VREMenuResetClicks", 1, 1, function() menuPressAmount = 0 end)
	end
        menuPressAmount = menuPressAmount + 1
        if VRUtilIsMenuOpen("vremenu") then
            VRUtilMenuClose("vremenu")
        end
    else
        if menuPressAmount > 2 then
		menuPressAmount = 0
			timer.Remove("VREMenuResetClicks")
            if VRUtilIsMenuOpen("chat") then
                VRUtilMenuClose("chat")
            end
            VREMenuToggle() 
        end
    end
    return
end)

function VREMenuToggle()
    if !open then
        VREMenuOpen()
    else
        VREMenuClose()
    end
end

function VREMenuOpen()
	if open then return end
    open = true

    gui.HideGameUI()
    LocalPlayer():ConCommand("hideconsole")

    vreMenu = vgui.Create( "DPanel" )
    vreMenu:SetPos( 0, 0 )
    vreMenu:SetSize( 600, 650 )
    function vreMenu:GetSize()
        return 450,310
    end


    -- Menu code starts here


    -- It is possible to add custom buttons externally using the VREMenuGetGrid hook.

    --Here's an example:

    --[[hook.Add( "VREMenuGetGrid", "VREMenu_YourCustomHookName", function(grid)
            local button1 = vgui.Create("DButton")
            grid:AddItem(button1)
            button1:SetText("Custom Button")
            button1:SetSize(120, 60)
            button1:SetTextColor(Color(255, 255, 255))
            button1.DoClick = function()
                print("test")
            end

            function button1:Paint(w, h)
                draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
            end
        end)]]--
     
    local grid = vgui.Create( "DGrid", vreMenu )
    grid:SetPos( 10, 30 )
    grid:SetCols( 4 )
    grid:SetColWide( 150 )
    grid:SetRowHeight( 100 )
    
    --Default buttons

    if hook.Run("PlayerNoClip", LocalPlayer(), true) == true then
        local button1 = vgui.Create( "DButton" )
        button1:SetText( "Noclip" )
        button1:SetSize( 120, 60 )
        button1:SetTextColor(Color(255, 255, 255))
        grid:AddItem( button1 )
        button1.DoClick = function()
            LocalPlayer():ConCommand("noclip")
        end

        function button1:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
        end
    end


    local button2 = vgui.Create( "DButton" )
    button2:SetText( "Undo" )
    button2:SetSize( 120, 60 )
    button2:SetTextColor(Color(255, 255, 255))
    grid:AddItem( button2 )
    button2.DoClick = function()
        LocalPlayer():ConCommand("gmod_undo")
    end

    function button2:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end


    local button3 = vgui.Create( "DButton" )
    button3:SetText( "Playermodels" )
    button3:SetSize( 120, 60 )
    button3:SetTextColor(Color(255, 255, 255))
    grid:AddItem(button3)
    button3.DoClick = function()
        VREMenuClose()
        VREModelMenuToggle()
    end

    function button3:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end


    local button4 = vgui.Create( "DButton" )
    button4:SetText( "VRMod Panel" )
    button4:SetSize( 120, 60 )
    button4:SetTextColor(Color(255, 255, 255))
    grid:AddItem(button4)
    button4.DoClick = function()
        VREMenuClose()
        VREVRModMenuToggle()
    end

    function button4:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end


    local button5 = vgui.Create( "DButton" )
    button5:SetText( "VR Keybinds" )
    button5:SetSize( 120, 60 )
    button5:SetTextColor(Color(255, 255, 255))
    grid:AddItem(button5)
    button5.DoClick = function()
        VREMenuClose()
        VREKeybindMenuToggle()
    end

    function button5:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end

    if game.SinglePlayer() or (LocalPlayer():IsSuperAdmin() and LocalPlayer():Ping() < 25) or (ULib and ULib.ucl.query( LocalPlayer(), "ulx map" ) == true) then
        local button6 = vgui.Create( "DButton" )
        button6:SetText( "Map Browser" )
        button6:SetSize( 120, 60 )
        button6:SetTextColor(Color(255, 255, 255))
        grid:AddItem(button6)
        button6.DoClick = function()
            VREMenuClose()
            VREHUD_DisplayMessage("<clr:255,176,0>Please wait...", 0, "generic")
            timer.Simple(1, function() VREMapBrowserToggle() end)
        end

        function button6:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
        end
    end

    local button7 = vgui.Create("DButton")
    button7:SetText("Settings")
    button7:SetSize(120, 60)
    button7:SetTextColor(Color(255, 255, 255))
    grid:AddItem(button7)
    button7.DoClick = function()
        VREMenuClose()
        VRESettingsMenuToggle()
    end

    function button7:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
    end


    hook.Run( "VREMenuGetGrid", grid)

    -- Menu code ends here
	
	local ply = LocalPlayer()
	
	local renderCount = 0
	
	local tmp = Angle(0,g_VR.tracking.hmd.ang.yaw-90,45) --Forward() = right, Right() = back, Up() = up (relative to panel, panel forward is looking at top of panel from middle of panel, up is normal)
	local pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
    --uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc
    
    if vre_menuguiattachment:GetInt("vre_ui_attachtohand") == 1 then
        VRUtilMenuOpen("vremenu", 600, 310, vreMenu, 1, Vector(10,6,13), Angle(0,-90,50), 0.03, true, function()
            vreMenu:Remove()
            vreMenu = nil
            hook.Remove("PreRender","vre_rendermenu")
            open = false
        end)
    else
        VRUtilMenuOpen("vremenu", 600, 310, vreMenu, 4, pos, ang, 0.03, true, function()
            vreMenu:Remove()
            vreMenu = nil
            hook.Remove("PreRender","vre_rendermenu")
            open = false
        end)
    end
	
	hook.Add("PreRender","vre_rendermenu",function()
	
        function vreMenu:Paint( w, h )
            surface.SetDrawColor( Color( 51, 51, 51, 200 ) )
            surface.DrawRect(0,0,w,h)
        end
			
		VRUtilMenuRenderPanel("vremenu")
    end)
    
    hook.Add("VREMenuOnOpen")
	
end

function VREMenuClose()
	VRUtilMenuClose("vremenu")
end

concommand.Add( "vre_menu", function( ply, cmd, args )
    if g_VR.net[ply:SteamID()] then
        VREMenuToggle()
    end
end)