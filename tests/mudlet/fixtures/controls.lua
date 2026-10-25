local T=DurisTest
ArjUI.initialDataRequested=true
local function bounds(widget)
 return {x=widget:get_x(),y=widget:get_y(),width=widget:get_width(),height=widget:get_height()}
end
local function measure(mode)
 local w,h=getMainWindowSize()
 local b={window={width=w,height=h},root=bounds(ArjUI.uiRoot),console=bounds(ArjUI.console)}
 local top=math.max(24,h*.028)
 T.check(math.abs(b.root.y-top)<2,mode.." root top")
 T.check(math.abs(b.root.height-(h*.972-top))<2,mode.." root height")
 T.check(math.abs(b.root.y+b.root.height-h*.972)<2,mode.." root bottom")
 T.check(math.abs(b.root.x-w*.025)<2 and math.abs(b.root.width-w*.95)<2,mode.." root width/inset")
 return b
end
local original,full,compact
local function retained()
 T.check(ArjUI.main==original.main and ArjUI.console==original.console and ArjUI.state==original.state,"header retains widgets and GMCP state")
 T.check(ArjUI.activeTab=="stats" and ArjUI.activeChatTab=="guild","header retains selected tabs")
 T.check(ArjUI.privateChats.retained==original.chat and original.chat.inputBox:getText()=="retained presentation draft","presentation retains private widget and draft")
 T.check(#original.chat.history==original.history and original.chat.unread==1,"presentation retains private history and unread")
 T.check(ArjUI.shipMode==original.shipMode,"presentation retains SHIP mode")
 T.check(#ArjUI.eventHandlers==original.handlers and #ArjMapper.handlers==original.mapHandlers,"header retains handler ownership")
 T.check(T.lines("ArjUI_Console"):find("HEADER-SCROLLBACK-SENTINEL",1,true),"header retains console scrollback")
 for key,value in pairs(original.settings) do
  if key~="compactHeader" then T.check(ArjUI.settings[key]==value,"header preserves "..key) end
 end
end
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
 end},
 {name="header-full",run=function()
  T.check(ArjUI.settings.compactHeader==false,"fresh profile selects Stormwatch")
  -- A settings file written before this option existed retains the full layout.
  local legacy=table.deepcopy(ArjUI.settings)
  legacy.compactHeader=nil
  local f=assert(io.open(getMudletHomeDir().."/arjui_settings.json","w"))
  f:write(yajl.to_string(legacy)); f:close()
  ArjUI:loadSettings()
  T.check(ArjUI.settings.compactHeader==false,"missing preference selects Stormwatch")
  assert(loadfile(getMudletHomeDir().."/Duris Test Companion/fixtures/lowhp.lua"))()
  local group,npcs,items,players={},{},{},{}
  for i=1,12 do
   group[i]={name="CompanionWithLongName"..i,hp=i*70,maxHp=1000,move=90,maxMove=120,inRoom=i~=4,isNpc=i==5}
   npcs[i]={name="an ornate sentinel "..i}
   items[i]={name="a bronze relic "..i}
   players[i]={name="Visitor"..i}
  end
  T.emit("Group.Status",{members=group,size=12,maxSize=12})
  T.emit("Room.Info",{num=90010,zone=9001,name="A long hall beneath the tower of ancient bronze and forgotten kings",
   area="A deliberately long area name for wrapping",exits={north=90011,["east #"]=90012},npcs=npcs,items=items,players=players})
  ArjUI.state.statsRaw={"Header state retention"}
  ArjUI:switchTab("stats")
  ArjUI:switchChatTab("guild")
  feedTriggers("HEADER-SCROLLBACK-SENTINEL\n")
  for i=1,60 do feedTriggers(string.format("Gameplay line %02d: the bronze gate opens before you.\n",i)) end
  ArjUI:openPrivateChat("Retained")
  local chat=ArjUI.privateChats.retained
  chat.inputBox:print("retained presentation draft")
  ArjUI:panelAction("tell:retained","minimize")
  T.emit("Comm.Channel",{channel="tell",sender="Retained",text="Unread across presentation changes"})
  original={chat=chat,history=#chat.history,shipMode=ArjUI.shipMode,main=ArjUI.main,console=ArjUI.console,state=ArjUI.state,handlers=#ArjUI.eventHandlers,
   mapHandlers=#ArjMapper.handlers,settings=table.deepcopy(ArjUI.settings)}
  expandAlias("ui set")
  T.check(T.lines("ArjUI_Console"):find("compactHeader",1,true),"setting discoverable through ui set")
  full=measure("full")
 end},
 {name="header-compact",wait=.4,run=function()
  expandAlias("ui set compactHeader on")
 end,verify=function()
  T.check(ArjUI.settings.compactHeader==true,"real alias enables compact header")
  T.check(ArjUI.backdrop.hidden and ArjUI.bg.stylesheet:find("qlineargradient",1,true) and ArjUI.frameArt.stylesheet:find("border-image",1,true),"quiet uses gradient and retains slim frame")
  compact=measure("compact")
  T.check(math.abs(compact.root.height-full.root.height)<2 and math.abs(compact.root.y-full.root.y)<2,"both presentations retain expanded root")
  T.check(math.abs(compact.console.height-full.console.height)<2,"both presentations retain console geometry")
  T.check(math.abs(compact.console.width-full.console.width)<2,"console width and wrapping unchanged")
  retained()
  T.write("header-geometry",{full=full,compact=compact})
  T.headerInput=0
  T.headerInputAlias=tempAlias("^h$",function() T.headerInput=T.headerInput+1 end)
 end,actions=function() return {T.click(ArjUI.tabButtons.group),{type="key",key="h"},{type="key",key="Return"},{type="key",key="Up"},{type="key",key="Return"}} end},
 {name="header-input",run=function()
  T.check(ArjUI.activeTab=="group","compact tab click target works")
  T.check(T.headerInput==2,"native input retains focus and command history after presentation change")
  killAlias(T.headerInputAlias)
  ArjUI:switchTab("stats")
  raiseEvent("sysAppStyleSheetChange")
 end,verify=function()
  T.check(ArjUI.backdrop.hidden,"stylesheet reapplication keeps compact")
 end},
 {name="header-restored",wait=.4,run=function()
  expandAlias("ui set compactHeader off")
 end,verify=function()
  local restored=measure("full")
  T.check(math.abs(restored.console.height-full.console.height)<2,"full console geometry restored")
  T.check(ArjUI.backdrop.stylesheet:find("border-image",1,true) and not ArjUI.backdrop.hidden,"full artwork restored")
  retained()
  for i=1,3 do
   expandAlias("ui set compactHeader on")
   expandAlias("ui set compactHeader off")
  end
  retained()
 end},
 {name="header-hidden",run=function()
  expandAlias("ui off")
  expandAlias("ui set compactHeader on")
  T.check(ArjUI.hidden and ArjUI.main.hidden and ArjUI.bg.hidden,"hidden setting change keeps UI hidden")
  feedTriggers("Hidden header setting: main output remains available.\n")
  T.check(T.lines():find("Hidden header setting:",1,true),"hidden main output remains usable")
  expandAlias("ui on")
 end,verify=function()
  measure("compact")
  retained()
  local f=assert(io.open(getMudletHomeDir().."/arjui_settings.json"))
  local settings=yajl.to_value(f:read("*a")); f:close()
  T.check(settings.compactHeader==true,"compact preference persisted to profile")
 end},
 {name="header-connection",wait=.4,run=function()
  raiseEvent("sysConnectionEvent")
 end,verify=function()
  measure("compact")
  T.check(ArjUI.settings.compactHeader and ArjUI.backdrop.hidden,"connection reset retains compact preference and style")
 end}
})
