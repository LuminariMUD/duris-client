local T=DurisTest
ArjUI.initialDataRequested=true
local function pageClick(widget)
 local action=T.click(widget)
 action.x=action.x+ArjUI.shipRoot:get_x()
 action.y=action.y+ArjUI.shipRoot:get_y()+(ArjUI.shipRoot:get_width()>=600 and 23 or 46)
 return action
end
local function countWidgets() local n=0; for _ in pairs(ArjUI.shipWidgets) do n=n+1 end; return n end
T.steps({
 {name="expanded-bridge",run=function()
  ArjUI:switchTab("ship")
  local f=assert(io.open(getMudletHomeDir().."/Duris Test Companion/fixtures/server-gmcp.json"))
  local wire=yajl.to_value(f:read("*a")); f:close()
  for _,packet in ipairs(wire.phases.snapshot) do if packet.package:find("Ship.",1,true) then T.emit(packet.package,packet.data) end end
  local info=gmcp.Ship.Info
  info.armor={bow={32,100},port={33,100},starboard={65,100},stern={66,100}}
  info.internal={bow={0,0},port={10,30},starboard={30,45},stern={27,27}}
  T.emit("Ship.Info",info)
  T.commands={}; ArjUI:panelAction("character","maximize")
 end,verify=function()
  T.check(ArjUI.shipMode=="bridge" and ArjUI.shipBox.hidden and not ArjUI.shipPage.hidden,"Bridge is the single visible mode")
  T.check(#ArjUI:shipView().slots==16,"all sixteen occupied slots reach the numbered manifest")
  T.check(ArjUI.shipWidgets.bowArmor.shipStyle:find("#ce7974",1,true),"32 of 100 is critical")
  T.check(ArjUI.shipWidgets.portArmor.shipStyle:find("#d4b56e",1,true),"33 of 100 reaches damaged band")
  T.check(ArjUI.shipWidgets.starboardArmor.shipStyle:find("#d4b56e",1,true),"65 of 100 remains damaged")
  T.check(ArjUI.shipWidgets.sternArmor.shipStyle:find("#7aa889",1,true),"66 of 100 reaches sound band")
  T.check(not ArjUI.shipWidgets.bowHullfill,"zero maximum produces no inferred gauge")
  T.check(#T.commands==0,"maximizing and painting send no game command")
  ArjUI.shipWidgets.badge2.clickCallback()
  T.check(ArjUI.shipSelection.slot==2 and ArjUI.shipWidgets.slotInspector.shipUsed,"weapon badge opens a complete local inspector")
  ArjUI.shipWidgets.contactMarker1.clickCallback()
  T.check(ArjUI.shipSelection.contacts and ArjUI.shipWidgets.contactInspector1.shipUsed,"contact marker opens its complete local inspector")
  T.check(#T.commands==0,"weapon and contact callbacks do not send orders")
  ArjUI.shipSelection=nil; ArjUI:renderShip()
 end,actions=function() return {pageClick(ArjUI.shipWidgets.portArmor)} end},
 {name="arc-inspection",run=function()
  T.check(ArjUI.shipSelection.arc=="port" and #T.commands==0,"arc click inspects locally")
 end,actions=function() return {T.click(ArjUI.shipControls[2])} end},
 {name="details-mode",run=function()
  T.check(ArjUI.shipMode=="details" and ArjUI.shipPage.hidden and not ArjUI.shipBox.hidden,"Details hides Bridge")
  T.check(ArjUI.shipDetailsText:find("Weight load: 136/165",1,true),"copy source contains the complete bridge ledger")
 end,actions=function() return {T.click(ArjUI.shipControls[3])} end},
 {name="copy-local",run=function()
  T.check(getClipboardText()==ArjUI.shipDetailsText,"Copy details exports exactly the rendered ledger")
  T.check(#T.commands==0,"view and clipboard actions send no commands")
 end,actions=function() return {T.click(ArjUI.shipControls[5]),T.click(ArjUI.shipControls[6]),T.click(ArjUI.shipControls[7])} end},
 {name="reference-commands",run=function()
  T.check(#T.commands==3,"reference buttons send exactly three commands")
  for i,value in ipairs({"look ship","look crew","look contacts"}) do T.check(T.commands[i].command==value,"explicit "..value) end
 end,actions=function() return {T.click(ArjUI.shipControls[1])} end},
 {name="coalesced-burst",run=function()
  T.paintCount=ArjUI.shipPaintCount; T.widgets=countWidgets(); T.hull=ArjUI.shipWidgets.portArmor
  for i=1,100 do
   gmcp.Ship.Contacts={shipKey=ArjUI.state.ship.shipKey,heading=i%360,speed=0,contacts=ArjUI.state.ship.contacts}
   raiseEvent("gmcp.Ship.Contacts")
  end
  T.check(ArjUI.shipPaintCount==T.paintCount and ArjUI.shipPaintTimer~=nil,"burst has one deferred paint")
 end,verify=function()
  T.check(ArjUI.shipPaintCount==T.paintCount+1 and ArjUI.shipPaintTimer==nil,"burst coalesces to one completed paint")
  T.check(countWidgets()==T.widgets and ArjUI.shipWidgets.portArmor==T.hull,"updates retain widget identities and count")
  T.paintCount=ArjUI.shipPaintCount
 end},
 {name="bridge-scroll",run=function() end,actions=function()
  return {{type="scroll",x=ArjUI.shipRoot:get_x()+ArjUI.shipRoot:get_width()/2,y=ArjUI.shipRoot:get_y()+200}}
 end},
 {name="scroll-refresh",run=function()
  T.emit("Ship.Contacts",{shipKey=ArjUI.state.ship.shipKey,heading=0,speed=0,contacts=ArjUI.state.ship.contacts})
 end},
 {name="unchanged-idle",run=function()
  T.check(ArjUI.shipPaintCount==T.paintCount+1 and ArjUI.shipPaintTimer==nil,"only the requested scroll-time update paints")
  ArjUI:panelAction("character","restore")
 end},
 {name="narrow-bridge",run=function()
  T.check(ArjUI.shipRoot:get_width()<720,"ordinary Character uses the compact column")
 end,actions=function() return {T.click(ArjUI.shipControls[4])} end},
 {name="narrow-bearing-toggle",run=function()
  T.check(ArjUI.shipPlotOpen and ArjUI.shipWidgets.plot.shipUsed,"narrow Bearing glass expands locally")
  ArjUI:panelAction("character","minimize")
  T.paintCount=ArjUI.shipPaintCount
  T.emit("Ship.Info",{shipKey="3:3",name="Hidden vessel",id="**"})
 end,verify=function()
  T.check(ArjUI.shipPaintCount==T.paintCount and ArjUI.shipPaintTimer==nil,"minimized panel accepts state without painting")
  ArjUI:panelAction("character","restore")
 end},
 {name="hidden-reveal",run=function()
  T.check(ArjUI.shipWidgets.identity.shipHTML:find("Hidden vessel",1,true),"reveal paints the latest hidden state")
  ArjUI:panelAction("output","maximize")
  T.paintCount=ArjUI.shipPaintCount
  T.emit("Ship.Contacts",{shipKey="3:3",heading=0,speed=0,contacts={}})
 end,verify=function()
  T.check(ArjUI.shipPaintCount==T.paintCount and ArjUI.shipPaintTimer==nil,"covered Character does not paint")
  ArjUI:panelAction("output","restore")
 end},
 {name="mode-restore",run=function()
  ArjUI.shipMode="details"; ArjUI:saveSettings(); ArjUI:setVisible(false)
  T.paintCount=ArjUI.shipPaintCount; T.emit("Ship.Info",{shipKey="3:3",name="Latest while off",id="**"})
  T.check(ArjUI.shipPaintCount==T.paintCount,"ui off accepts data without paint")
  ArjUI:setVisible(true)
 end,verify=function()
  T.check(ArjUI.shipPage.hidden and not ArjUI.shipBox.hidden,"ui on restores only selected Details")
  T.check(T.lines("ArjUI_ShipBox"):find("Latest while off",1,true),"latest data rendered on ui on")
  ArjUI.shipMode="bridge"; ArjUI:loadSettings()
  T.check(ArjUI.shipMode=="details","only view preference persists")
 end},
 {name="minimum-character",run=function()
  local panel=ArjUI.panels.character
  panel.state.mode="floating"; panel.state.rect={.3,.1,285/ArjUI.uiRoot:get_width(),160/ArjUI.uiRoot:get_height()}
  ArjUI.shipMode="bridge"; ArjUI:applyPanelLayout(); ArjUI:refreshPanelContent("character")
  panel.frame:raiseAll()
 end,verify=function()
  T.check(ArjUI.shipPage:get_height()>30 and ArjUI.shipControls[7]:get_width()>50,"minimum frame retains the action strip and scrollable body")
  T.check(not ArjUI.shipPage.hidden and ArjUI.shipBox.hidden,"minimum frame reconciles Bridge mode")
 end}
})
