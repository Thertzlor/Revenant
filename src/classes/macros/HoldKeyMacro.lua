local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')
local type = type
---@class HoldKeyMacro:BaseMacro
local HoldKeyMacro = BaseMacro:new()
HoldKeyMacro.singleTrigger = true


return HoldKeyMacro