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
Bad.repeatTimer = tempTimer(.25, "send('look')", true)
Bad.key = tempKey(key, "send('look')")
Bad.lines = tempLineTrigger(1, 2, "send('look')")
local crown = "\u{2654} leader"
return Bad
