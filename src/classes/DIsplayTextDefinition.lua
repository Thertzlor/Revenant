local tl = ...---@type MainLibObject

---@class DisplayTextDefinition:BaseClass
---@field pages (string[])[]
local DisplayTextDefinition = tl.baseClass:new()

local floor = math.floor

---@protected
---@param option {text:string, maxLines:number, paginationLine:boolean}
function DisplayTextDefinition:constructor(option)
    self.text = option.text
    self.maxLines = option.maxLines ---@private
    self.paginationLine = option.paginationLine ---@private
    self.currentPage = 1
    self.singlePage = true ---@private
    self.totalPages = 1 ---@private
    local lines = tl.lcd:stringBreaker(self.text)
    self.pages = { {} }
    if #lines > self.maxLines then
        local actualLines = self.paginationLine and self.maxLines - 1 or self.maxLines
        self.singlePage = false
        self.pages = floor(#lines / self.maxLines)
        for i = 1, #lines do local line = lines[i]
            if i % actualLines == 0 then self.pages[#self.pages + 1] = {} end
            local pageTab = self.pages[#self.pages]
            pageTab[#pageTab + 1] = line
        end
        self.totalPages = #self.pages
        for i = 1, self.totalPages do local page = self.pages[i]
            page[#page + 1] = "[" .. i .. "/" .. #self.pages .. "]"
        end
    else self.pages = { self.lines } end
    tl.tbl:prettyTab(self.pages,"Hurp")
end

function DisplayTextDefinition:reset()
    self.currentPage = 1
end

function DisplayTextDefinition:getCurrentPage()
    return self.pages[self.currentPage]
end

function DisplayTextDefinition:nextPage()
    self.currentPage = self.currentPage + 1
    if self.currentPage > self.totalPages then self.currentPage = 1 end
    return self.pages[self.currentPage]
end

---@param num number
function DisplayTextDefinition:toPage(num)
    if num > self.totalPages then self.currentPage = self.totalPages
    else self.currentPage = num end
end

return DisplayTextDefinition