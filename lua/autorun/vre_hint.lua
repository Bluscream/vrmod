if CLIENT then
	local vre_hidevrhint = CreateClientConVar("vre_hidehint", "0", true, false)

	function GetHasVRModule()
		local moduleLoaded = false
		if file.Exists("lua/bin/gmcl_vrmod_win32.dll", "GAME") and !game.SinglePlayer() and vre_hidevrhint:GetInt() != 1 then
			if pcall(function() require("vrmod") end) and vre_hidevrhint:GetInt("vre_hidehint") != 1 then
				LocalPlayer():ChatPrint("This server supports VRMod! To enter VR, type vrmod_start in console.")
				hook.Remove("SetupMove", "VREGetHasVR")
			end
		end
	end
	
	hook.Add("SetupMove", "VREGetHasVR", GetHasVRModule)
end