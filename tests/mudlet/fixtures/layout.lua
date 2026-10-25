local T=DurisTest
assert(loadfile(getMudletHomeDir().."/Duris Test Companion/fixtures/lowhp.lua"))()
local function point(id,dx,dy)
 local f=ArjUI.panels[id].frame
 return {x=f:get_x()+dx,y=f:get_y()+dy}
end
local function bounds(id)
 local f,root=ArjUI.panels[id].frame,ArjUI.uiRoot
 local x,y=f:get_x()-root:get_x(),f:get_y()-root:get_y()
 T.check(x>=-.5 and y>=-.5 and x+f:get_width()<=root:get_width()+.5 and y+f:get_height()<=root:get_height()+.5,"frame inside content root: "..id)
end
local function drag(id,dx,dy,tx,ty)
 local p=point(id,dx,dy)
 return {{type="drag",x=p.x,y=p.y,to_x=p.x+tx,to_y=p.y+ty}}
end
local steps={}
T.boundary={}
for _,value in ipairs({false,true}) do
 local quiet=value
 local mode=quiet and "quiet" or "scenic"
 local beforeWidth,normalRect
 steps[#steps+1]={name=mode.."-top-drag",run=function()
  ArjUI:resetLayout()
  ArjUI:setSetting("compactHeader",quiet)
  expandAlias("ui layout unlock")
 end,actions=function()
  local p=point("mobs",60,12)
  -- Keep the pointer over the title at the destination. Overshooting into
  -- the fixed Panels button can interrupt native move delivery on some Qt builds.
  return {{type="drag",x=p.x,y=p.y,to_x=p.x,to_y=ArjUI.uiRoot:get_y()+12}}
 end}
 steps[#steps+1]={name=mode.."-top-resize",run=function()
  local w,h=getMainWindowSize()
  local f=ArjUI.panels.mobs.frame
  T.boundary[mode]={window={w,h},rootY=ArjUI.uiRoot:get_y(),titleY=f:get_y()}
  T.write("boundary-geometry",T.boundary)
  T.check(math.abs(f:get_y()-math.max(24,h*.028))<2 and f:get_y()<h*.105-10,mode.." pointer title reaches new top above old boundary")
  T.check(ArjUI.panels.mobs.state.mode=="floating",mode.." pointer floats panel")
  beforeWidth=f:get_width()
 end,actions=function()
  local f=ArjUI.panels.mobs.frame
  return drag("mobs",f:get_width()-3,f:get_height()-3,65,25)
 end}
 steps[#steps+1]={name=mode.."-top-controls",run=function()
  local p=ArjUI.panels.mobs
  T.check(p.frame:get_width()>beforeWidth+35,mode.." physical resize at top")
  bounds("mobs")
  local rect=table.deepcopy(p.state.rect)
  ArjUI:saveLayout();ArjUI:loadLayout();ArjUI:applyPanelLayout()
  T.check(math.abs(p.state.rect[2]-rect[2])<.001,mode.." saved top rectangle reloads")
  for _,action in ipairs({"lock","unlock","minimize","restore","maximize","restore"}) do
   expandAlias("ui panel mobs "..action)
  end
  T.check(math.abs(p.frame:get_y()-ArjUI.uiRoot:get_y())<2,mode.." top restored after lock/minimize/maximize")
  T.check(ArjUI.panelsButton:get_y()+22<=ArjUI.uiRoot:get_y(),mode.." recovery controls clear titles")
  normalRect=table.deepcopy(p.state.rect)
 end,actions=function() return {{type="resize-window",width=900*T.config.scale,height=600*T.config.scale}} end}
 steps[#steps+1]={name=mode.."-window-shrunk",run=function()
  local p=ArjUI.panels.mobs
  bounds("mobs")
  for i=1,4 do T.check(p.state.rect[i]==normalRect[i],mode.." window shrink preserves normalized rectangle "..i) end
  T.check(math.abs(p.frame:get_y()-ArjUI.uiRoot:get_y())<2,mode.." title accessible after window shrink")
 end,actions=function()
  local w,h=T.config.size:match("(%d+)x(%d+)")
  return {{type="resize-window",width=tonumber(w),height=tonumber(h)}}
 end}
 steps[#steps+1]={name=mode.."-window-grown",run=function()
  local p=ArjUI.panels.mobs
  bounds("mobs")
  for i=1,4 do T.check(p.state.rect[i]==normalRect[i],mode.." window grow preserves normalized rectangle "..i) end
  expandAlias("ui panel mobs dock");expandAlias("ui panel mobs float")
  T.check(p.state.mode=="floating" and p.state.rect[2]==p.def.home[2],mode.." dock/float retain home bounds")
  expandAlias("ui panel output maximize")
 end,actions=function() return {T.click(ArjUI.panelsButton)} end}
 steps[#steps+1]={name=mode.."-maximized-panels",run=function()
  T.check(ArjUI.currentMenu,mode.." physical Panels click survives maximize")
  ArjUI:disposeWidget(ArjUI.currentMenu);ArjUI.currentMenu=nil
 end,actions=function() return {T.click(ArjUI.resetLayoutButton)} end}
 steps[#steps+1]={name=mode.."-private-top",run=function()
  T.check(not ArjUI.maximizedPanel and ArjUI.panels.mobs.state.mode=="docked",mode.." physical Reset restores defaults")
  ArjUI:openPrivateChat("Topprobe")
  local chat=ArjUI.privateChats.topprobe
  chat.inputBox:clear();chat.inputBox:print("top edge retained draft")
  expandAlias("ui panel tell:topprobe unlock")
 end,actions=function()
  local p=point("tell:topprobe",60,12)
  return {{type="drag",x=p.x,y=p.y,to_x=p.x,to_y=ArjUI.uiRoot:get_y()+12}}
 end}
 steps[#steps+1]={name=mode.."-private-top-resize",run=function()
  local f=ArjUI.panels["tell:topprobe"].frame
  T.check(math.abs(f:get_y()-ArjUI.uiRoot:get_y())<2,mode.." private pointer reaches usable top")
  beforeWidth=f:get_width()
 end,actions=function()
  local f=ArjUI.panels["tell:topprobe"].frame
  return drag("tell:topprobe",f:get_width()-3,f:get_height()-3,45,20)
 end}
 steps[#steps+1]={name=mode.."-private-top-retained",run=function()
  T.check(ArjUI.panels["tell:topprobe"].frame:get_width()>beforeWidth+20,mode.." private physical top resize")
  for _,action in ipairs({"lock","unlock","minimize","restore","maximize","restore"}) do expandAlias("ui panel tell:topprobe "..action) end
  T.check(ArjUI.privateChats.topprobe.inputBox:getText()=="top edge retained draft",mode.." top gestures retain private draft")
  bounds("tell:topprobe")
  ArjUI:resetLayout()
  T.write("boundary-geometry",T.boundary)
 end}
