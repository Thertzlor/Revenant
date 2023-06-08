local rv = ... ---@type Revenant
local sub, gsub, type, pairs, abs, tonumber, next = string.sub, string.gsub, type, pairs, math.abs, tonumber, next

---Functions for dealing with tables.
---@class TableUtilitiesModule
local TableUtilitiesModule = rv.baseClass:new()

---Does the table have any enumerable contents besides empty tables?
---@param tab table
function TableUtilitiesModule:hasContent(tab)
   if type(tab) ~= "table" then return true end
   for i = 1, #tab do if self:hasContent(tab[i]) then return true end end
   return false
end

---Does the table only contain enumerable members of a single type?
---@param tab table
---@param ty string
function TableUtilitiesModule:isSingleTypeTable(tab, ty) -- Is there only a single data type stored in a table?
   if type(tab) ~= "table" then return false end
   for i = 1, #tab do if type(tab[i]) ~= ty then return false end end
   return true
end

---Splits a table into two tables, one containing numeric keys and on containing non numeric ones.
---@return table<number,any>,table<string,any>
function TableUtilitiesModule:splitEnumerable(tab)
   local commands = {}
   local options = {}
   if type(tab) ~= "table" then return {tab}, {} end
   for k, v in pairs(tab) do ((type(k) == "string" and options) or commands)[k] = v end
   return commands, options
end

---does the table contain non-numeric keys?
---@param tb table
---@return boolean
function TableUtilitiesModule:hasProperties(tb)
   for i in pairs(tb) do if type(i) == "string" and not self:find(rv.stringPresets.internalProps, i) then return true end end
   return false
end

---Recursively checks if two tables are identical
---@param t1 table
---@param t2 table
function TableUtilitiesModule:sameContent(t1, t2)
   local t1_num = 0
   local t2_num = 0
   if type(t1) ~= type(t2) then return false end
   if type(t1) ~= "table" then return t1 == t2 end
   for k, v in pairs(t1) do
      t1_num = t1_num + 1
      if not t2[k] or type(t2[k]) ~= type(t1[k]) then return false end ---recursive search
      if t2[k] and not self:find(rv.stringPresets.internalPropsName, k) then if type(v) == "table" and not self:sameContent(t1[k], t2[k]) then return false end end
   end
   for _, _ in pairs(t2) do t2_num = t2_num + 1 end
   return t2_num == t1_num
end

---Find a number or string in a table.
---@param t table|any
---@param s string
---@return boolean
function TableUtilitiesModule:find(t, s)
   if type(t) ~= "table" then return t == s end
   for i = 1, #t do if t[i] == s then return true end end
   return false
end

