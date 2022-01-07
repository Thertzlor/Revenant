local rv = ...---@type Revenant
local pairs, concat, yield, type, running, rep, match, sub, error = pairs, table.concat, coroutine.yield, type, coroutine.running, string.rep, string.match, string.sub, error
local delayedTypes = rv.tbl:propsFrom { "instance", "group" }
local toMain = { { "type", "key" }, "name", { "direction", "normal" } }

---@class KeyPress
---@field keyNum number
---@field family string
---@field actionDelay number
---@field keyDelay number
---@field actionVariance number
---@field keyVariance number
---@field forceSleep boolean
--=============================================================
---@class AreaContainer
---@field screen number
---@field cl number[]
---@field cr number[]
--=============================================================
---@alias DirectionValue "'up'"|"'down'"
---@alias UnlockValue "'shift'"|"'mode'"|"'mkeys'"|"'area'"|"'condition'"
--=============================================================
---@class MacroOptions
---@field type string Specify the type of the macro. Defaults to "key"
---@field name string A which can be used to reference the macro in other contexts 
---@field direction DirectionValue The direction in which the Macro should play
---@field mode string|number|(string|number)[] Restrict teh macro to a specific mouse mode by selecting it by number or name. Accepts a list to enable it in multiple modes.
---@field gshift number Set to 1 to only activate macro if G-shift is active, set to 0 to activate only if it isn't. Set to 2 to run in all G-shift states.
---@field condition any One or more additional conditions the macro has to clear before running.
---@field documentation string A description of the macro to Log and Show during Documentation mode
---@field blocking number Set to 1 to block all following macros on the key from executing. Make sure you know the final compiled order of the macros before using this.
---@field unlock UnlockValue|UnlockValue[] Make the macro check run conditions both on keydown and keyup. Use with caution.
---@field area AreaContainer Restrict the activation of a macro to a specific section of the screen.
---@field mkey string Define modifier keys
---=============================================================
---@class BaseShorthands
---@field t string Shorthand for "type"
---@field n string Shorthand for "name" 
---@field b number Shorthand for "block".
---@field doc string Shorthand for "documentation".
---@field c any shorthand for "condition".
---@field g number Shorthand for "gshift"
---@field m string|number|(string|number)[] Shorthand for "mode"
---@field dir DirectionValue Shorthand for "direction"
--=============================================================
---@alias MacroInitDefinition MacroOptions|BaseShorthands Macro options with shorthands
--=============================================================
---@class SpeedStats
---@field actionDelay number
---@field actionVariance number
---@field keyDelay number
---@field keyVariance number
--=============================================================
---@class MacroDefinition:BaseClass
---@field profile ProfileDefinition
---@field options MacroOptions | SpeedStats
---@field manualDocumentation string
---@field shortHands  table<string,string> Maps long option names to shorter ones.
---@field lintProperties OptionsLintPreset
---@field lintCommand LintEntry
---@field sourceDevice HardwareDefinition
---@field defaults MacroOptions
---@field overrides MacroOptions
---@field stack string[]
---@field terminus boolean
---@field references string[]
---@field type string
---@field name string
local MacroDefinition = rv.baseClass:new()
MacroDefinition.lintProperties = {}
MacroDefinition.shortHands = {}
---@protected
---@param macroSummary table
---@param parentProfile ProfileDefinition
---@param device HardwareDefinition
---@param defaults MacroOptions
---@param overrides MacroOptions
---@param stack string[]
function MacroDefinition:constructor(macroSummary, parentProfile, defaults, overrides, stack, device)
    if not macroSummary then return end
    self.shortHands = rv.tbl:intersectSimple(rv.stringPresets.shortHands, self.shortHands, true)
    self.shortMap = {} ---@protected
    for k, v in pairs(self.shortHands) do self.shortMap[#self.shortMap + 1] = { k, v } end
    self.sourceDevice = device
    self.disabled = false
    self.stack = stack or {} ---@protected
    self.init = false ---@protected
    self.profile = parentProfile
    if self.terminus == nil then self.terminus = true end
    self.singleTrigger = self.singleTrigger or false ---@protected
    self.raw = macroSummary;
    self.subMacros = {} ---@protected
    self.references = {} ---@protected
    self.overrides = overrides or {} ---@protected
    self.defaults = defaults or {}
    self.rawCommand, self.rawOptions = rv.tbl:splitEnumerable(macroSummary) ---@protected
    self.command = self.rawCommand ---@protected
    self.options = rv.tbl:intersectSimple(self.rawOptions, (macroSummary._inherit or {}))
    for k, v in pairs(self.defaults) do self.options[k] = self.options[k] or v; end
    if self.type == "group" then self.raw.type = nil
    else for k, v in pairs(self.overrides) do self.options[k] = v; end end
    self:expandOptions()
    self:parseQualifiers()
    for i = 1, #toMain do local main, mainTab = toMain[i], (type(toMain[i]) == "table")
        local target = (mainTab and main[1] or main)
        local rep = self.options[target]
        if not rep and mainTab and main[2] then rep = main[2] end
        self[target] = rep
        self.options[target] = nil
    end
    self.titleExport = self:compileTitle()
    if not delayedTypes[self.type] then self.pID = self:genId() end
    self.state = self.state or {}
    self:async(self.parseInstructions, self)
    self.manualDocumentation = self.options.documentation or self.profile.documentation[self.name]
    if (not rv.lint:keyOptionsLinter(self.raw, self.type, self.lintProperties, self.shortHands, self.name or self:export(), self.name ~= nil))
    or (not rv.lint:keyCommandLinter((type(self.command) == "table" and self.command or { self.command }), self.lintCommand, self.type, (self.name or self:export()), self.name ~= nil))
    and self.profile.config.abortOnLintError then self.disabled = true end
end

---@protected
---@param transient boolean
function MacroDefinition:finishInit(transient)
    if self.pID then
        if not transient then self.profile.macroIndex[self.pID] = self end
        if self.name then
            self.profile.nameMap[self.name] = self.pID
            if self.profile.awaiting[self.name] then
                local store = self.profile.awaiting[self.name].queue
                for i = 1, #store do self:async(store[i], self.pID) end
            end
        end
    end
    if self.idThread then self:async(self.idThread, self:identify()) end
    self.init = true
end

function MacroDefinition:compileTitle()
    local title = ''
    local inTab = {} ---@type string[]
    if (self.options.mode and self.profile.config.defaultMode and self.options.mode ~= self.profile.config.defaultMode) then inTab[#inTab + 1] = 'm' .. (type(self.options.mode) == "table" and concat(self.options.mode, ', ') or self.options.mode) end
    if (self.options.gshift and self.profile.config.defaultShift and self.options.gshift ~= self.profile.config.defaultShift) then inTab[#inTab + 1] = 's' .. self.options.gshift end
    if #inTab ~= 0 then title = '[' .. concat(inTab, ',') .. '] ' end
    title = title .. (self.name and self.name .. ': ' or '')
    return title
end

---@protected
---@param target string|MacroDefinition
---@param key string|number
---@param parent table
---@param table boolean 
function MacroDefinition:replaceWithReferenceId(target, key, parent, table, func)
    local fetched = self:awaitId(target, true)
    func = func or function(x) return x end
    self.references[#self.references + 1] = fetched
    parent[key] = (table and { func(fetched) }) or func(fetched)
end

---@protected
---@param event Event
---@param virtualType number
function MacroDefinition:virtualize(event, virtualType)
    local virtuVent = event
    virtuVent.virtualType = virtualType
    virtuVent.stack = virtuVent.stack or {}
    virtuVent.stack[#virtuVent.stack + 1] = self.pID
    virtuVent.originator = virtuVent.originator or self.pID
    return virtuVent
end

---@protected
function MacroDefinition:expandOptions()
    local short = self.profile.config.preferShorthand
    local mappedTerms = self.shortMap;
    for i = 1, #mappedTerms do local term = mappedTerms[i]
        local primary = short and term[1] or term[2]
        local secondary = short and term[2] or term[1]
        if (self.options[primary] ~= nil) or (self.options[secondary] ~= nil) then
            local finalValue
            if (self.options[primary] ~= nil) then finalValue = self.options[primary]
            else finalValue = self.options[secondary] end
            self.options[term[2]] = finalValue
            self.options[term[1]] = nil
        end
    end
end

---@protected
---@param name string
---@param stack string[]
function MacroDefinition:circular(name, stack)
    if not self.profile.awaiting[name] then return end
    local stack = stack or {}
    local store = self.profile.awaiting[name].waiting
    for i = 1, #store do local waiter = store[i]
        for m = 1, #stack do
            if waiter == stack[m] then
                stack[#stack + 1] = waiter
                error('circular requirement detected: ' .. concat(stack, '->'))
            end
        end
        stack[#stack + 1] = name
        self:circular(waiter, stack)
    end
end

---@protected
---[async] Waits for a Macro to be fully initialized and then returns its ID.
---@param target string|MacroDefinition The macro can either be targeted by its name or referenced directly
---@param refOnly boolean If we're only waiting for a reference we don't care if the reference is circular.
function MacroDefinition:awaitId(target, refOnly)
    if type(target) ~= "string" then return target:awaitOwnId() end
    if self.profile.nameMap[target] then return self.profile.nameMap[target]
    else
        if self.profile.awaiting[target] then
            self.profile.awaiting[target].queue[#self.profile.awaiting[target].queue + 1] = running()
            self.profile.awaiting[target].waitNum = self.profile.awaiting[target].waitNum + 1
        else self.profile.awaiting[target] = { queue = { running() }, waitNum = 1 } end
        if self.name then
            if not self.profile.awaiting[target].waiting then self.profile.awaiting[target].waiting = { self.name }
            else self.profile.awaiting[target].waiting[#self.profile.awaiting[target].waiting + 1] = self.name end
            if not refOnly then self:circular(target) end
        end
        local yieldedName = yield() ---@type string
        self.profile.awaiting[target].waitNum = self.profile.awaiting[target].waitNum - 1
        --if self.profile.awaiting[target].waitNum == 0 then self.profile.awaiting[target] = nil end
        return yieldedName
    end
end

---@protected
---@param event Event
---@return KeyPress
function MacroDefinition:keyPress(event)
    return {
        actionDelay = self.options.actionDelay or self.profile.config.actionDelay,
        keyDelay = self.options.keyDelay or self.profile.config.keyDelay,
        actionVariance = self.options.actionVariance or self.profile.config.actionVariance,
        keyVariance = self.options.keyVariance or self.profile.config.keyVariance,
        family = event.family,
        keyNum = event.keyNum,
        forceSleep = false
    }
end

---[async] Returns the macro ID when the macro is fully initialized
---@return string ID of the macro or replacement macro if bypassed
function MacroDefinition:awaitOwnId()
    if self.init then return self:identify() end
    self.idThread = running()---@type thread
    return yield()
end

---@param event Event
function MacroDefinition:runFree(event)
    if self.disabled then return end
    local options = self.options
    if rv.validator:skipConditions(event, options, self.type, self.pID, self.singleTrigger) then
        if rv.scriptStates.docMode and (self.terminus or self.manualDocumentation) then return rv.lcd:displayOnLCD(self.pID, 1) end
        self:execute(event)
        self.profile.deviceState[event.family].conKey = (not (not event.virtualType and (options.blocking == 1 or options.blocking == 3)) and 0) or event.keyNum
    end
end

---@param event Event
function MacroDefinition:run(event)
    if self.disabled then return end
    local options = self.options
    if rv.validator:validateConditions(event, options, self.pID, self.singleTrigger) then
        if rv.scriptStates.docMode and (self.terminus or self.manualDocumentation) then return rv.lcd:displayOnLCD(self.pID, 1) end
        self:execute(event)
        self.profile.deviceState[event.family].conKey = (not (not event.virtualType and (options.blocking == 1 or options.blocking == 3)) and 0) or event.keyNum
    end
end

---@protected
function MacroDefinition:errorHandler(msg)
    local name = self.name
    rv:put(rv.helperUtils.pprint(self.stack))
    if not name then for i = 1, #self.stack do local stn = self.stack[i][2] if stn then name = "Child Macro of " .. stn end break end
    else name = "Macro " .. name end
    if not name then name = "a " .. self.type .. " macro" end
    rv.scriptStates.errors[#rv.scriptStates.errors + 1] = name .. " failed to initialize:\n  " .. msg
end

---@protected
function MacroDefinition:parseInstructions() self:finishInit() end
function MacroDefinition:parseDocs() rv.lcd:parseToDisplayDefinition(self.manualDocumentation or self:export(), self.pID, nil, nil, not self.manualDocumentation) end
---@private
function MacroDefinition:parseQualifiers()
    if self.options.mode then local modas = self.options.mode
        if type(modas) ~= "table" then modas = { modas } end
        for i = 1, #modas do local mod = modas[i]
            if type(mod) == "string" then
                local minus = match(mod, "^-")
                mod = (minus and sub(mod, 2)) or mod
                local realMod = self.profile.deviceState[self.sourceDevice].modeIndex[mod]
                if not realMod then error("mode " .. mod .. " not found on " .. self.profile.deviceState[self.sourceDevice].family) end
                modas[i] = realMod * ((minus and -1) or 1)
            end
        end
        self.options.mode = (#modas == 1 and modas[1]) or modas
    end
    if self.options.condition then
        local function testReplace(el, index, parent)
            if type(el) ~= "table" then if type(el) == "string" then
                    local prefix = sub(el, 1, 2)
                    if prefix == ":" or prefix == "~" then
                        self:async(self.replaceWithReferenceId, self, el, index, parent, function(wac) return prefix .. wac end) end
                end
            else for i = 1, #el do testReplace(el[i], i, el) end end
        end
        testReplace(self.options.condition, "condition", self.options)
    end
end

---@param depth number
function MacroDefinition:export(depth)
    depth = depth or 0
    local indent = rep("  ", depth) or ''
    return indent .. self.titleExport .. rv.classMap[self.type or "key"][1] .. " (" .. self.type .. ")"
end

---@protected
function MacroDefinition:identify() return self.pID or (#self.subMacros ~= 0 and self.subMacros[#self.subMacros]) or nil end

function MacroDefinition:execute(...) end

return MacroDefinition