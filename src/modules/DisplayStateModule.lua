local tl = ...---@type MainLibObject
local lower, match, sub, type, concat, pairs, find, ceil, tonumber, OutputLCDMessage, ClearLCD = tl.utf8.lower, tl.utf8.match, tl.utf8.sub, type, table.concat, pairs, tl.utf8.find, math.ceil, tonumber, OutputLCDMessage, ClearLCD
local cachedString, paginatorState
local DisplayDefinition ---@type DisplayTextDefinition
local maxDisplayLines = 7
local maxCharLength = 47

--TODO:fix string breaking
local stringRay = {
    ["1.1"] = { "i", "l", "'", "!", ":", ",", ";", ".", "|", "I", "f", " ", "j" },
    ["2"] = { '`', '´', '"', "[", "]", ")", "(", "{", "}", "\\", "/", "*", "-", "r", "t" },
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
function DisplayStateModule:stringBreaker(str)
    local stringArr = tl.str:separate(str)
    local simpleBreaks = {} ---@type number[]
    local hyphenationBreaks = {} ---@type number[]
    local currentLineLength = 0
    local whiteRadius = 3
    local lineRay = {} ---@type string[]
    local i = 1
    while i < #stringArr do
        local s = stringArr[i]
        local addition = (self.lengthMap[s] or 2.7) * 0.9
        currentLineLength = currentLineLength + (addition)
        if currentLineLength > maxCharLength then
            if match(s, "%s") or match(stringArr[i + 1], "%s") then
                simpleBreaks[i] = true
            else
                local foundWhite = false
                for n = 1, whiteRadius do
                    if match(stringArr[i - n], "%s") then
                        foundWhite = true
                        simpleBreaks[i - n] = true
                        break
                    end
                end
                if not foundWhite then
                    i = i + whiteRadius
                    local currentCopy = currentLineLength
                    local hyphVal = self.lengthMap['-']
                    local hyphenOffset = 0
                    while currentCopy > maxCharLength - hyphVal do
                        currentCopy = currentCopy - (self.lengthMap[stringArr[i - hyphenOffset]] or 0)
                        hyphenOffset = hyphenOffset + 1
                    end
                    hyphenationBreaks[i - hyphenOffset] = true
                    i = i + hyphenOffset
                end
            end
            currentLineLength = 0
        end
        i = i + 1
    end
    local lastStop = 1
    for i = 1, #stringArr do
        if simpleBreaks[i] then
            lineRay[#lineRay + 1] = sub(str, lastStop, i)
            lastStop = i + 1
        elseif hyphenationBreaks[i] then
            lineRay[#lineRay + 1] = sub(str, lastStop, i) .. '-'
            lastStop = i + 1
        end
        if i == #stringArr then lineRay[#lineRay + 1] = sub(str, lastStop, i) end
    end
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
function DisplayStateModule:parseToDisplayDefinition(text, id)
    local maxLines = maxDisplayLines
    local config = tl.profile.config
    if config.keepNameOnLCD then maxLines = maxLines - 1 end
    if config.LCDSeparator then maxLines = maxLines - 1 end
    if config.LCDClearLastLine then maxLines = maxLines - 1 end
    if not DisplayDefinition then DisplayDefinition = tl:classImport('DisplayTextDefinition') end
    local display = DisplayDefinition:new({
        text = text,
        origin = id,
        maxLines = maxLines,
        paginationLine = (config.LCDClearLastLine and config.LCDLastLinePagination)
    })
    self.displayIndex[id] = display
    return display
end

return DisplayStateModule