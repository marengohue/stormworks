local SIGNAL_IN_N__X = 3
local SIGNAL_IN_N__Y = 4
local SIGNAL_IN_B__IS_TOUCH = 1

local SIGNAL_OUT_N__CMD = 1
local SIGNAL_OUT_N__ARG_A = 2
local SIGNAL_OUT_N__ARG_B = 3

local CMD_OPCODE_NOP = 0
local CMD_ARG_NIL = 0
local CMD_OPCODE_FREENAV = 1
local CMD_OPCODE_SEND_COORD = 2
local CMD_OPCODE_SEND_LOCODE = 2

local UI_GRID_SIZE_PX = 8

function gotoMenuCb(name)
   uiState.menu = {}
   uiState.currentMenu = name
   if ui.menus[name].init ~= nil then
      ui.menus[name].init()
   end
end

function gotoMenu(name)
   return function()
      gotoMenuCb(name)
   end
end

function add(number)
   return function()
      uiState.menu.val = uiState.menu.val .. number
   end
end

function remove()
   return function()
      local valueLen = string.len(uiState.menu.val)
      if valueLen == 1 then
         gotoMenuCb("main")
      else
         uiState.menu.val =
            string.sub(uiState.menu.val, 1, -2)
      end
   end
end

ui = {
    menus = {
        main = {
            components = {
                { t = "txt", text = "=NAV=", w = 4 },
                {
                   t = "btn", text = "FREE", y = 1, w = 4,
                   act = gotoMenu("freeNav")
                },
                {
                   t = "btn", text = "SET", y = 2, w = 4,
                   act = gotoMenu("keypad")
                },
                {
                   t = "btn", text = "LOCOD", y = 3, w = 4,
                   act = gotoMenu("locode")
                }
            }
        },
        freeNav = {
           init = function()
              sendOp(CMD_OPCODE_FREENAV)
           end,
           components = {
              { t = "banner", text = "FREE", y = 1, w = 4 },
              { t = "banner", text = "NAV", y = 2, w = 4 },
               {
                  t = "btn", text = "<-", y = 3, x = 2, w = 2,
                  act = gotoMenu("main")
               },
           }
        },
        locode = {
            components = {
               { t = "banner", text = "LOCODE", y = 1, w = 4 },
               { t = "banner", text = "TBD", y = 2, w = 4 },
               {
                  t = "btn", text = "<-", y = 3, x = 2, w = 2,
                  act = gotoMenu("main")
               },
            }
        },
        keypad = {
           init = function()
              uiState.menu.val = "+"
           end,
           components = {
               {
                   t = "txt", w = 3,
                   text = function()
                      return uiState.menu.val
                   end
               },
               { t = "btn", text = "1", y = 1, act = add(1) },
               { t = "btn", text = "2", x = 1, y = 1, act = add(2) },
               { t = "btn", text = "3", x = 2, y = 1, act = add(3) },
               { t = "btn", text = "X", x = 3, y = 1, act = remove() },
               { t = "btn", text = "4", y = 2, act = add(4) },
               { t = "btn", text = "5", x = 1, y = 2, act = add(5) },
               { t = "btn", text = "6", x = 2, y = 2, act = add(6) },
               {
                  t = "btn",
                  x = 3, y = 2,
                  text = function()
                     if uiState.menu.val == "+" then
                         return "-"
                     elseif uiState.menu.val == "-" then
                        return "+"
                     else
                        return "0"
                     end
                  end,
                  act = function()
                     if uiState.menu.val == "+" then
                         uiState.menu.val = "-"
                     elseif uiState.menu.val == "-" then
                        uiState.menu.val = "+"
                     else
                        uiState.menu.val
                           = uiState.menu.val .. "0"
                     end
                  end
               },
               { t = "btn", text = "7", y = 3, act = add(7)},
               { t = "btn", text = "8", x = 1, y = 3, act = add(8) },
               { t = "btn", text = "9", x = 2, y = 3, act = add(9) },
               {
                  t = "btn", text = "V", x = 3, y = 3,
                  act = function()
                     if uiState.menu.x == nil then
                        uiState.menu.x
                           = tonumber(uiState.menu.val)
                        uiState.menu.val = "+"
                     else
                        sendOp(
                           CMD_OPCODE_SEND_COORD,
                           uiState.menu.x,
                           tonumber(uiState.menu.val)
                        )
                        gotoMenuCb("main")
                     end
                  end
               },
            }
        }
    }
}

uiState = {
   currentMenu = "main",
   colors = {},
   menu = {}
}

touchCtl = {}

function sendOp(op, a, b)
    output.setNumber(SIGNAL_OUT_N__CMD, op or CMD_OPCODE_NOP)
    output.setNumber(SIGNAL_OUT_N__ARG_A, a or CMD_ARG_NIL)
    output.setNumber(SIGNAL_OUT_N__ARG_B, b or CMD_ARG_NIL)
end

function clearScreen()
    useBgColor()
    screen.drawClear()
end

function useFgColor(color)
   local c = property.getNumber("foreground brightness")
   screen.setColor(c, c, c)
end

function useBgColor(color)
   local c = property.getNumber("background brightness")
   screen.setColor(c, c, c)
end

function useHlColor(color)
   local c = property.getNumber("highlight brightness")
   screen.setColor(c, c, c)
end

function isOver(component)
   local x, y, w, h = getBounds(component)
   return touchCtl.x > x and touchCtl.x < (x + w - 1)
      and touchCtl.y > y and touchCtl.y < (y + h - 1)
end

function getBounds(component)
   return
      (component.x or 0) * UI_GRID_SIZE_PX,
      (component.y or 0) * UI_GRID_SIZE_PX,
      (component.w or 1) * UI_GRID_SIZE_PX,
      (component.h or 1) * UI_GRID_SIZE_PX
end

function renderComponent(c)
    local x, y, w, h = getBounds(c)
    if c.t == "txt" then
       useFgColor()
       screen.drawText(x + 2, y + 1, getText(c))
    elseif c.t == "btn" then
       if touchCtl.isTouch and isOver(c) then
          useFgColor()
          screen.drawRectF(x + 1, y, w - 2, h - 1)
          useHlColor()
       else
          useHlColor()
          screen.drawRectF(x + 1, y, w - 2, h - 1)
          useFgColor()
       end
       screen.drawText(x + 2, y + 1, getText(c))
    elseif c.t == "banner" then
       useFgColor()
       screen.drawTextBox(x, y, w, h, getText(c), 0, 0)
    end
end

function getText(component)
   if type(component.text) == "function" then
       return component.text()
   else
       return component.text
   end
end

function renderMenu()
   local currentMenuDefn = ui.menus[uiState.currentMenu]
   for _, component in ipairs(currentMenuDefn.components) do
      renderComponent(component)
   end
end

function onTick()
   touchCtl.isRelease = touchCtl.isTouch
      and not input.getBool(SIGNAL_IN_B__IS_TOUCH)
   touchCtl.isTouch = input.getBool(SIGNAL_IN_B__IS_TOUCH)
   if touchCtl.isTouch then
       touchCtl.x = input.getNumber(SIGNAL_IN_N__X)
       touchCtl.y = input.getNumber(SIGNAL_IN_N__Y)
   end

   if touchCtl.isRelease then
       local currentMenuDefn = ui.menus[uiState.currentMenu]
       for _, component in ipairs(currentMenuDefn.components) do
           if isOver(component) and component.act ~= nil then
               component.act()
           end
       end
    else
        sendOp(CMD_OPCODE_NOP)
    end
end

function onDraw()
    clearScreen()
    renderMenu(width)
end
