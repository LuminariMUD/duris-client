local T=DurisTest
-- Observe the HTML actually sent to Mudlet, not just the desired stylesheet.
local labelHtml, originalEcho = {}, echo
echo=function(name, text, ...)
 if type(name)=="string" and name:match("^ArjUI_Group") then labelHtml[name]=text end
 return originalEcho(name, text, ...)
end
ArjUI.initialDataRequested=true
local function roster(n,overrides)
 local members={}
 for i=1,n do
  members[i]={name="Companion"..i,hp=700,maxHp=1000,move=100,maxMove=120,position="standing",inRoom=true,isNpc=false}
  for k,v in pairs((overrides or {})[i] or {}) do members[i][k]=v end
 end
 return members
end
local function status(n,overrides,max) T.emit("Group.Status",{members=roster(n,overrides),size=n,maxSize=max or 13}) end

-- Structural work counters: these do not depend on the speed of the machine.
local counts
local function resetCounts() counts={labels=0,disposed=0,rows={}} end
resetCounts()
local labelNew,dispose=Geyser.Label.new,ArjUI.disposeWidget
Geyser.Label.new=function(...) counts.labels=counts.labels+1; return labelNew(...) end
ArjUI.disposeWidget=function(...) counts.disposed=counts.disposed+1; return dispose(...) end
local function count(widget,method,i)
 local original=widget[method]
 widget[method]=function(...) counts.rows[i]=(counts.rows[i] or 0)+1; return original(...) end
end
local function instrument()
 for i,row in ipairs(ArjUI.groupWidgets) do
  if not row.counted then
   row.counted=true
   for _,label in ipairs({row.nameLabel,row.mvLabel,row.posLabel}) do count(label,"setStyleSheet",i); count(label,"echo",i) end
   count(row.nameLabel,"setToolTip",i); count(row.hpGauge,"setValue",i); count(row.hpGauge.front,"setStyleSheet",i)
  end
 end
end
local function qtCalls() local n=0; for _,c in pairs(counts.rows) do n=n+c end; return n end
local function rows() return #ArjUI.groupWidgets end
local function identities() local list={}; for i,row in ipairs(ArjUI.groupWidgets) do list[i]=row.hpGauge end; return list end
local function sameRows(list,n,what) for i=1,n do T.check(ArjUI.groupWidgets[i].hpGauge==list[i],what.." keeps row "..i) end end
local function header() return ArjUI.groupWidgets.header.container.groupText end
local function hpText(i) return ArjUI.groupWidgets[i].hpGauge.text.message end
local function occurrences(name,text) local n=0; for _ in T.lines(name):gmatch(text) do n=n+1 end; return n end
local function arm() T.paints=ArjUI.groupPaintCount or 0; resetCounts(); instrument(); T.rows=identities() end
local function paints() return (ArjUI.groupPaintCount or 0)-T.paints end

