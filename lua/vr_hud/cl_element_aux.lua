local ELEM = VRHUD.ElementCreate()

ELEM.height = VRHUD.BOX_HEIGHT/4
ELEM.padding = 8
ELEM.barHeight = ELEM.height-(ELEM.padding*2)

function ELEM:ShouldEnable(ply)

	local gamemode = engine.ActiveGamemode()
	if ply:Alive() then
		if gamemode == "lambda" then
			return true
		end
	end
	return false

end

function ELEM:Draw(x,y,ply)

	local colorBG = table.Copy(VRHUD.COLOR_BACKGROUND)
	colorBG.a=colorBG.a*self.a
	local colorFG = table.Copy(VRHUD.COLOR)
	colorFG.a=colorFG.a*self.a

	local gamemode = engine.ActiveGamemode()
	local suitPercent = 1
	if gamemode == "lambda" then
		suitPercent = ply:GetLambdaSuitPower()/100
	end
	draw.RoundedBox(VRHUD.BOX_RADIUS,x,y,VRHUD.BOX_WIDTH,self.height,colorBG)
	surface.SetDrawColor(colorFG)
	surface.DrawRect(x+ELEM.padding,y+ELEM.padding,(VRHUD.BOX_WIDTH-(ELEM.padding*2))*suitPercent,ELEM.barHeight)

end
