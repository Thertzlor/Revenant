local tl = ...
local match, gmatch,concat,type,pairs = string.match, string.gmatch,table.concat,type,pairs
local typeValues = { --List for the different valid macro designations of the library
  "mt","c","s","h","n","d","dr","u","et","p","pr","eh","vb","b","mn","m","t","nt","bf","hc","dh","e","w","sa","fn","cr","sp","sr","o","ea","v","doc","l"
}
tl.propertyDefinitions = { -- typdeDefs for properties
    type = {
      type = "string",
      values = typeValues
    },
    gshift = {
      type = "number",
      range = {0,2}
    },
    mode = {type = {"number","table","string"}},
    mkey = {
      type = "string",
      test = tl.validMod
    },
    consume = {
      type = "number",
      range = {1,3}
    },
    loop = { type= "number", range={-1}},
    play = { 
      type = "string",
      values = {"hold","toggle","normal","phold","ptoggle"}
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
      type = "number" 
    },
    keyDelay = { 
      type = "number" 
    },
    name = { 
      type = "string" 
    },
    update = {
      type = "table" 
    },
    test = {},
    logic = {
      type="string",
      values={"and","or","nor","nand","xor","xnor"}
    },
    cast = {
      type="string",
      values=typeValues
    },
    doc={
      type="string"
    },
    cancel={
      type="number"
    },
    monitor={
      type="number"
    },
    unlock = {
      type = {"string","table"},
      values = {"shift","mode","mkeys","area","test"}
    },
    keepExisting={},
    newType = {
      type = "string",
      values = typeValues
    },
    release = {
      type = "string",
      values = {"auto","hold"}
    },
    init = {
      type = "boolean"
    },
    stagger = {
      type = "string",
      values = {"absolute","relative","additive"}
    },
    inherit = {
      type = "string",
      values = {"all","none","timing","status"}
    },
    finish = {
      type = {"table","string"},
      values = {"stall","end","reset"}
    },
    limit = {
      type = "number",
      range = {0}
    },
    range = {
      type = "table"
    },
    area = {
      type = "table"
    },
    pID={},
    _scope={},
    _isCont={}
}

function tl.validMod(val) --checks if a modifier check is a valid modifier code
  for i in gmatch(val, "%a%a") do 
    if match( i,"[grl][cas]") == nil or match( i,"[cs]l" ) == nil then
      return false , "'"..i.."' is not a valid modifier code"
    end 
  end
  return true
end

function tl._lintingProcess(table) --the main linting function for properties and their contents
  local def
  for k,v in pairs(table) do
    if type(k) == "string" and not(tl.rename[k] or tl.unname[k])  then
        if not tl.propertyDefinitions[k] then return false, "Found unknown property '"..k.."'" end
        def = tl.propertyDefinitions[k]
        if def.type and not tl.find(def.type,type(v)) then return false, "Property '"..k.."' of invalid type "..type(v) end
        if def.values and (type(v) == "string" or type(v) == "number") and not tl.find(def.values,v)  then return false, "'"..v.."' is not a valid value for property '"..k.."'. Accepted values are: '"..concat( def.values, "' ,'").."'" end
        if def.range and type(v) == "number"and ((def.range[1] and v < def.range[1]) or (def.range[2] and v > def.range[2])) then return false, "Value '"..v.."' is out of range for property '"..k.."'."  end
        if def.test then return def.test(v) end
    end
  end
  return true
end

function tl.linter(table,parentKey) --wrapper function for executing and outputting linting results
  if(parentKey == nil) then return true end
  local res , mes = tl._lintingProcess(table)
  if res == false then
    local fullMes = "LINT ERROR: "..mes.." on '"..(tl.rename[parentKey] or tostring(parentKey)).."'"
    tl.lintErrors[tl.unname[parentKey] or tostring(parentKey)] = fullMes
  end
  return res
end