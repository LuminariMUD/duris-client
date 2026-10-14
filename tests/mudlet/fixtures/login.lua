local T=DurisTest
T.async=true
T.emit("Char.Status",{name="VisualTester"})
T.emit("Char.Status",{name="VisualTester",level=26})
tempTimer(1.3,function()
 local ok,err=xpcall(function()
  T.check(#T.commands==1 and T.commands[1].command=="time","one time query per login")
  raiseEvent("sysConnectionEvent")
  T.emit("Char.Status",{name="VisualTester"})
 end,debug.traceback)
 if not ok then T.finish(false,err);return end
 tempTimer(1.3,function()
  local ok,err=xpcall(function() T.check(#T.commands==2 and T.commands[2].command=="time","new connection requests time again") end,debug.traceback)
  T.finish(ok,err)
 end)
end)
