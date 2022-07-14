---@meta
--[[=============================================================]] --
--Type definitions for intellisense, never loaded.
--descriptions taken from the logitech lua API manual
--[[=============================================================]] --
---@alias EventType "PROFILE_ACTIVATED"|"PROFILE_DEACTIVATED"|"G_PRESSED"|"G_RELEASED"|"M_PRESSED"|"M_RELEASED"|"MOUSE_BUTTON_PRESSED"|"MOUSE_BUTTON_RELEASED"
--[[=============================================================]] --
---GetRunningTime() returns the total number of milliseconds elapsed since the script has been running.
GetRunningTime = nil ---@type fun():integer
---OutputLogMessage() will send log messages into the script editor.
OutputLogMessage = nil ---@type fun(msg:string)
---SetMouseDPITable() sets the current DPI table for a supported gaming mouse
SetMouseDPITable = nil ---@type fun(table:integer[],index?:integer)
---SetMouseDPITableIndex() sets the current DPI table index for a supported gaming mouse
SetMouseDPITableIndex = nil ---@type fun(idx:integer)
---The OnEvent() function serves as the event handler for the script.
OnEvent = nil ---@type fun(event:EventType,arg:integer,fam:HardwareFamily)
---GetMKeyState() returns the current state of the M keys.
GetMKeyState = nil ---@type fun(family?:HardwareFamily):integer
---SetMKeyState() sets the current state of the M keys. NOTE: Calling GetMKeyState immediately afterwards, will likely return the previous state. Use the OnEvent handler to determine when the operation has completed.
SetMKeyState = nil ---@type fun(state:integer,family?:HardwareFamily)
---Sleep() will cause the script to pause for the desired amount of time.
Sleep = nil ---@type fun(duration:integer)
---Use GetDate() to retrieve the formatted date
GetDate = nil ---@type fun(format:string,time:table):string|string[]
---The ClearLog() function clears the output window of the script editor.
ClearLog = nil ---@type fun()
---The PressKey() function is used to simulate a keyboard key press. NOTE: Calling IsModifierPressed or IsKeyLockOn immediately afterwards for a simulated modifier or lock key will likely return the previous state. It will take a few milliseconds for the operation to complete.
PressKey = nil ---@type fun(keyCode:string|integer, scanCode?:string|integer)
---The ReleaseKey() function is used to simulate a keyboard key release.
ReleaseKey = nil ---@type fun(keyCode:string|integer, scanCode?:string|integer)
---The PressAndReleaseKey() function is used to simulate a keyboard key press followed by a release. NOTE: Calling IsModifierPressed or IsKeyLockOn immediately afterwards for a simulated modifier or lock key will likely return the previous state. It will take a few milliseconds for the operation to complete.
PressAndReleaseKey = nil ---@type fun(keyCode:string|integer, scanCode?:string|integer)
---The IsModifierPressed() function is used to determine if a particular modifier key is currently in a pressed state.
IsModifierPressed = nil ---@type fun(keyName:string):boolean
---The PressMouseButton() function is used to simulate a mouse button press. NOTE: Calling IsMouseButtonPressed immediately afterwards, will likely return the previous state. It will take a few milliseconds for the operation to complete.
PressMouseButton = nil ---@type fun(button:integer)
---The ReleaseMouseButton() function is used to simulate a mouse button release.
ReleaseMouseButton = nil ---@type fun(button:integer)
---The PressAndReleaseMouseButton() function is used to simulate a mouse button press followed by a release. NOTE: Calling IsMouseButtonPressed immediately afterwards, will likely return the previous state. It will take a few milliseconds for the operation to complete.
PressAndReleaseMouseButton = nil ---@type fun(button:integer)
---The IsMouseButtonPressed() function is used to determine if a particular mouse button is currently in a pressed state.
IsMouseButtonPressed = nil ---@type fun(button:integer)
---The MoveMouseTo() function is used to move the mouse cursor to an absolute position on the screen. NOTE: Calling GetMousePosition immediately afterwards, will likely return the previous state. It will take a few milliseconds for the operation to complete.
MoveMouseTo = nil ---@type fun(x:integer,y:integer)
---The MoveMouseWheel() function is used to simulate mouse wheel movement.
MoveMouseWheel = nil ---@type fun(click:integer)
---The MoveMouseRelative() function is used to simulate relative mouse movement. NOTE: Calling GetMousePosition immediately afterwards, will likely return the previous state. It will take a few milliseconds for the operation to complete.
MoveMouseRelative = nil ---@type fun(x:integer,y:integer)
---The MoveMouseToVirtual() function is used to move the mouse cursor to an absolute position on a multi-monitor screen layout. NOTE: Calling GetMousePosition immediately afterwards, will likely return the previous state. It will take a few milliseconds for the operation to complete.
MoveMouseToVirtual = nil ---@type fun(x:integer,y:integer)
---The GetMousePosition() function returns the normalized coordinates of the current mouse cursor location.
GetMousePosition = nil ---@type fun():integer,integer
---The OutputLCDMessage() function is used to add a line of text on to the LCD.
OutputLCDMessage = nil ---@type fun(text:string,timeOut:integer)
---The ClearLCD() function clears the script display on the LCD.
ClearLCD = nil ---@type fun()
---The PlayMacro () function is used to play an existing macro.
PlayMacro = nil ---@type fun(macroname:string)
---The AbortMacro() function is used to abort any macro started from a script. Any keys still pressed after a call to PlayMacro will be released. Macros playing outside the script will continue to play.
AbortMacro = nil ---@type fun()
---The IsKeyLockOn() function used to determine if a particular lock button is currently in an enabled state .
IsKeyLockOn = nil ---@type fun(key:string):boolean
---The SetBacklightColor() function is used to set the custom backlight color of the device (if the device supports custom backlighting).
SetBacklightColor = nil ---@type fun(r:integer,g:integer,b:integer,family?:HardwareFamily)
---OutputDebugMessage() will send log messages to the Windows debugger.
OutputDebugMessage = nil ---@type fun(msg:string)
---EnablePrimaryMouseButtonEvents() enables event reporting for mouse button 1.
EnablePrimaryMouseButtonEvents = nil ---@type fun(arg:integer)
---SetSteeringWheelProperty() sets a steering wheel property.
SetSteeringWheelProperty = nil ---@type fun(device:string,property:string,value:any)
