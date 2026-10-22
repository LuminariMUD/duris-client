local T=DurisTest
assert(loadfile(getMudletHomeDir().."/Duris Test Companion/fixtures/lowhp.lua"))()
local function point(id,dx,dy)
 local f=ArjUI.panels[id].frame
 return {x=f:get_x()+dx,y=f:get_y()+dy}
end
local function drag(id,dx,dy,tx,ty)
 local p=point(id,dx,dy)
 return {{type="drag",x=p.x,y=p.y,to_x=p.x+tx,to_y=p.y+ty}}
end
T.steps({
 {name="unlocked-dashboard",run=function()
  expandAlias("ui layout unlock")
  T.layoutHp=ArjUI.state.hp
  T.layoutCommands=#T.commands
  T.layoutLines=T.lines("ArjUI_Console")
 end,actions=function() return drag("mobs",60,12,160,70) end},
 {name="title-drag",run=function()
  local p=ArjUI.panels.mobs
  T.check(p.state.mode=="floating" and p.state.rect[1]>.08,"physical title drag floats and moves")
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
  ArjUI:resetLayout()
  expandAlias("ui panel items hide")
  expandAlias("ui panel chat minimize")
  expandAlias("ui panel mobs float")
  ArjUI.panels.mobs.state.rect={.2,.2,.22,.3}
  ArjUI:applyPanelLayout(); ArjUI:saveLayout()
  T.check(ArjUI.panels.items.state.hidden and ArjUI.panels.chat.state.minimized,"mixed layout saved for restart")
 end}
})
