if CLIENT then

	vre_binding_key_chathold = CreateClientConVar("vre_key_chat_held", "100", true, false)
	vre_binding_runcmds = CreateClientConVar("vre_binds_concommands", "0", true, false)
	local menuPressTime = 0
	local chatholdcmd = input.LookupKeyBinding(vre_binding_key_chathold:GetInt("vre_key_chat_held", 100))
	
	function VRExtSimulateKey(vrinput)
		local key = GetConVar( "vre_key_"..vrinput )
		local cmd = input.LookupKeyBinding(key:GetInt("vre_key_"..vrinput, 100))
		if vrinput != "" then
			if vre_binding_runcmds:GetInt("vre_binds_concommands", 0) == 1 then
				LocalPlayer():ConCommand(cmd)
			end
			net.Start("vre_numpadbind")
			net.WriteInt(key:GetInt("vre_key_"..vrinput, 100), 9)
			net.SendToServer()
		end
	end
	
	hook.Add( "PopulateToolMenu", "VRKeybinds_populatetoolmenu", function()
		spawnmenu.AddToolMenuOption( "Utilities", "Virtual Reality", "vrkeybinds", "VR Keybinds", "", "", function( panel )
			local chatheldlabel = vgui.Create( "DLabel", panel )
			panel:AddItem(chatheldlabel)
			chatheldlabel:SetTextColor(Color(0, 0, 0))
			chatheldlabel:SetText("Button: boolean_chat (Long press)")
			
			local chatheldkey = vgui.Create("DBinder", vrcamPanel)
			panel:AddItem(chatheldkey)
			chatheldkey:SetValue(vre_binding_key_chathold:GetInt("vre_key_chat_held", 100))
			
			local chatheldruncmds = vgui.Create("DCheckBoxLabel", panel)
			panel:AddItem(chatheldruncmds)
			chatheldruncmds:SetTextColor(Color(0, 0, 0))
			chatheldruncmds:SetText("Run console commands bound to this key?")
			chatheldruncmds:SetValue(vre_binding_runcmds)
			chatheldruncmds:SetConVar("vre_binds_concommands")
			
			local chatheldbindlist = vgui.Create( "DLabel", panel )
			panel:AddItem(chatheldbindlist)
			chatheldbindlist:SetText(" ")
			
			function chatheldruncmds:OnChange(newval)
				if newval == true then
					chatholdcmd = input.LookupKeyBinding(vre_binding_key_chathold:GetInt("vre_key_chat_held", 100))
					local returnedcmd = chatholdcmd or "No commands"
					chatheldbindlist:SetText("Runs: "..returnedcmd)
				else
					chatheldbindlist:SetText(" ")
				end
			end
			
			function chatheldkey:OnChange( num )
				vre_binding_key_chathold:SetInt( num )
				if vre_binding_runcmds:GetInt("vre_key_chat_held", 0) == 1 then
					chatholdcmd = input.LookupKeyBinding(vre_binding_key_chathold:GetInt("vre_key_chat_held", 100))
					local returnedcmd = chatholdcmd or "No commands"
					chatheldbindlist:SetText("Runs: "..returnedcmd)
				end
			end
		end)
	end)
	
	
	hook.Add("VRUtilEventInput","vrextentionseventinput",function( action, pressed)
    if action == "boolean_chat" and pressed then
        menuPressTime = SysTime()
        if VRUtilIsMenuOpen("vrcameramenu") then --remove this in future
            VRUtilMenuClose("vrcameramenu")
        end
		
    else
        if action == "boolean_chat" and menuPressTime - SysTime() < -1 then
            if VRUtilIsMenuOpen("chat") then
                VRUtilMenuClose("chat")
            end
            VRExtSimulateKey("chat_held") 
        end
    end
    return
end)
	
elseif SERVER then
	util.AddNetworkString("vre_numpadbind")
	net.Receive( "vre_numpadbind", function( len, ply )
		local key = net.ReadInt(9)
		numpad.Toggle(ply, key )
	end)
end