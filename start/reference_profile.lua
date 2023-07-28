local profile = ... ---@type ProfileTemplate#, Revenant
local k = profile.key -- Quick access to the `key` table used for standard bindings.

profile.config = {} -- Put your configuration settings in here.
profile.library = {} -- Defined a list of named macros that can be referenced in other parts of the profile.

k.m3 = "/3"

profile.documentation = {} -- Put your documentation here. For example If you have a key or macro named "interaction", assign some text to a property named "interaction" in this table, to make it show up in documentation mode.
