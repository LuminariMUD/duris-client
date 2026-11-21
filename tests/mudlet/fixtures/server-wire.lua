local T=DurisTest
local nativeGMCP=sendGMCP
local recordedSend=send
local oldPlayerLook, sentBeforeRefresh
local function withNativeSend(action)
  local recordedSend = send
  send = T.originalSend
  local ok, err = pcall(action)
  send = recordedSend
  assert(ok, err)
end
local function clickPlayer(row)
  local box=ArjUI.enemyBox
  local w,h=calcFontSize(9)
  return {type="click",x=box:get_x()+w*2,y=box:get_y()+h*(row-.5)}
end
local function clickMenuAction(index)
  local menu=assert(ArjUI.currentMenu,"player row opens its menu")
  return {type="click",x=menu:get_x()+40,y=menu:get_y()+32+(index-1)*22}
end
local function firstMenuButton(menu)
  return menu.windowList[menu.name.."_entries"].windowList[menu.name.."_1"]
end
T.steps({
 {name="negotiate",run=function()
  -- Model another profile add-on sending its Add before this package's Add.
  sendGMCP=function(message)
    if message:match("^Core%.Hello") then
      nativeGMCP('Core.Supports.Add ["Duris.Time 1"]')
      sendGMCP=nativeGMCP
    end
    nativeGMCP(message)
  end
  connectToServer("127.0.0.1",T.config.gmcp_port)
 end,wait=1.6,verify=function()
  T.check(select(3,getConnectionInfo()),"connected to loopback fixture")
  local n=ArjUI.gmcpNegotiation
  T.check(n.advertisements==2 and n.synced and not ArjUI.gmcpRetryTimer,
    "ArjUI retries rate-limited Supports.Add and stops after acknowledged interest")
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
  send=T.originalSend
  ArjUI.initialDataRequested=false
  ArjUI:onLoginDetected()
  ArjUI:switchTab("spells")
  -- Structured time retires the old automatic login query. Still exercise a
  -- real interleaved manual time reply while the spell catalog is pending.
  ArjUI:after(.2,function() T.originalSend("time",false) end)
 end,wait=1.4,verify=function()
  send=recordedSend
  T.check(ArjUI.state.spellCommand=="commune","catalog survives earlier prompt, interleaved time query and a server page break")
  T.check(table.concat(ArjUI.state.spellList,"\n"):find("barkskin",1,true),"second page joins the catalog")
  T.check(not T.lines("ArjUI_SpellsBox"):find("Unrelated output",1,true),"previous response stays out of catalog")
 end},
 {name="spell-interface-wire",run=function()
  withNativeSend(function() ArjUI:requestSpellOutput("commune") end)
 end,wait=.5,verify=function()
  T.check(ArjUI.state.spellView=="interface" and #ArjUI.state.spellOutput==2,
    "only the recognized spell interface response is captured between unrelated and terminating GA prompts")
  T.check(ArjUI.state.spellOutput[1]=="You currently have the following spell slots available:",
    "unrelated output and prompt excluded from interface reply")
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
 {name="prepare-shared-socket",run=function()
  T.originalSend("prep-paused",false)
 end,wait=.4,verify=function()
  T.check(ArjUI.prepLabel.message=="HOLD 0:17","paused stream ready for reinstall")
  ArjUI:enableGMCP()
  T.check(ArjUI.prepLabel.message=="HOLD 0:17","duplicate enable preserves snapshot")
 end},
 {name="uninstall-with-new-interest",run=function()
  -- No event-loop turn for the capabilities acknowledgment before teardown.
  nativeGMCP('Duris.Subscribe ["Char.SpellPreparation 1","Duris.Time 1"]')
  uninstallPackage("Arjinius Client")
  T.check(not ArjUI.main and not ArjUI.gmcpRetryTimer,"teardown completed on the live test socket")
  T.originalSend("probe-interests",false)
 end,wait=.4,verify=function()
  T.check(gmcp.Test.Interests.names[2]=="Duris.Time",
    "uninstall preserves a second add-on's in-flight interest update")
 end},
 {name="reinstall-active-stream",run=function()
  installPackage(T.run.."/duris-client.mpackage")
  ArjMapper.config.apiBase=T.config.map_base
 end,wait=.65,verify=function()
  T.check(ArjUI.gmcpNegotiation.subscriptions==1 and ArjUI.prepLabel.message=="HOLD 0:17"
    and not ArjUI.gmcpRetryTimer,"reinstall requests and receives a fresh estimate for an already active stream")
  T.originalSend("probe-interests",false)
 end},
 {name="refreshed-interests",run=function()
  T.check(gmcp.Test.Interests.names[2]=="Duris.Time","resnapshot preserves other active interests")
 end},
 {name="racewar-player-snapshot",run=function()
  T.originalSend("racewar-players",false)
 end,wait=.5,verify=function()
  local players=ArjUI.state.players
  T.check(players[1].target=="3.Human" and players[3].target==yajl.null,
    "wire snapshot decodes the racewar selector and explicit JSON null")
  T.check(T.lines("ArjUI_EnemyBox"):find("Enemy",1,true),"opposing player keeps the displayed name")
 end,actions=function() return {clickPlayer(1)} end},
 {name="racewar-player-look",run=function() end,actions=function() return {clickMenuAction(1)} end},
 {name="racewar-player-result",run=function()
  T.check(T.commands[#T.commands].command=="look 3.Human","Look sends the opposing player's room selector")
 end,actions=function() return {clickPlayer(2)} end},
 {name="player-consent",run=function() end,actions=function() return {clickMenuAction(5)} end},
 {name="player-legacy",run=function()
  T.check(T.commands[#T.commands].command=="consent Friend","Consent uses the player name required by its parser")
 end,actions=function() return {clickPlayer(4)} end},
 {name="player-legacy-look",run=function() end,actions=function() return {clickMenuAction(1)} end},
 {name="player-unavailable",run=function()
  T.check(T.commands[#T.commands].command=="look Legacy","missing selector retains legacy Look by name")
 end,actions=function() return {clickPlayer(3)} end},
 {name="player-no-room-actions",run=function()
  T.check(firstMenuButton(assert(ArjUI.currentMenu)).message=="Consent",
    "explicitly unavailable selector omits room actions and retains name-based Consent")
 end,actions=function() return {clickPlayer(1)} end},
 {name="player-selector-refresh",run=function()
  oldPlayerLook=firstMenuButton(assert(ArjUI.currentMenu)).clickCallback
  sentBeforeRefresh=#T.commands
  T.originalSend("racewar-players-shifted",false)
 end,wait=.5,verify=function()
  T.check(not ArjUI.currentMenu,"replacement room snapshot closes the player menu")
  oldPlayerLook()
  T.check(#T.commands==sentBeforeRefresh,"stale Look cannot send the previous ordinal")
 end,actions=function() return {clickPlayer(1)} end},
 {name="player-refreshed-look",run=function() end,actions=function() return {clickMenuAction(1)} end},
 {name="mob-selectors-wire",run=function()
  T.check(T.commands[#T.commands].command=="look 2.Human","reopened player menu uses the new ordinal")
  T.originalSend("mob-selectors",false)
 end,wait=.5,verify=function()
  local npcs=ArjUI.state.npcs
  T.check(#npcs==2 and npcs[1].target=="2.bullywug" and npcs[2].target=="",
    "wire snapshot decodes the optional selector and explicitly unavailable target")
 end,actions=function()
  local box=ArjUI.mobsBox
  local w,h=calcFontSize(9)
  return {{type="click",x=box:get_x()+w*2,y=box:get_y()+h/2}}
 end},
 {name="preparation-protocol-disabled",run=function()
  T.originalSend("prep-active",false)
 end,wait=.5,verify=function()
  T.check(ArjUI.prepTimer,"timer can restart after invalidation")
  T.check(ArjUI.currentMenu,"wire mob selector opens a menu before GMCP stops")
  T.check(#ArjUI.state.players==1,"a player selector is present before GMCP stops")
  T.originalSend("prep-wont",false)
 end},
 {name="preparation-disabled-clear",run=function() end,verify=function()
  T.check(ArjUI.prepLabel.message=="PREP —" and not ArjUI.prepTimer,"WONT GMCP clears estimate and stops timer")
  T.check(select(3,getConnectionInfo()),"the game socket stays connected after WONT GMCP")
  T.check(#ArjUI.state.players==0 and T.lines("ArjUI_EnemyBox"):find("(none)",1,true),
    "WONT GMCP also invalidates the player list")
  T.check(not ArjUI.currentMenu and #ArjUI.state.npcs==0
    and T.lines("ArjUI_MobsBox"):find("(none)",1,true),"WONT GMCP invalidates mob rows and closes their menu")
 end},
 {name="wire-disconnect",run=function()
  ArjUI.state.spellCommand="commune"
  ArjUI.state.spellList={"catalog"}
  ArjUI.state.spellOutput={"response"}
  disconnect()
 end,wait=.5,verify=function()
  T.check(not select(3,getConnectionInfo()),"test socket disconnected")
  T.check(ArjUI.playerName==nil,"socket disconnect clears session")
  T.check(not ArjUI.state.spellCommand and not ArjUI.state.spellOutput and not ArjUI.state.spellList,"socket disconnect clears spell views")
 end}
})
