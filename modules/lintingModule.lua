local tl = ...
local match, gmatch = string.match, string.gmatch
tl.nativeProperties = {
    type = {
      type = "string",
      values = {
        "mt","c","s","h","n","d","dr","u","et","p","pr","eh","vb","b","mn","m","t","nt","bf","hc","dh","e","w","sa","fn","cr","sp","sr","o","ea","v","doc"
      }
    },
    gshift = {
      type = "number",
      values = {0,1,2}
    },
    mode = {type = {"number","table"}},
    mkey = {
      type = "string",
      test = tl.validMod
    },
    consume = {
      type = "number",
      values = {1,2}
    },
    loop = { type= "number"},
    play = { 
      type = "string",
      values = {"hold","toggle","normal"}
    },
    direction = { 
      type = "string" ,
      values = {"up","down"}
    },
    actionDelay = {type = "number" },
    keyDelay = { type = "number" },
    name = { type = "string" },
    update = { type = "table" },
    test = {},
    area = {type="table"}
}

function tl.validMod(val)
  for i in gmatch(val, "%a%a") do 
    if match( i,"[grl][cas]") == nil or match( i,"[cs]l" ) == nil then
      return false , "'"..i.."' is not a valid modifier code."
    end 
  end
  return true
end

function tl.linter(table,parentKey)
  for k,v in pairs(table) do
    if type(k) == string and not tl.nativeProperties[k] then return false, "unknown property "..k.."found" end
  end
  return true
end