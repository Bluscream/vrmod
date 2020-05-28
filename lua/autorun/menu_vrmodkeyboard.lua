if SERVER then return end

local open = false


function VREKeyboardToggle()
    if !open then
        VREKeyboardOpen()
    else
        VRUtilMenuClose("vremenu_vrmod")
    end
end


function VREKeyboardOpen()
	if open then return end
	open = true

    -- Keyboard UI (Almost entirely stolen from Catse. Thanks, by the way.)

    local keyboardPanel = vgui.Create( "DPanel" )
    keyboardPanel:SetPos( 0, 0 )
    keyboardPanel:SetSize( 555, 255 )
    function keyboardPanel:Paint( w, h )
        surface.SetDrawColor( Color( 0, 0, 0, 128 ) )
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
        surface.DrawOutlinedRect(0,0,w,h)
    end
    local lowerCase = "1234567890\1\nqwertyuiop\nasdfghjkl\2\n\3zxcvbnm,.\3\n "
    local upperCase = "!\"#$%&/=?-\1\nQWERTYUIOP\nASDFGHJKL\2\n\3ZXCVBNM;:\3\n "
    local selectedCase = lowerCase
    local selectedKey = ""
    local keys = {}
    local function updateKeyboard()
        for i = 1,#selectedCase do
            if selectedCase[i] == "\n" then continue end
            keys[i]:SetText(selectedCase[i] == "\1" and "Back" or selectedCase[i] == "\2" and "Enter" or selectedCase[i] == "\3" and "Shift" or selectedCase[i] )
        end
    end
    local x,y = 5,5
    for i = 1,#selectedCase do
        if selectedCase[i] == "\n" then
            y = y + 50
            x = (y==205) and 127 or (y==155) and 5 or 5 + ((y-5)/50*15)
            continue
        end
        keys[i] = vgui.Create( "DLabel", keyboardPanel )
        local key = keys[i]
        key:SetPos(x,y)
        key:SetSize(selectedCase[i] == " " and 300 or selectedCase[i] == "\2" and 65 or 45,45)
        key:SetTextColor(Color(255,255,255,255))
        key:SetFont((selectedCase[i] == "\1" or selectedCase[i] == "\2" or selectedCase[i] == "\3") and "HudSelectionText" or "vrmod_Verdana37")
        key:SetText(selectedCase[i] == "\1" and "Back" or selectedCase[i] == "\2" and "Enter" or selectedCase[i] == "\3" and "Shift" or selectedCase[i] )
        key:SetMouseInputEnabled(true)
        key:SetContentAlignment(5)
        key.OnMousePressed = function()
            if key:GetText() == "Back" then
                --print("back")
            elseif key:GetText() == "Enter" then
                --print("enter")
            elseif key:GetText() == "Shift" then
                --print("shift")
            else
                selectedKey = key:GetText()
                hook.Run("VREKeyboardOnPress", selectedKey or "")
            end
        end
        function key:Paint(w,h)
            surface.SetDrawColor( Color( 0, 0, 0, 200 ) )
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor( Color( 128, 128, 128, 255 ) )
            surface.DrawOutlinedRect(0,0,w,h)
        end
        x = x + 50
    end
    VRUtilMenuOpen("vrmod_keyboard", 555, 255, keyboardPanel, 1, Vector(4,6,5.5), Angle(0,-90,10), 0.03, true, function()
        keyboardPanel:Remove()
        keyboardPanel = nil
        open = false
        -- if chatPanel then
        --     chatPanel.msgbar:SetVisible(false)
        --     chatPanel.chatbox:SetSize(450,280)
        --     chatPanel.button3:SetColor(Color(255,0,0,255))
        -- end
    end)
	
end
