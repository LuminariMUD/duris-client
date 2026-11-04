local T=DurisTest
local function withNativeSend(action)
  local recordedSend = send
  send = T.originalSend
  local ok, err = pcall(action)
  send = recordedSend
  assert(ok, err)
end
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
  T.check(ArjUI.state.target=="wolf" and ArjUI.state.targetHpPct==32,"real Combat.Update decoded")
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
 {name="spell-catalog-wire",run=function()
  withNativeSend(function() ArjUI:switchTab("spells") end)
 end,wait=.5,verify=function()
  T.check(ArjUI.state.spellCommand=="commune","personal spell command decoded over Telnet")
 end},
 {name="spell-interface-wire",run=function()
  withNativeSend(function() ArjUI:requestSpellOutput("commune") end)
 end,wait=.5,verify=function()
  T.check(ArjUI.state.spellView=="interface" and #ArjUI.state.spellOutput==2,"Telnet GA ends the spell interface response at a custom prompt")
 end},
 {name="preparation-active",run=function()
  T.originalSend("prep-active",false)
 end,wait=.5,verify=function()
  T.check(ArjUI.state.prepMode=="active" and ArjUI.prepTimer,"opt-in stream negotiated and active snapshot decoded")
 end},
 {name="preparation-elapsed",run=function() end,wait=2.1,verify=function()
  T.check(ArjUI.prepLabel.message=="PREP 0:00" and not ArjUI.prepTimer,"local zero does not claim server completion")
 end},
 {name="preparation-paused",run=function()
  T.originalSend("prep-paused",false)
 end,wait=1.2,verify=function()
  T.check(ArjUI.prepLabel.message=="HOLD 0:17" and not ArjUI.prepTimer,"paused estimate stays fixed")
 end},
 {name="preparation-complete",run=function()
  T.originalSend("prep-complete",false)
 end,wait=.5,verify=function()
  T.check(ArjUI.prepLabel.message=="PREP OK","server completion is distinct")
 end},
 {name="preparation-inactive",run=function()
  T.originalSend("prep-inactive",false)
 end,wait=.5,verify=function()
  T.check(ArjUI.prepLabel.message=="PREP —" and not ArjUI.prepTimer,"capability invalidation clears estimate")
 end},
 {name="preparation-protocol-disabled",run=function()
  T.originalSend("prep-active",false)
 end,wait=.5,verify=function()
  T.check(ArjUI.prepTimer,"timer can restart after invalidation")
  T.originalSend("prep-wont",false)
 end},
 {name="preparation-disabled-clear",run=function() end,verify=function()
  T.check(ArjUI.prepLabel.message=="PREP —" and not ArjUI.prepTimer,"WONT GMCP clears estimate and stops timer")
 end},
 {name="wire-disconnect",run=function() disconnect() end,wait=.5,verify=function()
  T.check(not select(3,getConnectionInfo()),"test socket disconnected")
  T.check(ArjUI.playerName==nil,"socket disconnect clears session")
  T.check(not ArjUI.state.spellCommand and not ArjUI.state.spellOutput and not ArjUI.state.spellList,"socket disconnect clears spell views")
 end}
})
