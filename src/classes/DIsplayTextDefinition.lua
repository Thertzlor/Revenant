local tl = ...---@type MainLibObject
local DisplayTextDefinition = tl.baseClass:new()---@class MonitorDefinition:BaseClass

local type, tonumber, error, sub = type, tonumber, error, string.sub

---@protected
---@param option {text:string, maxLines:number, paginationLine:boolean}
function DisplayTextDefinition:constructor(option)
    self.text = option.text
    self.maxLines = option.maxLines
    self.paginationLine = option.paginationLine
    self.currentPage = 1
    self.singlePage = true
    self.lines = tl.lcd:stringbreaker(self.text)
    self.pages = {} ---@type (string[])[]
    if #self.lines > #self.maxLines then
        self.singlePage = false

    else self.pages = {self.lines} end
    self.pages = 1
end

function DisplayTextDefinition:reset()
    self.currentPage = 1
end

function DisplayTextDefinition:getCurrentPage()
  return self.pages[self.currentPage]
end

function DisplayTextDefinition:nextPage()
    self.currentPage = self.currentPage +1
    if self.currentPage > self.pages then self.currentPage = 1 end
    return self.pages[self.currentPage]
end

---@param num number
function DisplayTextDefinition:toPage(num)
    if num > self.pages then self.currentPage = self.pages
    else self.currentPage = num end
end

return DisplayTextDefinition