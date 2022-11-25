local rv = ... ---@type Revenant
local match, sub, type, pairs, tonumber, OutputLCDMessage, ClearLCD, min, max, rep, gsub, running, concat = string.match, string.sub, type, pairs, tonumber, OutputLCDMessage, ClearLCD, math.min, math.max, string.rep, string.gsub, coroutine.running, table.concat
---The Text Display class
local TextDisplay ---@type TextDisplay
---A map of Macro IDs to Display states
local displayIndex = {} ---@type table<string,TextDisplay|string>
local textIndex = {} ---@type table<string,string> stores... something idk
local displayRedirect = {} ---@type table<string,string>
local stringRay = { ---This records the widths of different Characters in the logitech LCD font
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
---@field lengthMap table<string,number> map of reach character to its width
---@field currentDisplay TextDisplay The currently displayed text state
---@field defaultDisplay TextDisplay Generic info text of the profile
local DisplayStateModule = rv.baseClass:new()
function DisplayStateModule:constructor()
    self.lengthMap = {} --character based indexing for better performance
    for k, v in pairs(stringRay) do for i = 1, #v do self.lengthMap[v[i]] = tonumber(k) end end
end

---Estimate how long a string is visually by adding up the widths of its characters.
---@param str string The string to check
---@return number, number[] #the relative length of the string, and the array of all values
function DisplayStateModule:getLength(str)
    if #str == 0 then return 0, {} end
    local lMap = {} ---@number[]
    local l = 0 --if we don't find a valid length value, we use a "default" of 2.7
    for i = 1, #str do
        local lVal = ((self.lengthMap[str[i]] or 2.7) * 0.9)
        lMap[#lMap + 1] = lVal
        l = (l + lVal)
    end
    return l, lMap
end

---Fill a line with one or more characters
---@param str string The "filler" string to repeat until the line is full.
---@return string #the final line string
function DisplayStateModule:fillLine(str)
    local repetition = 1
    local endString = str
    while self:getLength(rep(str, repetition)) <= rv.profile.config.LCDLineLength do
        endString = rep(str, repetition) --repeating the string as much as we need to
        repetition = repetition + 1
    end
    return endString
end

---cut off a string with a defined ending
---@param str string The string to truncate
---@param ending? string The string to attach at the end
---@param force? boolean if true the ending is always appended, even if nothing was cut
---@return string #the truncated string
function DisplayStateModule:truncate(str, ending, force)
    local maxLineLength = rv.profile.config.LCDLineLength or 50
    ending = ending or '...' -- "..." is the default ending
    if self:getLength(str .. (force and ending or '')) > maxLineLength then return str .. (force and ending or '')
    else --we have to check the string character by character, unfortunately, maybe there is a better way
        while self:getLength(str .. ending) < maxLineLength do str = sub(str, 1, -1) end
        return str .. ending
    end
end

local function _trim(s)
    local subbed = gsub(gsub(s, "^%s+", ""), "%s+$", "")
    return subbed
end

---Break a string into an array of strings of the same (visual) length.
---designed to run asynchronously since breaking long strings takes a while.
---@param str string The string to break
---@param keepIndent? boolean Keep indentation by not removing whitespace at start of line
---@return string[] #The array of lines making up the string
function DisplayStateModule:stringBreaker(str, keepIndent)
    ---line breaks directly after a word
    local simpleBreaks = {} ---@type boolean[]
    ---line breaks at whitespace around word
    local whiteSpaceBreaks = {} ---@type boolean[]
    ---line breaks within words
    local hyphenationBreaks = {} ---@type boolean[]
    local currentLineLength = 0 ---visual length of current line
    local config = rv.profile.config
    local int = 0 ---interruption duration, 0 is enough
    local maxLineLength = config.LCDLineLength or 50 --maximum length of any line
    local whiteRadius = 3 ---if whitespace is found within this range the word moves to the next page
    local currentIndent = 0 ---Keeping track of indentation
    ---list of lines
    local lineList = {} ---@type string[]
    local i = 1 ---iterator
    while i < #str do --we are not breaking yet, only noting where the different breaks will be.
        local s = sub(str, i, i)
        local addition = (self.lengthMap[s] or 2.7) * 0.9 ---length of current character
        currentLineLength = currentLineLength + addition
        if s == "\n" then
            simpleBreaks[i] = true --storing the position
            currentLineLength = 0
            if keepIndent then --not truncating whitespace
                currentIndent = #(match(sub(str, i), ' *') or '')
                currentLineLength = self.lengthMap[' '] * currentIndent
            end
        elseif match(s, "%s") and currentLineLength <= 0 and not keepIndent then
            currentLineLength = currentLineLength - addition --ignoring whitespace for length
        elseif currentLineLength > maxLineLength then
            if match(s, "%s") then simpleBreaks[i] = true --breaking outside of word
            else
                local foundWhite = false ---whitespace exists within radius
                for n = -1, whiteRadius do --finding the next possible whitespace to break at
                    if match(sub(str, i - n, i - n), "%s") then
                        foundWhite = true
                        whiteSpaceBreaks[i - n] = true --storing the position
                        break
                    end
                end
                if not foundWhite then --if there's no whitespace, we hyphenate
                    local currentCopy = currentLineLength
                    local hyphVal = self.lengthMap['-'] ---width of the hyphen character
                    local hyphenOffset = 0
                    while currentCopy > maxLineLength - hyphVal do --getting line + hyphen to the right length
                        currentCopy = currentCopy - (self.lengthMap[sub(str, i - hyphenOffset, i - hyphenOffset)] or 0)
                        hyphenOffset = hyphenOffset + 1
                    end
                    hyphenationBreaks[i - hyphenOffset] = true --storing the position
                    i = i + hyphenOffset
                end
            end
            currentLineLength = 0
        end
        i = i + 1
        if running() then rv.threading:wait(int) end --not blocking the execution of the rest of the script
    end
    local lastStop = 1
    local indentation = 0
    for n = 1, #str do ---the actual breaking happens in this loop
        if simpleBreaks[n] then
            if keepIndent then --for normal breaks indentation is impacted by the latest hyphenation breaks
                if hyphenationBreaks[lastStop - 1] then lineList[#lineList + 1] = concat { rep(' ', indentation), sub(str, lastStop, n) }
                else
                    indentation = #(match((lineList[#lineList] or ''), ' *') or '')
                    lineList[#lineList + 1] = rv.str:unbreak(sub(str, lastStop, n - 1), "")
                end
            else lineList[#lineList + 1] = _trim(sub(str, lastStop, n)) end
            lastStop = n
        elseif whiteSpaceBreaks[n] then --breaking around whitespace
            lineList[#lineList + 1] = concat { (keepIndent and rep(' ', indentation) or ''), _trim(rv.str:unbreak(sub(str, lastStop, n), "")) }
            lastStop = n
        elseif hyphenationBreaks[n] then --adding the line plus the hyphen
            lineList[#lineList + 1] = concat { _trim(sub(str, lastStop, n)), '-' }
            lastStop = n + 1
        end
        if n == #str then ---Adding the last line
            local lastLine = sub(str, lastStop, n)
            lineList[#lineList + 1] = (keepIndent and function(r) return r end or _trim)(rv.str:unbreak(lastLine, ""))
        end
    end
    return lineList
end

---Execute an asynchronous parse of a string to a display object
---@param text string contetn fo the text display
---@param id string ID ofthe macro the display is bound to
---@param maxPages? number Maximum page number
---@param maxLines? number maximum line number per page
---@param indent? boolean respect indentation?
---@param display? boolean show directly after parsing
function DisplayStateModule:parseToTextDisplay(text, id, maxPages, maxLines, indent, display)
    if displayIndex[id] then return end
    local prev = textIndex[text]
    if prev then --if we previously parsed this same text, we reuse the definition
        displayRedirect[id] = prev
        if display then self:displayOnLCD(prev, nil, rv.profile.config.LCDMessageDuration) end
        return
    end
    textIndex[text] = id --creating the new definition here, passing on all parameters
    rv.threading:taskRun(nil, nil, nil, self._asyncParse, self, text, id, (maxPages or false), maxLines or false, indent or false, display or false)
end

---@async
---async wrapper for generating display definitions, since they break text
---@param text string The text to parse
---@param id string id of the macro bound to the text
---@param maxPages number maximum number of pages in display
---@param maxLines number maximum number of lines in display
---@param indent boolean keep indentation?
---@param show boolean show text directly after parsing
---@private
function DisplayStateModule:_asyncParse(text, id, maxPages, maxLines, indent, show)
    local config = rv.profile.config
    maxLines = min((config.LCDLines or 1), (maxLines or config.LCDLines)) --taking the smallest max line value
    if config.keepNameOnLCD then maxLines = maxLines - 1 end --all of these options leave less space for text
    if config.LCDSeparator then maxLines = maxLines - 1 end
    if config.LCDClearLastLine then maxLines = maxLines - 1 end
    if not TextDisplay then TextDisplay = rv:classImport('TextDisplay') end --importing our class if we don't have it yet
    local display = TextDisplay:new({ --creating constructor object
        text = text,
        origin = id,
        maxLines = max(maxLines, 3),
        maxPages = maxPages,
        indentation = indent,
        paginationLine = (config.LCDClearLastLine and config.LCDLastLinePagination)
    })
    displayIndex[id] = display --finishing up parsing. Perhaps there should be an ID waiting list like with macros?
    if show then self:displayOnLCD(display, nil, rv.profile.config.LCDMessageDuration) end
    return -1
end

---@private
---generate a header for the current profile
---@return string the finished header
function DisplayStateModule:_getHeader()
    local header = rv.profile.name
    local hide = rv.profile.config.LCDHidePrimaryMode
    local singleDevice = rv.profile.globalState.singleDevice
    if singleDevice then --if there's one device, we append more information about modes
        local device = rv.profile.deviceState[singleDevice]
        if rv.macroImports.ModeChangeMacro and (device.modus ~= 1 or (not hide) or (hide == "unnamed" and type(device.modeConfig[device.modus][1]) == "string")) then
            header = header .. ' [' .. (device.modeConfig[device.modus][1] or device.modus) .. ']'
        end
    end
    if rv.scriptStates.docMode then header = header .. ' [doc]' end --documentation mode indicator
    return header
end

---@private
---@async
---Display a message for a certain duration
---@param def string|TextDisplay Text display or id of a text display
---@param page? integer The page of the display to show
---@param duration? integer duration of the display action
function DisplayStateModule:_asyncDisplay(def, page, duration)
    local config = rv.profile.config
    duration = duration or -1 --if there's no duration set, the text will stay indefinitely (-1)
    local newDisplay = (type(def) == "string" and displayIndex[def]) or def --finding our dislpay, aborting if there is none
    if not newDisplay or type(newDisplay) == "string" then rv:put('Could not find display with ID ' .. def) return -1 end
    if not self.currentDisplay or self.currentDisplay.origin ~= newDisplay.origin then
        if self.currentDisplay then self.currentDisplay:reset() end --making sure we'll be on the first page again for the next time
        self.currentDisplay = newDisplay
    else self.currentDisplay:nextPage() end --if it's the same display we just advance a page
    if page then self.currentDisplay:toPage(page) end --changing the page
    local displayPage = self.currentDisplay:getCurrentPage()
    if not config.outputLCD then return -1 end --not bothering with the display if it's not activated
    local lineCount = #displayPage ---keeping track of how much is on the display
    ClearLCD() --resetting the actual display

    if config.keepNameOnLCD then
        lineCount = lineCount + 1 --putting the header on the first line
        OutputLCDMessage(self:_getHeader(), duration)
    end
    if config.LCDSeparator then --adding our separator
        local sep = (type(config.LCDSeparator) == "string" and config.LCDSeparator) or "=" ---@cast sep string
        lineCount = lineCount + 1
        OutputLCDMessage(self:fillLine(sep), duration)
    end
    for i = 1, #displayPage do OutputLCDMessage(displayPage[i], duration) end --adding LCD content
    if config.LCDClearLastLine and (lineCount < (config.LCDLines or 1) - 1) then OutputLCDMessage('', duration) end --appending optional empty line
    if duration ~= -1 and rv.profile.config.LCDPersistentProfile then --re-displaying default profile display if set to persistent
        rv.threading:wait(duration - 20)
        self:_asyncDisplay('_profileDefault')
    end
    return -1
end

---Wrapper for the private async function
---@param def string|TextDisplay Text display or id of a text display
---@param page? number The page of the display to show
---@param duration? number duration of the display action
function DisplayStateModule:displayOnLCD(def, page, duration)
    local displayName = type(def) == "string" and (displayRedirect[def] or def) or def.origin --launching the display as async task
    rv.threading:taskRun('_anon_display_' .. displayName, nil, nil, self._asyncDisplay, self, def, page or false, duration or -1)
end

---refresh the display with or without advancing a page
---@param advance boolean If true display the next page after refreshing
function DisplayStateModule:refresh(advance)
    if advance then self.currentDisplay:nextPage() end
    self:displayOnLCD(self.currentDisplay, self.currentDisplay.currentPage)
end

return DisplayStateModule