local tl = ...---@type MainLibObject
local match, sub, type, pairs, tonumber, OutputLCDMessage, ClearLCD, min, max, rep, gsub, running = string.match, string.sub, type, pairs, tonumber, OutputLCDMessage, ClearLCD, math.min, math.max, string.rep, string.gsub, coroutine.running
local cachedString, paginatorState
local DisplayDefinition ---@type DisplayTextDefinition

local stringRay = {
    ["0"] = { "" },
    ["1.1"] = { "i", "l", "'", "!", ":", ",", ";", ".", "|", "I", "f", " ", "j", "*" },
    ["2"] = { '`', '´', '"', "[", "]", ")", "(", "{", "}", "\\", "/", "-", "r", "t" },
    ["2.2"] = { "?", "$", "^", "z", "y", "x", "c", "v" },
    ["3"] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "+", ">", "<", "=", "#", "_", "s", "J", "L" },
    ["3.1"] = { "Z", "q", "e", "u", "o", "p", "a", "d", "g", "h", "k", "b", "n", '~' },
    ["4"] = { "X", "w", "E", "T", "R", "U", "P", "A", "S", "D", "F", "G", "H", "K", "Y", "C", "V", "B", "N", "&" },
    ["5"] = { "Q", "O", "m", "M" },
    ["5.8"] = { "W", "@", "%" },
}

---@class DisplayStateModule:BaseClass Manages the state of the LCD display
---@field lengthMap table<string,number>
---@field currentDisplay DisplayTextDefinition
---@field defaultDisplay DisplayTextDefinition
---@field displayIndex table<string,DisplayTextDefinition>
local DisplayStateModule = tl.baseClass:new()
function DisplayStateModule:constructor()
    self.displayIndex = {}
    self.lengthMap = {}
    for k, v in pairs(stringRay) do
        for i = 1, #v do self.lengthMap[v[i]] = tonumber(k) end
    end
end

---@param str string
function DisplayStateModule:getLength(str)
    if #str == 0 then return 0 end
    local l = 0
    for i = 1, #str do l = (l + ((self.lengthMap[str[i]] or 2.7) * 0.9)) end
    return l
end

---@param str string
function DisplayStateModule:fillLine(str)
    local reps = 1
    local endString = str
    while self:getLength(rep(str, reps)) <= tl.profile.config.LCDLineLength do
        endString = rep(str, reps)
        reps = reps + 1
    end
    return endString
end

---@param str string
---@param ending string
---@param force boolean
function DisplayStateModule:truncate(str, ending, force)
    local maxLineLength = tl.profile.config.LCDLineLength or 50
    ending = ending or '...'
    local strLength = self:getLength(str)
    if self:getLength(str .. (force and ending or '')) > maxLineLength then return str .. (force and ending or '')
    else
        while self:getLength(str .. ending) < maxLineLength do str = sub(str, 1, -1) end
        return str .. ending
    end
end

local function _trim(s)
    return gsub(gsub(s, "^%s+", ""), "%s+$", "")
end

