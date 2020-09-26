local tl, Base = ...
local rawset,type, setmetatable = rawset,type ,setmetatable

local ProfileManager = Base:new()

function ProfileManager:autoTable(table)
  table = table or {}
  local magicMeta = {
    __index=function(table,key)
        if not self.autoKeys then return nil elseif key == "_meta" then return true end
        local newInf = self:autoTable()
        rawset(table,key,newInf)
        return newInf
    end,
    __newindex = function(table,key,value)
        if not self.autoKeys then return rawset(table,key,value) end
        if type(value) == "table" and not value._meta then value = self:recursiveTable(value) end
        rawset(table,key,value)
    end,
    __tostring = tl.helperUtils.pprint
  }
  setmetatable(table, magicMeta);
  return table
end


---@param b string | "'onClosed'" | "'onData'"
local function diablo(a,b)
if a == "onFull" then end
end

function ProfileManager:recursiveTable(table)
    for k, v in pairs(table) do if type(v) == "table" and not v._meta then 
        table[k]=self:recursiveTable(v)
        end
    end
    return self:autoTable(table)
end

---@alias MacTable GenericMacro[]|table<string,GenericMacro>

function ProfileManager:constructor()
  self.autoKeys = true
  ---@type MacTable
  self.assign = self:autoTable()
  diablo(self.assign)
end


local profile = ProfileManager:new()



--profile.autoKeys = false;

profile.assign.supi.sabi = {dangbor={},3}

profile.assign.supi.sabi.dangbor.felicia.shorpy = "thought so"

profile:recursiveTable({"dibadu",3,florence="hop"})
profile.autoKeys = false
tl:put(profile.assign)

profile.assign.b1 = { {},{}}

return ProfileManager