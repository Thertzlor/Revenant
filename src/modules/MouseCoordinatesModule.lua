local rv = ...---@type MainLibObject
local abs, GetRunningTime, MoveMouseToVirtual, MoveMouseTo, GetMousePosition, type, running, MoveMouseRelative, error, next, sqrt, floor, pcall, ceil = math.abs, GetRunningTime, MoveMouseToVirtual, MoveMouseTo, GetMousePosition, type, coroutine.running, MoveMouseRelative, error, next, math.sqrt, math.floor, pcall, math.ceil
local currentSample, mouseCount
local MonitorDefinition = rv:classImport("MonitorDefinition")---@type MonitorDefinition
--=============================================================
local MouseCoordinatesModule = rv.baseClass:new()---@class MouseCoordinatesModule:BaseClass Functions that deal with calculating screen resolution and mouse pos for area and velocity checks.
local mouseHistory = {}
local limit = (2 ^ 16) - 1 --65535

---Checks if the mouse is within a certain area.
---@param ar AreaContainer
local function _areaCheck(ar, x, y)
    return (x >= ar.cl[1]) and (x <= ar.cr[1])
    and (y >= ar.cl[2]) and (y <= ar.cr[2])
end

function MouseCoordinatesModule:constructor()
    self.screens = {}---@type MonitorDefinition[]
    self.rectStoreP = {}
    self.rectStoreN = {}
    self.pointStore = {}
    self.mainScreen = 1
    self.xRangeWin = { 0, limit }
    self.yRangeWin = { 0, limit }
    self.moveFunction = MoveMouseToVirtual---@type fun():void
    self.lagSample = 5
    self.interval = 2
end

