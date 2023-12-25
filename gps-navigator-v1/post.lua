function onDraw()
	local jitter = math.random(0, 255)
	screen.setColor(jitter, jitter, jitter, property.getNumber("screen jitter"))
	screen.drawRectF(0, 0, screen.getWidth(), screen.getHeight())
end
