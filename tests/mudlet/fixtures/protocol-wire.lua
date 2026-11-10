local T=DurisTest
T.steps({
 {name="connect",run=function()
  connectToServer("127.0.0.1",T.config.gmcp_port)
 end,wait=2,verify=function()
  T.check(select(3,getConnectionInfo()),"real loopback GMCP connection")
  T.check(ArjUI.gmcpNegotiation.synced,"versioned interests negotiated through native parser")
  ArjUI:switchTab("gear")
 end},
 {name="producer-contracts",run=function()
  T.originalSend("interfaces",false)
 end,wait=1.2,verify=function()
  T.check(ArjUI.session and ArjUI.session.state=="playing","production Session survives JSON/Telnet decoding")
  T.check(ArjUI.state.gameHour==10 and ArjUI.state.timeOfDay=="day","production clock updates HUD")
  T.check(ArjUI.damage.session==17 and ArjUI.damage.sessionHits==1,"secondary production hit decoded once across duplicate bootstrap")
  T.check(ArjUI.state.hp==70 and ArjUI.state.tank=="Ally" and ArjUI.state.tankHpPct==5,"wire self/tank HP remain independent")
  T.check(ArjUI.itemViews.inv and #ArjUI.itemViews.inv.items==0,"production known-empty inventory")
  T.check(ArjUI.itemViews.eq and ArjUI.itemViews.eq.items[1].description=="a blade","production equipment snapshot decoded")
  ArjUI.activeGearTab="eq"; ArjUI:renderEq()
  T.check(T.lines(ArjUI.eqBox.name):find("wielded a blade",1,true),"equipment slot and description reach GEAR")
 end},
 {name="disconnect",run=function() disconnect() end,wait=.4,verify=function()
  T.check(not ArjUI.session and not ArjUI.itemViews.inv and not ArjUI.itemViews.eq,"disconnect retires protocol scopes and selectors")
  T.check(ArjUI.state.timeOfDay==nil,"disconnect does not invent an authoritative clock phase")
 end}
})
