local rv = ...---@type Revenant
local pairs, concat, yield, type, running, rep, match, sub, error, next = pairs, table.concat, coroutine.yield, type, coroutine.running, string.rep, string.match, string.sub, error, next
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
---@class _ConditionOptions
---@field logic '"and"'|'"or"'|'"xor"'
--=============================================================
---@alias Condition Condition[]|string[]|(fun():boolean)[]|_ConditionOptions
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
---@field name string A name which can be used to reference the macro in other contexts
---@field direction DirectionValue The direction in which the Macro should play
---@field mode string|number|(string|number)[] Restrict teh macro to a specific mouse mode by selecting it by number or name. Accepts a list to enable it in multiple modes.
---@field gshift number Set to 1 to only activate macro if G-shift is active, set to 0 to activate only if it isn't. Set to 2 to run in all G-shift states.
---@field condition Condition|fun():boolean  One or more additional conditions the macro has to clear before running.
---@field documentation string A description of the macro to Log and Show during Documentation mode
---@field blocking boolean Set to true to block all following macros on the key from executing. Make sure you know the final compiled order of the macros before using this.
---@field unlock UnlockValue|UnlockValue[] Make the macro check run conditions both on keydown and keyup. Use with caution.
---@field area AreaContainer Restrict the activation of a macro to a specific section of the screen.
---@field mkey string Define modifier keys
---=============================================================
---@class BaseShorthands
---@field t string Shorthand for "type"
---@field n string Shorthand for "name"
---@field b boolean Shorthand for "blocking".
---@field doc string Shorthand for "documentation".
---@field c string|Condition|fun():boolean shorthand for "condition".
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
---@field inherited boolean
---@field direction "'up'"|"'normal'"
---@field options MacroOptions | SpeedStats
---@field manualDocumentation string
---@field shorthands  table<string,string> Maps long option names to shorter ones.
---@field lintProperties OptionsLintPreset
---@field lintCommand LintEntry
---@field subMacros string[]
---@field msgDuration number
---@field sourceDevice HardwareDefinition
---@field defaults MacroOptions
---@field stack string[][]
---@field continuous boolean
---@field terminus boolean
---@field blocked boolean
---@field references string[]
---@field type string
---@field name string
---@field new fun(self:MacroDefinition,macroSummary:MacroInitDefinition, defaults:MacroInitDefinition, stack:string[], device:HardwareDefinition):MacroDefinition
local MacroDefinition = rv.baseClass:new()
MacroDefinition.lintProperties = {} ---@type OptionsLintPreset
MacroDefinition.shorthands = {} ---@type table<string,string>
---@protected
---@param macroSummary table
---@param device HardwareDefinition
---@param defaults MacroOptions
---@param stack string[]
function MacroDefinition:constructor(macroSummary, defaults, stack, device)
    if not macroSummary then return end
    self.shorthands = rv.tbl:intersectSimple(self.shorthands, rv.stringPresets.shorthands)
    self.shortMap = {} ---@protected
    for k, v in pairs(self.shorthands) do self.shortMap[#self.shortMap + 1] = { k, v } end
    self.sourceDevice = device
    self.disabled = false
    self.stack = stack or {} ---@protected
    self.init = false ---@protected
    if self.terminus == nil then self.terminus = true end
    self.singleTrigger = self.singleTrigger or false ---@protected
    self.raw = macroSummary;
    self.subMacros = {} ---@protected
    self.references = {} ---@protected
    self.defaults = defaults or {}
    self.rawCommand, self.rawOptions = rv.tbl:splitEnumerable(macroSummary) ---@protected
    self.inherited = self.rawOptions.__inherited
    self.rawOptions.__inherited = nil
    self.command = self.rawCommand ---@protected
    self.options = self:keyFilter(rv.tbl:intersectSimple(rv.tbl:intersectSimple(self.rawOptions, (macroSummary._inherit or {})), self.defaults))
    if not rv.profile.assign then rv.tbl:prettyTab(self.raw) end
    if self.type == "group" then self.raw.type = nil
    else for k, v in pairs(rv.profile.assign.scopeOverride or {}) do self.options[k] = v; end end
    self:expandOptions()
    self:parseQualifiers()
    for i = 1, #toMain do local main, mainTab = toMain[i], (type(toMain[i]) == "table")
        local target = (mainTab and main[1] or main)
        local reps = self.options[target]
        if not reps and mainTab and main[2] then reps = main[2] end
        self[target] = reps
        self.options[target] = nil
    end
    self.msgDuration = (self.rawOptions.lcd and type(self.rawOptions.lcd) == "number") and self.rawOptions.lcd or rv.profile.config.LCDMessageDuration
    self.titleExport = self:compileTitle()
    if not delayedTypes[self.type] then self.pID = self:genId() end
    self.state = self.state or {}
    self:async(self.parseInstructions, self)
    self.manualDocumentation = self.options.documentation or rv.profile.documentation[self.name]
    if (rv.profile.config.enableLinting and not rv.lint:keyOptionsLinter(self.raw, self.type, self.lintProperties, self.shorthands, self.name or self:export(), self.name ~= nil))
    or (rv.profile.config.enableLinting and not rv.lint:keyCommandLinter((type(self.command) == "table" and self.command or { self.command }), self.lintCommand, self.type, (self.name or self:export()), self.name ~= nil))
    and rv.profile.config.abortOnLintError then self.disabled = true end
end

---@protected
---@param transient boolean
function MacroDefinition:finishInit(transient)
    if self.pID then
        if not transient then rv.profile.macroIndex[self.pID] = self end
        if self.name then
            rv.profile.nameMap[self.name] = self.pID
            if rv.profile.awaiting[self.name] then
                local store = rv.profile.awaiting[self.name].queue
                for i = 1, #store do self:async(store[i], self.pID) end
            end
        end
    end
    if self.idThread then self:async(self.idThread, self:identify()) end
    self.init = true
    if self.inherited then self:inheritanceCheck() end
end

function MacroDefinition:compileTitle()
    local title = ''
    local inTab = {} ---@type string[]
    if (self.options.mode and rv.profile.config.defaultMode and self.options.mode ~= rv.profile.config.defaultMode) then inTab[#inTab + 1] = 'm' .. (type(self.options.mode) == "table" and concat(self.options.mode, ', ') or self.options.mode) end
    if (self.options.gshift and rv.profile.config.defaultShift and self.options.gshift ~= rv.profile.config.defaultShift) then inTab[#inTab + 1] = 's' .. self.options.gshift end
    if #inTab ~= 0 then title = '[' .. concat(inTab, ',') .. '] ' end
    title = title .. (self.name and self.name .. ': ' or '')
    return title
end

function MacroDefinition:keyFilter(tab)
    local newTab = {}
    if not tab or not next(tab) or self.lintProperties.__all then return tab or {} end
    local validProperties = rv.tbl:intersectSimple(self.lintProperties, rv.lint.genericMacroProperties)
    for k, v in pairs(tab) do if (validProperties[k] or self.shorthands[k]) then newTab[k] = v end end
    return newTab
end

function MacroDefinition:inheritanceCheck()
    local preventions = rv.profile.config.preventInheritance or {}
    for i = 1, #preventions do if self.name == preventions[i] then self.disabled = true end end
    for i = 1, #self.subMacros do local subMacro = rv.profile.macroIndex[self.subMacros[i]]
        subMacro.inherited = true
        subMacro:inheritanceCheck()
    end
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
    local virtuVent = rv.tbl:intersectSimple(event, {})
    virtuVent.virtualType = virtualType
    virtuVent.stack = virtuVent.stack or {}
    virtuVent.stack[#virtuVent.stack + 1] = self.pID
    virtuVent.originator = virtuVent.originator or self.pID
    return virtuVent
end

---@protected
function MacroDefinition:expandOptions()
    local mappedTerms = self.shortMap;
    for i = 1, #mappedTerms do local term = mappedTerms[i]
        local primary = term[2]
        local secondary = term[1]
        if (self.options[primary] ~= nil) or (self.options[secondary] ~= nil) then
            local finalValue
            if (self.options[primary] ~= nil) then finalValue = self.options[primary]
            else finalValue = self.options[secondary] end
            self.options[primary] = finalValue
            self.options[secondary] = nil
        end
    end
end

---@protected
---@param name string
---@param stack string[]
function MacroDefinition:circular(name, stack)
    if not rv.profile.awaiting[name] then return end
    stack = stack or {}
    local store = rv.profile.awaiting[name].waiting
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
    if rv.profile.nameMap[target] then return rv.profile.nameMap[target]
    else
        if rv.profile.awaiting[target] then
            rv.profile.awaiting[target].queue[#rv.profile.awaiting[target].queue + 1] = running()
            rv.profile.awaiting[target].waitNum = rv.profile.awaiting[target].waitNum + 1
        else rv.profile.awaiting[target] = { queue = { running() }, waitNum = 1 } end
        if self.name then
            if not rv.profile.awaiting[target].waiting then rv.profile.awaiting[target].waiting = { self.name }
            else rv.profile.awaiting[target].waiting[#rv.profile.awaiting[target].waiting + 1] = self.name end
            if not refOnly then self:circular(target) end
        end
        local yieldedName = yield() ---@type string
        rv.profile.awaiting[target].waitNum = rv.profile.awaiting[target].waitNum - 1
        --if rv.profile.awaiting[target].waitNum == 0 then rv.profile.awaiting[target] = nil end
        return yieldedName
    end
end

---@protected
---@param event Event
---@return KeyPress
function MacroDefinition:keyPress(event)
    return {
        actionDelay = self.options.actionDelay or rv.profile.config.actionDelay,
        keyDelay = self.options.keyDelay or rv.profile.config.keyDelay,
        actionVariance = self.options.actionVariance or rv.profile.config.actionVariance,
        keyVariance = self.options.keyVariance or rv.profile.config.keyVariance,
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
function MacroDefinition:blockNext(event, linked)
    if event.virtualType or linked then return end
    local block = self.options.blocking
    if block and #self.stack ~= 0 then
        local blockTargets = self.stack
        for i = 1, #blockTargets do local mac = (rv.profile.macroIndex[self.stack[i][1]] or {})
            if mac.type == "group" then mac.blocked = true end
        end
    end
end

---@param event Event
function MacroDefinition:runFree(event)
    if self.disabled then return end
    local options = self.options
    if rv.validator:skipConditions(event, options, self.type, self.pID, self.singleTrigger) then
        if rv.scriptStates.docMode and (self.terminus or self.manualDocumentation) then return rv.lcd:displayOnLCD(self.pID, 1) end
        local linked = event.link
        event.link = nil
        self:execute(event)
        self:blockNext(event, linked)
    end
end

---@param event Event
function MacroDefinition:run(event)
    if self.disabled then return end
    local options = self.options
    if rv.validator:validateConditions(event, options, self.pID, self.singleTrigger) then
        if rv.scriptStates.docMode and (self.terminus or self.manualDocumentation) then return rv.lcd:displayOnLCD(self.pID, 1) end
        local linked = event.link
        event.link = nil
        self:execute(event)
        self:blockNext(event, linked)
    end
end
---@protected
function MacroDefinition:errorHandler(msg)
    local name = self.name
    if not name then for i = 1, #self.stack do local stn = self.stack[i][2] if stn then name = "Child Macro of " .. stn end break end
    else name = "Macro " .. name end
    if not name then name = "a " .. self.type .. " macro" end
    rv.scriptStates.errors[#rv.scriptStates.errors + 1] = name .. " failed to initialize:\n  " .. msg
end

---@protected
function MacroDefinition:parseInstructions() self:finishInit() end
function MacroDefinition:parseDocs() rv.lcd:parseToDisplayDefinition(self.manualDocumentation or self:export(), self.pID, nil, nil, not self.manualDocumentation) end
---@param text string
---@param macroId string
function MacroDefinition:parseControls(text, macroId)
    if text and macroId then return rv.lcd:parseToDisplayDefinition(text, self.pID .. "_" .. macroId, 1) end
    local controlTypes = { { "multiPause", "Pausing" }, { "taskResume", "Resuming" }, { "taskAbort", "Canceling" } } ---@type string[][]
    for i = 1, #controlTypes do local con = controlTypes[i]
        rv.lcd:parseToDisplayDefinition(con[2] .. " macro '" .. self.name .. "'", self.pID .. "_" .. con[1], 1)
    end
end

---@private
function MacroDefinition:parseQualifiers()
    if self.options.mode then local modas = self.options.mode
        if type(modas) ~= "table" then modas = { modas } end
        for i = 1, #modas do local mod = modas[i]
            if type(mod) == "string" then
                local minus = match(mod, "^-")
                mod = (minus and sub(mod, 2)) or mod
                local realMod = rv.profile.deviceState[self.sourceDevice].modeIndex[mod]
                if not realMod then error("mode " .. mod .. " not found on " .. rv.profile.deviceState[self.sourceDevice].family) end
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

---@param option string
---@param output number|boolean
---@param duration number
function MacroDefinition:control(option, output, duration, _)
    local controls = {
        pause = "multiPause",
        cancel = "taskAbort",
        resume = "taskResume",
        toggle = (rv.threading:taskStatus(self.pID) == 1 and "multiPause") or "taskResume"
    }
    local action = controls[option or "cancel"]
    rv.threading[action](rv.threading, self.pID)
    if output then rv.lcd:displayOnLCD(self.pID .. "_" .. action, 1, duration) end
end

---@protected
function MacroDefinition:identify() return self.pID or (#self.subMacros ~= 0 and self.subMacros[#self.subMacros]) or nil end

function MacroDefinition:execute(...) end

return MacroDefinition