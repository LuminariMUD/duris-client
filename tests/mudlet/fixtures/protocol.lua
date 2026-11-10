local T=DurisTest
local messages,opened={},{}
local originalGMCP,originalUrl=sendGMCP,openUrl
sendGMCP=function(message) messages[#messages+1]=message end
openUrl=function(url) opened[#opened+1]=url end
local supported={"Duris.Time","Duris.Session","Duris.Combat","Char.Items","Char.SpellPreparation","Duris.Links"}
local active={"Duris.Time","Duris.Combat","Char.Items","Char.SpellPreparation"}
local features={}
for _,name in ipairs(supported) do features[name]=1 end
local process,body,generation="process-one","1","9007199254740993"
local function scope(extra)
 local data={version=1,context="fixture-context",process=process,generation=generation,bodyRevision=body}
 for k,v in pairs(extra or {}) do data[k]=v end
 return data
end
local function caps(names)
 T.emit("Duris.Capabilities",{version=1,enabled=true,features=features,supported=supported,interested=names or active,active=names or active})
end
local function session(state)
 T.emit("Duris.Session",{context="fixture-context",process=process,generation=generation,state=state or "playing",
  character=state and state~="playing" and yajl.null or {name="Tester",bodyRevision=body}})
end
local selector="@i:fixtureopaque:9007199254740993"
local function item(description,target)
 return {description=description,quantity=1,condition=" [75%]",flags={"glowing"},selector=target or selector}
end
local function items(location,revision,page,list,complete,available)
 T.emit("Char.Items.List",scope({revision=revision,location=location,page=page,items=list,complete=complete,available=available~=false}))
end
local function damage(sequence,n,extra)
 local data=scope({sequence=sequence,kind="damage",outcome="applied",damage=n,primary=false,target="wolf"})
 for k,v in pairs(extra or {}) do data[k]=v end
 T.emit("Duris.Combat",data)
end
local url="https://example.test/?x=1&name=two"
local snapshot={version=1,text="LINK",underline=false,runs={{0,4,19,0}},links={{start=0,["end"]=4,kind="url",target=url}}}
local oldItemAction,separator
local initialized=0
local login=ArjUI.onLoginDetected
ArjUI.onLoginDetected=function(self)
 local before=self.initialDataRequested
 login(self)
 if not before and self.initialDataRequested then initialized=initialized+1 end
end
T.steps({
 {name="entry-and-clock",run=function()
  ArjUI:clearGMCPNegotiation(); ArjUI:endSession(); ArjUI:enableGMCP()
  T.emit("Char.Status",{name="Tester",level=10,class="Warrior",race="Human"})
  ArjUI:switchTab("gear"); caps(); caps(); session()
  T.check(ArjUI.state.charLevel==10,"first Session keeps legacy bootstrap state the server will not resend")
  T.emit("Duris.Time",{process=process,revision="9007199254740993",hour=20,phase="night"})
  T.emit("Duris.Time",{process=process,revision="9007199254740992",hour=9,phase="day"})
  feedTriggers("The day has begun.\n")
  T.check(ArjUI.state.timeOfDay=="night","clock is lossless and authoritative over older revision/text")
  session(); T.check(ArjUI.initialDataRequested,"duplicate Session preserves entry initialization")
  T.check(initialized==1,"legacy bootstrap and Session acknowledgment initialize one entry once")
 end,wait=1.3,verify=function()
  for _,command in ipairs(T.commands) do T.check(command.command~="time","supporting server needs no background time command") end
  T.check(messages[1]:find("Core.Hello",1,true),"existing client identity retained")
  T.check(table.concat(messages,"\n"):find("Duris.Links",1,true),"new decoders advertised")
 end},
 {name="combat-events",run=function()
  T.emit("Char.Vitals",{hp=70,maxHp=100,move=80,maxMove=100,mana=0,maxMana=0,usesMana=false})
  damage("9007199254740993",17); damage("9007199254740993",17)
  damage("9007199254740994",8)
  damage("9007199254740995",90,{bodyRevision="stale"})
  T.emit("Combat.Update",{revision="9007199254740993",target={name="wolf",healthPercent=32,health="awful"},
   tank={name="Ally",healthPercent=5,health="awful"},round={attacker="Tester",damage=90}})
  feedTriggers("< T: Other TP: sta TC: excellent E: old EP: sta EC: excellent>\n[Damage: 17]\n")
  T.check(ArjUI.damage.session==25 and ArjUI.damage.sessionHits==2,"secondary hits counted once; legacy round/text do not double count")
  T.check(ArjUI.state.hp==70 and ArjUI.state.tank=="Ally" and ArjUI.state.tankHpPct==5,"self/tank/enemy ownership survives legacy prompt")
  T.check(ArjUI.state.target=="wolf" and ArjUI.state.targetHpPct==32,"structured target owns its display")
  T.emit("Combat.Update",{revision="9007199254740992",target=yajl.null,tank=yajl.null})
  T.check(ArjUI.state.target=="wolf","older combat state cannot clear current target")
 end},
 {name="paged-items",run=function()
  items("inv","7",0,{item("a <red> literal bag")},false)
  T.check(not ArjUI.itemViews.inv,"partial item page is not a visible replacement")
  items("eq","7",0,{},true)
  items("inv","7",1,{item("another bag","@i:fixtureopaque:9007199254740994")},true)
  T.check(#ArjUI.itemViews.inv.items==2 and #ArjUI.itemViews.eq.items==0,"top-level lists commit independently only at completion")
  T.check(T.lines(ArjUI.invBox.name):find("<red> literal bag",1,true),"item descriptions stay literal")
  T.check(ArjUI.itemViews.inv.items[1].selector==selector,"selector never converts to a number")
  local before=#messages
  ArjUI:requestTabData("inv")
  T.check(#messages==before+1 and messages[#messages]=="Char.Items.Get []","gear refresh resyncs once without redundant subscriptions")
  items("eq","7",0,{{description="Something.",quantity=1,slotName="held",flags={}}},true)
  T.check(not ArjUI.itemViews.eq.items[1].selector and ArjUI.itemViews.eq.items[1].description=="Something.","unseen equipped placeholder needs no selector or condition")
 end,actions=function()
  local w,h=calcFontSize(9)
  return {{type="click",x=ArjUI.invBox:get_x()+w*2,y=ArjUI.invBox:get_y()+h*1.5}}
 end},
 {name="item-actions",run=function()
  local menu=assert(ArjUI.currentMenu,"item click opens normal action menu")
  local entries=menu.windowList[menu.name.."_entries"]
  oldItemAction=entries.windowList[menu.name.."_3"].clickCallback
  separator=entries.windowList[menu.name.."_7"].clickCallback
 end,actions=function()
  local menu=ArjUI.currentMenu
  -- Labels inside a ScrollBox report scroll-local coordinates. Position the
  -- native click using the observed menu frame and its 22px title band.
  return {{type="click",x=menu:get_x()+40,y=menu:get_y()+32}}
 end},
 {name="paced-container-request",run=function() end,wait=1.2,verify=function()
  T.check(messages[#messages]:find(selector,1,true),"paced container request uses opaque selector")
  local sent=#T.commands; separator()
  T.check(#T.commands==sent,"menu separator sends no game command")
 end},
 {name="nested-items",run=function()
  items(selector,"8",0,{item("a nested gem")},true)
  T.check(T.lines(ArjUI.invBox.name):find("a nested gem",1,true),"requested contents render in existing GEAR console")
 end},
 {name="expire-item-scope",run=function()
  items("inv","9",0,{},true)
  local sent=#T.commands; oldItemAction()
  T.check(#T.commands==sent,"stale action menu cannot act on expired selector")
  T.check(not ArjUI.itemViews[selector] and not ArjUI.itemRequested,"new top-level revision retires nested contents/selectors")
  items(selector,"8",0,{item("stale contents")},true)
  T.check(not ArjUI.itemViews[selector],"stale nested response cannot resurrect contents")
  local previous=ArjUI.itemViews.inv
  items("inv","999",0,{{description="bad\nrecord",quantity=1,condition=""}},true)
  T.check(ArjUI.itemViews.inv==previous and ArjUI.itemRevision=="9","malformed page cannot poison a revision or expire valid views")
  items("eq","9",0,{},true,false)
  ArjUI.activeGearTab="eq"; ArjUI:renderEq()
  T.check(T.lines(ArjUI.eqBox.name):find("unavailable",1,true),"unavailable is distinct from known-empty")
 end},
 {name="chat-links",run=function()
  ArjUI:switchChatTab("nchat"); ArjUI.nchatBox:clear()
  T.emit("Comm.Channel",{channel="nchat",sender="Alice",text="LINK",bodyPresentation=snapshot})
  T.check(#opened==0,"chat receipt never opens a URL")
  local invalid=yajl.to_value(yajl.to_string(snapshot)); invalid.links[1].kind="command"; invalid.links[1].target="help weather"
  T.check(not ArjUI:decodeChatPresentation(invalid),"player chat cannot supply command links")
  local unicode={version=1,text="🧭 literal <tag>",underline=false,runs={{0,15,0,0}},links={}}
  T.check(ArjUI:decodeChatPresentation(unicode),"snapshot ranges are Unicode code points")
  local bad=yajl.to_value(yajl.to_string(snapshot)); bad.runs[1][3]=15
  T.check(not ArjUI:decodeChatPresentation(bad),"invalid palette falls back without trusting styles")
  bad=yajl.to_value(yajl.to_string(snapshot)); bad.links[1].target="javascript:ignored"
  T.check(not ArjUI:decodeChatPresentation(bad),"only HTTP/HTTPS targets are accepted")
  bad=yajl.to_value(yajl.to_string(snapshot)); bad.links[1].target="https://example.test/\194\128"
  T.check(not ArjUI:decodeChatPresentation(bad),"C1 controls cannot enter URL targets")
  T.emit("Comm.Channel",{channel="say",sender="Alice",text="LINK",presentation={
   version=1,text="Alice says LINK",underline=false,runs={{0,15,25,0}},links={{start=11,["end"]=15,kind="url",target=url}},
   channelId=11,channel="chat.say",policy="static"}})
  T.check(T.lines(ArjUI.roomBox.name):find("Alice says LINK",1,true),"recipient full-line presentation replaces local chat formatting")
 end,actions=function()
  local b=ArjUI.nchatBox
  local w,h=calcFontSize(9)
  local column=assert(T.lines(b.name):find("LINK",1,true))
  return {{type="click",x=b:get_x()+w*(column-.5),y=b:get_y()+h/2}}
 end},
 {name="tell-history",run=function()
  T.check(opened[1]==url and #opened==1,"real chat-pane click opens exact URL once")
  T.emit("Comm.Channel",{channel="nchat",sender="Alice",text="🧭 <literal> LINK",bodyPresentation={
   version=1,text="🧭 <literal> LINK",underline=false,runs={{0,16,19,0}},
   links={{start=12,["end"]=16,kind="url",target=url}}}})
  T.check(T.lines(ArjUI.nchatBox.name):find("🧭 <literal> LINK",1,true),"Unicode and markup-like chat labels render literally")
  T.emit("Comm.Channel",{channel="nchat",sender="Mallory",text="<red>RAW markup"})
  T.check(T.lines(ArjUI.nchatBox.name):find("<red>RAW markup",1,true),"chat without a snapshot keeps player text literal")
  T.emit("Comm.Channel",{channel="tell",sender="Alice",text="LINK",bodyPresentation=snapshot})
  ArjUI.privateChats.alice.history[1].time="01:23"
  ArjUI:openPrivateChat("Alice")
  T.check(T.lines(ArjUI.privateChats.alice.historyBox.name):find("[01:23]",1,true),"history replay keeps each message's own time")
  T.check(ArjUI.privateChats.alice.history[1].snapshots.body.links[1].target==url,"private history retains frozen links")
  T.check(T.lines(ArjUI.privateChats.alice.historyBox.name):find("LINK",1,true),"private replay renders retained snapshot")
 end},
 {name="process-and-body",run=function()
  local count=ArjUI.damage.session
  process="process-two"; session()
  T.check(ArjUI.initialDataRequested and ArjUI.damage.session==count,"hotboot keeps entry initialization and session damage")
  T.emit("Duris.Time",{process=process,revision="1",hour=9,phase="day"})
  T.check(ArjUI.state.timeOfDay=="day","new process resets time revision baseline")
  T.emit("Duris.Time",{process="process-one",revision="9999999999999999999",hour=20,phase="night"})
  T.check(ArjUI.state.timeOfDay=="day","retired process cannot overwrite the current clock")
  damage("1",3); T.check(ArjUI.damage.session==count+3,"new process resets event sequence baseline")
  T.emit("Duris.Time",{process=process,revision="2",hour=20,phase="night"})
  body="2"; session()
  T.check(ArjUI.state.timeOfDay=="night" and ArjUI.timeRevision=="2","body change preserves the connection-scoped clock")
  T.check(not ArjUI.itemViews.inv and ArjUI.state.target==nil,"body boundary clears views and item selectors")
  T.check(ArjUI.initialDataRequested,"body change is not a second login")
 end},
 {name="quota-and-menu",run=function()
  caps({"Duris.Time","Char.SpellPreparation","Char.Items"})
  T.check(ArjUI.damage.incomplete and ArjUI.combatStopped,"quota removal marks incomplete history without automatic resubscription")
  ArjUI:reportDamage(true)
  T.check(ArjUI.damage.incomplete,"counter reset does not hide a still-stopped event stream")
  ArjUI:switchTab("group")
  T.check(not messages[#messages]:find('"Duris.Combat 1"',1,true),"other interest changes do not restart stopped combat events")
  T.emit("Duris.Capabilities",{version=1,enabled=true,features=features,supported=supported,
   interested={"Duris.Time","Char.SpellPreparation"},active={}})
  session("account")
  T.check(ArjUI.playerName==nil and not ArjUI.itemViews.inv,"account boundary clears character views")
  T.check(ArjUI.state.timeOfDay==nil,"account transition cannot replace unavailable time with a guessed phase")
  T.emit("Char.Status",{name="Old body",level=99})
  T.check(ArjUI.playerName==nil,"account context rejects late character gameplay data")
  caps({"Duris.Time","Char.SpellPreparation"})
  generation="9007199254740994"; body="1"; session()
  T.check(ArjUI.initializedEntry:find(generation,1,true),"same-name re-entry uses lossless new generation")
  T.check(ArjUI.damage.incomplete,"a stopped combat stream remains explicit after re-entry")
  local entry=ArjUI.initializedEntry
  raiseEvent("sysProtocolDisabled","GMCP")
  raiseEvent("sysProtocolEnabled","GMCP")
  caps(); session()
  T.check(ArjUI.initializedEntry==entry and ArjUI.initialDataRequested,"transport re-enable retains once-per-entry initialization")
  sendGMCP,openUrl=originalGMCP,originalUrl
  ArjUI.onLoginDetected=login
 end}
})
