VRHUD = {}
VRHUD.STATE_ENABLED = 0
VRHUD.STATE_DISABLED = 1
VRHUD.STATE_FADEIN = 2
VRHUD.STATE_FADEOUT = 3
VRHUD.COLOR_BACKGROUND = Color(0,0,0,150)
VRHUD.COLOR = Color(255,255,0,150)
VRHUD.BOX_HEIGHT = 128
VRHUD.BOX_WIDTH = VRHUD.BOX_HEIGHT*2.5
VRHUD.BOX_RADIUS = 8
VRHUD.BOX_PADDING = 8
VRHUD.BOX_MARGIN = 8
VRHUD.OFFSET = Vector(1,1.5,0)
VRHUD.ANGLE = Angle(1,-8,-90)
VRHUD.ANIM_LENGTH = 0.25
VRHUD.SPEED = 250
VRHUD.height = 0
VRHUD.x = 0
VRHUD.y = 0
VRHUD.dy = 0
VRHUD.lastTime = 0
VRHUD.Elements = {}

surface.CreateFont("VRHUD",{
	font = "HalfLife2",
	size = 128,
	antialias = true
})

surface.CreateFont("VRHUD_Small",{
	font = "Trebuchet",
	size = 48,
	antialias = true
})

function VRHUD.ElementCreate()
	local tbl = {}
	tbl.state = VRHUD.STATE_DISABLED
	tbl.animStart = 0
	tbl.y = 0
	tbl.a = 0
	tbl.sy = 0
	tbl.sa = 0
	tbl.dy = 0
	tbl.da = 0
	tbl.height = 0
	table.insert(VRHUD.Elements,tbl)
	return tbl
end

function VRHUD.CalculateSize()

	VRHUD.height = 0
	for i,elem in ipairs(VRHUD.Elements) do
		if elem.state ~= VRHUD.STATE_DISABLED and elem.state ~= VRHUD.STATE_FADEOUT then
			elem.dy = VRHUD.height
			VRHUD.height = VRHUD.height+elem.height+VRHUD.BOX_MARGIN
		end
	end
	VRHUD.height = VRHUD.height-VRHUD.BOX_MARGIN
	VRHUD.dy = -(VRHUD.height/2)

end

function VRHUD.ElementEnable(elem)
	local curTime = CurTime()
	elem.state = VRHUD.STATE_FADEIN
	elem.sy = elem.y
	elem.sa = elem.a
	elem.da = 1
	elem.animStart = curTime
end

function VRHUD.ElementDisable(elem)
	local curTime = CurTime()
	elem.state = VRHUD.STATE_FADEOUT
	elem.sy = elem.y
	elem.sa = elem.a
	elem.dy = 0
	elem.da = 0
	elem.animStart = curTime
end

function VRHUD.Update(ply)

	local curTime = CurTime()
	local delta = curTime-VRHUD.lastTime
	VRHUD.y = math.Approach(VRHUD.y,VRHUD.dy,delta*VRHUD.SPEED)
	local elemStateChanged = false
	for i,elem in ipairs(VRHUD.Elements) do
		if elem.state == VRHUD.STATE_FADEIN or elem.state == VRHUD.STATE_FADEOUT or elem.state == VRHUD.STATE_MOVE then
			if curTime > elem.animStart+VRHUD.ANIM_LENGTH then
				if elem.state == VRHUD.STATE_FADEIN then elem.state = VRHUD.STATE_ENABLED
				elseif elem.state == VRHUD.STATE_FADEOUT then	elem.state = VRHUD.STATE_DISABLED
				end
				elem.y = elem.dy
				elem.a = elem.da
			else
				local p = (curTime-elem.animStart)/VRHUD.ANIM_LENGTH
				elem.y = Lerp(p,elem.sy,elem.dy)
				elem.a = Lerp(p,elem.sa,elem.da)
			end
		elseif elem.state == VRHUD.STATE_DISABLED then
			if elem:ShouldEnable(ply) then
				VRHUD.ElementEnable(elem)
				elemStateChanged = true
			end
		elseif elem.state == VRHUD.STATE_ENABLED then
			if not elem:ShouldEnable(ply) then
				VRHUD.ElementDisable(elem)
				elemStateChanged = true
			end
		end
	end
	if elemStateChanged then
		for i,v in ipairs(VRHUD.Elements) do
			if v ~= elem and (v.state == VRHUD.STATE_ENABLED or v.state == VRHUD.STATE_FADEIN) then
				v.state = VRHUD.STATE_FADEIN
				v.sy = v.y
				v.sa = v.a
				v.animStart = curTime
			end
		end
		VRHUD.CalculateSize()
	end
	VRHUD.lastTime = curTime

