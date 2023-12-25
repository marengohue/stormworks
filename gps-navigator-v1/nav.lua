local SIGNAL_IN_N__CMD = 1
local SIGNAL_IN_N__ARG_A = 2
local SIGNAL_IN_N__ARG_B = 3
local SIGNAL_IN_N__GPS_X = 4
local SIGNAL_IN_N__GPS_Y = 5
local SIGNAL_IN_N__COMPASS = 6

local CMD_OPCODE_NOP = 0
local CMD_OPCODE_FREENAV = 1
local CMD_OPCODE_SEND_COORD = 2
local CMD_OPCODE_SEND_LOCODE = 2

local MI_TO_M = 1852

modeCtl = {
   currentMode = "idle",
   target = nil
}

navState = {}

function clearScreen()
    useBgColor()
    screen.drawClear()
end

function useFgColor()
   local c = property.getNumber("foreground brightness")
   screen.setColor(c, c, c)
end

function useBgColor()
   local c = property.getNumber("background brightness")
   screen.setColor(c, c, c)
end

function useHlColor()
   local c = property.getNumber("highlight brightness")
   screen.setColor(c, c, c)
end

function onTick()
   local inOpCode = input.getNumber(SIGNAL_IN_N__CMD)
   local inArgA = input.getNumber(SIGNAL_IN_N__ARG_A)
   local inArgB = input.getNumber(SIGNAL_IN_N__ARG_B)
   navState.x = input.getNumber(SIGNAL_IN_N__GPS_X)
   navState.y = input.getNumber(SIGNAL_IN_N__GPS_Y)
   navState.phi = input.getNumber(SIGNAL_IN_N__COMPASS)
   
   if inOpCode == CMD_OPCODE_FREENAV then
      modeCtl.currentMode = "compass"
      modeCtl.target = nil
   elseif inOpCode == CMD_OPCODE_SEND_COORD then
      modeCtl.currentMode = "compass"
      modeCtl.target = { x = inArgA, y = inArgB }
   end
end

function renderCompassArrow(pos, height, label)
   screen.drawLine(16 + pos, 16, 16 + pos, 16 + height)
   if label ~= nil then
      screen.drawText(14 + pos, 20, label)
   end
end

function getPolarToTarget()
   local dx = modeCtl.target.x - navState.x
   local dy = modeCtl.target.y - navState.y
   local theta = math.atan(dy / dx)
   if dx < 0 then
      theta = theta + math.pi
   end

   return
      math.sqrt(dx * dx + dy * dy),
      math.fmod(theta + 2 * math.pi, 2 * math.pi)
end

function formatDistance(meters)
   if meters > MI_TO_M then
      return string.format("%.2fmi", meters / MI_TO_M)
   else
      return string.format("%.0fm", meters)
   end
end

function renderTargetArrow()
   local distance, theta = getPolarToTarget()
   local relativeAngle = theta / 2 / math.pi - 0.5
   local tgtPos1 = (navState.phi - relativeAngle) * 48
   local tgtPos2 = (navState.phi - 1 - relativeAngle) * 48
   screen.setColor(0, 255, 0)
   screen.drawLine(16 + tgtPos1, 16, 16 + tgtPos1, 13)
   screen.drawLine(16 + tgtPos2, 16, 16 + tgtPos2, 13)
   useFgColor()
   screen.drawTextBox(
      1, 1, screen.getWidth() - 2, 7,
      formatDistance(distance),
      0, 0
   )
end

function renderHorizon()
   useHlColor()
   screen.drawLine(0, 16, 32, 16)
   screen.drawLine(16, 16, 16, 12)
end

function renderCompass()
   renderHorizon()
   if modeCtl.target ~= nil then
      renderTargetArrow()
   end
   
   useFgColor()

   -- Compass sensor readings:
   -- +-0.0 == WEST
   -- 0.25 == SOUTH
   -- +- 0.5 == EAST
   -- -0.25 == NORTH     
   local northArrow1 = (navState.phi + 0.25) * 48
   local northArrow2 = (navState.phi - 0.75) * 48
   local nwArrow = (navState.phi + 0.125) * 48
   local neArrow1 = (navState.phi + 0.375) * 48
   local neArrow2 = (navState.phi - 0.625) * 48

   local eastArrow1 = (navState.phi - 0.5) * 48
   local eastArrow2 = (navState.phi + 0.5) * 48
   
   local southArrow1 = (navState.phi - 0.25) * 48
   local southArrow2 = (navState.phi + 0.75) * 48
   local seArrow1 = (navState.phi - 0.375) * 48
   local seArrow2 = (navState.phi + 0.625) * 48
   local swArrow = (navState.phi - 0.125) * 48
   
   local westArrow = navState.phi * 48  

   renderCompassArrow(eastArrow1, 2, "E")
   renderCompassArrow(eastArrow2, 2, "E")

   renderCompassArrow(southArrow1, 2, "S")
   renderCompassArrow(southArrow2, 2, "S")
   renderCompassArrow(seArrow1, 1)
   renderCompassArrow(seArrow2, 1)
   renderCompassArrow(swArrow, 1)
   
   renderCompassArrow(westArrow, 2, "W")

   renderCompassArrow(nwArrow, 1)
   renderCompassArrow(neArrow1, 1)
   renderCompassArrow(neArrow2, 1)

   screen.setColor(255, 0, 0)
   renderCompassArrow(northArrow1, 3, "N")
   renderCompassArrow(northArrow2, 3, "N")
end

function onDraw()
   clearScreen()
   useFgColor()
   if modeCtl.currentMode == "compass" then
      renderCompass()
   end
end
