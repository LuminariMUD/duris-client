-- Executed only after the controller saves, closes and reopens the same profile.
local T=DurisTest
local ok,err=xpcall(function()
 T.check(getMudletHomeDir()==T.config.profile,"reopened intended saved profile")
 T.check(not select(3,getConnectionInfo()),"reopened offline")
 T.check(ArjUI.main and ArjMapper.ui.zoneContainer,"saved package initializes after full restart")
 T.check(ArjUI.settings.compactHeader==true,"full profile restart restores compact header")
 assert(loadfile(getMudletHomeDir().."/Duris Test Companion/fixtures/lowhp.lua"))()
end,debug.traceback)
T.finish(ok,err)