end

-- function VRHUD.Draw2D()
-- 	local ply = LocalPlayer()
-- 	VRHUD.Update(ply)
-- 	for i,elem in ipairs(VRHUD.Elements) do
-- 		if elem.state ~= VRHUD.STATE_DISABLED then
-- 			elem:Draw(VRHUD.x,(ScrH()/2)+VRHUD.y+elem.y,ply)
-- 		end
-- 	end
-- end

-- function VRHUD.Draw(depth,skybox)
-- 	if depth or skybox then return end
-- 	local ply = LocalPlayer()
-- 	if not g_VR.active then return end
-- 	local leftHandBoneID = ply:LookupBone("ValveBiped.Bip01_L_Hand")
-- 	if type(leftHandBoneID) ~= "number" then return end
-- 	local boneMatrix = ply:GetBoneMatrix(leftHandBoneID)
-- 	if type(boneMatrix) ~= "VMatrix" then return end
-- 	local wristWorldPos = boneMatrix:GetTranslation()
-- 	local wristWorldAng = boneMatrix:GetAngles()
-- 	local pos, ang = LocalToWorld(VRHUD.OFFSET,VRHUD.ANGLE,wristWorldPos,wristWorldAng)
-- 	VRHUD.Update(ply)
-- 	cam.Start3D2D(pos,ang,0.01)
-- 		for i,elem in ipairs(VRHUD.Elements) do
-- 			if elem.state ~= VRHUD.STATE_DISABLED then
-- 				elem:Draw(VRHUD.x,VRHUD.y+elem.y,ply)
-- 			end
-- 		end
-- 	cam.End3D2D()
-- end

function VRHUD.Draw(ply)
	if ply ~= LocalPlayer() or not g_VR.active then return end
	local leftHandBoneID = ply:LookupBone("ValveBiped.Bip01_L_Hand")
	if type(leftHandBoneID) ~= "number" then return end
	local boneMatrix = ply:GetBoneMatrix(leftHandBoneID)
	if type(boneMatrix) ~= "VMatrix" then return end
	local wristWorldPos = boneMatrix:GetTranslation()
	local wristWorldAng = boneMatrix:GetAngles()
	local pos, ang = LocalToWorld(VRHUD.OFFSET,VRHUD.ANGLE,wristWorldPos,wristWorldAng)
	VRHUD.Update(ply)
	cam.Start3D2D(pos,ang,0.01)
		for i,elem in ipairs(VRHUD.Elements) do
			if elem.state ~= VRHUD.STATE_DISABLED then
				elem:Draw(VRHUD.x,VRHUD.y+elem.y,ply)
			end
		end
	cam.End3D2D()
end

include("vr_hud/cl_element_health.lua")
include("vr_hud/cl_element_armor.lua")
include("vr_hud/cl_element_aux.lua")
include("vr_hud/cl_element_ttt.lua")

-- hook.Add("PostDrawTranslucentRenderables","VRHUD_Draw",VRHUD.Draw)
hook.Add("PostPlayerDraw","VRHUD_Draw",VRHUD.Draw)
-- hook.Add("HUDPaint","VRHUD_Draw",VRHUD.Draw2D)
