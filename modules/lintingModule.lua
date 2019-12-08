---@type MainLibObject
local tl = ...
local match, gmatch,concat,type,pairs =
string.match, string.gmatch,table.concat,type,pairs
-->>>>> Functions for T-Lib specific linting ================================================================

---checks if a modifier check is a valid modifier code.
---@param val string
---@return boolean,string
local function _validMod(val)
  for i in gmatch(val, "%a%a") do
    if match( i,"[grl][cas]") == nil and match( i,"[cs]l" ) == nil then
      return false , "'"..i.."' is not a valid modifier code"
    end
  end
  return true
end

---the main linting function for properties and their contents
---@param table table
---@param typeCast string
---@return boolean,string
local function _lintingProcess(table,typeCast)
  local def
  local tableType = table.type or typeCast
  for k,v in pairs(table) do
    if type(k) == "string" and not(tl.config.rename[k] or tl.unname[k])  then
        if not tl.propertyDefinitions[k] and not match(k,"^mode%d+") and not match(k,"^s%d+") and not match(k,"^_c") then return false, "Found unknown property '"..k.."'" end
        def = tl.propertyDefinitions[k]
        if tableType and def.propertyOf and not tl.find(def.propertyOf,tableType) then return false, "A macro of type '"..tableType.."' has no property '"..k.."'" end
        if def and def.type and not tl.find(def.type,type(v)) then return false, "Property '"..k.."' of invalid type "..type(v) end
        if def and def.values and (type(v) == "string" or type(v) == "number") then
          if (not tableType) or not def.values[tableType] then
            if #def.values ~= 0 and not tl.find(def.values,v) then return false, "'"..v.."' is not a valid value for property '"..k.."'. Accepted values are: '"..concat( def.values, "' ,'").."'" end
          elseif def.values[tableType] then
            if not tl.find(def.values[tableType],v) then return false, "'"..v.."' is not a valid value for property '"..k.."' on macro type '"..tableType.."'. Accepted values are: '"..concat( def.values[tableType], "' ,'").."'" end
          end
        end
        if type(v) == "string" then local illegalStart = match(v, "^[%!%^%°%:%~%#%/\\%@%-]") if illegalStart then return false , "Found string value starting with illegal character '"..illegalStart.."' on property "..k  end end
        if def and def.range and type(v) == "number"and ((def.range[1] and v < def.range[1]) or (def.range[2] and v > def.range[2])) then return false, "Value '"..v.."' is out of range for property '"..k.."'."  end
        if def and def.test then return def.test(v) end
    end
  end
  return true
end

---Wrapper function for executing and outputting lint results
---@param table table
---@param parentKey string
---@param typeCast string
function tl.linter(table,parentKey,typeCast)
  if(parentKey == nil) then return true end
  local res , mes = _lintingProcess(table,typeCast)
  if res == false then
    local fullMes = "LINT ERROR: "..mes.." on '"..(tl.config.rename[parentKey] or tostring(parentKey)).."'"
    tl.lintErrors[tl.unname[parentKey] or tostring(parentKey)] = fullMes
  end
  return res
end

tl.propertyDefinitions = { -- typdeDefs for properties
    type = {
      type = "string",
      values = tl.rawFuncTerms
    },
    gshift = {
      type = "number",
      range = {0,2}
    },
    mode = {type = {"number","table","string"}},
    mkey = {
      type = "string",
      test = _validMod
    },
    consume = {
      type = "number",
      range = {1,3}
    },
    loop = {
      type= "number",
      range={-1},
      propertyOf="s"
    },
    play = {
      type = "string",
      values = {s={"hold","toggle","normal","phold","ptoggle"},e={"hold","toggle","normal"}},
      propertyOf = {"s","e"}
    },
    direction = {
      type = "string" ,
      values = {"up","normal"}
    },
    stack={
      type="number",
      range={0,2}
    },
    actionDelay = {
      type = "number",
      propertyOf="s"
    },
    keyDelay = {
      type = "number",
      propertyOf="s"
    },
    kdelay = {
      type = "number",
      propertyOf="s"
    },
    delay = {
      type = "number",
      propertyOf="s"
    },
    name = {
      type = "string"
    },
    update = {
      type = "table",
      propertyOf="l"
    },
    test = {},
    logic = {
      type="string",
      values={"and","or","nor","nand","xor","xnor"}
    },
    cast = {
      type="string",
      values=tl.rawFuncTerms,
      propertyOf = {"s","c","h"}
    },
    doc={
      type="string"
    },
    cancel={
      type="number",
      propertyOf="c"
    },
    monitor={
      type="number",
      propertyOf="p"
    },
    unlock = {
      type = {"string","table"},
      values = {"shift","mode","mkeys","area","test"}
    },
    keepExisting={
      propertyOf = "l"
    },
    newType = {
      type = "string",
      values = tl.rawFuncTerms,
      propertyOf = "l"
    },
    release = {
      type = "string",
      values = {"auto","hold"},
      propertyOf="h"
    },
    init = {
      type = "boolean",
      propertyOf="h"
    },
    stagger = {
      type = "string",
      values = {"absolute","relative","additive"},
      propertyOf="h"
    },
    inherit = {
      type = "string",
      values = {"all","none","timing","status"},
      propertyOf="c"
    },
    finish = {
      type = {"table","string"},
      values = {"stall","end","reset"},
      propertyOf="c"
    },
    limit = {
      type = "number",
      range = {0},
      propertyOf="c"
    },
    range = {
      type = "table",
      propertyOf="c"
    },
    area = {
      type = "table"
    },
    timer = {
      type = "number",
      range = {0},
      propertyOf = "t"
    },
    pID={},
    _scope={},
    _isCont={}
}