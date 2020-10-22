local tl = ...---@type MainLibObject
local BaseMacro = tl:classImport('BaseMacro')
local type = type
---@class MouseMoveMacro:BaseMacro
local MouseMoveMacro = BaseMacro:new()
MouseMoveMacro.singleTrigger = true


return MouseMoveMacro