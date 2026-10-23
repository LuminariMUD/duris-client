local T=DurisTest
T.steps({
 {name="negotiate",run=function()
  connectToServer("127.0.0.1",T.config.gmcp_port)
 end,wait=.8,verify=function()
  T.check(select(3,getConnectionInfo()),"connected to loopback fixture")
  ArjUI.playerName="Tester"
  ArjUI.initialDataRequested=true
  ArjUI:setSetting("damageTracker",true)
  ArjUI:switchTab("ship")
 end},
 {name="real-server-snapshot",run=function()
  T.originalSend("snapshot",false)
 end,wait=.8,verify=function()
  T.check(ArjUI.state.room=='Gate of "Dawn"',"room quotes survive JSON decoding once")
  T.check(ArjUI.state.charClass=="Warrior" and ArjUI.state.charRace=="Human","real identity decoded")
  T.check(#ArjUI.state.affects==1 and ArjUI.state.affects[1].duration==180,"real active affects decoded")
  T.check(ArjUI.state.quest.killCount==2 and ArjUI.state.quest.killRequired==5,"real active quest decoded")
  T.check(T.lines("ArjUI_NchatBox"):find("hello",1,true),"real channel data routes to chat")
  T.check(ArjUI.state.hp==70 and ArjUI.state.hpmax==100,"real Char.Vitals decoded")
  T.check(#ArjUI.state.group==2 and ArjUI.state.groupMax==13,"real Group.Status decoded")
  T.check(ArjUI.state.target=="wolf" and ArjUI.state.targetHpPct==40,"real Combat.Update decoded")
  T.check(ArjUI.damage.fight==8,"real GMCP round decoded")
  T.check(ArjUI.state.ship.heading==90 and ArjUI.state.ship.speed==12,"real ship navigation decoded")
  T.check(ArjAuto:targetContact().id=="BB","real contact targeting decoded")
  local out=T.lines("ArjUI_ShipBox")
  T.check(out:find("80/100",1,true) and out:find("silk",1,true),"real nested ship payload rendered")
  T.check(gmcp.Room.Map.map:find("@",1,true),"real Room.Map arrives via Telnet")
 end},
 {name="real-empty-updates",run=function()
  T.originalSend("clear",false)
 end,wait=.8,verify=function()
  T.check(#ArjUI.state.affects==0 and ArjUI.state.quest==nil,"real affects and quest clears replace populated state")
  T.check(#ArjUI.state.group==0,"real empty group replaces populated group")
  T.check(ArjUI.state.target==nil and ArjUI.damage.fight==0 and ArjUI.damage.session==8,"real null combat end ignores subsequently flushed text damage")
  T.check(ArjAuto:targetContact()==nil and ArjUI.state.ship.maxSpeed==nil,"real bridge departure clears ship")
  T.check(T.lines("ArjUI_ShipBox"):find("(no ship data)",1,true),"real departure sequence leaves the no-ship display")
 end},
 {name="custom-prompt-inventory",run=function()
  T.originalSend("inventory",false)
 end,wait=.8,verify=function()
  T.check(ArjUI.state.capturing==nil,"Telnet GA terminates capture with a custom prompt")
  T.check(ArjUI.state.inventory and #ArjUI.state.inventory.lines==1,"custom prompt excluded from inventory")
 end},
 {name="wire-disconnect",run=function() disconnect() end,wait=.5,verify=function()
  T.check(not select(3,getConnectionInfo()),"test socket disconnected")
  T.check(ArjUI.playerName==nil,"socket disconnect clears session")
 end}
})
