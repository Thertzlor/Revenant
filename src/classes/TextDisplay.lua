local rv = ... ---@type Revenant
local huge = math.huge

--[[=============================================================]] --
---@class DisplayDefinitionOptions #Object to construct a TextDisplay from
---@field text string #The text shown on the display
---@field origin? string #The name or ID of the macro associated with the text display
---@field maxLines number #Maximum number of text lines, more will be truncated
---@field maxPages number #Maximum number of pages, more will be truncated
---@field paginationLine boolean #reserve a single line for pagination?
---@field singleTruncate boolean #Use full height if there's only a single page (I think?)
---@field truncateEnd string #The string used to signify truncation, "..." by default
---@field indentation boolean #Should the text respect indentation?
--[[=============================================================]] --
---@class TextDisplay:BaseClass #A class that manages text displayed on the LCD display.
---@field pages string[][] #An array of string arrays, representing lines on each page.
local TextDisplay = rv.baseClass:new()

---@protected
---Construct a new TextDisplay
---@param option DisplayDefinitionOptions #The options object to intitialize the class with.
function TextDisplay:constructor(option)
    self.initialized = false
    self.origin = option.origin
    self.text = option.text
    self.maxPages = option.maxPages or huge ---Maximum pages for display
    self.maxLines = option.maxLines ---@private Maximum lines per page
    self.paginationLine = option.paginationLine ---@private Stuff
    self.truncateEnd = option.truncateEnd or '...' ---String for truncation
    self.currentPage = 1 ---Currently active page
    self.singlePage = true ---@private only one page in display
    self.totalPages = 1 ---@private Number of pages in display
    local lines = option.singleTruncate and { rv.lcd:truncate(self.text, self.truncateEnd) } or rv.lcd:stringBreaker(self.text, option.indentation) --Breaking the text into lines of the right length
    self.pages = { {} }
    if #lines > self.maxLines then --Here we handle splitting the text into multiple pages if neccesary
        self.singlePage = false
        for i = 1, #lines do local line = lines[i]
            local pageList = self.pages[#self.pages]
            pageList[#pageList + 1] = line
            if i % (self.maxLines - 1) == 0 or self.maxLines == 1 then --truncating any pages over the limit
                if #self.pages == self.maxPages then
                    pageList[#pageList] = rv.lcd:truncate(pageList[#pageList], self.truncateEnd, lines[i + 1] ~= nil)
                    break
                else self.pages[#self.pages + 1] = {} end
            end
        end
        self.totalPages = #self.pages
        if self.totalPages ~= 1 then --Adding paginations to every page
            for i = 1, self.totalPages do local page = self.pages[i]
                page[#page + 1] = "[" .. i .. "/" .. #self.pages .. "]"
            end
        end
    else self.pages = { lines } end
end

---Close and reset the display to the first page.
function TextDisplay:reset()
    rv.threading:taskAbort('_anon_display_' .. self.origin)
    self.currentPage = 1
    self.initialized = false
end

---Get the contents of the current page
---@return string[] #An array of text lines on the page
function TextDisplay:getCurrentPage()
    if not self.initialized then
        rv:put(self.text) --outputting the text to console if it's the first display trigger
        self.initialized = true
    end
    if self.singlePage then return self.pages[1] end --No next page on single page text
    return self.pages[self.currentPage]
end

---Iterate to the next page of the DisplayDefinition
---@return string[] #all lines of the next page
function TextDisplay:nextPage()
    if self.singlePage then return self.pages[1] end --No next page on single page text
    self.currentPage = self.currentPage + 1
    if self.currentPage > self.totalPages then self.currentPage = 1 end
    return self.pages[self.currentPage]
end

---Go to a specific page without returning it.
---If the number is bigger than the number of pages
---on the DisplayDefinition, the last page will be selected.
---@param num number #the page number to navigate to.
function TextDisplay:toPage(num)
    if self.singlePage then return end --No next page on single page text
    if num > self.totalPages then self.currentPage = self.totalPages
    else self.currentPage = num end
end

return TextDisplay