TOOL.Category = "Virtual Reality"
TOOL.Name = "VR Teleport"

if CLIENT then
	
	language.Add("tool.vr_teleport.name", "VR Teleport")
	language.Add("tool.vr_teleport.desc", " ")
	language.Add("tool.vr_teleport.0", " ")

	net.Receive("vr_teleport_net_deploy",function(len, ply)
		if GetConVar("vrutil_laserpointer"):GetBool() then
			return
		end
		local mat = Material("cable/redlaser")
		hook.Add("PostDrawTranslucentRenderables","vr_teleport_laser",function(vm, ply, wep)
			if g_VR ~= nil and g_VR.viewModelMuzzle and not g_VR.menuFocus then
				render.SetMaterial(mat)
				render.DrawBeam(g_VR.viewModelMuzzle.Pos, g_VR.viewModelMuzzle.Pos + g_VR.viewModelMuzzle.Ang:Forward()*10000, 1, 0, 1, Color(255,255,255,255))
			end
		end)
	end)
	
	net.Receive("vr_teleport_net_holster",function(len, ply)
		hook.Remove("PostDrawTranslucentRenderables","vr_teleport_laser")
	end)
	
else

	util.AddNetworkString("vr_teleport_net_deploy")
	util.AddNetworkString("vr_teleport_net_holster")

	function TOOL:LeftClick(trace)
		local ply = self:GetOwner()
		if g_VR[ply:SteamID()] ~= nil and (hook.Run("PlayerNoClip", ply, true) == true or ULib and ULib.ucl.query( ply, "ulx noclip" ) == true) then
			self:GetOwner():SetPos(trace.HitPos)
		end
		return true
	end

	function TOOL:Deploy()
		net.Start("vr_teleport_net_deploy") net.Send(self:GetOwner())
		return true
	end

	function TOOL:Holster()
		net.Start("vr_teleport_net_holster") net.Send(self:GetOwner())
		return true
	end
	
end