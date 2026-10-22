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
  local out=T.lines("ArjUI_ShipBox"):gsub("%s+"," ")
  for _,v in ipairs({"80/100","40/50","cannon","levistone","silk","flying","targeting you","H:90","S:12/18","Condition","Weapons","Equipment","Cargo","Ammo: 8/10","Timer: Ready"}) do T.check(out:find(v,1,true),"ship renders "..v) end
  T.check(not out:find("&+W",1,true),"ship name strips Duris color codes")
 end},
 {name="readable-ship",run=function()
  T.emit("Ship.Info", {
   name="&+WThe Bronze Voyager of the Far Northern Sea&n",id="AA",status="under way",captain="Tester",frags=0,maxSpeed=18,contactRange=35,
   armor={bow={80,100},port={25,100},starboard={50,100},stern={0,0}},internal={bow={40,50},port={10,50},starboard={30,50},stern={0,0}},sail=0,maxSail=100,
   crewType="Human",crewStamina=65,maxCrewStamina=100,people=0,maxPeople=20,repairStock=0,
   chiefs={sail="",guns="&+RGunner&n",repair=""},skills={sail=15,guns=20,repair=0},skillMods={sail=2,guns=-3,repair=0},
   weapons={{slot=10,name="&+RA very long broadside cannon with bronze fittings&n",position="stern",ammo=0,maxAmmo=10,damage=2,ready=true},
    {slot=2,name="&+WForward cannon&n",position="bow",ammo=8,maxAmmo=10,damage=0,ready=false}},
   equipment={{slot=4,name="levistone",ready=false}},
   cargo={current=3,max=50,items={{slot=5,name="&+YSilken cargo from a distant southern harbor&n",crates=3,invoicePrice=0,contraband=true}}}
  })
  local info=ArjUI.state.ship.info
  local out=T.lines("ArjUI_ShipBox")
  local previous=0
  for _,label in ipairs({"Condition","Weapons","Crew and supplies","Equipment","Cargo","Contacts (2)"}) do
   local at=out:find(label,1,true)
   T.check(at and at>previous,"ordered section "..label); previous=at
  end
  T.check(out:find("[2] Forward cannon",1,true)<out:find("[10] A very long",1,true),"weapon slots sort numerically")
  T.check(info.weapons[1].slot==10 and info.armor.bow[1]==80,"rendering leaves supplied table order and values intact")
  for _,v in ipairs({"Position: Forward","Position: Rear","Ammo: 0/10 (empty)","Damage: 2","Timer: Ready","Timer: Not ready","Sail: 0/100","Passengers: 0/20","Repair stock: 0","Deck chief: None","Guns chief: Gunner","Deck skill: 15","Deck modifier: +2","Guns modifier: -3","Repair modifier: +0","(contraband)","Invoice price: 0"}) do
   T.check(out:find(v,1,true),"readable supplied fact "..v)
  end
  T.check(not out:find("skillMods",1,true) and not out:find("ready=",1,true) and not out:find("%",1,true),"no raw dump or invented skill percentages")
 end},
 {name="ship-weapons-view",run=function()
  local out=T.lines("ArjUI_ShipBox")
  local prefix=out:sub(1,out:find("Weapons",1,true)-1)
  local _,lines=prefix:gsub("\n","")
  ArjUI.shipBox:scrollTo(lines+getRowCount("ArjUI_ShipBox"))
 end},
 {name="ship-crew-view",run=function()
  local out=T.lines("ArjUI_ShipBox")
  local prefix=out:sub(1,out:find("Crew and supplies",1,true)-1)
  local _,lines=prefix:gsub("\n","")
  ArjUI.shipBox:scrollTo(lines+getRowCount("ArjUI_ShipBox"))
 end},
 {name="ship-lower-view",run=function()
  local out=T.lines("ArjUI_ShipBox")
  local prefix=out:sub(1,out:find("Equipment",1,true)-1)
  local _,lines=prefix:gsub("\n","")
  ArjUI.shipBox:scrollTo(lines+getRowCount("ArjUI_ShipBox"))
 end},
 {name="ship-refresh-scroll",run=function()
  -- Keep the comparison away from the end-of-buffer clamp at each geometry.
  local out=T.lines("ArjUI_ShipBox")
  local prefix=out:sub(1,out:find("Weapons",1,true)-1)
  local _,lines=prefix:gsub("\n","")
  ArjUI.shipBox:scrollTo(lines+getRowCount("ArjUI_ShipBox"))
 end},
 {name="ship-refresh-observation",run=function()
  T.shipTop=ArjUI.shipBox:getScroll()-getRowCount("ArjUI_ShipBox")
  T.check(T.shipTop>0,"lower ship sections are reachable by scrolling")
  T.emit("Ship.Contacts",{heading=0,speed=0,contacts=ArjUI.state.ship.contacts})
 end,verify=function()
  local top=ArjUI.shipBox:getScroll()-getRowCount("ArjUI_ShipBox")
  T.check(top==T.shipTop,"navigation updates preserve the viewed ship section: "..T.shipTop.." -> "..top)
 end},
 {name="ship-partial-replacement",run=function()
  T.emit("Ship.Info",{name="Partial <red>ship",armor={bow={0,0}},internal={port={10}},weapons={{slot=0,name="&+WZero gun&n",ammo=0,damage=0,ready=false}},skills={sail=0}})
  local out=T.lines("ArjUI_ShipBox")
  for _,v in ipairs({"Partial ship","0/0","10/?","[0] Zero gun","Ammo: 0/? (empty)","Damage: 0","Timer: Not ready","Deck skill: 0","H:0  S:0/?"}) do T.check(out:find(v,1,true),"partial ship keeps "..v) end
  T.check(not out:find("Voyager",1,true) and not out:find("bronze fittings",1,true) and not out:find("Silken cargo",1,true),"replacement retires old identity, weapons and cargo")
  T.check(not out:find("chief: None",1,true) and not out:find("Weapons: None",1,true),"missing lists and chiefs are not known empty")
  ArjUI.shipBox:scrollTo(0)
 end},
 {name="ship-empty-lists",run=function()
  T.emit("Ship.Info",{name="Empty hold",weapons={},equipment={},cargo={current=0,max=0,items={}}})
  local out=T.lines("ArjUI_ShipBox")
  for _,v in ipairs({"Weapons: None","Equipment: None","Cargo: None","Crates: 0/0"}) do T.check(out:find(v,1,true),"known empty "..v) end
  T.check(not out:find("Zero gun",1,true),"empty weapon list removes previous weapon")
  ArjUI.shipBox:scrollTo(0)
 end},
 {name="empty-contacts",run=function()
  ArjUI.state.ship.textContacts={{id="OLD",name="Ghost vessel"}}
  wire("Ship.Contacts", [[{"heading":0,"speed":0,"contacts":[]}]])
  T.check(ArjAuto:targetContact()==nil and ArjUI.state.ship.target==nil,"empty contacts retire lock")
  T.check(T.lines("ArjUI_ShipBox"):find("Contacts: None",1,true),"known empty contacts have a readable message")
  T.check(not T.lines("ArjUI_ShipBox"):find("Ghost vessel",1,true),"empty GMCP does not revive text contacts")
  wire("Ship.Info", "{}")
  T.check(ArjUI.state.ship.maxSpeed==nil and not T.lines("ArjUI_ShipBox"):find("Bronze Voyager",1,true),"bridge departure clears ship")
 end},
 {name="ship-text-fallback",run=function()
  feedTriggers("You board &+WText Voyager&n\nCaptain: Tester\nThis ship can only go from 0 to 18.\nDeck skill: 15\nContact listing  H: 0 S: 0\n[ZZ] Text contact X: 2 Y: 3 R: 5 B: 20 H: 60 S: 4 |NE\n")
  local out=T.lines("ArjUI_ShipBox")
  for _,v in ipairs({"Text Voyager","Captain: Tester","H:0  S:0/18","Deck skill: 15","Text contact"}) do T.check(out:find(v,1,true),"text-only fallback "..v) end
  T.check(not out:find("&+W",1,true),"text fallback strips server colors")
  T.emit("Ship.Info",{})
  T.check(T.lines("ArjUI_ShipBox"):find("(no ship data)",1,true),"departure clears text fallback")
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
