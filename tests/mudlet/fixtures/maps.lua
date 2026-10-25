local T=DurisTest
local function room(zone)
 T.emit("Room.Info",{num=90010,zone=zone,name="Bronze Gate",area="Bronze Tower",exits={north=90011,["east #"]=90012}})
end
local cached,roomSize,wildZoom,fullPadding,pausedText
local function centered()
 local container=ArjMapper.ui.zoneContainer
 local player=ArjMapper.ui.roomLabels.room_90010
 T.check(math.abs(player:get_y()+player:get_height()/2-container:get_y()-math.floor(container:get_height()/2))<2,"zone player recenters after header change")
 T.check(ArjMapper.state.zoneData[9001]==cached and ArjMapper.config.roomSize==roomSize,"header retains map cache and zoom")
end
T.steps({
 {name="zone",wait=.8,run=function() room(9001) end,verify=function()
  T.check(ArjMapper.state.zoneData[9001] and ArjMapper.state.lastDisplayMode=="zone","zone fetched and shown")
  T.check(ArjMapper.state.currentRoom==90010,"current room")
  T.check(ArjMapper.state.roomDoors[90010].east,"door marker retained")
 end,actions=function()
  local widget=ArjMapper.ui.roomLabels.room_90010
  return {{type="hover",x=widget:get_x()+widget:get_width()/2,y=widget:get_y()+widget:get_height()/2}}
 end},
 {name="zone-compact",wait=.5,run=function()
  cached=ArjMapper.state.zoneData[9001]
  roomSize=ArjMapper.config.roomSize
  expandAlias("ui set compactHeader on")
 end,verify=centered,actions=function()
  local widget=ArjMapper.ui.roomLabels.room_90010
  return {{type="hover",x=widget:get_x()+widget:get_width()/2,y=widget:get_y()+widget:get_height()/2}}
 end},
 {name="zone-full",wait=.5,run=function()
  expandAlias("ui set compactHeader off")
 end,verify=centered},
 {name="stationary-zone-normal-maximize",wait=.5,run=function()
  ArjUI:panelAction("map","restore")
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  local c=ArjMapper.ui.zoneContainer
  local player=ArjMapper.ui.roomLabels.room_90010
  T.check(math.abs(player:get_x()+player:get_width()/2-c:get_x()-math.floor(c:get_width()/2))<2,"stationary maximized zone centers horizontally")
  centered()
  T.check(true,"zone maximize retains saved normal state")
  T.check(ArjMapper.ui.wildConsole.hidden,"maximized zone keeps wilderness hidden")
 end},
 {name="stationary-zone-normal-restore",run=function()
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  ArjUI:panelAction("map","restore")
 end},
 {name="stationary-zone-minimize-maximize",wait=.5,run=function()
  ArjUI:panelAction("map","restore")
  ArjUI:panelAction("map","minimize")
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  local c=ArjMapper.ui.zoneContainer
  local player=ArjMapper.ui.roomLabels.room_90010
  T.check(math.abs(player:get_x()+player:get_width()/2-c:get_x()-math.floor(c:get_width()/2))<2,"stationary maximized zone centers horizontally")
  centered()
  T.check(ArjUI.panels.map.state.minimized,"zone maximize retains saved normal state")
  T.check(ArjMapper.ui.wildConsole.hidden,"maximized zone keeps wilderness hidden")
 end},
 {name="stationary-zone-minimize-restore",run=function()
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  T.check(ArjUI.panels.map.state.minimized,"normal map minimize state survives maximize")
  ArjUI:panelAction("map","restore")
 end},
 {name="stationary-zone-hide-maximize",wait=.5,run=function()
  ArjUI:panelAction("map","restore")
  ArjUI:panelAction("map","hide")
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  local c=ArjMapper.ui.zoneContainer
  local player=ArjMapper.ui.roomLabels.room_90010
  T.check(math.abs(player:get_x()+player:get_width()/2-c:get_x()-math.floor(c:get_width()/2))<2,"stationary maximized zone centers horizontally")
  centered()
  T.check(ArjUI.panels.map.state.hidden,"zone maximize retains saved normal state")
  T.check(ArjMapper.ui.wildConsole.hidden,"maximized zone keeps wilderness hidden")
 end},
 {name="stationary-zone-hide-restore",run=function()
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  T.check(ArjUI.panels.map.state.hidden,"normal map hide state survives maximize")
  ArjUI:panelAction("map","restore")
 end},
 {name="zoom",run=function()
  for i=1,20 do ArjMapper:zoomIn() end
  T.check(ArjMapper.config.roomSize==24,"zone zoom upper bound")
  for i=1,20 do ArjMapper:zoomOut() end
  T.check(ArjMapper.config.roomSize>=8,"zone zoom lower bound")
  room(9001)
 end},
 {name="delayed-to-wilderness",wait=1.4,run=function()
  room(9002); room(9002)
  T.emit("Room.Info",{num=0,zone=600,name="Wilderness",area="Open plains",exits={north=true,east=true}})
  T.emit("Room.Map",{map="&+G....&+W^&+G....\n&+G...&+R@&+G.....\n&+G....&+B~&+G...."})
 end,verify=function()
  T.check(ArjMapper.state.lastDisplayMode=="wilderness","late zone response preserves wilderness")
  T.check(ArjMapper.state.zoneData[9002]~=nil,"late data cached")
 end},
 {name="wilderness-compact",run=function()
  local text=T.lines(ArjMapper.ui.wildConsole.name)
  fullPadding=#(text:match("^\n*") or "")
  T.fullMapHeight=ArjMapper.ui.wildConsole:get_height()
  wildZoom=ArjMapper.config.wildZoom
  expandAlias("ui set compactHeader on")
 end,verify=function()
  local text=T.lines(ArjMapper.ui.wildConsole.name)
  T.check(ArjMapper.ui.wildConsole:get_height()==T.fullMapHeight and #(text:match("^\n*") or "")==fullPadding,"quiet wilderness retains viewport and padding")
  T.check(text:find("@",1,true) and ArjMapper.state.lastDisplayMode=="wilderness","header retains wilderness content and display mode")
  T.check(ArjMapper.config.wildZoom==wildZoom,"header retains wilderness zoom")
 end},
 {name="wilderness-full",run=function()
  expandAlias("ui set compactHeader off")
 end,verify=function()
  local text=T.lines(ArjMapper.ui.wildConsole.name)
  T.check(#(text:match("^\n*") or "")==fullPadding,"full wilderness restores padding")
 end},
 {name="stationary-wilderness-normal-maximize",wait=.5,run=function()
  ArjUI:panelAction("map","restore")
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  T.check(ArjMapper.ui.wildConsole:get_height()>T.fullMapHeight+100,"stationary maximized wilderness grows")
  local text=T.lines(ArjMapper.ui.wildConsole.name)
  T.check(#(text:match("^\n*") or "")>fullPadding and text:find("@",1,true),"stationary maximized wilderness redraws cached padding and marker")
  T.check(true,"wilderness maximize retains saved normal state")
  T.check(ArjMapper.ui.zoneContainer.hidden,"maximized wilderness keeps zone hidden")
 end},
 {name="stationary-wilderness-normal-restore",run=function()
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  ArjUI:panelAction("map","restore")
 end},
 {name="stationary-wilderness-minimize-maximize",wait=.5,run=function()
  ArjUI:panelAction("map","restore")
  ArjUI:panelAction("map","minimize")
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  T.check(ArjMapper.ui.wildConsole:get_height()>T.fullMapHeight+100,"stationary maximized wilderness grows")
  local text=T.lines(ArjMapper.ui.wildConsole.name)
  T.check(#(text:match("^\n*") or "")>fullPadding and text:find("@",1,true),"stationary maximized wilderness redraws cached padding and marker")
  T.check(ArjUI.panels.map.state.minimized,"wilderness maximize retains saved normal state")
  T.check(ArjMapper.ui.zoneContainer.hidden,"maximized wilderness keeps zone hidden")
 end},
 {name="stationary-wilderness-minimize-restore",run=function()
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  T.check(ArjUI.panels.map.state.minimized,"normal map minimize state survives maximize")
  ArjUI:panelAction("map","restore")
 end},
 {name="stationary-wilderness-hide-maximize",wait=.5,run=function()
  ArjUI:panelAction("map","restore")
  ArjUI:panelAction("map","hide")
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  T.check(ArjMapper.ui.wildConsole:get_height()>T.fullMapHeight+100,"stationary maximized wilderness grows")
  local text=T.lines(ArjMapper.ui.wildConsole.name)
  T.check(#(text:match("^\n*") or "")>fullPadding and text:find("@",1,true),"stationary maximized wilderness redraws cached padding and marker")
  T.check(ArjUI.panels.map.state.hidden,"wilderness maximize retains saved normal state")
  T.check(ArjMapper.ui.zoneContainer.hidden,"maximized wilderness keeps zone hidden")
 end},
 {name="stationary-wilderness-hide-restore",run=function()
  ArjUI:panelAction("map","maximize")
 end,verify=function()
  T.check(ArjUI.panels.map.state.hidden,"normal map hide state survives maximize")
  ArjUI:panelAction("map","restore")
 end},
 {name="paused-wilderness-compact",run=function()
  expandAlias("mapper off")
  pausedText=T.lines(ArjMapper.ui.wildConsole.name)
  T.emit("Room.Map",{map="&+RIGNORED-WHILE-PAUSED"})
  T.check(gmcp.Room.Map.map:find("IGNORED-WHILE-PAUSED",1,true),"Mudlet replaces GMCP even while mapper is paused")
  T.check(T.lines(ArjMapper.ui.wildConsole.name)==pausedText,"paused mapper ignores new payload")
  expandAlias("ui set compactHeader on")
  raiseEvent("sysWindowResizeEvent")
  expandAlias("ui off")
  expandAlias("ui on")
 end,verify=function()
  T.check(T.lines(ArjMapper.ui.wildConsole.name)==pausedText,"compact/resize/show do not bypass mapper pause")
 end},
 {name="paused-wilderness-full",run=function()
  expandAlias("ui set compactHeader off")
  raiseEvent("sysWindowResizeEvent")
 end,verify=function()
  T.check(T.lines(ArjMapper.ui.wildConsole.name)==pausedText,"restoring full header respects mapper pause")
 end},
 {name="resumed-wilderness",run=function()
  expandAlias("mapper on")
  T.emit("Room.Map",{map="&+W@ RESUMED-WILDERNESS"})
  expandAlias("ui set compactHeader on")
  expandAlias("ui set compactHeader off")
 end,verify=function()
  T.check(T.lines(ArjMapper.ui.wildConsole.name):find("RESUMED-WILDERNESS",1,true),"resumed mapper accepts data and redraws with header")
 end},
 {name="covered-zone-event",wait=.5,run=function()
  if not ArjUI.panels then return end
  room(9001)
  expandAlias("ui panel output maximize")
  T.emit("Room.Info",{num=90011,zone=9001,name="Covered update",exits={}})
 end,verify=function()
  if not ArjUI.panels then return end
  T.check(ArjMapper.state.currentRoom==90011,"covered map still accepts room updates")
  for _,label in pairs(ArjMapper.ui.roomLabels) do T.check(label.hidden or label.auto_hidden,"covered map label stays hidden") end
  T.check(ArjUI.panels.map.frame.hidden,"maximized output covers map frame")
 end},
 {name="reveal-updated-zone",wait=.5,run=function()
  if ArjUI.panels then expandAlias("ui panel output restore") end
 end,verify=function()
  if not ArjUI.panels then return end
  T.check(not ArjUI.panels.map.frame.hidden,"map frame restored")
  T.check(ArjMapper.state.currentRoom==90011 and not ArjMapper.ui.roomLabels.room_90011.hidden,"revealed map shows latest accepted room")
 end},
 {name="covered-deferred-map",wait=.5,run=function()
  room(9001)
  ArjUI:resetLayout()
  ArjUI:openPrivateChat("Mapprobe")
  expandAlias("ui panel output maximize")
  T.emit("Room.Info",{num=90011,zone=9001,name="Deferred covered update",exits={}})
 end,verify=function()
  T.check(ArjMapper.state.currentRoom==90011,"deferred covered map keeps accepted room")
  T.check(ArjUI.panels.map.frame.hidden,"pending viewport refresh keeps map covered")
  for _,label in pairs(ArjMapper.ui.roomLabels) do T.check(label.hidden or label.auto_hidden,"deferred map labels remain covered") end
  T.check(ArjMapper.ui.zoomIn.hidden or ArjMapper.ui.zoomIn.auto_hidden,"deferred zoom control remains covered")
 end},
 {name="malformed",wait=.6,run=function() expandAlias("ui panel output restore"); room(9003) end,verify=function()
  T.check(ArjMapper.state.zoneData[9003]==nil and ArjMapper.requests[9003]==nil,"malformed response rejected and request cleaned")
  T.check(ArjMapper.state.lastWildernessMap==nil,"retiring wilderness clears accepted payload")
  T.check(ArjMapper.state.lastDisplayMode=="zone" and not next(ArjMapper.ui.roomLabels),"failed zone does not retain prior wilderness or room labels")
 end},
 {name="http-error",wait=.6,run=function() room(9004) end,verify=function()
  T.check(ArjMapper.state.zoneData[9004]==nil and ArjMapper.requests[9004]==nil,"HTTP failure cleaned")
 end},
 {name="invalid-schema",wait=.6,run=function() room(9005) end,verify=function()
  T.check(ArjMapper.state.zoneData[9005]==nil and ArjMapper.requests[9005]==nil,"invalid map schema rejected")
 end},
 {name="invalid-edge",wait=.6,run=function() room(9007) end,verify=function()
  T.check(ArjMapper.state.zoneData[9007]==nil and ArjMapper.requests[9007]==nil,"invalid nested map field rejected")
 end},
 {name="timeout",wait=15.5,run=function() room(9006) end,verify=function()
  T.check(ArjMapper.requests[9006]==nil and ArjMapper.state.zoneData[9006]==nil,"map timeout cleans handlers and request")
 end},
 {name="recovered",wait=.6,run=function()
  expandAlias("mapper reload")
  room(9001)
 end,verify=function() T.check(ArjMapper.state.lastDisplayMode=="zone","recovery after reload") end}
})