T.steps({
 {name="twelve-members",wait=.8,run=function()
  T.emit("Char.Status",{name="VisualTester",level=25,class="Warrior",race="Human"})
  T.emit("Char.Vitals",{hp=750,maxHp=1000,move=120,maxMove=120,usesMana=false})
  status(12)
 end,verify=function()
  T.check(rows()==12 and header():find("(12/13)",1,true),"twelve rows and capacity painted")
  T.check(hpText(12):find("700/1000",1,true),"last row painted")
  local fill,box=ArjUI.groupFill,ArjUI.groupContainer
  T.check(fill:get_height()==26+11*42+38 and fill:get_width()==box:get_width()-20,
    "panel fill covers scrolled rows and leaves the scrollbar gutter")
  for _,label in ipairs({ArjUI.groupWidgets.header.container,ArjUI.groupWidgets[1].nameLabel,
      ArjUI.groupWidgets[1].mvLabel,ArjUI.groupWidgets[1].posLabel}) do
   T.check(labelHtml[label.name] and not labelHtml[label.name]:find("color:",1,true),
     label.name.." renders stylesheet colors without an inline override")
  end
 end,actions=function()
  return {{type="scroll",x=ArjUI.tabContent:get_x()+80,y=ArjUI.tabContent:get_y()+100}}
 end},
 {name="identical-burst-keeps-scroll",wait=.3,run=function()
  arm()
  for _=1,5 do status(12) end
  feedTriggers("GROUP-BURST-TEXT-ONCE arrives after five snapshots.\n")
  T.check(paints()==0 and ArjUI.groupPaintTimer~=nil,"burst defers one paint past the game text")
  T.check(#ArjUI.state.group==12 and ArjUI.state.groupSize==12,"authoritative state updates synchronously")
  T.check(occurrences("ArjUI_Console","GROUP%-BURST%-TEXT%-ONCE")==1,"text routes once before the group paint")
 end,verify=function()
  T.check(paints()==1 and ArjUI.groupPaintTimer==nil,"five identical snapshots coalesce to one paint")
  T.check(counts.labels==0 and counts.disposed==0,"identical snapshots create and dispose nothing")
  T.check(qtCalls()==0,"identical snapshots make no widget calls")
  sameRows(T.rows,12,"identical snapshots")
  T.check(occurrences("ArjUI_Console","GROUP%-BURST%-TEXT%-ONCE")==1,"text is not duplicated by the paint")
 end},
 {name="changed-member-only",run=function()
  arm()
  status(12,{[3]={hp=500}})
  status(12,{[3]={hp=240,position="sitting"}})
 end,verify=function()
  T.check(paints()==1,"changed burst paints once")
  T.check(hpText(3):find("240/1000  -760",1,true),"paint uses the newest snapshot")
  T.check(ArjUI.groupWidgets[3].posLabel.groupText=="[SIT]","changed position painted")
  T.check(ArjUI.groupWidgets[3].nameLabel.groupStyle:find("#ff8080",1,true),"new weakest member highlighted")
  T.check(ArjUI.groupWidgets[3].hpGauge.groupStyle==ArjUI:getGroupHpStyle(24),"low HP color applied")
  T.check(counts.rows[3]>0,"changed row updated")
  T.check(counts.rows[1]==1 and ArjUI.groupWidgets[1].nameLabel.groupStyle:find("#d0d0d0",1,true),"previous weakest member only loses its highlight")
  for i=2,12 do if i~=3 then T.check(not counts.rows[i],"unchanged row "..i.." untouched") end end
  T.check(counts.labels==0 and counts.disposed==0,"value change reuses widgets")
  sameRows(T.rows,12,"value change")
 end},
 {name="thirteenth-member",wait=.3,run=function() arm(); status(13) end,verify=function()
  T.check(rows()==13 and header():find("(13/13)",1,true),"thirteen rows painted")
  sameRows(T.rows,12,"growth")
  T.check(counts.labels>0 and counts.disposed==0,"growth only adds the new row")
  T.check(ArjUI.groupWidgets[13].container:get_y()-ArjUI.groupWidgets[12].container:get_y()==42,"new row keeps row spacing")
 end},
 {name="callback-follows-slot",run=function()
  status(13,{[2]={name="Replacement Companion"},[5]={isNpc=true,inRoom=false}})
 end,verify=function()
  local requested
  local items,show=ArjUI.getContextMenuItems,ArjUI.showContextMenu
  ArjUI.getContextMenuItems=function(_,kind,name) requested={kind,name}; return {} end
  ArjUI.showContextMenu=function() end
  local ok,err=pcall(ArjUI.groupWidgets[2].nameLabel.clickCallback)
  ArjUI.getContextMenuItems,ArjUI.showContextMenu=items,show
  assert(ok,err)
  T.check(requested[1]=="players" and requested[2]=="Replacement Companion","reused row click targets its current member")
  local row=ArjUI.groupWidgets[5]
  T.check(row.nameLabel.groupText:sub(-1)=="*" and row.posLabel.groupText=="[AWAY]" and row.nameLabel.groupStyle:find("#707070",1,true),"NPC and away markers follow the slot")
  status(13,{[5]={isNpc=false,inRoom=true}})
 end},
 {name="resize-reused-rows",wait=.4,run=function()
  T.width=ArjUI.groupWidgets[1].container:get_width()
  ArjUI:panelAction("character","maximize")
 end,verify=function()
  local row=ArjUI.groupWidgets[1]
  T.check(row.container:get_width()>T.width,"reused rows follow panel resize")
  T.check(math.abs(row.hpGauge:get_width()-row.container:get_width())<=2,"reused gauge follows its row")
  ArjUI:panelAction("character","restore")
 end},
 {name="hidden-tab-defers",wait=.3,run=function()
  ArjUI:switchTab("stats")
  arm()
  for i=1,5 do status(3,{[1]={hp=100+i}}) end
  T.check(#ArjUI.state.group==3,"hidden tab keeps state current")
  T.check(ArjUI.groupPaintTimer==nil,"hidden tab schedules no paint")
 end,verify=function()
  T.check(paints()==0 and counts.labels==0 and counts.disposed==0 and qtCalls()==0,"hidden tab does no widget work")
  T.check(rows()==13,"hidden tab leaves widgets for the reveal")
 end},
 {name="hidden-tab-reopen",run=function()
  ArjUI:switchTab("group")
  T.check(paints()==1,"reopening paints immediately")
 end,verify=function()
  T.check(rows()==3 and header():find("(3/13)",1,true),"reopen shrinks to the latest membership")
  T.check(hpText(1):find("105/1000",1,true),"reopen shows the latest member values")
  T.check(counts.disposed>0,"departing rows are disposed")
  sameRows(T.rows,3,"shrink")
 end},
 {name="covered-panel",run=function()
  ArjUI:panelAction("output","maximize")
  arm()
  status(3,{[2]={hp=111}})
  T.check(ArjUI.groupPaintTimer==nil,"covered panel schedules no paint")
 end,verify=function()
  T.check(paints()==0,"covered panel does not paint")
  ArjUI:panelAction("output","restore")
 end},
 {name="covered-panel-restored",run=function() end,verify=function()
  T.check(paints()==1 and hpText(2):find("111/1000",1,true),"restored panel paints the latest state")
 end},
 {name="ui-off",run=function()
  ArjUI:setVisible(false)
  arm()
  status(3,{[2]={hp=222}})
  T.check(ArjUI.groupPaintTimer==nil and paints()==0,"ui off accepts state without paint")
  ArjUI:setVisible(true)
 end,wait=.3,verify=function()
  T.check(hpText(2):find("222/1000",1,true),"ui on paints the latest state")
 end},
 {name="clear-to-solo",run=function() arm(); T.emit("Group.Status",{members={},size=0,maxSize=13}) end,verify=function()
  T.check(rows()==0 and ArjUI.groupWidgets.solo and not ArjUI.groupWidgets.header,"empty group shows only the solo notice")
  local fill,box=ArjUI.groupFill,ArjUI.groupContainer
  T.check(fill:get_width()==box:get_width()-4 and fill:get_height()==box:get_height()-4,"panel fill covers the solo view")
 end},
 {name="regroup",run=function() status(2) end,verify=function()
  T.check(rows()==2 and ArjUI.groupWidgets.header and not ArjUI.groupWidgets.solo,"regrouping replaces the solo notice")
  local gauge=ArjUI.groupWidgets[1].hpGauge
  T.check(math.abs(gauge.front:get_width()-gauge.back:get_width()*.7)<=1,"recreated row has a correct HP fill")
 end},
 {name="session-end",run=function()
  status(4)
  T.check(ArjUI.groupPaintTimer~=nil,"paint pending at session end")
  ArjUI:endSession()
  T.check(ArjUI.groupPaintTimer==nil,"session end clears the pending paint")
  T.check(rows()==0 and ArjUI.groupWidgets.solo,"session end shows solo")
  ArjUI.initialDataRequested=true
  T.emit("Char.Status",{name="VisualTester",level=25,class="Warrior",race="Human"})
  status(2)
  T.check(ArjUI.groupPaintTimer~=nil,"a later snapshot can schedule again")
 end,verify=function()
  T.check(rows()==2 and hpText(2):find("700/1000",1,true),"new session paints normally")
 end}
})
