local rv = ... ---@type Revenant
local MonitorDefinition = rv.baseClass:new() ---@class MonitorDefinition:BaseClass
local type, tonumber, sub, assert = type, tonumber, string.sub, assert

--[[=============================================================]] --
---@alias Coordinates {[1]:number,[2]:number} first Position: X value, second position: Y value.
--[[=============================================================]] --
---@class DeskoptDefinition The Option for Screen construction provided in the options
---@field win {h:number,w:number} Screen resolution in normal pixels
---@field topLeft? Coordinates **Logitech** coordinates for the top left corner of the screen
--[[=============================================================]] --
---@class RectDefinition
---@field size? number|string|{[1]:string|number,[2]:string|number} The size of the rectangle, if one number height will equal width
---@field s? number|string|{[1]:string,[2]:string}|Coordinates Shorthand for "size"
---@field offset? number|string|{[1]:string,[2]:string}|Coordinates Offset from bottom right, if one number offset height will equal offset width
---@field o? number|string|{[1]:string,[2]:string}|Coordinates Shorthand for "offset"
---@field screen? number The screen the rectangle originates on
---@field exclude? boolean Rectangle refers to everything outside of itself
--[[=============================================================]] --
---@class Rect a rectangle, defining its area by corner coordinates.
---@field cr Coordinates Coordinates of the right corner
---@field cl Coordinates Coordinates of the left corner
--[[=============================================================]] --
---@protected
---@param option Coordinates|DeskoptDefinition Definition to initialize Monitor definition with.
function MonitorDefinition:constructor(option)
    self.w = option[1]
    self.h = option[2]
    self.win = option.win
    self.ratio = (option[1] / option[2])
    self.offsetX = (option.topLeft and option.topLeft[1]) or 0
    self.offsetY = (option.topLeft and option.topLeft[2]) or 0
    self.singleW = { self:getWinPixel(1, 1, true) } ---@type Coordinates
    self.singleL = { 0, 0 }
end

function MonitorDefinition:setAbsoluteSingle()
    self.singleL = { rv.mouseMonitorUtils:virtualTransform(self.singleW[1], self.singleW[2]) }
end

---Receives an absolute virtual **windows** units and outputs whether they are sloacted within the monitor's boundaries
---@param x number
---@param y number
function MonitorDefinition:contains(x, y)
    return (x >= self.offsetX) and (x <= self.offsetX + self.win.w)
        and (y >= self.offsetY) and (y <= self.offsetY + self.win.h)
end

---comment
---@param def RectDefinition
---@return Rect
function MonitorDefinition:getRect(def)
    local offset = def.offset or def.o or 0
    local size = def.size or def.s or "100%"
    if type(size) ~= "table" then size = { size, size }
    elseif size[2] == nil then size[2] = size[1] end
    if type(offset) ~= "table" then offset = { offset, offset }
    elseif offset[2] == nil then offset[2] = offset[1] end
    local oX, oY = self:convertToPixel(offset[1], offset[2])
    local sX, sY = self:convertToPixel(size[1], size[2])
    local absetX, absetY = self:getWinPixel(oX, oY)
    local absizeX, absizeY = self:getWinPixel(oX + sX, oY + sY)
    return { cl = { absetX, absetY }, cr = { absizeX, absizeY } }
end

---Converts non-standard sizes like negative pixels and percentages to absolute normal pixels
---@param x number|string
---@param y number|string
---@param noWrap? boolean
function MonitorDefinition:convertToPixel(x, y, noWrap)
    local result = { 0, 0 }
    for i = 1, 2 do local target = ({ { x, self.w }, { y, self.h } })[i]
        local t1 = target[1]
        if type(t1) == "string" then
            local coNum = assert(sub(t1, -1) == "%" and tonumber(sub(t1, 1, -2), 10), '"' .. t1 .. '" is not a valid coordinate value')
            t1 = target[2] * (coNum / 100)
        end
        if (not noWrap) and target[1] < 0 then t1 = target[2] + t1 end
        result[i] = t1
    end
    return result[1], result[2]
end

---Converts actual pixels or percentage values into *absolute* virtual **windows** units
---@param x number
---@param y number
---@param relative? boolean
function MonitorDefinition:getWinPixel(x, y, relative)
    local newX = rv.utils.linearTransform(x, 0, self.w, 0, self.win.w)
    local newY = rv.utils.linearTransform(y, 0, self.h, 0, self.win.h)
    if relative then return newX, newY end
    return self.offsetX + newX, self.offsetY + newY
end

return MonitorDefinition
