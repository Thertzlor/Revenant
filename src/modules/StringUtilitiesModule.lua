local rv = ... ---@type Revenant
local lower, sub, type, gsub = rv.utf8.lower, rv.utf8.sub, type, string.gsub

---Functions that process or type strings
---@class StringUtilitiesModule
local StringUtilitiesModule = rv.baseClass:new()

---@param str string
function StringUtilitiesModule:valid(str) return type(str) == "string" and #str ~= 0 end

---Outputs the first character of a string in lowercase.
---@generic T:string
---@param f T
---@return T
function StringUtilitiesModule:token(f)
   if type(f) ~= "string" then return "" end
   return lower(sub(f, 1, 1))
end

---@param string string
---@param fam FamilyToken
---@param num integer
---@param scope "family"| "global"|"key"
function StringUtilitiesModule:addStringBuffer(string, fam, num, scope)
   local bufferTarget ---@type table
   local state = rv.profile.deviceState
   if scope == "family" then
      bufferTarget = state[fam]
   elseif scope == "global" then
      bufferTarget = rv.profile.globalState
   else
      if (not state[fam].keyBuffers["_b" .. num]) then state[fam].keyBuffers["_b" .. num] = {} end
      bufferTarget = state[fam].keyBuffers["_b" .. num]
   end
   bufferTarget.bufferContent = (bufferTarget.bufferContent ~= nil and bufferTarget.bufferContent .. string) or string
end

---@param str string
---@param rep? string
function StringUtilitiesModule:unbreak(str, rep) return gsub(str, "\n", rep or "\\n") end

---@param str string
function StringUtilitiesModule:firstLower(str) return lower(sub(str, 1, 1)) .. sub(str, 2, #str) end

return StringUtilitiesModule
