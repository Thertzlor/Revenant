local rv = ... ---@type Revenant
local huge = math.huge

--[[=============================================================]] --
---@class DisplayDefinitionOptions
---ffff
---@field text string
---@field origin string
---@field maxLines number
---@field maxPages number
---@field paginationLine boolean
---@field singleTruncate boolean
---@field truncateEnd string
---@field indentation boolean
--[[=============================================================]] --
---A class that manages text displayed on the LCD display.
---@class DisplayTextDefinition:BaseClass
---@field pages string[][]
local DisplayTextDefinition = rv.baseClass:new()

---@protected
---Construct a new DisplayTextDefinition
---@param option DisplayDefinitionOptions The options object to intitialize the class with.
function DisplayTextDefinition:constructor(option)
    self.initialized = false
    self.origin = option.origin
    self.text = option.text
    self.maxPages = option.maxPages or huge
    self.maxLines = option.maxLines ---@private
    self.paginationLine = option.paginationLine ---@private
    self.truncateEnd = option.truncateEnd or '...'
    self.currentPage = 1
    self.singlePage = true ---@private
    self.totalPages = 1 ---@private
    local lines = option.singleTruncate and { rv.lcd:truncate(self.text, self.truncateEnd) } or rv.lcd:stringBreaker(self.text, option.indentation)
    self.pages = { {} }
    if #lines > self.maxLines then
        self.singlePage = false
        for i = 1, #lines do local line = lines[i]
            local pageTab = self.pages[#self.pages]
            pageTab[#pageTab + 1] = line
            if i % (self.maxLines - 1) == 0 or self.maxLines == 1 then
                if #self.pages == self.maxPages then
                    pageTab[#pageTab] = rv.lcd:truncate(pageTab[#pageTab], self.truncateEnd, lines[i + 1] ~= nil)
                    break
                else self.pages[#self.pages + 1] = {} end
            end
        end
        self.totalPages = #self.pages
        if self.totalPages ~= 1 then
            for i = 1, self.totalPages do local page = self.pages[i]
                page[#page + 1] = "[" .. i .. "/" .. #self.pages .. "]"
            end
        end
    else self.pages = { lines } end
end

---Close and reset the display to the first page.
function DisplayTextDefinition:reset()
    rv.threading:taskAbort('_anon_display_' .. self.origin)
    self.currentPage = 1
    self.initialized = false
end

---Get the contents of the current page
---@return string[] An array of text lines on the page
function DisplayTextDefinition:getCurrentPage()
    if not self.initialized then
        rv:put(self.text)
        self.initialized = true
    end
    if self.singlePage then return self.pages[1] end
    return self.pages[self.currentPage]
end

---Iterate to the next page of the DisplayDefinition
---@return string[]
function DisplayTextDefinition:nextPage()
    if self.singlePage then return self.pages[1] end
    self.currentPage = self.currentPage + 1
    if self.currentPage > self.totalPages then self.currentPage = 1 end
    return self.pages[self.currentPage]
end

---Go to a specific page without returning it.
---If the number is bigger than the number of pages
--- on the DisplayDefinition, the last page will be selected.
---@param num number the page number to navigate to.
function DisplayTextDefinition:toPage(num)
    if self.singlePage then return end
    if num > self.totalPages then self.currentPage = self.totalPages
    else self.currentPage = num end
end

return DisplayTextDefinition
