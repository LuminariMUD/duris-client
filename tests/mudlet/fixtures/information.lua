local T=DurisTest
ArjUI.initialDataRequested=true
T.steps({
 {name="room-mobs",run=function()
  local room,players=ArjUI.panels.room.frame,ArjUI.panels.players.frame
  T.check(math.abs(room:get_height()-players:get_height())<1,"ROOM and PLAYERS have equal docked heights")
  T.check(room:get_y()+room:get_height()<=ArjUI.panels.vitals.frame:get_y()
    and players:get_y()+players:get_height()<=ArjUI.panels.chat.frame:get_y(),
    "docked ROOM and PLAYERS clear the bottom panels")
  T.emit("Room.Info",{name="A quiet clearing",npcs={{name="a snow wolf"}},items={{name="a red apple"}}})
  T.check(ArjUI.activeRoomTab=="mobs" and ArjUI.objsBox.hidden,"MOBS is initially visible")
  T.check(T.lines("ArjUI_MobsBox"):find("snow wolf",1,true),"room mob received")
 end,actions=function() return {T.click(ArjUI.roomTabs.items)} end},
 {name="room-items",run=function()
  T.check(ArjUI.activeRoomTab=="items" and ArjUI.mobsBox.hidden and not ArjUI.objsBox.hidden,"ITEMS click switches views")
  T.check(T.lines("ArjUI_ObjsBox"):find("red apple",1,true) and #T.commands==0,"hidden room list receives data and switching sends nothing")
  ArjUI:panelAction("room","maximize")
  ArjUI:panelAction("room","restore")
  T.check(ArjUI.mobsBox.hidden and not ArjUI.objsBox.hidden,"ROOM restore retains selected view")
 end,actions=function() return {T.click(ArjUI.tabButtons.gear)} end},
 {name="inventory",run=function()
  T.check(ArjUI.activeTab=="gear" and ArjUI.activeGearTab=="inv" and T.commands[#T.commands].command=="inv","INV click sends one inventory request")
  feedTriggers("You are carrying:\na bronze sword\nsome healing herbs\nA swirling mass\nboots of endurance\n[2] a scarf\nboots of endurance\n< 100h/100H 100v/100V Pos: standing>\n")
  T.check(ArjUI.state.inventory and #ArjUI.state.inventory.lines==6,"all inventory names, counts and repeated items captured")
 end,actions=function() return {T.click(ArjUI.gearTabs.eq)} end},
 {name="equipment",run=function()
  T.check(ArjUI.activeTab=="gear" and ArjUI.activeGearTab=="eq" and ArjUI.invBox.hidden and T.commands[#T.commands].command=="eq","EQ click request")
  feedTriggers("You are using:\n<wielded> a bronze sword\n<worn on body> a leather vest\n< 100h/100H 100v/100V Pos: standing>\n")
  T.check(ArjUI.state.equipment and #ArjUI.state.equipment.lines==2,"equipment capture")
 end},
 {name="equipment-empty",run=function()
  feedTriggers("You aren't wearing anything!\n")
  T.check(#ArjUI.state.equipment.lines==0,"empty equipment clears prior gear")
  ArjUI:panelAction("character","minimize")
  ArjUI:panelAction("character","restore")
  T.check(ArjUI.invBox.hidden and not ArjUI.eqBox.hidden,"GEAR restore retains selected view")
 end,actions=function() return {T.click(ArjUI.tabButtons.spells)} end},
 {name="spell-list",run=function()
  T.check(ArjUI.activeTab=="spells" and T.commands[#T.commands].command=="spells","opening SPELLS requests the read-only personal list")
  feedTriggers("\27[36m>====[ VisualTester | Druid | Max Circle 5 ]====<\27[0m\n\n1st CIRCLE:\ncure light\n\ncommune is your spell interface\nSee: spells <class or specialization> | spells info <spell name>\n")
  T.check(ArjUI.state.spellCommand=="commune" and T.lines("ArjUI_SpellsBox"):find("cure light",1,true),"personal catalog and server-selected command rendered")
 end,actions=function()
  local click=T.click(ArjUI.spellTabs.interface)
  click.button=3
  return {click}
 end},
 {name="spell-interface-right-click",run=function()
  T.check(T.commands[#T.commands].command=="spells" and not ArjUI.spellCapture,
    "right-click cannot run the preparation command")
 end,actions=function() return {T.click(ArjUI.spellTabs.interface)} end},
 {name="spell-interface",run=function()
  T.check(T.commands[#T.commands].command=="commune","explicit interface click runs the server-selected command")
  feedTriggers("You currently have the following spell slots available:\n  1st circle:  2 of  3   (  12 seconds)\n< 100h/100H 100v/100V Pos: standing>\n")
  T.check(ArjUI.state.spellView=="interface" and T.lines("ArjUI_SpellsBox"):find("2 of  3",1,true),"native spell interface output captured")
  T.emit("Duris.Capabilities",{version=1,active={"Char.SpellPreparation"}})
  T.emit("Char.SpellPreparation",{state="active",estimatedSeconds=37})
  T.emit("Char.Vitals",{position="on your ass",hp=75,maxHp=100})
  T.check(ArjUI.prepLabel.message=="PREP 0:37" and ArjUI.posLabel.message=="ON YOUR ASS","active estimate and position render independently")
  T.check(ArjUI.posLabel:get_x()+ArjUI.posLabel:get_width()<ArjUI.prepLabel:get_x(),"position and estimate have separate bounds")
 end,actions=function() return {T.click(ArjUI.spellTabs.list)} end},
 {name="no-spells",run=function()
  T.check(T.commands[#T.commands].command=="spells","list click requests an updated catalog")
  feedTriggers(">====[ VisualTester | Warrior | Max Circle 0 ]====<\n  No eligible spells for this character's current classes/specialization.\nSee: spells <class or specialization> | spells info <spell name>\n")
  T.check(ArjUI.state.spellCommand==nil and not ArjUI.state.spellOutput,"new catalog clears the prior interface")
 end,actions=function() return {T.click(ArjUI.tabButtons.who)} end},
 {name="who",run=function()
  T.check(ArjUI.activeTab=="who" and T.commands[#T.commands].command=="who","WHO click request")
  feedTriggers("Listing of the Gods\n [60 Warrior] Tester\nListing of the Mortals\n [25 Psionicist] VisualTester\nThere are 2 visible players.\n< 100h/100H 100v/100V Pos: standing>\n")
  T.check(ArjUI.state.whoList and #ArjUI.state.whoList.lines>=3,"who capture")
 end,actions=function() return {T.click(ArjUI.tabButtons.stats)} end},
 {name="quest-progress",run=function()
  T.check(ArjUI.activeTab=="stats" and T.commands[#T.commands].command=="score","STATS click sends player score command")
  T.emit("Char.Status",{name="VisualTester",class="&+BWarrior&n",race="Human"})
  T.check(ArjUI.state.charClass=="Warrior","server class color codes removed")
  T.emit("Quest.Status",{active=true,type="kill",target="bronze guardians",killCount=2,killRequired=5,remaining=300,mapBought=false})
  T.check(ArjUI.state.quest.killCount==2,"quest progress")
 end},
 {name="quest-clear",run=function()
  T.emit("Quest.Status",{active=false})
  T.check(ArjUI.state.quest==nil,"quest completion clears panel")
 end,actions=function() return {T.click(ArjUI.tabButtons.ship)} end},
 {name="ship-contacts",run=function()
  T.check(ArjUI.activeTab=="ship" and T.commands[#T.commands].command=="look ship","SHIP click requests the bridge reference")
  T.emit("Ship.Info",{name="Bronze Voyager",heading=90,speed=12,maxSpeed=20,captain="VisualTester",weapons={
   {slot=10,name="Port cannon",position="port",ammo=0,maxAmmo=10,damage=1,ready=false},
   {slot=2,name="Forward cannon",position="bow",ammo=8,maxAmmo=10,damage=0,ready=true}}})
  T.emit("Ship.Contacts",{contacts={{id=1,name="Far vessel",range=300,heading=30,speed=8,side="evil"},{id=2,name="Near vessel",range=50,heading=60,speed=4,side="good"}}})
  local output=T.lines("ArjUI_ShipBox")
  T.check(output:find("Near vessel",1,true)<output:find("Far vessel",1,true),"ship contacts sorted by range")
  T.check(output:find("Weapons",1,true)<output:find("Contacts",1,true),"mouse-reachable SHIP has ordered sections")
  T.check(output:find("[2] Forward cannon",1,true)<output:find("[10] Port cannon",1,true),"mouse-reachable weapons sort by slot")
 end},
 {name="ship-clear",run=function()
  T.emit("Ship.Contacts",{contacts={}})
  T.check(not T.lines("ArjUI_ShipBox"):find("Far vessel",1,true),"removed contacts clear")
 end}
})
