local T=DurisTest
ArjUI.initialDataRequested=true
local function wire(package, json) T.emit(package, yajl.to_value(json)) end
T.steps({
 {name="server-ship-payload",run=function()
  ArjUI:switchTab("ship")
  wire("Ship.Info", [[{"name":"&+WBronze Voyager&n","id":"AA","captain":"Tester","maxSpeed":18,"armor":{"bow":[80,100],"port":[70,100]},"internal":{"bow":[40,50]},"weapons":[{"slot":1,"name":"cannon","position":"port","ammo":8,"maxAmmo":10,"ready":true}],"equipment":[{"slot":2,"name":"levistone","ready":true}],"cargo":{"current":3,"max":50,"items":[{"slot":3,"name":"silk","crates":3,"contraband":false}]}}]])
  wire("Ship.Contacts", [[{"heading":90,"speed":12,"contacts":[{"id":"BB","name":"Far vessel","range":30,"bearing":70,"heading":50,"speed":8,"race":"evil","arc":"port","status":"flying","targeting_you":true,"you_targeting":true},{"id":"CC","name":"Near vessel","range":5,"bearing":20,"heading":60,"speed":4,"race":"good","status":"","targeting_you":false,"you_targeting":false}]}]])
  local s=ArjUI.state.ship
  T.check(s.heading==90 and s.speed==12 and s.maxSpeed==18,"navigation and max speed reach automation")
  T.check(s.target=="BB" and ArjAuto:targetContact().bearing==70,"GMCP lock reaches ship controls")
  ArjAuto:orderHeadingRelative(90)
  T.check(T.commands[#T.commands].command=="order heading 160","relative ship control uses server bearing")
  local out=T.lines("ArjUI_ShipBox")
  for _,v in ipairs({"80/100","40/50","cannon","levistone","silk","flying","targeting you","H:90","S:12"}) do T.check(out:find(v,1,true),"ship renders "..v) end
  T.check(not out:find("&+W",1,true),"ship name strips Duris color codes")
 end},
 {name="empty-contacts",run=function()
  ArjUI.state.ship.textContacts={{id="OLD",name="Ghost vessel"}}
  wire("Ship.Contacts", [[{"heading":0,"speed":0,"contacts":[]}]])
  T.check(ArjAuto:targetContact()==nil and ArjUI.state.ship.target==nil,"empty contacts retire lock")
  T.check(not T.lines("ArjUI_ShipBox"):find("Ghost vessel",1,true),"empty GMCP does not revive text contacts")
  wire("Ship.Info", "{}")
  T.check(ArjUI.state.ship.maxSpeed==nil and not T.lines("ArjUI_ShipBox"):find("Bronze Voyager",1,true),"bridge departure clears ship")
 end},
 {name="actual-doors",run=function()
  T.emit("Room.Info",{num=22800,zone=228,name="Door test",area="Test",exits={n=22801},doors={n={name="gate",closed=true,locked=true}},players={},npcs={},items={}})
  T.check(ArjMapper.state.roomDoors[22800].north==true,"mapper consumes real abbreviated door keys")
  T.emit("Room.Info",{num=22800,zone=228,name="Door test",area="Test",exits={n=22801},doors={n={name="gate",closed=false,locked=false}},players={},npcs={},items={}})
  T.check(ArjMapper.state.roomDoors[22800].north==false,"opening door clears closed passage")
 end},
 {name="combat-end",run=function()
  ArjUI.playerName="Tester"
  ArjUI:setSetting("damageTracker",true)
  wire("Combat.Update", [[{"target":{"name":"wolf","healthPercent":0,"health":"bleeding to death","position":"on their ass"},"round":{"attacker":"Tester","damage":8,"damageType":"physical","critical":false}}]])
  T.check(ArjUI.damage.fight==8,"server round damages counted")
  wire("Combat.Update", [[{"target":null}]])
  T.check(ArjUI.state.target==nil and ArjUI.damage.fight==0 and ArjUI.damage.source==nil,"null combat end clears bleeding target and fight")
 end},
 {name="logout-clears-state",run=function()
  T.emit("Group.Status",{members={{name="Oldmember",hp=40,maxHp=100}},size=1,maxSize=20})
  T.emit("Char.Affects",{{name="bless",duration=60}})
  T.emit("Quest.Status",{active=true,type="ask",target="Go ask the elder.",remaining=2})
  ArjAuto:startTimer("contacts",1,"look contacts")
  ArjAuto:after(1,function() send("OLD_CHARACTER_ACTION",false) end)
  ArjUI.initialDataRequested=false
  ArjUI:onLoginDetected()
  ArjAuto.settings.scanReport=true
  ArjAuto.vars.channel="gsay"
  ArjUI:setSetting("scanFormat",true)
  feedTriggers("You quickly scan the area.\nA Drow Elf who is not far off to your east.\n")
  feedTriggers("ACCOUNT MENU\n")
  T.check(ArjUI.playerName==nil and #ArjUI.state.group==0 and #ArjUI.state.affects==0 and ArjUI.state.quest==nil,"account menu clears character state")
  T.check(ArjUI.initialDataRequested==false,"same socket character login is rearmed")
  T.check(next(ArjAuto.timers)==nil and next(ArjAuto.pendingTimers)==nil,"logout cancels repeat and delayed actions")
  T.check(ArjUI.scanTimer==nil and next(ArjUI.scanCounts)==nil,"logout cancels delayed scan report")
  T.check(ArjMapper.state.currentRoom==nil and next(ArjMapper.requests)==nil,"logout clears map and downloads")
  T.commands={}
 end,wait=1.3,verify=function() T.check(#T.commands==0,"no delayed command escapes into account menu") end},
 {name="reconnect",run=function()
  T.emit("Char.Status",{name="SecondCharacter",class="Warrior",race="Human"})
  T.check(ArjUI.playerName=="SecondCharacter" and ArjUI.initialDataRequested,"next character logs in without reconnect")
  raiseEvent("sysDisconnectionEvent")
  T.check(ArjUI.playerName==nil and not ArjUI.initialDataRequested,"disconnect clears next session too")
 end},
 {name="supported-packages",run=function()
  local seen={}
  local oldGmod,oldSend=gmod,sendGMCP
  gmod={enableModule=function(owner,module) T.check(owner=="ArjUI","GMCP module owner"); seen[module]=true end}
  local hello
  sendGMCP=function(message) if message:find("Core.Hello",1,true) then hello=message end end
  ArjUI:enableGMCP()
  gmod,sendGMCP=oldGmod,oldSend
  for _,module in ipairs({"Char.Vitals","Char.Status","Char.Affects","Room.Info","Room.Map","Combat.Update","Group.Status","Comm.Channel","Quest.Status","Ship.Info","Ship.Contacts"}) do T.check(seen[module],"advertises "..module) end
  T.check(hello:find('"version":"'..ArjUI.VERSION..'"',1,true),"hello advertises built version")
 end}
})
