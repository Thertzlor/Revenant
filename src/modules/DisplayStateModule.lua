local rv = ... ---@type Revenant
local match, sub, type, pairs, tonumber, OutputLCDMessage, ClearLCD, min, max, rep, gsub, running, concat = string.match, string.sub, type, pairs, tonumber, OutputLCDMessage, ClearLCD, math.min, math.max, string.rep, string.gsub, coroutine.running, table.concat
local TextDisplay ---@type TextDisplay
local displayIndex = {} ---@type table<string,TextDisplay|string>
local textIndex = {} ---@type table<string,string>
local displayRedirect = {} ---@type table<string,string>
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
} ---@type table<string,string[]>
---@class DisplayStateModule:BaseClass Manages the state of the LCD display
---@field lengthMap table<string,number>
---@field currentDisplay TextDisplay
---@field defaultDisplay TextDisplay
---@field activeDisplays string[]
local DisplayStateModule = rv.baseClass:new()
function DisplayStateModule:constructor()
    self.lengthMap = {}
    for k, v in pairs(stringRay) do
        for i = 1, #v do self.lengthMap[v[i]] = tonumber(k) end
    end
end

---Estimate how long a string is visually by adding up the widths of its characters.
---@param str string The string to check
function DisplayStateModule:getLength(str)
    if #str == 0 then return 0 end
    local l = 0
    for i = 1, #str do l = (l + ((self.lengthMap[str[i]] or 2.7) * 0.9)) end
    return l
end

---Fill a line with one or more characters
---@param str string The "filler" string to repeat until the line is full.
function DisplayStateModule:fillLine(str)
    local reps = 1
    local endString = str
    while self:getLength(rep(str, reps)) <= rv.profile.config.LCDLineLength do
        endString = rep(str, reps)
        reps = reps + 1
    end
    return endString
end

---@param str string
---@param ending string
---@param force? boolean
function DisplayStateModule:truncate(str, ending, force)
    local maxLineLength = rv.profile.config.LCDLineLength or 50
    ending = ending or '...'
    if self:getLength(str .. (force and ending or '')) > maxLineLength then return str .. (force and ending or '')
    else
        while self:getLength(str .. ending) < maxLineLength do str = sub(str, 1, -1) end
        return str .. ending
    end
end

local function _trim(s)
    local subbed = gsub(gsub(s, "^%s+", ""), "%s+$", "")
    return subbed
end

