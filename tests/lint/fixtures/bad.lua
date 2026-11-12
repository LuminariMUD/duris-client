-- Each flagged line number is listed in bad.expected (one finding per number).
local Bad = {}
os.execute("rm -rf /")
local h = io.popen("ls")
local f = loadstring("return 1")
dofile("x.lua")
local g = load("return 2")
Bad.t = tempTimer(1, [[send("look")]])
Bad.k = tempKey(mod, key, "send('flee')")
tempTimer(5, function() end)
registerAnonymousEventHandler("gmcp.Char.Vitals", function() end)
  tempAlias("^x$", function()
  end)
return Bad
