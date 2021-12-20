local tl = ...---@type MainLibObject
local lower, match, sub, type, concat, pairs, find, ceil, tonumber, OutputLCDMessage, ClearLCD = tl.utf8.lower, tl.utf8.match, tl.utf8.sub, type, table.concat, pairs, tl.utf8.find, math.ceil, tonumber, OutputLCDMessage, ClearLCD
local cachedString, paginatorState

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
local DisplayStateModule = tl.baseClass:new()
function DisplayStateModule:constructor()
    self.lengthMap = {}
    for k, v in pairs(stringRay) do
        for i = 1, #v do self.lengthMap[v[i]] = tonumber(k) end
    end
end

---intelligently divide text into multiple pages for display on LCD screen
---@param str string
local function _paginator(str)
    local config = tl.profile.config
    if str ~= cachedString then
        paginatorState = 0
        cachedString = str
    end
    local sep = tl.helperUtils.splitter(str, "\n");
    if tl.profile.config.displayLines == 0 or #sep <= config.displayLines then
        return concat(sep, '\n')
    else
        local pageMax = ceil(#sep / (config.displayLines - 1))
        if paginatorState == pageMax then paginatorState = 0 end
        local outTable = {}
        for k = config.displayLines * (paginatorState), (config.displayLines * (paginatorState)) + config.displayLines - 1 do
            if k ~= 0 then outTable[#outTable + 1] = sep[k] or "" end
        end
        local pageNums = "[" .. (paginatorState + 1) .. "/" .. (pageMax) .. "]"
        outTable[config.displayLines] = pageNums
        paginatorState = paginatorState + 1
        return concat(outTable, "\n")
    end
end

function DisplayStateModule:stringbreaker(str)
    local stringArr = tl.str:separate(str)
    local simpleBreaks = {} ---@type number[]
    local hyphenationBreaks = {} ---@type number[]
    local currentLineLength = 0
    local cursor = 1
    local whiteRadius = 3
    local lastLineStart = 1
    local lineRay = {}
    local i = 1
    while i < #stringArr do
        tl:put(currentLineLength)
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
    tl.tbl:prettyTab(simpleBreaks)
    tl.tbl:prettyTab(hyphenationBreaks)
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

return DisplayStateModule