local T=DurisTest
ArjUI.initialDataRequested=true
T.steps({
 {name="defaults-off",run=function()
  for key in pairs(ArjAuto.toggleDefaults) do T.check(ArjAuto.settings[key]==false,key.." defaults off") end
  feedTriggers("You are knocked to the ground\n")
  T.check(#T.commands==0,"off automation emits no command")
  expandAlias("tt guardian")
  expandAlias("kt")
  T.check(#T.commands==1 and T.commands[1].command=="kill guardian","target alias emits exactly one command")
  expandAlias("auto autoStand on")
  feedTriggers("You are knocked to the ground\n")
  T.check(#T.commands==2 and T.commands[2].command=="stand","enabled autoStand emits one command")
  expandAlias("auto autoStand off")
  feedTriggers("You are knocked to the ground\n")
  T.check(#T.commands==2,"disabled autoStand stops")
 end,actions=function() return {{type="key",key="KP_8"}} end},
 {name="keypad-on",run=function()
  T.check(T.commands[#T.commands].command=="north","physical numpad key sends north")
  ArjUI:setSetting("keypad",false)
  T.keyCount=#T.commands
 end,actions=function() return {{type="key",key="KP_8"}} end},
 {name="keypad-off",run=function()
  T.check(#T.commands==T.keyCount,"disabled numpad emits no command")
  ArjUI:setSetting("keypad",true)
  local items=ArjUI:getContextMenuItems("mobs","guardian")
  T.check(items[1].cmd=="look guardian","context menu target")
  ArjUI:showContextMenu(items,500,300)
 end,actions=function() return {{type="click",x=525,y=332}} end},
 {name="context-menu",run=function()
  T.check(T.commands[#T.commands].command=="look guardian","menu click sends selected command")
  expandAlias("spam look")
  expandAlias("spamon")
  expandAlias("spamoff")
  T.check(ArjAuto.timers.spam==nil,"spam cancel removes repeat timer")
  ArjAuto:load()
  T.check(ArjAuto.settings.autoStand==false,"automation setting persisted")
 end}
})
