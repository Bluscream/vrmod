local ELEM = VRHUD.ElementCreate()

ELEM.height = 48
ELEM.textOffset = 4


function ELEM:ShouldEnable(ply)

	return engine.ActiveGamemode() == "terrortown"

end

function ELEM:Draw(x,y,ply)

	local colorBG = table.Copy(VRHUD.COLOR_BACKGROUND)
	colorBG.a=colorBG.a*self.a
	local colorFG = table.Copy(VRHUD.COLOR)
	colorFG.a=colorFG.a*self.a

	local roundstate_string = {
		[ROUND_WAIT] = "round_wait",
		[ROUND_PREP] = "round_prep",
		[ROUND_POST] = "round_post"
	};

	local stateText
	if GAMEMODE.round_state == ROUND_ACTIVE then
		if ply:GetDetective() then
			stateText =  LANG.GetTranslation("detective")
		elseif ply:GetTraitor() then
			stateText = LANG.GetTranslation("traitor")
		else
			stateText = LANG.GetTranslation("innocent")
		end
	else
		stateText = LANG.GetTranslation(roundstate_string[GAMEMODE.round_state])
	end

	local timeText = util.SimpleTime(math.max(0, GetGlobalFloat("ttt_round_end", 0) - CurTime()), "%02i:%02i")

	draw.RoundedBox(VRHUD.BOX_RADIUS,x,y,VRHUD.BOX_WIDTH,self.height,colorBG)
	draw.DrawText( stateText, "VRHUD_Small", x+VRHUD.BOX_PADDING, y+self.textOffset, colorFG)
	draw.DrawText( timeText, "VRHUD_Small", x+VRHUD.BOX_WIDTH-VRHUD.BOX_PADDING, y+self.textOffset, colorFG, TEXT_ALIGN_RIGHT)

end
