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
  wildZoom=ArjMapper.config.wildZoom
  expandAlias("ui set compactHeader on")
 end,verify=function()
  local text=T.lines(ArjMapper.ui.wildConsole.name)
  T.check(#(text:match("^\n*") or "")>fullPadding,"compact wilderness recalculates vertical padding")
  T.check(text:find("@",1,true) and ArjMapper.state.lastDisplayMode=="wilderness","header retains wilderness content and display mode")
  T.check(ArjMapper.config.wildZoom==wildZoom,"header retains wilderness zoom")
 end},
 {name="wilderness-full",run=function()
  expandAlias("ui set compactHeader off")
 end,verify=function()
  local text=T.lines(ArjMapper.ui.wildConsole.name)
  T.check(#(text:match("^\n*") or "")==fullPadding,"full wilderness restores padding")
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
 {name="malformed",wait=.6,run=function() room(9003) end,verify=function()
  T.check(ArjMapper.state.zoneData[9003]==nil and ArjMapper.requests[9003]==nil,"malformed response rejected and request cleaned")
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