---Merge two tables in different ways.
---@param tBase table #the Base Table.
---@param tAdd table #the Added Table
---@param override? number
---@param exRay? table
function TableUtilitiesModule:intersect(tBase, tAdd, override, exRay)
   local resultTable = {}
   local overridingTable = {}
   local overrider = override or 1
   local ignoreLists = {{"pID", "name"}, {1, "type", "t", "pID", "name", "n", "newType", "update", "u"}, {1, "type", "t", "pID", "name", "n", "newType", "update", "u"}}
   -- We ignore a specific internal fields depending on the override mode.
   for k, v in pairs(tBase) do resultTable[k] = v end
   for k, v in pairs(tAdd) do overridingTable[k] = v end

   if override == 3 and type(exRay) == "table" then
      for m = 1, #exRay do ignoreLists[3][#ignoreLists[3] + 1] = exRay[m] end
   elseif override == 3 and type(exRay) == "string" then
      ignoreLists[overrider][#ignoreLists[overrider] + 1] = exRay
   end

   for k, v in pairs(overridingTable) do
      local ig = true
      for i = 1, #ignoreLists[overrider] do if k == ignoreLists[overrider][i] then ig = false end end
      if (override == 3 or override == 4) and k == "newType" then resultTable.type = v end -- type override for link bindings
      if (resultTable[k] == nil or override == 1 or override == 3) and sub(k, 1, 2) ~= "_c" and ig then resultTable[k] = v end
   end
   return resultTable
end

---@generic A table
---@generic B table
---@param first A #First table
---@param second B #Second Table
---@param replaceExisting? boolean #If true, the second table's contents can override the first one's.
---@return A|B
function TableUtilitiesModule:intersectSimple(first, second, replaceExisting)
   local out = {}
   for k, v in pairs(second) do
      if replaceExisting then
         if v ~= nil then out[k] = v end
      elseif first[k] == nil and v ~= nil then
         out[k] = v
      end
   end
   for k, v in pairs(first) do if out[k] == nil and v ~= nil then out[k] = v end end
   return out
end

---Convert an array of strings into a table using those strings
---@param array string[]
---@return table<string,true>
function TableUtilitiesModule:propsFrom(array)
   local obj = {}
   for i = 1, #array do obj[array[i]] = true end
   return obj
end

---Extract all string keys from a table
---@param tab table<string,any> #The table to extract keys from
---@return string[] #all keys in the table
function TableUtilitiesModule:getKeys(tab)
   local obj = {}
   for k in pairs(tab) do obj[#obj + 1] = k end
   return obj
end

---Pretty prints a Table
---@param tabu table|string
---@param specmes? string
---@param out? boolean
function TableUtilitiesModule:prettyTab(tabu, specmes, out)
   specmes = specmes and "\n" .. specmes .. "\n" or ""
   local processed = type(tabu) == "table" and rv.utils.pprint(tabu) or tabu --[[@as string]]
   local replacer = {{"[\n]", ""}, {" +", " "}, {"^{ *", ""}, {"}$", ""}, {", pID = \"[^\"]+\"", ""}, {", ([gmkal][0-9])", ",\n%1"}}
   for i = 1, #replacer do processed = gsub(processed, replacer[i][1], replacer[i][2]) end
   local finalString = specmes .. processed
   return (out and finalString) or rv:put(finalString)
end

---Cycle through a table's index with looping
---@param targetIndex table|integer
---@param max integer|string
---@param current integer|boolean
function TableUtilitiesModule:cycleIndex(targetIndex, max, current)
   if not targetIndex then return 1 end
   if type(targetIndex) ~= "number" then targetIndex = #targetIndex end
   if not max or max == 0 then
      max = (current or 0) + 1
      if max > targetIndex then max = 1 end
   elseif type(max) ~= "number" then
      if type(max) ~= "string" or not current then return 1 end
      local sign = sub(max, 1, 1)
      local parsedNum = tonumber(sub(max, 2)) --[[@as integer]]
      if type(current) == "number" and (not parsedNum or (sign ~= "+" and sign ~= "-")) then return current end
      max = (current + (parsedNum * (sign == "-" and -1 or 1))) % (targetIndex or 1)
   elseif max > targetIndex then
      max = targetIndex
   elseif max < 0 then
      if abs(max) > targetIndex then
         max = 1
      else
         max = targetIndex + max
      end
   end
   return max
end

---Check if an assignment is a macro a group of macros or an empty table
---@return "group"|"macro"|"empty"
---@param tbl table|string
function TableUtilitiesModule:identifyTableType(tbl)
   local t = type(tbl)
   if t == "string" then -- strings count as key macros
      return "macro"
   elseif t == "nil" then -- nil is obviously empty
      return "empty"
   elseif t ~= "table" then -- non table types
      error("Malformed Macro or Group, invalid type '" .. t .. "'", 2)
   end
   local cm, op = self:splitEnumerable(tbl)
   if next(op) then
      if (op.type or op.t) then
         tbl.type = op.type or op.t
         tbl.t = nil
         return "macro"
      elseif #cm == 0 then
         return "empty"
      elseif #cm == 1 and type(cm[1]) == "string" then
         return "macro"
      else
         return "group"
      end
   elseif #cm == 1 and type(cm[1]) == "string" then
      return "macro"
   elseif #cm ~= 0 then
      return "group"
   else
      return "empty"
   end
end

---Get the correct class for a table identified as a macro
---@param def table
---@return MacroDefinition|false
function TableUtilitiesModule:getMacroClass(def)
   local detected = self:identifyTableType(def)
   if detected == "group" then
      def.type = "group" -- group macros don't need to be designated, so we add the type automatically
      return rv:classImport("GroupMacro")
   elseif detected == "macro" then
      if type(def) == "string" then
         def = {def, type = "key"} -- simple key macros
      elseif not def.type then
         def.type = "key" -- macros are key macros by default
      end
      local macroType = rv.classMap[def.type]
      def.type = macroType[2] -- removing shortcut definitions
      return rv:classImport(macroType[1])
   end
   return false
end

---Append to number indexed tables to each other
---@param t1 table
---@param t2 table
function TableUtilitiesModule:add(t1, t2)
   local combi = {}
   for i = 1, #t1 do combi[#combi + 1] = t1[i] end
   for i = 1, #t2 do combi[#combi + 1] = t2[i] end
   return combi
end

---@param profile ProfileDefinition
function TableUtilitiesModule:optionResolver(profile)
   local mappedTerms = rv.stringPresets.shortMapper
   local defaultTerms = rv.stringPresets.optionDefaults
   ---@param mac MacroInitDefinition
   ---@param prop string
   local function resolve(mac, prop)
      local mapped = mappedTerms[prop]
      local directLong = mac[prop]
      local defaultLong = profile.assign.scopeDefaults[prop]
      local defaultShort ---@type string
      local directShort ---@type string
      if mapped then
         defaultShort = profile.assign.scopeDefaults[mapped]
         directShort = mac[mapped]
      end
      local fallback = defaultTerms[prop] and profile.config[defaultTerms[prop]]
      return directLong or directShort or defaultLong or defaultShort or fallback or nil -- None of the Determinants can be false so we don't care about it here
   end

   return resolve
end

---Checks if a macro is an automatically generated group or a user created one
---@param macro MacroInitDefinition|{__autoName?:boolean} #the macro to check
---@return boolean #`true` if the group was defined by the user
function TableUtilitiesModule:isActualGroup(macro)
   if macro.__autoName then ---if there are any keys besides "name" and "__autoName" the group is user defined
      for k in pairs(macro) do if type(k) == "string" and k ~= "name" and k ~= "__autoName" then return true end end
      return false
   else
      return self:hasProperties(macro)
   end
end

return TableUtilitiesModule
