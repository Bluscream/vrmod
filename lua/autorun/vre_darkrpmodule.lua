if CLIENT and engine.ActiveGamemode() == "darkrp" then
    
    hook.Add( "VREMenuGetGrid", "VREMenu_AddDarkRPModule", function(grid)
        local button1 = vgui.Create("DButton")
        grid:AddItem(button1)
        button1:SetText("DarkRP Menu")
        button1:SetSize(120, 60)
        button1:SetTextColor(Color(255, 255, 255))
        button1.DoClick = function()
            VRUtilMenuClose("vremenu")
            VREF4MenuToggle()
        end

        function button1:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(51,51,51))
        end
    end)


    function VREF4MenuToggle()
        if !open then
            VREF4MenuOpen()
        else
            VRUtilMenuClose("vremenu_darkrpmenu")
        end
    end
        
        
    function VREF4MenuOpen()
        if open then return end
        open = true
        DarkRP.openF4Menu()
        
		local vreDarkRPF4Panel = DarkRP.getF4MenuPanel()
        vreDarkRPF4Panel:SetPos( 0, 0 )
        vreDarkRPF4Panel:SetSize( 600, 310 )
        vreDarkRPF4Panel:Show()
		
    
        -- Menu code starts here
    
    
        local backbutton = vgui.Create("DButton", vreDarkRPF4Panel)
    
        backbutton:SetText("<---")
        backbutton:SetSize(60, 30)
        backbutton:SetPos(540, 0)
        backbutton:SetTextColor(Color(255, 255, 255))
        backbutton.DoClick = function()
            VRUtilMenuClose("vremenu_darkrpmenu")
            VREMenuOpen()
        end
    
    
        function backbutton:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(0,122,204))
        end
    

        local ply = LocalPlayer()
    
        local renderCount = 0
         
        local tmp = Angle(0,g_VR.tracking.hmd.ang.yaw-90,45) --Forward() = right, Right() = back, Up() = up (relative to panel, panel forward is looking at top of panel from middle of panel, up is normal)
        local pos, ang = WorldToLocal( g_VR.tracking.pose_righthand.pos + tmp:Forward()*-9 + tmp:Right()*-11 + tmp:Up()*-7, tmp, g_VR.origin, g_VR.originAngle)
        --uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc
        VRUtilMenuOpen("vremenu_darkrpmenu", 600, 310, nil, 4, pos, ang, 0.03, true, function()
            hook.Remove("PreRender","vre_renderdrpmenu")
            open = false
            DarkRP.closeF4Menu()
            vreDarkRPF4Panel:Remove()
            vreDarkRPF4Panel = nil
        end)
        
        hook.Add("PreRender","vre_renderdrpmenu",function()
            if VRUtilIsMenuOpen("chat") or VRUtilIsMenuOpen("vremenu") then
                VRUtilMenuClose("vremenu_darkrpmenu")
            elseif IsValid(vreDarkRPF4Panel) then
                VRUtilMenuRenderStart("vremenu_darkrpmenu")
                vreDarkRPF4Panel:PaintManual()
                VRUtilMenuRenderEnd()
                VRUtilMenuRenderPanel("vremenu_darkrpmenu")
            end
        end)
    end
end