local T=DurisTest
assert(loadfile(getMudletHomeDir().."/Duris Test Companion/fixtures/lowhp.lua"))()
local main, state, handlers = ArjUI.main, ArjUI.state, #ArjUI.eventHandlers
expandAlias("ui off")
expandAlias("ui set compactHeader on")
T.check(ArjUI.hidden and ArjUI.main.hidden and ArjUI.bg.hidden,"compact selection while hidden stays hidden")
expandAlias("ui on")
for i=1,3 do
 expandAlias("ui off")
 T.check(ArjUI.hidden and ArjUI.main.hidden, "hide "..i)
 feedTriggers("Hidden main console "..i.."\n")
 T.check(T.lines():find("Hidden main console "..i,1,true), "main console usable while hidden")
 expandAlias("ui on")
 T.check(ArjUI.main==main and ArjUI.state==state and ArjUI.state.hp==150, "state/widgets retained "..i)
 T.check(#ArjUI.eventHandlers==handlers, "no duplicate handlers "..i)
end
ArjUI.initialDataRequested=false
ArjUI:onLoginDetected() -- Pending time query must be canceled by uninstall.
ArjAuto:after(.3, function() send("UNEXPECTED-after-uninstall") end)
T.emit("Room.Info",{num=90010,zone=9002,name="Pending download",exits={}})
T.check(ArjMapper.requests[9002]~=nil,"map download pending before uninstall")
local aliasIds={}
for _,id in ipairs(ArjAuto.aliases) do aliasIds[#aliasIds+1]=id end
local triggerIds={}
for _,id in ipairs(ArjUI.runtimeTriggers) do triggerIds[#triggerIds+1]=id end
for _,id in ipairs(ArjAuto.triggers) do triggerIds[#triggerIds+1]=id end
local thirdParty=Adjustable.Container:new({name="DurisTest_ThirdParty",autoSave=false,autoLoad=false,x=0,y=0,width=100,height=70})
local ownedNames={}
for _,panel in pairs(ArjUI.panels) do ownedNames[#ownedNames+1]=panel.frame.name end
ArjUI:openPrivateChat("Companion")
ownedNames[#ownedNames+1]=ArjUI.panels["tell:companion"].frame.name
ArjMapper:refreshViewport()
uninstallPackage("Arjinius Client")
for _,name in ipairs(ownedNames) do T.check(Adjustable.Container.all[name]==nil,"owned frame unregistered "..name) end
T.check(Adjustable.Container.all.DurisTest_ThirdParty==thirdParty,"uninstall preserves third party frame")
T.check(ArjMapper.viewportTimer==nil,"uninstall cancels pending viewport redraw")
thirdParty:delete()
T.check(not ArjUI.main and #ArjUI.eventHandlers==0 and #ArjMapper.handlers==0, "uninstall cleans widgets and handlers")
feedTriggers("After uninstall: ordinary text must remain in the main console.\n")
T.async=true
tempTimer(1.3,function()
 local ok,err=xpcall(function()
  -- Mudlet queues temporary-object deletion until the callback returns.
  for _,id in ipairs(aliasIds) do T.check(exists(id,"alias")==0,"removed alias "..id) end
  for _,id in ipairs(triggerIds) do T.check(exists(id,"trigger")==0,"removed trigger "..id) end
  T.check(#T.commands==0,"no delayed commands after uninstall")
  T.check(not next(ArjMapper.requests) and not ArjMapper.ui.zoneContainer,"late download leaves no handlers or widgets")
  assert(installPackage(T.run.."/duris-client.mpackage"))
 end,debug.traceback)
 if not ok then T.finish(false,err); return end
 tempTimer(.8,function()
  local ok,err=xpcall(function()
   T.check(ArjUI.main and ArjMapper.ui.zoneContainer,"reinstall initializes UI and mapper")
   T.check(#ArjUI.eventHandlers==handlers,"replacement has exactly one set of handlers")
   T.check(ArjUI.settings.compactHeader==true,"reinstall loads saved compact preference before layout")
   assert(loadfile(getMudletHomeDir().."/Duris Test Companion/fixtures/lowhp.lua"))()
  end,debug.traceback)
  T.finish(ok,err)
 end)
end)
