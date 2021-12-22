local tl = ...---@type MainLibObject
--=============================================================
---@class DisplayDefinitionOptions
---@field text string
---@field origin string
---@field maxLines number
---@field paginationLine boolean
---@field forceTruncate boolean
---@field truncateEnd string
--=============================================================
---@class DisplayTextDefinition:BaseClass
---@field pages (string[])[]
local DisplayTextDefinition = tl.baseClass:new()

---@protected
---@param option DisplayDefinitionOptions
function DisplayTextDefinition:constructor(option)
    self.initialized = false
    self.origin = option.origin
    self.text = option.text
    self.maxLines = option.maxLines ---@private
    self.paginationLine = option.paginationLine ---@private
    self.currentPage = 1
    self.singlePage = true ---@private
    self.totalPages = 1 ---@private
    local lines = option.forceTruncate and { tl.lcd:truncate(self.text, option.truncateEnd or '...') } or tl.lcd:stringBreaker(self.text)
    self.pages = { {} }
    if #lines > self.maxLines then
        self.singlePage = false
        for i = 1, #lines do local line = lines[i]
            local pageTab = self.pages[#self.pages]
            pageTab[#pageTab + 1] = line
            if i % (self.maxLines-1) == 0 then self.pages[#self.pages + 1] = {} end
        end
        self.totalPages = #self.pages
        for i = 1, self.totalPages do local page = self.pages[i]
            page[#page + 1] = "[" .. i .. "/" .. #self.pages .. "]"
        end
    else self.pages = { lines } end
end

function DisplayTextDefinition:reset()
    self.currentPage = 1
    self.initialized = false
end

function DisplayTextDefinition:getCurrentPage()
    if not self.initialized then
        tl:put(self.text)
        self.initialized = true
    end
    if self.singlePage then return self.pages[1] end
    return self.pages[self.currentPage]
end

function DisplayTextDefinition:nextPage()
    if self.singlePage then return self.pages[1] end
    self.currentPage = self.currentPage + 1
    if self.currentPage > self.totalPages then self.currentPage = 1 end
    return self.pages[self.currentPage]
end

---@param num number
function DisplayTextDefinition:toPage(num)
    if self.singlePage then return end
    if num > self.totalPages then self.currentPage = self.totalPages
    else self.currentPage = num end
end

return DisplayTextDefinition