---calculate coordinate Data for allefin ded screens
---@param profile ProfileDefinition
function MouseCoordinatesModule:compileScreenCoordinates(origin, profile)
    if not origin[1] then return end
    if rv.profile.config.restrictToMainScreen then self.moveFunction = MoveMouseTo end
    self.interval = rv.profile.config.pollInterval
    local multiMonitor = type(origin[1]) == "table"
    if multiMonitor then
        for i = 1, #origin do local m = origin[i]
            if m.main then self.mainScreen = i end
            local cl = (m.main and ({ 0, 0 })) or m.topLeft
            local cr = (m.main and ({ limit, limit })) or m.bottomRight
            if (not cl) or (not cr) then error('please corner coordinates for a multi monitor setup') end
            m.win = { w = abs(cl[1] - cr[1]), h = abs(cl[2] - cr[2]) }
            if not rv.profile.config.restrictToMainScreen then
                if cr[1] > self.xRangeWin[2] then self.xRangeWin[2] = cr[1] end
                if cl[1] < self.xRangeWin[1] then self.xRangeWin[1] = cl[1] end
                if cl[2] < self.yRangeWin[1] then self.yRangeWin[1] = cl[2] end
                if cr[2] > self.yRangeWin[2] then self.yRangeWin[2] = cr[2] end
            end
            self.screens[#self.screens + 1] = (rv:classImport('MonitorDefinition')):new(m)
        end
    else
        origin.win = { h = self.xRangeWin, w = self.YRangeWin }
        self.screens[#self.screens + 1] = (rv:classImport('MonitorDefinition')):new(origin)
    end
    for i = 1, #self.screens do self.screens[i]:setAbsoluteSingle() end
end

---@param absX number
---@param absY number
---@return number,number
function MouseCoordinatesModule:virtualTransform(absX, absY)
    return rv.helperUtils.linearTransform(absX, self.xRangeWin[1], self.xRangeWin[2], 0, limit), rv.helperUtils.linearTransform(absY, self.yRangeWin[1], self.yRangeWin[2], 0, limit)
end

---@return number[]
function MouseCoordinatesModule:genPoint(arg, opts, id)
    local x, y = self:virtualTransform(self.screens[opts.screen]:getWinPixel(arg[1], arg[2]))
    self.pointStore[id] = { x, y }
    return { x, y }
end

function MouseCoordinatesModule:addRect(def, id)
    local store = def.exclude and self.rectStoreN[id] or self.rectStoreP[id]
    local rect = self.screens[def.screen or self.mainScreen]:getRect(def)
    store[#store + 1] = { cl = { self:virtualTransform(rect.cl[1], rect.cl[2]) }, cr = { self:virtualTransform(rect.cr[1], rect.cr[2]) } }
end

function MouseCoordinatesModule:genRects(rectDef, id)
    self.rectStoreN[id] = {}
    self.rectStoreP[id] = {}
    if rectDef[1] then for i = 1, #rectDef do self:addRect(rectDef[i], id) end
    else self:addRect(rectDef, id) end
    return self.rectStoreP[id]
end

function MouseCoordinatesModule:getMonitorNo(x, y)
    for i = 1, #self.screens do if self.screens[i]:contains(x, y) then return i end end
    error('could not find mouse location.')
end

function MouseCoordinatesModule:onMonitor(i, x, y)
    return self.screens[i]:contains(x, y)
end

--- wrapper for the previously broken MoveMouseRelative() function
---@param x number
---@param y number
---@return  nil
function MouseCoordinatesModule:relativeMouse(x, y)
    if x == nil then return end
    local movedX = 0
    local movingX = 0
    local movedY = 0
    local movingY = 0
    local limit = 0
    y = y or 0
    while movedX ~= x or movedY ~= y do
        movingX = x - movedX
        movingY = y - movedY
        if abs(movingX) > 127 then
            movingX = 127
            if x < 0 then movingX = movingX * -1 end
        end
        if abs(movingY) > 127 then
            movingY = 127
            if y < 0 then movingY = movingY * -1 end
        end
        MoveMouseRelative(movingX, movingY)
        movedX = movedX + movingX
        movedY = movedY + movingY
    end
    limit = limit + 1
end

---@param arg table<number,number>
---@param options MouseMoveMacro
---@param dir '"up"'|'"down"'
---@param pID string
function MouseCoordinatesModule:relativeWrapper(arg, options, dir, pID)
    local x, y = arg[1], arg[2]
    if x == nil then return end
    self:relativeMouse(x, y)
end


---@param arg table<number,number>
---@param num number
local function avNum(arg, num)
    local av = arg[#arg]
    for i = 1, num - 1 do av = av + arg[#arg - i] end
    return av / num
end

local firstMove = true
local lagMultiplier = 1
local averageLag = {}---@type table<number,number>
local noLag = false

---@private
---@param x number
---@param y number
---@param baseX number
---@param baseY number
---@param destX number
---@param destY number
---@param steps number
function MouseCoordinatesModule:moveFor(x, y, baseX, baseY, destX, destY, steps)
    local func = self.rawMove
    local int = self.interval
    local config = rv.profile.config
    local threshold = config.lagPositionThreshold
    local lagSample = config.lagSampleSize
    local sampleAmount = config.lagSampleAmount
    local maxLag = config.permissibleLag / 100
    local checkTime = GetRunningTime()
    local now = checkTime
    local tenCompare = int * 10
    local bx = baseX or 0
    local by = baseY or 0
    for i = 1, steps / lagMultiplier do
        func(self, (bx + x * lagMultiplier), (by + y * lagMultiplier))
        bx = bx + x * lagMultiplier
        by = by + y * lagMultiplier
        if lagSample and noLag == false and i % 10 == 0 then
            now = GetRunningTime()
            averageLag[#averageLag + 1] = (now - checkTime) / tenCompare
            if #averageLag % lagSample == 0 then lagMultiplier = avNum(averageLag, lagSample) end
            checkTime = now
            if lagSample and firstMove and abs(bx - destX) < threshold then
                self:rawMove(destX, destY)
                return -1
            end
        end
        rv.coroutines:wait(int)
    end
    self:rawMove(destX, destY)
    firstMove = false
    if lagSample and noLag == false and #averageLag > sampleAmount then
        local currentAvg = avNum(averageLag, #averageLag)
        noLag = (abs(currentAvg - 1)) < maxLag
        if noLag then lagMultiplier = 1 end
        averageLag = { currentAvg }
    end
    return -1
end

---wrapper for posivite or negative areaChecks.
---@param arg AreaContainer[]
function MouseCoordinatesModule:areaCheckWrapper(arg, id)
    if #self.screens == 0 or not next(arg) then return true end
    local posX, posY = GetMousePosition();
    local posMap = self.rectStoreP[id] or self:genRects(arg, id)
    local negMap = self.rectStoreN[id]
    for i = 1, #negMap do if _areaCheck(negMap[i], posX, posY) then return false end end
    for i = 1, #posMap do if _areaCheck(posMap[i], posX, posY) then return true end end
    return #posMap == 0
end

---not implemented yet
function MouseCoordinatesModule:mouseVelocity()
end

---automatically check the position of the mouse after a certain interval.
function MouseCoordinatesModule:mouseCheckFunc()
    local config = rv.profile.config
    mouseCount = mouseCount + 1
    if mouseCount >= config.mouseInterval then
        currentSample = currentSample + 1
        mouseHistory[currentSample] = {}
        mouseHistory[currentSample].w, mouseHistory[currentSample].h = GetMousePosition()
        if currentSample == config.mouseHistoryLimit then currentSample = 1 end
        mouseCount = 0
    end
end

function MouseCoordinatesModule:rawMove(x, y)
    pcall(self.moveFunction, x, y)
end

---Main function for moving the mouse instantly or over time
---@param arg (string|number)[]
---@param options MouseMoveOptions
---@param dir string
---@param pID string
function MouseCoordinatesModule:mouseMoveWrapper(arg, options, dir, pID)
    if options.relative and (not options.duration) and (not options.velocity) then return self:relativeWrapper(arg, options, dir, pID) end
    if (not options.duration) and (not options.velocity) then return self:mouseMove(arg, options, pID) end
    local coords = self.pointStore[pID] or self:genPoint(arg, options, pID)
    local currentX, currentY = self:virtualTransform(GetMousePosition())
    local targetX, targetY = coords[1], coords[2]
    if options.relative then targetX, targetY = currentX + targetX, currentY + targetY end
    local distanceX, distanceY = (targetX - currentX), (targetY - currentY)
    local numStep = 0
    if options.velocity then
        local pixelSize = self.screens[options.screen].singleL
        local pixelDistance = sqrt(((distanceX / pixelSize[1]) ^ 2) + ((distanceY / pixelSize[2]) ^ 2))
        local time = floor((pixelDistance / options.velocity) * (1000))
        numStep = ceil(time / self.interval)
    else numStep = options.duration / self.interval end
    local stepX, stepY = (distanceX / numStep), (distanceY / numStep)
    if running() then self:moveFor(stepX, stepY, currentX, currentY, targetX, targetY, numStep)
    else rv.coroutines:taskRun(pID, nil, nil, self.moveFor, self, stepX, stepY, currentX, currentY, targetX, targetY, numStep) end
end

function MouseCoordinatesModule:mouseMove(arg, opts, id)
    local coords = self.pointStore[id] or self:genPoint(arg, opts, id)
    self.moveFunction(coords[1], coords[2])
end

return MouseCoordinatesModule