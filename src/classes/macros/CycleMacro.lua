local tl = ...---@type MainLibObject
local type,GetRunningTime,abs = type, GetRunningTime,math.abs
local BaseMacro = tl:classImport('BaseMacro')

---@class CycleMacro:BaseMacro
---@field options {limit:number,cancel:number,inherit:string,finish:string,range:number[]}
---@field profile ProfileDefinition
local CycleMacro = BaseMacro:new()

function CycleMacro:execute(event)
local dir = event.dir
local vir = event.vir
local virtparent = event.virtParent
local fam = event.family
local num = event.num
local tar = self.command

  if type(tar) ~= "table" then return end
  local step = 1
  local lim =  (self.options.limit == 0 and huge) or self.options.limit or huge
  local inherit = self.options.inherit or "all"
  local rupture = self.options.cancel or 0
  local parent = (virtParent and type(virtParent) ~= "number" and "_" .. parent) or virtParent or 999
  local currentPosition = ((rupture == 1 or rupture < 0) and self.profile.deviceState[fam].unstable) or self.profile.deviceState[fam].stable
  local quitter = self.options.finish or "stall"
  local start = 1
  local init = start
  local finish = #tar
  if type(self.options.range) == "table" and tl.tbl:isSingleTypeTable(tar.range, "number") then
    local range = self.options.range
    for j = 1, range do
      if range[j] <= 0 then range[j] = #tar + range[j] end
    end
    if range[2] and range[2] < #tar then init = range[2] end
    if range[1] < #tar then start = range[1] end
    finish = range[3] or finish
    if finish > #tar then finish = #tar end
  end
  local directed = vir and 2 or 3
  
  if currentPosition["_" .. self.pID] == nil or (vir and dir == "down" and (self.profile.deviceState[fam].unstable[parent] == 1 
  or self.profile.deviceState.deviceState[fam].stable[parent] == 1) and self.state.cyclesComplete == 1 and inherit ~= "timing" and inherit ~= "none") then
    currentPosition["_" .. tar.pID] = init
    self.state.cyclesComplete = 1
    self.state.cycleTimer = GetRunningTime()
  elseif rupture ~= 0 and rupture ~= 1 and (vir ~= nil or dir == "down") and (GetRunningTime() - tar._meta.cycleTimer > abs(rupture)) then
    currentPosition["_" .. tar.pID] = init
    self.state.cyclesComplete = 1
  end

  if type(self.state.cyclesComplete) == "number" and self.state.cyclesComplete > lim then
    if quitter == "end" then
      return
    elseif quitter == "reset" then
      currentPosition["_" .. tar.pID] = init
      self.state.cyclesComplete = 1
    elseif type(quitter) == "table" then
      self.options.finish = quitter
      if not quitter.type then quitter.type = self.options.cast end
      tl.bindings:launchMacro(num, fam, tar.finish, directed, dir, quitter.pID)
      return
    end
  end
  if vir and virtParent and inherit ~= "status" and inherit ~= "none" then
    self.state.cycleTimer = tl.macroIndex[parent]._meta.cycleTimer
  else
    self.state.cycleTimer = GetRunningTime()
  end
  if currentPosition["_" .. self.pID] ~= 1 or type(tar[currentPosition["_" .. self.pID]]) ~= "number" then
    local mac = tar[currentPosition["_" .. self.pID]]
    if type(mac) == "table" and not mac.type then mac.type = self.options.cast end
    tl.bindings:launchMacro(num, fam, mac, directed, dir, tar.pID)
  end
  if vir ~= nil or dir == "up" then
    while type(tar[currentPosition["_" .. self.pID] + step]) == "number" do step = step + 1 end
    currentPosition["_" .. self.pID] = currentPosition["_" .. self.pID] + step
    if currentPosition["_" .. self.pID] > finish or currentPosition["_" .. self.pID] > #tar then
      if not (init > finish and currentPosition["_" .. self.pID] <= #tar and self.state.cyclesComplete == 1) then
        if tar._meta.cyclesComplete < lim then
          currentPosition["_" .. self.pID] = start
          tar._meta.cyclesComplete = self.state.cyclesComplete + 1
        else
          tar._meta.cyclesComplete = lim + 1
          currentPosition["_" .. self.pID] = #tar
        end
      end
    end
  end


end

function CycleMacro:parseSubMacros()end

return CycleMacro