```lua
k.m4 = {
   { "x", type = "keydown" }, 
   { "x", type = "keyup", name = "upX" }, 
   1000,
   { {"upX"}, "yz", type = "sequence" }, 
   release = "hold", init = true, type = "holdkey"
}

k.m4 = { {"x", t = "d"}, "x", 1000, "xyz", release = "hold", init = true, t = "h" } 

```