---@param str string
---@param keepIndent boolean
function DisplayStateModule:stringBreaker(str, keepIndent)
    local simpleBreaks = {} ---@type number[]
    local whiteSpaceBreaks = {} ---@type number[]
    local hyphenationBreaks = {} ---@type number[]
    local currentLineLength = 0
    local config = tl.profile.config
    local int = 0
    local maxLineLength = config.LCDLineLength or 50
    local whiteRadius = 3
    local currentIndent = 0
    local tempIndent = 0
    local lineRay = {} ---@type string[]
    local i = 1
    while i < #str do
        local s = sub(str, i, i)
        local addition = (self.lengthMap[s] or 2.7) * 0.9
        currentLineLength = currentLineLength + addition
        if s == "\n" then
            simpleBreaks[i] = true
            currentLineLength = 0
            if keepIndent then
                currentIndent = #(match(sub(str, i), ' *') or '')
                currentLineLength = self.lengthMap[' '] * currentIndent
            end
        elseif match(s, "%s") and currentLineLength <= 0 and not keepIndent then
            currentLineLength = currentLineLength - addition
        elseif currentLineLength > maxLineLength then
            if match(s, "%s") or match(sub(str, i + 1, i + 1), "%s") then simpleBreaks[i] = true
            else
                local foundWhite = false
                for n = -1, whiteRadius do
                    if match(sub(str, i - n, i - n), "%s") then
                        foundWhite = true
                        whiteSpaceBreaks[i - n] = true
                        --i = i - n
                        break
                    end
                end
                if not foundWhite then
                    local currentCopy = currentLineLength
                    local hyphVal = self.lengthMap['-']
                    local hyphenOffset = 0
                    while currentCopy > maxLineLength - hyphVal do
                        currentCopy = currentCopy - (self.lengthMap[sub(str, i - hyphenOffset, i - hyphenOffset)] or 0)
                        hyphenOffset = hyphenOffset + 1
                    end
                    hyphenationBreaks[i - hyphenOffset] = true
                    i = i + hyphenOffset
                end
            end
            currentLineLength = 0
        end
        i = i + 1
        if running() then tl.coroutines:wait(int) end
    end
    local lastStop = 1
    local indentation = 0
    for i = 1, #str do
        if simpleBreaks[i] then
            if keepIndent then
                if hyphenationBreaks[lastStop - 1] then
                    lineRay[#lineRay + 1] = rep(' ', indentation) .. sub(str, lastStop, i)
                else
                    indentation = #(match((lineRay[#lineRay] or ''), ' *') or '')
                    lineRay[#lineRay + 1] = sub(str, lastStop, i - 1)
                end
            else lineRay[#lineRay + 1] = _trim(sub(str, lastStop, i)) end
            lastStop = i + 1
        elseif whiteSpaceBreaks[i] then
            lineRay[#lineRay + 1] = (keepIndent and rep(' ', indentation) or '') .. _trim(sub(str, lastStop, i))
            lastStop = i + 1
        elseif hyphenationBreaks[i] then
            lineRay[#lineRay + 1] = _trim(sub(str, lastStop, i)) .. '-'
            lastStop = i + 1
        end
        if i == #str then
            local lastLine = sub(str, lastStop, i)
            local lastIndent = simpleBreaks[lastStop - 1] and #(match((lastLine or ''), ' *') or '') or indentation
            lineRay[#lineRay + 1] = (keepIndent and rep(' ', lastIndent) or '') .. _trim(lastLine)
        end
    end
    tl.tbl:prettyTab(lineRay)
    return lineRay
end

---Outputs messages to the Logitech LCD display
---Includes formatters for paginating and splitting.
---@private
---@param msg string
---@param dur number
function DisplayStateModule:putLCD(msg, dur) --Outputs messages to lua log
    local deviceState, config = tl.profile.deviceState, tl.profile.config
end

---@param text string
---@param id string
---@param maxPages number
---@param maxLines number
---@param indent boolean
---@param display boolean
---@return void
function DisplayStateModule:parseToDisplayDefinition(text, id, maxPages, maxLines, indent, display)
    tl.coroutines:taskRun(nil, nil, nil, self._asyncParse, self, text, id, maxPages, maxLines, indent, display)
end

---@param text string
---@param id string
---@param maxPages number
---@param maxLines number
---@param indent boolean
---@param show boolean
---@return void
---@private
function DisplayStateModule:_asyncParse(text, id, maxPages, maxLines, indent, show)
    local config = tl.profile.config
    local maxLines = min((config.LCDLines or 1), (maxLines or config.LCDLines))
    if config.keepNameOnLCD then maxLines = maxLines - 1 end
    if config.LCDSeparator then maxLines = maxLines - 1 end
    if config.LCDClearLastLine then maxLines = maxLines - 1 end
    if not DisplayDefinition then DisplayDefinition = tl:classImport('DisplayTextDefinition') end
    local display = DisplayDefinition:new({
        text = text,
        origin = id,
        maxLines = max(maxLines, 1),
        maxPages = maxPages,
        indentation = indent,
        paginationLine = (config.LCDClearLastLine and config.LCDLastLinePagination)
    })
    self.displayIndex[id] = display
    if show then self:displayOnLCD(display) end
end

--TODO:Probably doesn't need to be async
---@param def string|DisplayTextDefinition
---@param page number
---@param duration number
---@private
function DisplayStateModule:_asyncDisplay(def, page, duration)
    local config = tl.profile.config
    duration = duration or -1
    local newDisplay = type(def) == "string" and self.displayIndex[def] or def ---@type DisplayTextDefinition
    if not newDisplay then return end --TODO:Do we need an error message here?
    if not self.currentDisplay or self.currentDisplay.origin ~= newDisplay.origin then
        if self.currentDisplay then self.currentDisplay:reset() end
        self.currentDisplay = newDisplay
    else self.currentDisplay:nextPage() end
    if page then self.currentDisplay:toPage(page) end
    local displayPage = self.currentDisplay:getCurrentPage()
    local lineCount = #displayPage
    ClearLCD()
    if config.keepNameOnLCD then
        lineCount = lineCount + 1
        OutputLCDMessage(tl.profile.name, duration)
    end
    if config.LCDSeparator then
        local sep = type(config.LCDSeparator) == "string" and config.LCDSeparator or "="        lineCount = lineCount + 1
        OutputLCDMessage(self:fillLine(sep), duration)
    end
    for i = 1, #displayPage do
        OutputLCDMessage(displayPage[i], duration)
    end
    if lineCount < (config.LCDLines or 1) - 1 then
        OutputLCDMessage('', duration)
    end
    if duration ~= -1 then
        tl.coroutines:wait(duration)
        if self.displayIndex['_profileDefault'] then
            self:_asyncDisplay('_profileDefault')
        end
    end
end

---@param def string|DisplayTextDefinition
---@param page number
function DisplayStateModule:displayOnLCD(def, page, duration)
    self:async(self._asyncDisplay, self, def, page, duration)
end

---@param advance boolean
function DisplayStateModule:refresh(advance)
    if advance then self.currentDisplay:nextPage() end
    self:displayOnLCD(self.currentDisplay, self.currentDisplay.currentPage)
end

return DisplayStateModule