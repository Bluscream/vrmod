if SERVER then return end

local open = false

function VREModelMenuToggle()
    if !open then
        VREVRModelMenuOpen()
    else
        VRUtilMenuClose("vremenu_pm")
    end
end


function VREVRModelMenuOpen()
	if open then return end
	open = true
    local selectedmodel = LocalPlayer():GetModel() or "models/player/kleiner.mdl"
    local selectedmodelname = player_manager.TranslateToPlayerModelName(selectedmodel) or "Choose a model"

    local vrePMSelection = vgui.Create( "DPanel" )
    vrePMSelection:SetPos( 0, 0 )
    vrePMSelection:SetSize( 600, 310 )
    function vrePMSelection:GetSize()
        return 450,310
    end

    -- Menu code starts here

    local fullpmlist = player_manager.AllValidModels()
    
    local gridscroller = vgui.Create( "DScrollPanel", vrePMSelection )
    gridscroller:Dock(FILL)
    
    local settingsgrid = vgui.Create( "DIconLayout", gridscroller )
    settingsgrid:Dock(FILL)
    settingsgrid:SetSpaceY(3)
    settingsgrid:SetSpaceX(3)
    

    local modelpreview = vgui.Create( "DModelPanel", vrePMSelection )
    modelpreview:Dock(RIGHT)
    modelpreview:SetSize(260, 100)
    modelpreview:SetModel( selectedmodel )


    for pmname, pmmodel in SortedPairs(fullpmlist) do
        local previewicon = vgui.Create("SpawnIcon", settingsgrid)
        previewicon:SetModel(pmmodel) 
        previewicon:SetSize(35, 35)
        settingsgrid:Add(previewicon)
        previewicon.DoClick = function()
            selectedmodel = pmmodel
            selectedmodelname = pmname
            modelpreview:SetModel( selectedmodel )
        end
    end

    -- local preview = vgui.Create("SpawnIcon", vrePMSelection)
    -- preview:SetModel(selectedmodel) 
    -- preview:SetSize( 200, 200 )
    -- backbutton:SetPos(260, 270)

    local modelname = vgui.Create("DPanel", modelpreview)
    modelname:SetSize(100, 100)
    modelname:Dock(TOP)
    modelname:DockPadding(40, 0, 0, 0)

    function modelname:Paint(w, h)
        draw.DrawText(selectedmodelname, "DermaLarge", 0, 0, Color(255,255,255,255), TEXT_ALIGN_CENTRE)
    end

    local applymodel = vgui.Create("DButton", modelpreview)
    applymodel:SetText("Select Playermodel")
    applymodel:Dock(BOTTOM)
    applymodel:DockPadding(0, 0, 0, 10)
    applymodel:SetTextColor(Color(255, 255, 255))
    applymodel.DoClick = function()
        LocalPlayer():ConCommand("cl_playermodel "..selectedmodelname)
    end

    function applymodel:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0,122,204))
    end

    local backbutton = vgui.Create("DButton", vrePMSelection)

    backbutton:SetText("<---")
    backbutton:SetSize(60, 30)
    backbutton:SetPos(540, 0)
    backbutton:SetTextColor(Color(255, 255, 255))
    backbutton.DoClick = function()
        VRUtilMenuClose("vremenu_pm")
        VREMenuToggle()
    end

    function backbutton:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0,122,204))
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

    VRUtilMenuOpen("vremenu_pm", 600, 310, vrePMSelection, mode, pos, ang, 0.03, true, function()
        vrePMSelection:Remove()
        vrePMSelection = nil
         hook.Remove("PreRender","vrcam_rendermodelmenu")
		 open = false
	end)
	
    hook.Add("PreRender","vrcam_rendermodelmenu",function()
        if VRUtilIsMenuOpen("chat") or VRUtilIsMenuOpen("vremenu") then
            VRUtilMenuClose("vremenu_pm")
        elseif IsValid(vrePMSelection) then
            function vrePMSelection:Paint( w, h )
                surface.SetDrawColor( Color( 51, 51, 51, 235 ) )
                surface.DrawRect(0,0,w,h)
            end
            VRUtilMenuRenderPanel("vremenu_pm")
        end
    end)

end