end
steps[#steps+1]={name="scenic-restored",run=function() ArjUI:setSetting("compactHeader",false) end}
local existing={
 {name="portable-layout-replace",run=function()
  local path=getMudletHomeDir().."/arjui_layout.json"
  ArjUI:saveLayout()
  local rename=os.rename
  local function read() local f=assert(io.open(path,"r")); local s=f:read("*a");f:close();return s end
  local ok,err=xpcall(function()
   os.rename=function(from,to)
    local f=io.open(to,"r")
    if f then f:close();return nil,"simulated Windows existing destination" end
    return rename(from,to)
   end
   ArjUI.panels.items.state.hidden=true;ArjUI:saveLayout()
   T.check(yajl.to_value(read()).panels.items.hidden,"Windows-style replacement persists later saves")
   local previous=read()
   os.rename=function(from,to)
    if from==path..".tmp" and to==path then return nil,"simulated install failure" end
    return rename(from,to)
   end
   ArjUI.panels.items.state.hidden=false;ArjUI:saveLayout()
   T.check(read()==previous,"failed replacement restores previous layout")
   assert(rename(path,path..".bak"))
   ArjUI:loadLayout()
   T.check(ArjUI.panels.items.state.hidden,"interrupted replacement loads retained backup")
   assert(rename(path..".bak",path))
  end,debug.traceback)
  os.rename=rename
  assert(ok,err)
  ArjUI:resetLayout()
 end},
 {name="unlocked-dashboard",run=function()
  expandAlias("ui layout unlock")
  T.layoutHp=ArjUI.state.hp
  T.layoutCommands=#T.commands
  T.layoutLines=T.lines("ArjUI_Console")
 end,actions=function() return drag("mobs",60,12,160,70) end},
 {name="title-drag",run=function()
  local p=ArjUI.panels.mobs
  T.check(p.state.mode=="floating" and p.state.rect[1]>.08,"physical title drag floats and moves")
  bounds("mobs")
  T.beforeResize=p.frame:get_width()
 end,actions=function()
  local f=ArjUI.panels.mobs.frame
  return drag("mobs",f:get_width()-3,f:get_height()-3,85,45)
 end},
 {name="border-resize",run=function()
  T.check(ArjUI.panels.mobs.frame:get_width()>T.beforeResize+40,"physical border resize changes width")
  for _,def in ipairs(ArjUI.panelDefinitions) do
   local id=def.id
   expandAlias("ui panel "..id.." float")
   expandAlias("ui panel "..id.." maximize")
   T.check(ArjUI.maximizedPanel==id,"maximize "..id)
   expandAlias("ui panel "..id.." restore")
   T.check(not ArjUI.maximizedPanel,"restore "..id)
   if not def.essential then
    for i=1,2 do expandAlias("ui panel "..id.." minimize") end
    T.check(ArjUI.panels[id].state.minimized,"minimize "..id)
    for i=1,2 do expandAlias("ui panel "..id.." restore") end
    expandAlias("ui panel "..id.." hide")
    T.check(ArjUI.panels[id].frame.hidden,"hide "..id)
    expandAlias("ui panel "..id.." show")
   end
   expandAlias("ui panel "..id.." dock")
  end
  expandAlias("ui panel output minimize"); expandAlias("ui panel output hide")
  T.check(not ArjUI.panels.output.state.hidden and not ArjUI.panels.output.state.minimized,"output restrictions")
  expandAlias("ui panel items hide")
  expandAlias("ui panel chat minimize")
  expandAlias("ui panel map maximize")
  T.check(ArjUI.resetLayoutButton.hidden~=true,"fixed reset survives maximize")
 end,actions=function()
  local b=ArjUI.resetLayoutButton
  return {{type="click",x=b:get_x()+30,y=b:get_y()+10}}
 end},
 {name="fixed-reset",run=function()
  for _,def in ipairs(ArjUI.panelDefinitions) do
   local s=ArjUI.panels[def.id].state
   T.check(s.mode=="docked" and s.locked and not s.minimized and not s.hidden,"button reset "..def.id)
  end
  for _,panel in pairs(ArjUI.panels) do T.check(not panel.frame.Inside.hidden,"reset restores panel body "..panel.def.id) end
  T.check(not ArjUI.maximizedPanel and ArjUI.activeTab=="group" and ArjUI.activeChatTab=="all","reset views")
  T.check(ArjUI.state.hp==T.layoutHp,"reset preserves live vitals")
  T.check(T.lines("ArjUI_Console"):find("Visual test: plain incoming text.",1,true),"reset preserves scrollback")
  T.check(#T.commands==T.layoutCommands,"layout sends no game commands")
  expandAlias("ui off"); expandAlias("ui layout reset")
  T.check(ArjUI.hidden,"reset while hidden stays off")
  expandAlias("ui on")
  T.check(ArjUI.tabPanels.stats.hidden and ArjUI.chatPanels.tells.hidden,"off/on restores inactive tabs")
  expandAlias("ui panel mobs unlock")
 end,actions=function()
  local p=point("mobs",60,12)
  return {{type="click",button=3,x=p.x,y=p.y}}
 end},
 {name="title-menu",run=function()
  T.check(ArjUI.currentMenu~=nil,"physical right click opens panel menu")
 end,actions=function()
  local menu=ArjUI.currentMenu
  local entries=menu.windowList[menu.name.."_entries"]
  local item=entries.windowList[menu.name.."_5"]
  return {{type="click",x=menu:get_x()+2+item:get_x()+20,y=menu:get_y()+22+item:get_y()+10}}
 end},
 {name="title-menu-action",run=function()
  T.check(ArjUI.maximizedPanel=="mobs","physical title menu action maximizes owned panel")
  ArjUI:resetLayout()
  T.emit("Comm.Channel",{channel="tell",sender="Companion",text="Before first window"})
  expandAlias("ui panel tell:companion show")
  T.check(ArjUI.privateChats.companion.window,"command opens an existing unopened conversation")
  ArjUI:openPrivateChat("Watcher")
  ArjUI:openPrivateChat("Companion")
  local chat=ArjUI.privateChats.companion
  chat.inputBox:print("unfinished draft")
  T.emit("Comm.Channel",{channel="tell",sender="Companion",text="Retained private history"})
  T.privateHistory=#chat.history
  T.chatWidth=chat.window:get_width()
 end,actions=function()
  local f=ArjUI.panels["tell:companion"].frame
  return drag("tell:companion",f:get_width()-3,f:get_height()-3,90,40)
 end},
 {name="private-resize",run=function()
  local chat=ArjUI.privateChats.companion
  T.check(chat.window:get_width()>T.chatWidth+30,"private window physically resizes")
  bounds("tell:companion")
  T.check(chat.inputBox:get_width()>200,"private input follows width")
  expandAlias("ui panel tell:companion minimize")
  T.emit("Comm.Channel",{channel="tell",sender="Companion",text="Unread while minimized"})
  T.check(chat.unread==1,"minimized private conversation tracks unread")
  expandAlias("ui panel tell:companion restore")
  chat.inputBox:clear(); chat.inputBox:print("pointer send probe")
 end,actions=function() return {T.click(ArjUI.privateChats.companion.sendButton)} end},
 {name="private-send",run=function()
  local chat=ArjUI.privateChats.companion
  T.check(T.commands[#T.commands].command=="tell companion pointer send probe","private Send click uses typed message")
  T.check(chat.inputBox:getText()=="","private Send clears draft")
  chat.inputBox:print("unfinished draft")
  T.commandsBeforePrivateReset=#T.commands
  expandAlias("ui panel tell:watcher maximize")
  expandAlias("ui layout reset")
  T.check(chat.window.hidden and not chat.visible,"reset closes private window")
  T.check(chat.inputBox:getText()=="unfinished draft","reset preserves private draft")
  T.check(#chat.history==T.privateHistory+1 and chat.unread==0,"reset preserves private history/unread")
  T.check(#T.commands==T.commandsBeforePrivateReset,"private reset sends no commands")
  ArjUI:openPrivateChat("Companion")
  T.check(not chat.window.hidden and not chat.window.Inside.hidden,"private window reopens after reset")
  local _,copies=T.lines(chat.historyBox.name):gsub("\n",""):gsub("Unread while minimized","")
  T.check(copies==1,"latest private message rendered once")
  ArjUI:resetLayout()
  expandAlias("ui panel items hide")
 end,actions=function() return {T.click(ArjUI.panelsButton)} end},
 {name="panels-recovery-menu",run=function()
  T.check(ArjUI.currentMenu,"fixed Panels button opens recovery menu")
 end,actions=function()
  local menu=ArjUI.currentMenu
  local entries=menu.windowList[menu.name.."_entries"]
  local item=entries.windowList[menu.name.."_3"]
  return {{type="click",x=menu:get_x()+2+item:get_x()+20,y=menu:get_y()+22+item:get_y()+10}}
 end},
 {name="covered-private-unread",run=function()
  ArjUI:openPrivateChat("Readprobe")
  expandAlias("ui panel output maximize")
  T.emit("Comm.Channel",{channel="tell",sender="Readprobe",text="UNREAD-BEHIND-OUTPUT"})
  ArjUI:applyPanelLayout()
  local chat=ArjUI.privateChats.readprobe
  T.check(not chat.visible and chat.unread==1,"covered private tell remains unread through layout")
  ArjUI:openPrivateChat("Readprobe")
  T.check(not chat.visible and chat.unread==1,"open request behind output does not acknowledge unseen tell")
 end},
 {name="reveal-private-unread",run=function()
  expandAlias("ui panel output restore")
  local chat=ArjUI.privateChats.readprobe
  T.check(chat.visible and chat.unread==0,"actual reveal acknowledges private tell")
  T.check(not T.lines(ArjUI.tellsBox.name):find("Readprobe (1 new)",1,true),"actual reveal refreshes unread indicator")
  local _,copies=T.lines(chat.historyBox.name):gsub("UNREAD%-BEHIND%-OUTPUT","")
  T.check(copies==1,"covered private message appears once")
 end},
 {name="maximize-private-from-minimized",run=function()
  expandAlias("ui panel tell:readprobe minimize")
  T.emit("Comm.Channel",{channel="tell",sender="Readprobe",text="UNREAD-MINIMIZED"})
  expandAlias("ui panel tell:readprobe maximize")
  local chat=ArjUI.privateChats.readprobe
  T.check(chat.visible and chat.unread==0 and ArjUI.panels["tell:readprobe"].state.minimized,"maximized private reveal keeps normal minimized state")
 end},
 {name="restore-private-to-minimized",run=function()
  expandAlias("ui panel tell:readprobe maximize")
  T.check(not ArjUI.privateChats.readprobe.visible,"restore returns private window to minimized state")
 end},
 {name="panels-recovery",run=function()
  T.check(not ArjUI.panels.items.state.hidden and ArjUI.currentMenu,"fixed Panels entry restores hidden panel and opens actions")
  ArjUI:resetLayout()
  -- A tiny viewport may clamp the display, never the saved normal rectangle.
  expandAlias("ui panel mobs float")
  ArjUI.panels.mobs.state.rect={.7,.7,.25,.25}
  ArjUI.uiRoot:resize(130,80); ArjUI:applyPanelLayout()
  T.check(ArjUI.panels.mobs.frame:get_width()<=131,"small viewport contains frame")
  T.check(ArjUI.panels.mobs.state.rect[1]==.7,"clamp retains requested normal rectangle")
  ArjUI:layout()
  ArjUI:resetLayout()
  local path=getMudletHomeDir().."/arjui_layout.json"
  local function load(text) local f=assert(io.open(path,"w")); f:write(text); f:close(); ArjUI:loadLayout() end
  load("{broken")
  T.check(ArjUI.panels.output.state.mode=="docked","corrupt layout keeps defaults")
  load(yajl.to_string({version=999,panels={}}))
  T.check(ArjUI.panels.output.state.mode=="docked","unsupported layout keeps defaults")
  load(yajl.to_string({version=1,panels={mobs={mode="floating",locked=false,hidden=false,minimized=false,rect={.2,.2,.22,.3}},unknown={}}}))
  T.check(ArjUI.panels.mobs.state.mode=="floating" and ArjUI.panels.chat.state.mode=="docked","partial layout fills missing panels")
  load(yajl.to_string({version=1,panels={mobs={mode="floating",locked=false,hidden=false,minimized=false,rect={2,0,-1,0}}}}))
  -- Bad entries must replace even previously loaded geometry, not retain it.
  T.check(ArjUI.panels.mobs.state.mode=="docked","invalid geometry resets affected panel")
  ArjUI:resetLayout()
  expandAlias("ui panel items hide")
  expandAlias("ui panel chat minimize")
  expandAlias("ui panel mobs float")
  ArjUI.panels.mobs.state.rect={.2,.2,.22,.3}
  ArjUI:applyPanelLayout(); ArjUI:saveLayout()
  T.check(ArjUI.panels.items.state.hidden and ArjUI.panels.chat.state.minimized,"mixed layout saved for restart")
 end}

}
for _,step in ipairs(existing) do steps[#steps+1]=step end
T.steps(steps)
