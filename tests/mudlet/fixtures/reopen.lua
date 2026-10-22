-- Executed only after the controller saves, closes and reopens the same profile.
local T=DurisTest
local ok,err=xpcall(function()
 T.check(getMudletHomeDir()==T.config.profile,"reopened intended saved profile")
 T.check(not select(3,getConnectionInfo()),"reopened offline")
 T.check(ArjUI.main and ArjMapper.ui.zoneContainer,"saved package initializes after full restart")
 if T.config.scenario=="layout" then
  T.check(ArjUI.panels.items.state.hidden,"hidden panel restored after restart")
  T.check(ArjUI.panels.chat.state.minimized,"minimized panel restored after restart")
  T.check(ArjUI.panels.mobs.state.mode=="floating" and math.abs(ArjUI.panels.mobs.state.rect[1]-.2)<.001,"normal rectangle restored after restart")
  T.check(not ArjUI.maximizedPanel,"maximize is transient")
  expandAlias("ui layout reset")
 end
 assert(loadfile(getMudletHomeDir().."/Duris Test Companion/fixtures/lowhp.lua"))()
end,debug.traceback)
T.finish(ok,err)