---Break a string into an array of strings of the same (visual) length
---@param str string The string to break
---@param keepIndent? boolean Keep indentation by not removing whitespace at start of line
---@return string[] The array of lines making up the string
function DisplayStateModule:stringBreaker(str, keepIndent)
    local simpleBreaks = {} ---@type boolean[]
    local whiteSpaceBreaks = {} ---@type boolean[]
    local hyphenationBreaks = {} ---@type boolean[]
    local currentLineLength = 0
    local config = rv.profile.config
    local int = 0
    local maxLineLength = config.LCDLineLength or 50
    local whiteRadius = 3
    local currentIndent = 0
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
            if match(s, "%s") then simpleBreaks[i] = true
            else
                local foundWhite = false
                for n = -1, whiteRadius do
                    if match(sub(str, i - n, i - n), "%s") then
                        foundWhite = true
                        whiteSpaceBreaks[i - n] = true
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
        if running() then rv.threading:wait(int) end
    end
    local lastStop = 1
    local indentation = 0
    for n = 1, #str do
        if simpleBreaks[n] then
            if keepIndent then
                if hyphenationBreaks[lastStop - 1] then
                    lineRay[#lineRay + 1] = concat { rep(' ', indentation), sub(str, lastStop, n) }
                else
                    indentation = #(match((lineRay[#lineRay] or ''), ' *') or '')
                    lineRay[#lineRay + 1] = rv.str:unbreak(sub(str, lastStop, n - 1), "")
                end
            else lineRay[#lineRay + 1] = _trim(sub(str, lastStop, n)) end
            lastStop = n
        elseif whiteSpaceBreaks[n] then
            lineRay[#lineRay + 1] = concat { (keepIndent and rep(' ', indentation) or ''), _trim(rv.str:unbreak(sub(str, lastStop, n), "")) }
            lastStop = n
        elseif hyphenationBreaks[n] then
            lineRay[#lineRay + 1] = concat { _trim(sub(str, lastStop, n)), '-' }
            lastStop = n + 1
        end
        if n == #str then
            local lastLine = sub(str, lastStop, n)
            lineRay[#lineRay + 1] = (keepIndent and function(r) return r end or _trim)(rv.str:unbreak(lastLine, ""))
        end
    end
    return lineRay
end

---@param text string
---@param id string
---@param maxPages? number
---@param maxLines? number
---@param indent? boolean
---@param display? boolean
function DisplayStateModule:parseToTextDisplay(text, id, maxPages, maxLines, indent, display)
    if displayIndex[id] then return end
    local prev = textIndex[text]
    if prev then
        displayRedirect[id] = prev
        if display then self:displayOnLCD(prev, nil, rv.profile.config.LCDMessageDuration) end
        return
    end
    displayIndex[text] = id
    rv.threading:taskRun(nil, nil, nil, self._asyncParse, self, text, id, (maxPages or false), maxLines or false, indent or false, display or false)
end

---@param text string
---@param id string
---@param maxPages number
---@param maxLines number
---@param indent boolean
---@param show boolean
---@private
function DisplayStateModule:_asyncParse(text, id, maxPages, maxLines, indent, show)
    local config = rv.profile.config
    maxLines = min((config.LCDLines or 1), (maxLines or config.LCDLines))
    if config.keepNameOnLCD then maxLines = maxLines - 1 end
    if config.LCDSeparator then maxLines = maxLines - 1 end
    if config.LCDClearLastLine then maxLines = maxLines - 1 end
    if not TextDisplay then TextDisplay = rv:classImport('TextDisplay') end
    local display = TextDisplay:new({
        text = text,
        origin = id,
        maxLines = max(maxLines, 3),
        maxPages = maxPages,
        indentation = indent,
        paginationLine = (config.LCDClearLastLine and config.LCDLastLinePagination)
    })
    displayIndex[id] = display
    if show then self:displayOnLCD(display, nil, rv.profile.config.LCDMessageDuration) end
    return -1
end

---@private
function DisplayStateModule:_getHeader()
    local header = rv.profile.name
    local hide = rv.profile.config.LCDHidePrimaryMode
    local singleDevice = rv.profile.globalState.singleDevice
    if singleDevice then
        local device = rv.profile.deviceState[singleDevice]
        if rv.macroImports.ModeChangeMacro and (device.modus ~= 1 or (not hide) or (hide == "unnamed" and type(device.modeConfig[device.modus][1]) == "string")) then
            header = header .. ' [' .. (device.modeConfig[device.modus][1] or device.modus) .. ']'
        end
    end
    if rv.scriptStates.docMode then header = header .. ' [doc]' end
    return header
end

---@param def string|TextDisplay
---@param page? number
---@param duration? number
---@private
function DisplayStateModule:_asyncDisplay(def, page, duration)
    local config = rv.profile.config
    duration = duration or -1
    local newDisplay = (type(def) == "string" and displayIndex[def]) or def
    if not newDisplay or type(newDisplay) == "string" then rv:put('Could not find display with ID ' .. def) return -1 end
    if not self.currentDisplay or self.currentDisplay.origin ~= newDisplay.origin then
        if self.currentDisplay then self.currentDisplay:reset() end
        self.currentDisplay = newDisplay
    else self.currentDisplay:nextPage() end
    if page then self.currentDisplay:toPage(page) end
    local displayPage = self.currentDisplay:getCurrentPage()
    if not config.outputLCD then return -1 end
    local lineCount = #displayPage
    ClearLCD()

    if config.keepNameOnLCD then
        lineCount = lineCount + 1
        OutputLCDMessage(self:_getHeader(), duration)
    end
    if config.LCDSeparator then
        local sep = (type(config.LCDSeparator) == "string" and config.LCDSeparator) or "=" ---@cast sep string
        lineCount = lineCount + 1
        OutputLCDMessage(self:fillLine(sep), duration)
    end
    for i = 1, #displayPage do
        OutputLCDMessage(displayPage[i], duration)
    end
    if config.LCDClearLastLine and (lineCount < (config.LCDLines or 1) - 1) then
        OutputLCDMessage('', duration)
    end
    if duration ~= -1 and rv.profile.config.LCDPersistentProfile then
        rv.threading:wait(duration - 20)
        self:_asyncDisplay('_profileDefault')
    end
    return -1
end

---@param def string|TextDisplay
---@param page? number
---@param duration? number
function DisplayStateModule:displayOnLCD(def, page, duration)
    local dispName = type(def) == "string" and (displayRedirect[def] or def) or def.origin
    rv.threading:taskRun('_anon_display_' .. dispName, nil, nil, self._asyncDisplay, self, def, page or false, duration or -1)
end

---@param advance boolean
function DisplayStateModule:refresh(advance)
    if advance then self.currentDisplay:nextPage() end
    self:displayOnLCD(self.currentDisplay, self.currentDisplay.currentPage)
end

return DisplayStateModule
