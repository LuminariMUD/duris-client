local T=DurisTest
ArjUI.initialDataRequested=true
T.steps({
 {name="click-inv",run=function() end,actions=function() return {T.click(ArjUI.tabButtons.inv)} end},
 {name="inventory",run=function()
  T.check(ArjUI.activeTab=="inv" and T.commands[#T.commands].command=="inv","INV click sends one inventory request")
  feedTriggers("You are carrying:\na bronze sword\nsome healing herbs\nA swirling mass\nboots of endurance\n[2] a scarf\nboots of endurance\n< 100h/100H 100v/100V Pos: standing>\n")
  T.check(ArjUI.state.inventory and #ArjUI.state.inventory.lines==6,"all inventory names, counts and repeated items captured")
 end,actions=function() return {T.click(ArjUI.tabButtons.eq)} end},
 {name="equipment",run=function()
  T.check(ArjUI.activeTab=="eq" and T.commands[#T.commands].command=="eq","EQ click request")
  feedTriggers("You are using:\n<wielded> a bronze sword\n<worn on body> a leather vest\n< 100h/100H 100v/100V Pos: standing>\n")
  T.check(ArjUI.state.equipment and #ArjUI.state.equipment.lines==2,"equipment capture")
 end},
 {name="equipment-empty",run=function()
  feedTriggers("You aren't wearing anything!\n")
  T.check(#ArjUI.state.equipment.lines==0,"empty equipment clears prior gear")
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
  T.check(ArjUI.activeTab=="ship" and T.commands[#T.commands].command=="look contacts","SHIP click request")
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
