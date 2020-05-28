local ELEM = VRHUD.ElementCreate()

ELEM.height = VRHUD.BOX_HEIGHT

function ELEM:ShouldEnable(ply)

	return ply:Armor() > 0 and ply:Alive()

end

function ELEM:Draw(x,y,ply)

	local colorBG = table.Copy(VRHUD.COLOR_BACKGROUND)
	colorBG.a=colorBG.a*self.a
	local colorFG = table.Copy(VRHUD.COLOR)
	colorFG.a=colorFG.a*self.a

	draw.RoundedBox(VRHUD.BOX_RADIUS,x,y,VRHUD.BOX_WIDTH,self.height,colorBG)
	draw.DrawText( "*", "VRHUD", x+VRHUD.BOX_PADDING, y, colorFG)
	draw.DrawText( tostring(ply:Armor()), "VRHUD", x+VRHUD.BOX_WIDTH-VRHUD.BOX_PADDING, y, colorFG, TEXT_ALIGN_RIGHT)

end
