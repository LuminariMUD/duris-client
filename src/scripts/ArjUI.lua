-- ArjUI Core v1.2 (Mudlet 4.19.1)
-- GMCP-based UI for Duris MUD
-- Dark Fantasy Aesthetic

ArjUI = ArjUI or {}
ArjUI.VERSION = "1.3.0"
ArjUI.eventHandlers = ArjUI.eventHandlers or {}
ArjUI.playerName = ArjUI.playerName or nil
ArjUI.captureTriggers = ArjUI.captureTriggers or {}
ArjUI.capturing = nil
ArjUI.captureBuffer = {}
ArjUI.customCommands = ArjUI.customCommands or {
  players = {},    -- { {text="Label", cmd="command"}, ... } - target auto-appended
  mobs = {},
  objects = {},
  inventory = {},
  equipment = {}
}
-- Private messaging system (session-only, not persisted)
ArjUI.privateChats = {}  -- { [playerName] = { window, history, unread } }
ArjUI.tellContacts = {}  -- List of players we've had tells with

-- ============================================================
-- CLEANUP
-- ============================================================

function ArjUI:kill()
  if self.panelGesture then self:finishPanelGesture(self.panelGesture) end
  if self.panels then self:saveLayout() end
  for _,panel in pairs(self.panels or {}) do self:disposeWidget(panel.frame) end
  self.panels=nil; self.maximizedPanel=nil
  if gmod and gmod.disableModule then
    for _, module in ipairs(self.gmcpModules or {}) do gmod.disableModule("ArjUI", module) end
  end
  for id in pairs(self.timers or {}) do killTimer(id) end
  self.timers = {}
  for _, id in ipairs(self.runtimeTriggers or {}) do killTrigger(id) end
  self.runtimeTriggers = {}
  for _, id in ipairs(self.captureTriggerIds or {}) do killTrigger(id) end
  self.captureTriggerIds = {}
  for _, key in ipairs({"uiOnAlias", "uiOffAlias", "debugAlias"}) do
    if self[key] then killAlias(self[key]); self[key] = nil end
  end
  for _, id in ipairs(self.portAliases or {}) do killAlias(id) end
  self.portAliases = {}
  for _, handler in ipairs(self.eventHandlers) do
    killAnonymousEventHandler(handler)
  end
  self.eventHandlers = {}
  -- Kill capture triggers
  for _, tid in pairs(self.captureTriggers or {}) do
    pcall(function() killTrigger(tid) end)
  end
  self.captureTriggers = {}
  self.capturing = nil
  self.captureBuffer = {}
  if self.teardownPorted then self:teardownPorted() end
  -- Kill routeall trigger
  if self.routeAllTriggerId then
    pcall(function() killTrigger(self.routeAllTriggerId) end)
    self.routeAllTriggerId = nil
  end
  -- Also kill by name in case it's a permanent trigger
  if exists("ArjUI_RouteAll", "trigger") > 0 then
    pcall(function() killTrigger("ArjUI_RouteAll") end)
  end
  -- Clean up popup if open
  if self.addCmdPopup then self:disposeWidget(self.addCmdPopup); self.addCmdPopup = nil end
  if self.currentMenu then self:disposeWidget(self.currentMenu); self.currentMenu = nil end
  if self.bg then
    self:disposeWidget(self.bg)
    self.bg = nil
  end
  if self.main then
    self:disposeWidget(self.main)
    self.main = nil
  end
  self.uiRoot, self.console = nil, nil
  -- Old Geyser retains hidden primitives. Release Lua references as well as
  -- callback/registry ownership so a removed frame cannot remain active.
  for key,value in pairs(self) do
    if type(value)=="table" and type(value.name)=="string" and value.name:match("^ArjUI_") then self[key]=nil end
  end
  self.tabPanels,self.tabButtons,self.chatPanels,self.chatTabs=nil,nil,nil,nil
  self.privateChats, self.tellContacts = {}, {}
  self.exitButtonsStatic, self.groupWidgets = nil, {}
  self.playerName, self.damage = nil, nil
  -- Restore default borders so main console is visible again
  setBorderTop(0)
  setBorderBottom(0)
  setBorderLeft(0)
  setBorderRight(0)
  -- Mudlet's main command line remains available while the UI is hidden.
end

function ArjUI:disposeWidget(widget)
  -- Adjustable menus live outside the frame's child tree in older Mudlet.
  -- Remove only this instance's menu labels and registry entries.
  if widget.expiryTimer then killTimer(widget.expiryTimer); self.timers[widget.expiryTimer]=nil; widget.expiryTimer=nil end
  if widget.adjLabel then
    local function disposeMenu(menu)
      if not menu then return end
      for _,label in pairs(menu.MenuLabels or {}) do
        disposeMenu(label)
        self:disposeWidget(label)
      end
      menu.MenuLabels={}
    end
    disposeMenu(widget.rCLabel)
    if Adjustable.Container.all[widget.name]==widget then
      Adjustable.Container.all[widget.name]=nil
      for i=#Adjustable.Container.all_windows,1,-1 do
        if Adjustable.Container.all_windows[i]==widget.name then table.remove(Adjustable.Container.all_windows,i) end
      end
    end
  end
  -- Geyser delete() is available on newer Mudlet releases. Older releases
  -- retain hidden primitives; stable names allow them to be reused on import.
  if widget.delete then widget:delete()
  else
    widget:hide()
    for _,child in pairs(widget.windowList or {}) do self:disposeWidget(child) end
    for _,method in ipairs({"setClickCallback","setReleaseCallback","setMoveCallback","setOnEnter","setOnLeave"}) do
      if widget[method] then widget[method](widget,function() end) end
    end
    if widget.setAction then widget:setAction(function() end) end
    if widget.container then widget.container:remove(widget) end
  end
end

function ArjUI:after(delay, callback)
  self.timers = self.timers or {}
  local id
  id = tempTimer(delay, function()
    self.timers[id] = nil
    callback()
  end)
  self.timers[id] = true
  return id
end

function ArjUI:addRuntimeTrigger(pattern, callback)
  local id = tempRegexTrigger(pattern, callback)
  self.runtimeTriggers = self.runtimeTriggers or {}
  table.insert(self.runtimeTriggers, id)
  return id
end

function ArjUI:setVisible(visible)
  if not self.main then return end
  self.hidden = not visible
  if visible then
    self.bg:show()
    self.main:show()
    self:layout()
    self:applyPanelLayout()
  else
    self.main:hide()
    self.bg:hide()
    if self.currentMenu then self.currentMenu:hide() end
    for _, chat in pairs(self.privateChats) do
      if chat.window then chat.window:hide() end
      chat.visible = false
    end
    if self.panelGesture then self:finishPanelGesture(self.panelGesture) end
    setBorderTop(0)
    setBorderBottom(0)
    setBorderLeft(0)
    setBorderRight(0)
  end
end

function ArjUI:applyBackground()
  -- Package installs to profile folder: getMudletHomeDir()/profiles/[profile]/[package]/
  -- Try multiple possible paths
  local possiblePaths = {
    getMudletHomeDir() .. "/Arjinius Client V1.0/duris-v1.png",  -- Old location
    getMudletHomeDir() .. "/Arjinius Client/duris-v1.png",       -- Without version
  }
  
  -- Also try profile-relative path if available
  if getProfileName then
    local profile = getProfileName()
    if profile then
      table.insert(possiblePaths, 1, getMudletHomeDir() .. "/profiles/" .. profile .. "/Arjinius Client V1.0/duris-v1.png")
      table.insert(possiblePaths, 2, getMudletHomeDir() .. "/profiles/" .. profile .. "/Arjinius Client/duris-v1.png")
    end
  end
  
  local bgPath = nil
  for _, path in ipairs(possiblePaths) do
    -- Forward slashes work on Windows as well as Unix. Converting them to
    -- backslashes before io.open makes a valid Unix asset path unreadable.
    local f = io.open(path, "rb")
    if f then
      f:close()
      bgPath = path:gsub("\\", "/")  -- Qt needs forward slashes
      break
    end
  end
  
  if self.bg then
    if bgPath and not self.settings.compactHeader then
      self.bg:setStyleSheet(string.format([[
        border-image: url("%s") 0 0 0 0 stretch stretch;
      ]], bgPath))
    else
      -- Compact mode omits the illustrated header; also used if artwork is missing.
      self.bg:setStyleSheet([[
        background-color: qlineargradient(x1:0,y1:0,x2:1,y2:1,stop:0 #0a0908,stop:0.5 #12100c,stop:1 #0a0908);
      ]])
    end
  end
end

-- ============================================================
-- UTILITIES
-- ============================================================

local function styleSafe(widget, css)
  if widget and widget.setStyleSheet then
    widget:setStyleSheet(css)
  end
end

local function labelSet(labelObj, text)
  if not labelObj then return end
  if labelObj.clear then labelObj:clear() end
  if labelObj.echo then labelObj:echo(text or "") end
end

local function makePanel(parent, name, x, y, w, h, css)
  local panel = Geyser.Label:new({
    name = name, x = x, y = y, width = w, height = h,
  }, parent)
  styleSafe(panel, css)
  labelSet(panel, "")
  return panel
end

local function makeConsole(parent, name, x, y, w, h, fontSize, bgColor)
  local console = Geyser.MiniConsole:new({
    name = name, x = x, y = y, width = w, height = h, fontSize = fontSize or 10, autoWrap = true
  }, parent)
  -- Default to the warm panel color; the main MUD feed supplies black.
  bgColor = bgColor or {12, 11, 9}
  console:setBgColor(unpack(bgColor))
  console:setFgColor(200, 200, 200)
  setBackgroundColor(console.name, bgColor[1], bgColor[2], bgColor[3], 255)
  return console
end

-- ============================================================
-- PLAYER LAYOUT (normal rectangles are fractions of uiRoot)
-- ============================================================

ArjUI.panelDefinitions = {
  {id="map", title="MAP", home={0,0,.165,.32}, minimum={190,170}},
  {id="mobs", title="MOBS", home={0,.33,.165,.215}, minimum={150,95}},
  {id="items", title="ITEMS", home={0,.555,.165,.235}, minimum={150,95}},
  {id="output", title="GAME OUTPUT", home={.167,0,.57,.79}, minimum={340,180}, essential=true},
  {id="character", title="CHARACTER", home={.739,0,.26,.45}, minimum={285,160}},
  {id="players", title="PLAYERS", home={.739,.46,.26,.26}, minimum={190,95}},
  {id="chat", title="CHAT", home={.739,.73,.26,.27}, minimum={285,110}},
  {id="vitals", title="VITALS", home={0,.80,.165,.195}, minimum={150,110}},
  {id="tank", title="TANK / BUFFS", home={.167,.80,.283,.195}, minimum={220,110}},
  {id="target", title="TARGET / DEBUFFS", home={.455,.80,.282,.195}, minimum={220,110}},
}

local function copyRect(rect) return {rect[1],rect[2],rect[3],rect[4]} end
local function panelDefault(def)
  return {rect=copyRect(def.home), mode=def.private and "floating" or "docked",
          locked=not def.private, hidden=false, minimized=false}
end
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function validRect(rect)
  if type(rect)~="table" then return false end
  for i=1,4 do if not finite(rect[i]) then return false end end
  return rect[1]>=0 and rect[2]>=0 and rect[1]<1 and rect[2]<1
    and rect[3]>0 and rect[3]<=1 and rect[4]>0 and rect[4]<=1
end

function ArjUI:loadLayout()
  for _,def in ipairs(self.panelDefinitions) do self.panels[def.id].state=panelDefault(def) end
  local path=getMudletHomeDir().."/arjui_layout.json"
  local file=io.open(path,"r") or io.open(path..".bak","r")
  if not file then return end
  local text=file:read("*a"); file:close()
  local ok,data=pcall(yajl.to_value,text)
  if not ok or type(data)~="table" or data.version~=1 or type(data.panels)~="table" then
    self:note("<indian_red>Saved panel layout is invalid or unsupported; using defaults.")
    return
  end
  local invalid=false
  for _,def in ipairs(self.panelDefinitions) do
    local saved=data.panels[def.id]
    if saved~=nil then
      if type(saved)=="table" and validRect(saved.rect)
        and (saved.mode=="docked" or saved.mode=="floating")
        and type(saved.locked)=="boolean" and type(saved.hidden)=="boolean"
        and type(saved.minimized)=="boolean" then
        self.panels[def.id].state={rect=copyRect(saved.rect),mode=saved.mode,
          locked=saved.locked,hidden=not def.essential and saved.hidden,
          minimized=not def.essential and saved.minimized}
      else invalid=true end
    end
  end
  if invalid then self:note("<indian_red>Invalid saved panel entries replaced with defaults.") end
end

function ArjUI:saveLayout()
  if not self.panels then return end
  local data={version=1,panels={}}
  for _,def in ipairs(self.panelDefinitions) do data.panels[def.id]=self.panels[def.id].state end
  local path=getMudletHomeDir().."/arjui_layout.json"
  local ok,err=pcall(function()
    local file=assert(io.open(path..".tmp","w"))
    local written,why=file:write(yajl.to_string(data))
    local closed,closeError=file:close()
    assert(written,why); assert(closed,closeError)
    local installed,why=os.rename(path..".tmp",path)
    if not installed then
      -- Windows rename cannot replace an existing destination. Retain the old
      -- file until installation succeeds, and recover it on failure/restart.
      local backup=path..".bak"
      os.remove(backup)
      assert(os.rename(path,backup),why)
      installed,why=os.rename(path..".tmp",path)
      if not installed then
        local restored,restoreError=os.rename(backup,path)
        error(tostring(why)..(restored and "" or "; previous layout retained at "..backup..": "..tostring(restoreError)))
      end
      os.remove(backup)
    end
  end)
  if not ok then self:note("<indian_red>Cannot save panel layout: "..tostring(err)) end
end

function ArjUI:panelBounds(panel)
  local w,h=math.max(1,self.uiRoot:get_width()),math.max(1,self.uiRoot:get_height())
  local rect=panel.state.mode=="docked" and panel.def.home or panel.state.rect
  if self.maximizedPanel==panel.def.id then return 0,0,w,h end
  local pw=math.min(w,math.max(panel.def.minimum[1],rect[3]*w))
  local ph=math.min(h,math.max(panel.def.minimum[2],rect[4]*h))
  if panel.state.minimized then ph=math.min(h,22) end
  return math.max(0,math.min(rect[1]*w,w-pw)),math.max(0,math.min(rect[2]*h,h-ph)),pw,ph
end

-- Whether the panel body can actually be read, independent of saved normal state.
function ArjUI:panelIsVisible(id)
  if self.hidden or (self.maximizedPanel and self.maximizedPanel~=id) then return false end
  local panel=self.panels and self.panels[id]
  return not panel or self.maximizedPanel==id or (not panel.state.hidden and not panel.state.minimized)
end

function ArjUI:reconcilePanelViews()
  for name,widget in pairs(self.tabPanels or {}) do
    if name==self.activeTab then widget:show() else widget:hide() end
  end
  for name,widget in pairs(self.chatPanels or {}) do
    if name==self.activeChatTab then widget:show() else widget:hide() end
  end
  -- Parent show() recursively exposes inactive views. Hide them again without
  -- switching tabs (which can send a server command or clear scrollback).
  if self.mapper then self.mapper:hide() end
  if ArjMapper and ArjMapper.ui then
    local ui=ArjMapper.ui
    if ui.hoverLabel then ui.hoverLabel:hide() end
    if ArjMapper.state.lastDisplayMode=="wilderness" then
      if ui.zoneContainer then ui.zoneContainer:hide() end
    elseif ui.wildConsole then ui.wildConsole:hide() end
  end
  for _,panel in pairs(self.panels or {}) do
    if self.hidden or (self.maximizedPanel and self.maximizedPanel~=panel.def.id) or (panel.state.hidden and self.maximizedPanel~=panel.def.id) then panel.frame:hide()
    elseif panel.state.minimized and self.maximizedPanel~=panel.def.id then panel.frame.Inside:hide() end
  end
  if self.creditTooltip then self.creditTooltip:hide() end
end

function ArjUI:applyPanel(panel)
  local frame,state=panel.frame,panel.state
  if panel.def.private then
    local chat=self.privateChats[panel.def.id:sub(6)]
    if chat then
      local visible=self:panelIsVisible(panel.def.id)
      if visible and not chat.visible then
        chat.unread=0
        self:renderTellContacts()
      end
      chat.visible=visible
    end
  end
  local x,y,w,h=self:panelBounds(panel)
  frame:move(x,y); frame:resize(w,h)
  frame.locked=state.locked or self.maximizedPanel==panel.def.id
  local maximized=self.maximizedPanel==panel.def.id
  frame.minimized=state.minimized and not maximized
  frame.Inside:move(5,22)
  frame.Inside:resize("100%-10px","100%-27px")
  if self.hidden or (self.maximizedPanel and not maximized) or (state.hidden and not maximized) then frame:hide()
  else
    frame:show()
    if state.minimized and not maximized then frame.Inside:hide() else frame.Inside:show() end
  end
  if panel.def.essential then frame.exitLabel:hide(); frame.minimizeLabel:hide() end
end

function ArjUI:applyPanelLayout()
  for _,panel in pairs(self.panels or {}) do self:applyPanel(panel) end
  self:reconcilePanelViews()
  if self.maximizedPanel and not self.hidden then self.panels[self.maximizedPanel].frame:raiseAll() end
  if self.panelsButton then self.panelsButton:raise(); self.resetLayoutButton:raise() end
end

function ArjUI:finishPanelGesture(panel)
  if self.panelGesture~=panel then return end
  panel.frame:onRelease(panel.frame.adjLabel,{button="LeftButton"})
  self.panelGesture=nil
end

function ArjUI:capturePanelGesture(panel)
  local frame,state=panel.frame,panel.state
  local w,h=math.max(1,self.uiRoot:get_width()),math.max(1,self.uiRoot:get_height())
  local x=frame:get_x()-self.uiRoot:get_x()
  local y=frame:get_y()-self.uiRoot:get_y()
  state.mode="floating"
  state.rect={math.max(0,x/w),math.max(0,y/h),math.min(1,frame:get_width()/w),
    state.minimized and state.rect[4] or math.min(1,frame:get_height()/h)}
  self:applyPanel(panel)
  self:reconcilePanelViews()
end

function ArjUI:createPanel(def)
  local frame=Adjustable.Container:new({name="ArjUI_Panel_"..def.id:gsub(":","_"),
    x=0,y=0,width=200,height=180,autoSave=false,autoLoad=false,dragOut=false,
    padding=5,buttonsize=15,titleText=def.title,titleTxtColor="tan",titleFormat="l8",
    adjLabelstyle="background-color: #0f0e0c; border: 2px solid #5a4b37; color: #d4a855;",
    buttonstyle="background-color: #1a1610; color: #d4a855; border: none;"},self.uiRoot)
  local panel={def=def,frame=frame,state=panelDefault(def)}
  self.panels[def.id]=panel
  frame.adjLabel:setClickCallback(function(event)
    if event.button=="RightButton" then self:showPanelMenu(def.id); return end
    frame:raiseAll()
    if not frame.locked and event.button=="LeftButton" then
      -- Prime hit testing on click too: no dependence on a preceding hover.
      frame:onMove(frame.adjLabel,event)
      frame:onClick(frame.adjLabel,event)
      self.panelGesture=panel
    end
  end)
  frame.adjLabel:setMoveCallback(function(event)
    frame:onMove(frame.adjLabel,event)
    if self.panelGesture==panel then self:capturePanelGesture(panel) end
  end)
  frame.adjLabel:setReleaseCallback(function(event)
    if event.button=="LeftButton" and self.panelGesture==panel then
      self:finishPanelGesture(panel)
      self:saveLayout()
      self:refreshPanelContent(def.id)
    end
  end)
  frame.exitLabel:setClickCallback(function() self:panelAction(def.id,"hide") end)
  frame.minimizeLabel:setClickCallback(function()
    self:panelAction(def.id,panel.state.minimized and "restore" or "minimize")
  end)
  return frame.Inside
end

function ArjUI:refreshPanelContent(id)
  if ArjMapper and ArjMapper.state.enabled and self:panelIsVisible("map") then
    ArjMapper:refreshViewport()
  end
  if (not id or id=="character") and self.activeTab=="ship" then self:renderShipIfActive() end
end

function ArjUI:panelAction(id,action)
  local panel=self.panels and self.panels[id]
  local contact=type(id)=="string" and id:match("^tell:(.+)$")
  if not panel and contact and self.privateChats[contact] then
    self:openPrivateChat(contact)
    panel=self.panels[id]
  end
  if not panel then self:note("<indian_red>Unknown panel: "..tostring(id)); return false end
  if (action=="hide" or action=="minimize") and panel.def.essential then
    self:note("<tan>Game output stays visible. Use maximize, float or dock."); return false
  end
  if action=="dock" and panel.def.private then self:note("<tan>Private chats float inside the dashboard."); return false end
  if self.panelGesture then self:finishPanelGesture(self.panelGesture) end
  local state=panel.state
  if action=="maximize" then
    if self.maximizedPanel==id then self.maximizedPanel=nil else self.maximizedPanel=id end
  elseif action=="restore" then
    if self.maximizedPanel==id then self.maximizedPanel=nil
    else state.hidden=false; state.minimized=false end
  elseif action=="show" then state.hidden=false; state.minimized=false
  elseif action=="hide" then state.hidden=true
  elseif action=="minimize" then state.minimized=true
  elseif action=="dock" then
    state.mode="docked"; state.rect=copyRect(panel.def.home); state.hidden=false; state.minimized=false
  elseif action=="float" then state.mode="floating"
  elseif action=="lock" then state.locked=true
  elseif action=="unlock" then state.locked=false
  else return false end
  if action~="maximize" and self.maximizedPanel==id and action~="lock" and action~="unlock" then self.maximizedPanel=nil end
  self:applyPanelLayout()
  if self:panelIsVisible(id) then panel.frame:raiseAll() end
  self:refreshPanelContent(id)
  if panel.def.private then self:renderTellContacts() end
  self:saveLayout()
  return true
end

function ArjUI:showPanelMenu(id)
  local panel=self.panels[id]
  local items={}
  for _,action in ipairs({"show","hide","minimize","restore","maximize","dock","float","lock","unlock"}) do
    if not ((panel.def.essential and (action=="hide" or action=="minimize")) or (panel.def.private and action=="dock")) then
      table.insert(items,{text=action:sub(1,1):upper()..action:sub(2),callback=function() self:panelAction(id,action) end})
    end
  end
  self:showContextMenu(items)
end

function ArjUI:showPanelsMenu()
  local items={}
  for _,def in ipairs(self.panelDefinitions) do
    table.insert(items,{text=def.title,callback=function()
      self:panelAction(def.id,"show"); self:showPanelMenu(def.id)
    end})
  end
  for name,chat in pairs(self.privateChats) do
    table.insert(items,{text="Tell: "..name,callback=function() self:openPrivateChat(name); self:showPanelMenu("tell:"..name) end})
  end
  self:showContextMenu(items)
end

function ArjUI:resetLayout()
  if self.panelGesture then self:finishPanelGesture(self.panelGesture) end
  self.maximizedPanel=nil
  if self.currentMenu then self:disposeWidget(self.currentMenu); self.currentMenu=nil end
  if self.addCmdPopup then self:disposeWidget(self.addCmdPopup); self.addCmdPopup=nil end
  for _,panel in pairs(self.panels) do
    panel.state=panelDefault(panel.def)
    if panel.def.private then panel.state.hidden=true end
  end
  for _,chat in pairs(self.privateChats) do if chat.window then chat.visible=false end end
  self.activeTab="group"; self.activeChatTab="all"
  self:updateTabStyles(); self:updateChatTabStyles()
  self:applyPanelLayout(); self:renderActiveTab(); self:refreshPanelContent()
  self:saveLayout()
end

function ArjUI:setupPanelControls()
  self.panelsButton=makePanel(self.main,"ArjUI_PanelsButton",0,0,76,22,self.styles.header)
  self.panelsButton:echo("Panels")
  self.panelsButton:setClickCallback(function() self:showPanelsMenu() end)
  self.resetLayoutButton=makePanel(self.main,"ArjUI_ResetLayoutButton",0,0,92,22,self.styles.header)
  self.resetLayoutButton:echo("Reset layout")
  self.resetLayoutButton:setClickCallback(function() self:resetLayout() end)
end

function ArjUI:layoutCommand(action)
  if action=="reset" then self:resetLayout()
  elseif action=="lock" or action=="unlock" then
    for _,panel in pairs(self.panels) do panel.state.locked=action=="lock" end
    if self.panelGesture then self:finishPanelGesture(self.panelGesture) end
    self:applyPanelLayout(); self:saveLayout()
  else
    self:note("<tan>ui layout reset|lock|unlock; ui panel <id> show|hide|minimize|restore|maximize|dock|float|lock|unlock")
    for name in pairs(self.privateChats) do self:note("tell:"..name.." (session conversation)") end
    for _,def in ipairs(self.panelDefinitions) do
      local s=self.panels[def.id].state
      self:note(def.id..": "..s.mode..(s.locked and " locked" or " unlocked")..(s.hidden and " hidden" or "")..(s.minimized and " minimized" or ""))
    end
  end
end

local function toNum(x) return tonumber(x) end

local function upper3(pos)
  if not pos or type(pos) ~= "string" then return "" end
  return string.upper(pos:sub(1,3))
end

local function pick(tbl, ...)
  if not tbl then return nil end
  for i = 1, select("#", ...) do
    local k = select(i, ...)
    local v = tbl[k]
    if v ~= nil then return v end
  end
  return nil
end

local function stripColors(text)
  if not text then return "" end
  text = text:gsub("&%+.", "")
  text = text:gsub("&=..", "")
  text = text:gsub("&[nN%]]", "")
  text = text:gsub("\27%][^\7]*\7", "")
  text = text:gsub("\27%][^\27]*\27\\", "")
  text = text:gsub("\27%[%d*;?%d*m", "")
  return text
end

-- Duris color code to decho RGB format (for MiniConsoles)
local durisColors = {
  r = "<128,0,0>",       R = "<255,0,0>",
  g = "<0,128,0>",       G = "<0,255,0>",
  b = "<0,0,170>",       B = "<85,85,255>",
  c = "<0,128,128>",     C = "<0,255,255>",
  m = "<128,0,128>",     M = "<255,0,255>",
  y = "<128,128,0>",     Y = "<255,255,0>",
  w = "<192,192,192>",   W = "<255,255,255>",
  L = "<96,96,96>",      l = "<96,96,96>",
}

-- Convert Duris color codes to Mudlet decho format (RGB)
local function durisToDecho(text)
  if not text then return "" end
  local result = {}
  local i, len = 1, #text
  local currentColor = nil
  local buffer = ""
  
  local function flushBuffer()
    if buffer ~= "" then
      if currentColor then
        table.insert(result, currentColor .. buffer)
      else
        table.insert(result, buffer)
      end
      buffer = ""
    end
  end
  
  while i <= len do
    local ch = text:sub(i, i)
    if ch == "&" and i < len then
      local nxt = text:sub(i+1, i+1)
      if nxt == "+" and i + 2 <= len then
        flushBuffer()
        local colorCode = text:sub(i+2, i+2)
        currentColor = durisColors[colorCode]
        i = i + 3
      elseif nxt == "n" or nxt == "N" or nxt == "]" then
        flushBuffer()
        currentColor = nil
        i = i + 2
      elseif nxt == "=" and i + 3 <= len then
        flushBuffer()
        local fgCode = text:sub(i+2, i+2)
        currentColor = durisColors[fgCode]
        i = i + 4
      else
        i = i + 1
      end
    else
      buffer = buffer .. ch
      i = i + 1
    end
  end
  
  flushBuffer()
  return table.concat(result)
end




-- ============================================================
-- TARGET NORMALIZATION (FIX: clickable mobs/objs passing tags)
-- ============================================================

local function trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeTargetName(name)
  if not name then return "" end

  -- 1) remove formats we already handle
  local s = stripColors(name)

  -- 2) remove Mudlet-style tags like <red>, <reset>, etc.
  s = s:gsub("<[^>]+>", "")

  -- 2b) sometimes we get partial/broken tag fragments; strip common leftovers
  s = s:gsub("</[%w_]+", "")
       :gsub("<[%w_]+", "")
       :gsub("/[%w_]+>", "")

  -- 3) collapse whitespace
  s = trim(s):gsub("%s+", " ")

  -- 4) optionally strip leading articles (often helps targeting)
  s = s:gsub("^[Aa]n%s+", "")
       :gsub("^[Aa]%s+", "")
       :gsub("^[Tt]he%s+", "")

  return trim(s)
end

local function quoteIfNeeded(s)
  s = trim(s or "")
  if s:find("%s") then
    return "'" .. s .. "'"
  end
  return s
end

local function durisTargetKey(name)
  -- Start from the clean display name
  local s = normalizeTargetName(name)
  s = trim(s)
  if s == "" then return "" end

  -- If it has an "of ..." tail, drop it (corpse of a raccoon -> corpse)
  -- This avoids the classic "that isn't a container" / parse confusion.
  if s:find("%s+[Oo][Ff]%s+") then
    local head = s:match("^(.-)%s+[Oo][Ff]%s+.+$")
    if head and head ~= "" then s = trim(head) end
  end

  -- If it's still multi-word, prefer the last word as a stable keyword
  -- (black wolf -> wolf) which Duris will generally match.
  if s:find("%s") then
    s = s:match("(%S+)$") or s
  end

  return trim(s)
end

-- ============================================================
-- UI INITIALIZATION
-- ============================================================

function ArjUI:resetCharacterState()
  self.state = {
    hp = 1, hpmax = 1, mana = 1, manamax = 1, move = 1, movemax = 1,
    tnl = 0, tnlBaseline = nil, position = "standing",
    area = "Unknown", room = "Unknown", roomId = nil, zoneId = nil,
    exits = {}, exitsRaw = {}, npcs = {}, items = {}, players = {},
    target = nil, targetHpPct = 100, targetCond = nil, targetPos = nil,
    tank = nil, tankHp = nil, tankMaxHp = nil, tankCond = nil, tankPos = nil, iAmTank = false,
    group = {}, groupSize = 0, groupMax = 0, affects = {},
    doors = {},
    coins = { platinum = 0, gold = 0, silver = 0, copper = 0 },
    usesMana = true, fighting = nil,
    charLevel = nil, charClass = nil, charRace = nil, charGuild = nil, charTitle = nil,
    quest = nil,
    timeOfDay = "day",  -- day, night, dawn, dusk
  }

  self.initialDataRequested = false

  self.playerName = nil
  self.timeQuerySilent = false
  self.capturing, self.captureBuffer = nil, {}
  self:resetShip()
end

function ArjUI:endSession()
  for id in pairs(self.timers or {}) do killTimer(id) end
  self.timers = {}
  if self.scanTimer then killTimer(self.scanTimer); self.scanTimer = nil end
  self.scanCounts = {}
  self:resetCharacterState()
  self.damage = {fight=0, fightHits=0, session=0, sessionHits=0, sessionStart=os.time(), lastHit=0}
  if ArjAuto and ArjAuto.resetSession then ArjAuto:resetSession() end
  if ArjMapper and ArjMapper.resetSession then ArjMapper:resetSession() end
  self:renderAll()
  self:renderDamage()
  self:renderStats()
  self:renderInventory()
  self:renderEq()
  self:renderWho()
  self:renderShip()
end

-- Advertise every package consumed by the UI and mapper.
ArjUI.gmcpModules = {"Char.Vitals", "Char.Status", "Char.Affects", "Room.Info", "Room.Map",
  "Group.Status", "Comm.Channel", "Combat.Update", "Quest.Status", "Ship.Info", "Ship.Contacts"}

function ArjUI:enableGMCP()
  sendGMCP('Core.Hello {"client":"Mudlet-ArjUI","version":"' .. ArjUI.VERSION .. '"}')
  local modules = {}
  for _, module in ipairs(self.gmcpModules) do modules[#modules+1] = module .. " 1" end
  if gmod and gmod.enableModule then
    for _, module in ipairs(self.gmcpModules) do gmod.enableModule("ArjUI", module) end
  end
  -- gmod retains registrations across sockets; always renew this subscription.
  sendGMCP("Core.Supports.Add " .. yajl.to_string(modules))
end

function ArjUI:headerHeightPct()
  return self.settings.compactHeader and 2.8 or 10.5
end

function ArjUI:init()
  self:kill()
  self.hidden = false
  self:loadSettings()
  
  -- Layout constants as percentages for DPI-independent scaling
  -- Tuned to match the decorative background frame
  local bannerPct = self:headerHeightPct()
  self.frameInsetXPct = 2.5 -- side margins (inside decorative frame)
  self.frameInsetBottomPct = 2.8  -- bottom margin (above bottom frame)

  local w, h = getMainWindowSize()

  -- Create background label at ROOT level (no parent) so it sits behind everything including main console
  self.bg = Geyser.Label:new({
    name = "ArjUI_Background", x = 0, y = 0, width = "100%", height = "100%"
  })
  self.bg:setStyleSheet([[background-color: #000000;]])
  self:applyBackground()

  -- Reserve ALL space with borders so main console has nowhere to render
  -- This pushes the main console out of view
  setBorderTop(h)
  setBorderBottom(0)
  setBorderLeft(0)
  setBorderRight(0)

  -- Mudlet does not permit disableCommandLine("main"). Use its native input
  -- as our single command line, including history, completion and focus.

  -- Main container for our UI, sits on top of background (transparent so bg shows through gaps)
  self.main = Geyser.Container:new({
    name = "ArjUI_Main", x = 0, y = 0, width = "100%", height = "100%"
  })

  -- Use percentage-based positioning for DPI independence
  local rootX = self.frameInsetXPct .. "%"
  local rootY = bannerPct .. "%"
  local rootW = (100 - self.frameInsetXPct * 2) .. "%"
  local rootH = (100 - bannerPct - self.frameInsetBottomPct) .. "%"

  self.uiRoot = Geyser.Container:new({
    name = "ArjUI_Root", x = rootX, y = rootY, width = rootW, height = rootH
  }, self.main)

  local colors = {
    -- Backgrounds: warm-tinted dark (not pure black)
    bgDark = "#0a0908", bgMid = "#0f0e0c", bgLight = "#16140f",
    -- Border hierarchy: primary (muted bronze), secondary (darker), dividers (near-neutral)
    borderPrimary = "#8c6e46",   -- muted bronze for primary panels
    borderSecondary = "#5a4b37", -- darker bronze for secondary panels  
    borderDivider = "#3c3832",   -- near-neutral warm gray for dividers
    borderDark = "#2a2520",      -- darkest for subtle edges
    accent = "#c9a227",          -- warm gold accent (unchanged)
    -- Text colors (unchanged - no font changes)
    textDim = "#8a8a8a", textMid = "#b0b0b0", textBright = "#e6e6e6",
    textGold = "#d4a855", textRed = "#c45050", textGreen = "#50c070", textBlue = "#7090c0",
  }
  self.colors = colors

  self.styles = {
    -- Primary panels (main output, map, input) - stronger bronze border, near-opaque
    panel = string.format("background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 %s,stop:1 %s); border: 2px solid %s; border-top: 2px solid %s; border-radius: 4px;", colors.bgMid, colors.bgDark, colors.borderSecondary, colors.borderPrimary),
    -- Main output panel - solid black to match the MUD text background
    panelPrimary = "background-color: #000000; border: 2px solid #5a4b37; border-top: 2px solid #8c6e46; border-radius: 4px;",
    -- Secondary panels (side info) - softer border, slight transparency (85-90%)
    panelGlass = "background-color: rgba(10, 9, 8, 218); border: 1px solid #5a4b37; border-top: 1px solid #8c6e46; border-radius: 4px;",
    header = string.format("background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 %s,stop:1 %s); border: 1px solid %s; border-bottom: 1px solid %s; color: %s; qproperty-alignment: 'AlignCenter'; font-size: 9px; font-weight: bold;", colors.bgLight, colors.bgMid, colors.borderDivider, colors.borderSecondary, colors.textDim),
    headerCombat = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #1a100c,stop:1 #0f0e0c); border: 1px solid #4a3028; border-bottom: 1px solid #5a3830; color: #c45050; qproperty-alignment: 'AlignCenter'; font-size: 9px; font-weight: bold;",
    headerTarget = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #18140c,stop:1 #0f0e0c); border: 1px solid #4a4028; border-bottom: 1px solid #5a4830; color: #d4a855; qproperty-alignment: 'AlignCenter'; font-size: 9px; font-weight: bold;",
    headerAffects = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #10140c,stop:1 #0f0e0c); border: 1px solid #384a28; border-bottom: 1px solid #405830; color: #50c070; qproperty-alignment: 'AlignCenter'; font-size: 9px; font-weight: bold;",
    areaName = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #0c1012,stop:1 #0a0908); border: 1px solid #3c3832; border-bottom: 1px solid #5a4b37; color: #70b0c0; qproperty-alignment: 'AlignCenter'; font-weight: bold; font-size: 11px;",
    areaNameHover = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #10141a,stop:1 #0c1012); border: 1px solid #5a4b37; border-bottom: 1px solid #8c6e46; color: #90d0e0; qproperty-alignment: 'AlignCenter'; font-weight: bold; font-size: 11px;",
    exits = string.format("background-color: %s; border: 1px solid %s; color: %s; font-size: 10px;", colors.bgMid, colors.borderDivider, colors.textDim),
    pos = string.format("background-color: %s; border: 1px solid %s; color: %s; qproperty-alignment: 'AlignCenter'; font-size: 9px; font-weight: bold;", colors.bgLight, colors.borderDivider, colors.textBlue),
    posAlert = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #1a0c0c,stop:1 #120808); border: 1px solid #8a4040; border-top: 1px solid #a05050; color: #ff6060; qproperty-alignment: 'AlignCenter'; font-size: 9px; font-weight: bold;",
    tankName = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #10140c,stop:1 #0a0908); border: 1px solid #384a28; border-bottom: 1px solid #405830; color: #70d070; qproperty-alignment: 'AlignLeft'; font-weight: bold; font-size: 11px; padding-left: 4px;",
    tankNameMe = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #1a0c0c,stop:0.5 #200f0f,stop:1 #1a0c0c); border: 1px solid #5a3028; border-bottom: 1px solid #6a3830; color: #ff7070; qproperty-alignment: 'AlignLeft'; font-weight: bold; font-size: 11px; padding-left: 4px;",
    targetName = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #16120a,stop:1 #0a0908); border: 1px solid #5a4b37; border-bottom: 1px solid #8c6e46; color: #e0b060; qproperty-alignment: 'AlignLeft'; font-weight: bold; font-size: 11px; padding-left: 4px;",
    targetDead = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #0c0b0a,stop:1 #0a0908); border: 1px solid #3c3832; border-bottom: 1px solid #3c3832; color: #606060; qproperty-alignment: 'AlignLeft'; font-weight: bold; font-size: 11px; padding-left: 4px;",
    roomName = string.format("background-color: %s; border: 1px solid %s; color: %s; qproperty-alignment: 'AlignCenter'; font-size: 12px; font-weight: bold;", colors.bgMid, colors.borderDivider, colors.textBlue),
    separator = "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #0a0908,stop:0.5 #5a4b37,stop:1 #0a0908); border: none; border-radius: 1px;",  -- warm bronze separator with gradient
    inputBar = "background-color: qlineargradient(x1:0,y1:0,x2:0,y2:1,stop:0 #12100c,stop:1 #0a0908); border: 2px solid #5a4b37; border-top: 2px solid #8c6e46; border-radius: 4px; color: #d0d0d8; font-size: 12px; font-family: Consolas; padding: 3px 6px;",
    exitButton = "background-color: transparent; color: #7090c0; font-size: 10px; font-weight: bold;",
    exitButtonHover = "background-color: #1a2a3a; color: #90b0e0; font-size: 10px; font-weight: bold; border-radius: 2px;",
    exitButtonClosed = "background-color: transparent; color: #b08040; font-size: 10px; font-weight: bold; border-bottom: 1px solid #8a5a20;",
    exitButtonLocked = "background-color: transparent; color: #c05050; font-size: 10px; font-weight: bold; border-bottom: 1px solid #8a3030;",
  }

  self.gaugeStyles = {
    -- Gauge borders use warm-tinted versions of their colors
    hpFront = "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #6b1010,stop:0.5 #8b2020,stop:1 #6b1010); border: none; border-radius: 2px;",
    hpBack = "background-color: #0a0908; border: 1px solid #3a2520; border-radius: 3px;",
    mpFront = "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #102060,stop:0.5 #203080,stop:1 #102060); border: none; border-radius: 2px;",
    mpBack = "background-color: #0a0908; border: 1px solid #2a3040; border-radius: 3px;",
    mvFront = "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #105010,stop:0.5 #207020,stop:1 #105010); border: none; border-radius: 2px;",
    mvBack = "background-color: #0a0908; border: 1px solid #2a3a20; border-radius: 3px;",
    xpFront = "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #301050,stop:0.5 #502080,stop:1 #301050); border: none; border-radius: 2px;",
    xpBack = "background-color: #0a0908; border: 1px solid #302540; border-radius: 3px;",
    targetFront = "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #5a4010,stop:0.5 #7a5520,stop:1 #5a4010); border: none; border-radius: 2px;",
    targetBack = "background-color: #0a0908; border: 1px solid #3c3020; border-radius: 3px;",
    deadFront = "background-color: #1a1816; border: none; border-radius: 2px;",
    deadBack = "background-color: #0a0908; border: 1px solid #2a2520; border-radius: 3px;",
    gaugeText = "color: #e6e6e6; font-size: 9px; font-weight: bold;",
  }

  self.panels={}
  local definitions={}
  for _,def in ipairs(self.panelDefinitions) do definitions[def.id]=def end
  local function panel(id) return self:createPanel(definitions[id]) end

  -- SECTION 1: Area + Map (0% - 35%) - Larger map section
  self.mapSection = panel("map")
  styleSafe(self.mapSection, self.styles.panelGlass)
  
  -- Globe/World Map link (top-left, above area label)
  self.globeBtn = Geyser.Label:new({ name = "ArjUI_GlobeBtn", x = "3%", y = 1, width = "12%", height = 18 }, self.mapSection)
  self.globeBtn:setStyleSheet([[
    QLabel { background-color: rgba(10,9,8,200); color: #7be; border: 1px solid #5a4b37; border-radius: 10px; font-size: 11px; }
    QLabel:hover { background-color: rgba(22,20,15,220); color: #9df; border-color: #8c6e46; }
  ]])
  self.globeBtn:echo("<center>🌐</center>")
  self.globeBtn:setClickCallback(function() openUrl("https://duris.sbs/wiki/map") end)
  self.globeBtn:setOnEnter(function() self.globeBtn:setCursor("PointingHand") end)
  self.globeBtn:setOnLeave(function() self.globeBtn:setCursor("Arrow") end)
  
  -- Area label (next to globe)
  self.areaLabel = Geyser.Label:new({ name = "ArjUI_AreaLabel", x = "16%", y = 1, width = "81%", height = 18 }, self.mapSection)
  styleSafe(self.areaLabel, self.styles.areaName)
  labelSet(self.areaLabel, "Unknown Area")
  self.areaLabel:setClickCallback(function()
    if self.state.zoneId then openUrl("https://duris.sbs/wiki/zones/" .. tostring(self.state.zoneId)) end
  end)
  self.areaLabel:setOnEnter(function()
    if self.state.zoneId then styleSafe(self.areaLabel, self.styles.areaNameHover); self.areaLabel:setCursor("PointingHand") end
  end)
  self.areaLabel:setOnLeave(function() styleSafe(self.areaLabel, self.styles.areaName); self.areaLabel:setCursor("Arrow") end)

  -- Map - below globe and area label (with clipping to prevent overflow)
  self.mapWrap = makePanel(self.mapSection, "ArjUI_MapWrap", "3%", 22, "94%", "100%-44px", self.styles.panel)
  self.mapWrap:setStyleSheet("background-color: rgba(10,9,8,240); border: 2px solid #5a4b37; border-top: 2px solid #8c6e46; border-radius: 4px; overflow: hidden;")
  self.mapper = Geyser.Label:new({ name = "ArjUI_Mapper", x = "2%", y = "2%", width = "96%", height = "96%" }, self.mapWrap)
  self.mapper:setStyleSheet("background-color: #0c0b09; color: #8a8a8a; qproperty-alignment: 'AlignCenter'; font-size: 10px;")
  self.mapper:echo("Waiting for room data")

  -- SECTION 2: Exits + Time (36% - 40%) - Split into two halves
  self.exitsSection = makePanel(self.mapSection, "ArjUI_ExitsSection", 0, "100%-20px", "50%", 20, self.styles.panel)
  styleSafe(self.exitsSection, self.styles.panelGlass)
  
  self.exitsWrap = Geyser.Label:new({ name = "ArjUI_ExitsWrap", x = "3%", y = "5%", width = "94%", height = "90%" }, self.exitsSection)
  styleSafe(self.exitsWrap, self.styles.exits)
  self.exitButtons = {}
  
  -- Time of day section (right half) - clickable to send 'time' command
  self.timeSection = makePanel(self.mapSection, "ArjUI_TimeSection", "51%", "100%-20px", "49%", 20, self.styles.panel)
  styleSafe(self.timeSection, self.styles.panelGlass)
  
  self.timeLabel = Geyser.Label:new({ name = "ArjUI_TimeLabel", x = "5%", y = "5%", width = "90%", height = "90%" }, self.timeSection)
  self.timeLabel:setStyleSheet("background-color: transparent; color: #a0a0b0; font-size: 10px; qproperty-alignment: 'AlignCenter';")
  self.timeLabel:echo("☀ Day")
  self.timeLabel:setClickCallback(function() send("time") end)

  -- SECTION 3: Mobs (41% - 69%)
  self.mobsSection = panel("mobs")
  styleSafe(self.mobsSection, self.styles.panelGlass)
  
  self.mobsBox = makeConsole(self.mobsSection, "ArjUI_MobsBox", "3%", "3%", "94%", "94%", 9)

  -- SECTION 4: Items (70% - 100%) - extends to match output window bottom
  self.itemsSection = panel("items")
  styleSafe(self.itemsSection, self.styles.panelGlass)
  
  self.objsBox = makeConsole(self.itemsSection, "ArjUI_ObjsBox", "3%", "3%", "94%", "94%", 9)

  -- CENTER COLUMN (with gaps on sides) - opaque black behind the main MUD feed
  self.centerCol = panel("output")
  styleSafe(self.centerCol, self.styles.panelPrimary)

  self.xpGauge = Geyser.Gauge:new({ name = "ArjUI_TNLTop", x = "0.5%", y = "0.5%", width = "99%", height = "2.2%" }, self.centerCol)
  self.xpGauge.front:setStyleSheet(self.gaugeStyles.xpFront)
  self.xpGauge.back:setStyleSheet(self.gaugeStyles.xpBack)
  self.xpGauge.text:setStyleSheet(self.gaugeStyles.gaugeText)

  self.roomLabel = Geyser.Label:new({ name = "ArjUI_RoomLabel", x = "0.5%", y = "3.0%", width = "99%", height = "3.2%" }, self.centerCol)
  styleSafe(self.roomLabel, self.styles.roomName)

  self.console = makeConsole(self.centerCol, "ArjUI_Console", "0.5%", "6.5%", "99%", "93%", 10, {0, 0, 0})

  -- SECTION 1: Tabbed Pane (0% - 45%) - Info tabs fill top space
  self.tabSection = panel("character")
  styleSafe(self.tabSection, self.styles.panelGlass)

  -- TABBED PANE (Group/Stats/Inv/Eq/Skills)
  self.tabButtons = {}
  self.tabPanels = {}
  self.activeTab = "group"
  
  local tabNames = { "group", "stats", "inv", "eq", "who", "ship" }
  local tabLabels = { "GROUP", "STATS", "INV", "EQ", "WHO", "SHIP" }
  local tabW = 16  -- percentage width per tab
  
  for i, tabName in ipairs(tabNames) do
    local xPos = string.format("%d%%", 2 + (i-1) * tabW)
    local btn = Geyser.Label:new({ name = "ArjUI_Tab_" .. tabName, x = xPos, y = 1, width = (tabW - 1) .. "%", height = 18 }, self.tabSection)
    btn:echo("<center>" .. tabLabels[i] .. "</center>")
    self.tabButtons[tabName] = btn
    
    btn:setClickCallback(function() self:switchTab(tabName) end)
    btn:setOnEnter(function() btn:setCursor("PointingHand") end)
    btn:setOnLeave(function() btn:setCursor("Arrow") end)
  end
  
  -- Tab content area
  self.tabContent = Geyser.Container:new({ name = "ArjUI_TabContent", x = "3%", y = 21, width = "94%", height = "100%-23px" }, self.tabSection)
  
  -- GROUP panel (default) - Container for dynamic gauge widgets
  self.groupContainer = Geyser.ScrollBox:new({ name = "ArjUI_GroupContainer", x = 0, y = 0, width = "100%", height = "100%" }, self.tabContent)
  self.tabPanels.group = self.groupContainer
  self.groupWidgets = {}  -- Store dynamically created group member widgets
  
  -- STATS panel
  self.statsBox = makeConsole(self.tabContent, "ArjUI_StatsBox", 0, 0, "100%", "100%", 9)
  self.statsBox:hide()
  self.tabPanels.stats = self.statsBox
  
  -- INVENTORY panel
  self.invBox = makeConsole(self.tabContent, "ArjUI_InvBox", 0, 0, "100%", "100%", 9)
  self.invBox:hide()
  self.tabPanels.inv = self.invBox
  
  -- EQ panel (equipment)
  self.eqBox = makeConsole(self.tabContent, "ArjUI_EqBox", 0, 0, "100%", "100%", 9)
  self.eqBox:hide()
  self.tabPanels.eq = self.eqBox
  
  -- WHO panel
  self.whoBox = makeConsole(self.tabContent, "ArjUI_WhoBox", 0, 0, "100%", "100%", 9)
  self.whoBox:hide()
  self.tabPanels.who = self.whoBox
  
  -- SHIP panel (GMCP Ship.Info/Ship.Contacts, or 'look contacts' text)
  self.shipBox = makeConsole(self.tabContent, "ArjUI_ShipBox", 0, 0, "100%", "100%", 9)
  self.shipBox:enableScrollBar()
  self.shipBox:hide()
  self.tabPanels.ship = self.shipBox
  
  self:updateTabStyles()

  -- SECTION 2: Players (46% - 72%) - Players section above chat (expanded to fill gap)
  self.playersSection = panel("players")
  styleSafe(self.playersSection, self.styles.panelGlass)

  self.enemyBox = makeConsole(self.playersSection, "ArjUI_EnemyBox", "3%", "3%", "94%", "94%", 9)

  -- SECTION 3: Chat (73% - 100%) - Chat at bottom, sits just above credit box
  self.chatSection = panel("chat")
  styleSafe(self.chatSection, self.styles.panelGlass)

  -- Chat tabs
  self.chatTabs = {}
  self.chatPanels = {}
  self.activeChatTab = "all"
  
  local chatTabNames = { "all", "tells", "nchat", "room", "guild", "group" }
  local chatTabLabels = { "ALL", "TELLS", "NCHAT", "ROOM", "GUILD", "GROUP" }
  local chatTabW = 16  -- percentage width per tab
  
  for i, tabName in ipairs(chatTabNames) do
    local xPos = string.format("%d%%", 2 + (i-1) * chatTabW)
    local btn = Geyser.Label:new({ name = "ArjUI_ChatTab_" .. tabName, x = xPos, y = 1, width = (chatTabW - 1) .. "%", height = 18 }, self.chatSection)
    btn:echo("<center>" .. chatTabLabels[i] .. "</center>")
    self.chatTabs[tabName] = btn
    
    btn:setClickCallback(function() self:switchChatTab(tabName) end)
    btn:setOnEnter(function() btn:setCursor("PointingHand") end)
    btn:setOnLeave(function() btn:setCursor("Arrow") end)
  end
  
  -- Chat content area
  self.chatContent = Geyser.Container:new({ name = "ArjUI_ChatContent", x = "3%", y = 21, width = "94%", height = "100%-23px" }, self.chatSection)
  
  -- ALL chat panel (default)
  self.chatBox = makeConsole(self.chatContent, "ArjUI_ChatBox", 0, 0, "100%", "100%", 9)
  self.chatPanels.all = self.chatBox
  
  -- TELLS panel
  self.tellsBox = makeConsole(self.chatContent, "ArjUI_TellsBox", 0, 0, "100%", "100%", 9)
  self.tellsBox:hide()
  self.chatPanels.tells = self.tellsBox
  
  -- NCHAT panel
  self.nchatBox = makeConsole(self.chatContent, "ArjUI_NchatBox", 0, 0, "100%", "100%", 9)
  self.nchatBox:hide()
  self.chatPanels.nchat = self.nchatBox
  
  -- ROOM panel (say/yell)
  self.roomBox = makeConsole(self.chatContent, "ArjUI_RoomBox", 0, 0, "100%", "100%", 9)
  self.roomBox:hide()
  self.chatPanels.room = self.roomBox
  
  -- GUILD panel
  self.guildBox = makeConsole(self.chatContent, "ArjUI_GuildBox", 0, 0, "100%", "100%", 9)
  self.guildBox:hide()
  self.chatPanels.guild = self.guildBox
  
  -- GROUP panel
  self.groupChatBox = makeConsole(self.chatContent, "ArjUI_GroupChatBox", 0, 0, "100%", "100%", 9)
  self.groupChatBox:hide()
  self.chatPanels.group = self.groupChatBox
  
  self:updateChatTabStyles()

  -- Credit box (directly under chat panel, same width as right column)
  local creditX = "73.9%"  -- same as rightCol
  local creditW = "26%"   -- same width as rightCol (26%)
  local creditY = (100 - self.frameInsetBottomPct + 0.3) .. "%"
  self.creditBox = Geyser.Label:new({
    name = "ArjUI_CreditBox",
    x = creditX, y = creditY, width = creditW, height = 20
  }, self.main)
  self.creditBox:setStyleSheet([[
    background-color: rgba(15, 14, 12, 0.85);
    border: 1px solid #3c3428;
    border-radius: 3px;
    color: #8a7a5a;
    font-size: 9px;
    qproperty-alignment: 'AlignRight | AlignVCenter';
    padding-right: 8px;
  ]])
  self.creditBox:echo("Arjinius Client v" .. self.VERSION)
  
  -- Hover tooltip (appears above credit box)
  local tooltipY = (100 - self.frameInsetBottomPct - 3.2) .. "%"
  self.creditTooltip = Geyser.Label:new({
    name = "ArjUI_CreditTooltip",
    x = creditX, y = tooltipY, width = creditW, height = 36
  }, self.main)
  self.creditTooltip:setStyleSheet([[
    background-color: rgba(15, 14, 12, 0.95);
    border: 1px solid #5a4b37;
    border-radius: 3px;
    color: #c0b090;
    font-size: 8px;
    padding: 4px;
  ]])
  self.creditTooltip:echo("<center>A Mudlet client for Duris\nCreated by Arjin / Arjinius</center>")
  self.creditTooltip:hide()
  
  self.creditBox:setOnEnter(function()
    self.creditBox:setStyleSheet([[
      background-color: rgba(20, 18, 14, 0.95);
      border: 1px solid #5a4b37;
      border-radius: 3px;
      color: #d4a855;
      font-size: 9px;
      qproperty-alignment: 'AlignRight | AlignVCenter';
      padding-right: 8px;
    ]])
    self.creditTooltip:show()
    self.creditTooltip:raise()
  end)
  self.creditBox:setOnLeave(function()
    self.creditBox:setStyleSheet([[
      background-color: rgba(15, 14, 12, 0.85);
      border: 1px solid #3c3428;
      border-radius: 3px;
      color: #8a7a5a;
      font-size: 9px;
      qproperty-alignment: 'AlignRight | AlignVCenter';
      padding-right: 8px;
    ]])
    self.creditTooltip:hide()
  end)

  -- BOTTOM BAR (aligned with columns above)
  -- Vitals: under left column (0-16.5%)
  -- Tank: first half under output (16.7%-45.2%)
  -- Target: second half under output (45.4%-73.7%)
  self.myVitalsWrap = panel("vitals")
  styleSafe(self.myVitalsWrap, self.styles.panelGlass)

  self.hpGauge = Geyser.Gauge:new({ name="ArjUI_HP", x="4%", y="4%", width="92%", height="19%" }, self.myVitalsWrap)
  self.hpGauge.front:setStyleSheet(self.gaugeStyles.hpFront)
  self.hpGauge.back:setStyleSheet(self.gaugeStyles.hpBack)
  self.hpGauge.text:setStyleSheet(self.gaugeStyles.gaugeText)

  self.mpGauge = Geyser.Gauge:new({ name="ArjUI_MP", x="4%", y="26%", width="92%", height="19%" }, self.myVitalsWrap)
  self.mpGauge.front:setStyleSheet(self.gaugeStyles.mpFront)
  self.mpGauge.back:setStyleSheet(self.gaugeStyles.mpBack)
  self.mpGauge.text:setStyleSheet(self.gaugeStyles.gaugeText)

  self.mvGauge = Geyser.Gauge:new({ name="ArjUI_MV", x="4%", y="48%", width="92%", height="19%" }, self.myVitalsWrap)
  self.mvGauge.front:setStyleSheet(self.gaugeStyles.mvFront)
  self.mvGauge.back:setStyleSheet(self.gaugeStyles.mvBack)
  self.mvGauge.text:setStyleSheet(self.gaugeStyles.gaugeText)

  self.posLabel = Geyser.Label:new({ name="ArjUI_PosLabel", x="4%", y="70%", width="92%", height="26%" }, self.myVitalsWrap)
  styleSafe(self.posLabel, self.styles.pos)
  labelSet(self.posLabel, "STANDING")

  -- TANK (with gap from vitals) - Name as header, HP gauge, buffs below
  -- Tank: 16.7% to 45.2% (first half under output window)
  self.tankWrap = panel("tank")
  styleSafe(self.tankWrap, self.styles.panelGlass)
  
  -- Tank name as header (replaces "TANK" label)
  self.tankNameLabel = Geyser.Label:new({ name="ArjUI_TankName", x="3%", y=0, width="80%", height=16 }, self.tankWrap)
  styleSafe(self.tankNameLabel, self.styles.tankName)
  labelSet(self.tankNameLabel, "---")
  
  self.tankPosLabel = Geyser.Label:new({ name="ArjUI_TankPos", x="85%", y=0, width="12%", height=16 }, self.tankWrap)
  styleSafe(self.tankPosLabel, self.styles.pos)
  
  self.tankHpGauge = Geyser.Gauge:new({ name="ArjUI_TankHP", x="3%", y=18, width="94%", height=16 }, self.tankWrap)
  self.tankHpGauge.front:setStyleSheet(self.gaugeStyles.hpFront)
  self.tankHpGauge.back:setStyleSheet(self.gaugeStyles.hpBack)
  self.tankHpGauge.text:setStyleSheet("color: #d0d0d0; font-size: 10px; font-weight: bold;")
  
  -- Buffs section under tank
  self.buffsHeader = Geyser.Label:new({ name="ArjUI_BuffsHeader", x="3%", y=36, width="94%", height=14 }, self.tankWrap)
  styleSafe(self.buffsHeader, self.styles.headerAffects)
  labelSet(self.buffsHeader, "✦ BUFFS")
  self.buffsBox = makeConsole(self.tankWrap, "ArjUI_BuffsBox", "3%", 52, "94%", "100%-52px", 8)

  -- TARGET (with gap from tank) - Name as header, HP gauge, debuffs below
  -- Target: 45.5% to 73.7% (aligned with output window right edge)
  self.targetWrap = panel("target")
  styleSafe(self.targetWrap, self.styles.panelGlass)
  
  -- Target position label on left (mirrors tank layout)
  self.targetPosLabel = Geyser.Label:new({ name="ArjUI_TargetPos", x="3%", y=0, width="12%", height=16 }, self.targetWrap)
  styleSafe(self.targetPosLabel, self.styles.pos)
  
  -- Target name as header (to the right of position)
  self.targetNameLabel = Geyser.Label:new({ name="ArjUI_TargetName", x="17%", y=0, width="80%", height=16 }, self.targetWrap)
  styleSafe(self.targetNameLabel, self.styles.targetName)
  labelSet(self.targetNameLabel, "No Target")
  
  self.targetHpGauge = Geyser.Gauge:new({ name="ArjUI_TargetHP", x="3%", y=18, width="94%", height=16 }, self.targetWrap)
  self.targetHpGauge.front:setStyleSheet(self.gaugeStyles.targetFront)
  self.targetHpGauge.back:setStyleSheet(self.gaugeStyles.targetBack)
  self.targetHpGauge.text:setStyleSheet("color: #d0d0d0; font-size: 10px; font-weight: bold;")
  
  -- Debuffs section under target
  self.debuffsHeader = Geyser.Label:new({ name="ArjUI_DebuffsHeader", x="3%", y=36, width="62%", height=14 }, self.targetWrap)
  styleSafe(self.debuffsHeader, self.styles.headerCombat)
  labelSet(self.debuffsHeader, "☠ DEBUFFS")
  
  -- Damage counter for the current fight (see setupDamageTracker)
  self.damageLabel = Geyser.Label:new({ name="ArjUI_DamageLabel", x="66%", y=36, width="31%", height=14 }, self.targetWrap)
  styleSafe(self.damageLabel, self.styles.headerTarget)
  labelSet(self.damageLabel, "⚔ DMG")
  self.damageLabel:setClickCallback(function() self:reportDamage(false) end)
  self.damageLabel:setOnEnter(function() self.damageLabel:setCursor("PointingHand") end)
  self.damageLabel:setOnLeave(function() self.damageLabel:setCursor("Arrow") end)
  self.debuffsBox = makeConsole(self.targetWrap, "ArjUI_DebuffsBox", "3%", 52, "94%", "100%-52px", 8)

  self:resetCharacterState()
  self:setupPanelControls()
  self:loadLayout()

  local h
  h = registerAnonymousEventHandler("sysWindowResizeEvent", function() self:layout() end)
  table.insert(self.eventHandlers, h)

  h = registerAnonymousEventHandler("sysConnectionEvent", function()
    self:applyBackground()
    self:after(0.2, function() if self and self.applyBackground then self:applyBackground() end end)
  end)
  table.insert(self.eventHandlers, h)

  h = registerAnonymousEventHandler("sysAppStyleSheetChange", function()
    self:applyBackground()
    self:after(0.2, function() if self and self.applyBackground then self:applyBackground() end end)
  end)
  table.insert(self.eventHandlers, h)

  self:layout()

  self:loadCustomCommands()
  self:registerGMCPHandlers()
  self:setupPorted()
  self:renderAll()
  
  -- If GMCP data already exists (reconnecting to existing session), render again after short delay
  self:after(1, function()
    if ArjUI and gmcp and gmcp.Char and gmcp.Char.Vitals then
      ArjUI:renderAll()
    end
  end)
  
  -- Output launch message to the UI console
  if self.console then
    self.console:cecho("\n<gold>══ Arjinius Client v" .. ArjUI.VERSION .. " ══<reset>\n")
    self.console:cecho("<dim_gray>  A Mudlet client for Duris<reset>\n")
    self.console:cecho("<dim_gray>  Created by Arjin / Arjinius<reset>\n")
    self.console:cecho("<gold>═══════════════════════════════<reset>\n\n")
  end
end

function ArjUI:layout()
  if not self.uiRoot or self.hidden then return end
  local w, h = getMainWindowSize()
  setBorderTop(h)
  
  -- Calculate pixel values from percentages for resize
  local banner = h * self:headerHeightPct() / 100
  local insetX = w * (self.frameInsetXPct or 3.8) / 100
  local insetBottom = h * (self.frameInsetBottomPct or 3.5) / 100
  
  if self.main and w and h then
    self.main:move(0, 0)
    self.main:resize(w, h)
  end
  if self.bg and w and h then
    self.bg:move(0, 0)
    self.bg:resize(w, h)
  end
  local rootW = math.max(0, w - (insetX * 2))
  local rootH = math.max(0, h - banner - insetBottom)
  self.uiRoot:move(insetX, banner)
  self.uiRoot:resize(rootW, rootH)
  if self.panelsButton then
    local controlsY=math.max(0,banner-24)
    self.panelsButton:move(insetX,controlsY)
    self.resetLayoutButton:move(insetX+80,controlsY)
  end
  self:applyPanelLayout()
  self:refreshPanelContent()
  
  -- Reposition credit box and tooltip on resize (aligned under chat/right column)
  if self.creditBox then
    local creditX = insetX + rootW * 0.739  -- 73.9% of rootW from left edge
    local creditW = rootW * 0.26            -- 26% width (same as rightCol)
    local creditY = h - insetBottom + 3
    self.creditBox:move(creditX, creditY)
    self.creditBox:resize(creditW, 20)
    if self.creditTooltip then
      self.creditTooltip:move(creditX, creditY - 38)
      self.creditTooltip:resize(creditW, 36)
    end
  end

end

-- ============================================================
-- CONTEXT MENUS
-- ============================================================

function ArjUI:showContextMenu(items, x, y)
  -- Hide any existing menu
  if self.currentMenu then self:disposeWidget(self.currentMenu); self.currentMenu=nil end

  -- If caller didn't pass coordinates, use the actual mouse position
  if not x or not y then
    x, y = getMousePosition()
  end

  -- Clamp so it never spawns off-screen
  local winW, winH = getMainWindowSize()
  local menuW = 160
  local menuH = math.min(math.max(26,winH-4),#items * 22 + 26)  -- Extra space for close button

  x = math.max(0, math.min(x, winW - menuW - 2))
  y = math.max(0, math.min(y, winH - menuH - 2))

  local menu = Geyser.Label:new({
    name = "ArjUI_Menu_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000,9999)),
    x = x, y = y, width = menuW, height = menuH,
  }, self.main)
  menu:setStyleSheet("background-color: #0f0e0c; border: 1px solid #5a4b37; border-radius: 3px;")
  menu:raise()
  
  -- Close button at top
  local closeBtn = Geyser.Label:new({
    name = menu.name .. "_close",
    x = menuW - 20, y = 2, width = 18, height = 18,
  }, menu)
  closeBtn:setStyleSheet("background-color: #1a1610; color: #c05050; font-size: 10px; font-weight: bold; border: 1px solid #5a4b37; border-radius: 2px;")
  closeBtn:echo("<center>X</center>")
  closeBtn:setClickCallback(function()
    self:disposeWidget(menu)
    self.currentMenu = nil
  end)
  closeBtn:setOnEnter(function()
    closeBtn:setStyleSheet("background-color: #c05050; color: #ffffff; font-size: 10px; font-weight: bold; border: 1px solid #5a4b37; border-radius: 2px;")
  end)
  closeBtn:setOnLeave(function()
    closeBtn:setStyleSheet("background-color: #1a1610; color: #c05050; font-size: 10px; font-weight: bold; border: 1px solid #5a4b37; border-radius: 2px;")
  end)

  local entries=Geyser.ScrollBox:new({name=menu.name.."_entries",x=2,y=22,width=menuW-4,height=menuH-24},menu)
  for i, item in ipairs(items) do
    local btn = Geyser.Label:new({
      name = menu.name .. "_" .. i, x = 0, y = (i-1) * 22, width = menuW-20, height = 20,
    }, entries)
    btn:setStyleSheet("background-color: transparent; color: #c0b8a0; font-size: 10px; padding-left: 5px;")
    btn:echo(item.text)

    btn:setClickCallback(function()
      self:disposeWidget(menu)
      self.currentMenu = nil
      -- Package actions share the same menu path as existing game commands.
      if item.callback then item.callback()
      elseif item.cmd and item.cmd:match("^arjui_add_") then
        local category = item.cmd:gsub("^arjui_add_", "")
        self:showAddCommandPopup(category)
      elseif item.cmd and item.cmd:match("^arjui_spell_") then
        local category = item.cmd:gsub("^arjui_spell_", "")
        self:showAddSpellPopup(category)
      elseif item.cmd and item.cmd:match("^arjui_remove_") then
        local category = item.cmd:gsub("^arjui_remove_", "")
        self:showRemoveCommandMenu(category)
      elseif item.cmd and item.cmd:match("^arjui_del_") then
        -- Handle actual deletion: arjui_del_category_index
        local parts = item.cmd:match("^arjui_del_(.+)_(%d+)$")
        if parts then
          local cat, idx = item.cmd:match("^arjui_del_(.+)_(%d+)$")
          idx = tonumber(idx)
          if self.customCommands[cat] and idx and self.customCommands[cat][idx] then
            local removed = table.remove(self.customCommands[cat], idx)
            self:saveCustomCommands()
            cecho(string.format("<green>[ArjUI]<reset> Removed '%s'.\n", removed.text))
          end
        end
      elseif item.cmd and item.cmd ~= "" then
        send(item.cmd)
      end
    end)

    btn:setOnEnter(function()
      btn:setStyleSheet("background-color: #1a1610; color: #e0d8c0; font-size: 10px; padding-left: 5px;")
    end)

    btn:setOnLeave(function()
      btn:setStyleSheet("background-color: transparent; color: #c0b8a0; font-size: 10px; padding-left: 5px;")
    end)
  end

  -- Auto-hide after 10 seconds so it can't get stuck
  menu.expiryTimer=self:after(10, function()
    menu.expiryTimer=nil
    if self.currentMenu==menu then self.currentMenu=nil end
    self:disposeWidget(menu)
  end)

  self.currentMenu = menu
end

-- ============================================================
-- CUSTOM COMMANDS - LOAD/SAVE
-- ============================================================

function ArjUI:loadCustomCommands()
  local path = getMudletHomeDir() .. "/arjui_custom_commands.json"
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(yajl.to_value, content)
    if ok and data then
      self.customCommands = data
      cecho("<dim_gray>[ArjUI] Custom commands loaded.\n")
    end
  end
end

function ArjUI:saveCustomCommands()
  local path = getMudletHomeDir() .. "/arjui_custom_commands.json"
  local ok, json = pcall(yajl.to_string, self.customCommands)
  if ok then
    local file = io.open(path, "w")
    if file then
      file:write(json)
      file:close()
      cecho("<dim_gray>[ArjUI] Custom commands saved.\n")
    end
  end
end

-- ============================================================
-- CUSTOM COMMANDS - ADD POPUP
-- ============================================================

function ArjUI:showAddCommandPopup(category)
  -- Clean up any existing popup
  if self.addCmdPopup then
    self.addCmdPopup:hide()
    self.addCmdPopup = nil
  end
  
  local w, h = getMainWindowSize()
  local popupW, popupH = 280, 140
  local popupX = (w - popupW) / 2
  local popupY = (h - popupH) / 2
  
  -- Main popup container
  local popup = Geyser.Label:new({
    name = "ArjUI_AddCmdPopup_" .. os.time(),
    x = popupX, y = popupY, width = popupW, height = popupH
  }, self.main)
  popup:setStyleSheet("background-color: #0f0e0c; border: 2px solid #8c6e46; border-radius: 4px;")
  popup:raise()
  
  -- Title
  local title = Geyser.Label:new({
    name = popup.name .. "_title",
    x = 0, y = 5, width = popupW, height = 20
  }, popup)
  title:setStyleSheet("background-color: transparent; color: #d4a855; font-size: 11px; font-weight: bold;")
  title:echo("<center>Add " .. category:upper() .. " Command</center>")
  
  -- Label field
  local labelLbl = Geyser.Label:new({
    name = popup.name .. "_labelLbl",
    x = 10, y = 30, width = 50, height = 22
  }, popup)
  labelLbl:setStyleSheet("background-color: transparent; color: #a09080; font-size: 10px;")
  labelLbl:echo("Label:")
  
  local labelInput = Geyser.CommandLine:new({
    name = popup.name .. "_labelInput",
    x = 65, y = 30, width = popupW - 80, height = 22
  }, popup)
  labelInput:setStyleSheet("background-color: #16140f; border: 1px solid #5a4b37; color: #d0d0d8; font-size: 10px;")
  
  -- Command field
  local cmdLbl = Geyser.Label:new({
    name = popup.name .. "_cmdLbl",
    x = 10, y = 58, width = 50, height = 22
  }, popup)
  cmdLbl:setStyleSheet("background-color: transparent; color: #a09080; font-size: 10px;")
  cmdLbl:echo("Command:")
  
  local cmdInput = Geyser.CommandLine:new({
    name = popup.name .. "_cmdInput",
    x = 65, y = 58, width = popupW - 80, height = 22
  }, popup)
  cmdInput:setStyleSheet("background-color: #16140f; border: 1px solid #5a4b37; color: #d0d0d8; font-size: 10px;")
  
  -- Help text
  local helpLbl = Geyser.Label:new({
    name = popup.name .. "_help",
    x = 10, y = 82, width = popupW - 20, height = 16
  }, popup)
  helpLbl:setStyleSheet("background-color: transparent; color: #606060; font-size: 9px;")
  helpLbl:echo("Target name auto-added to command")
  
  -- Save button
  local saveBtn = Geyser.Label:new({
    name = popup.name .. "_save",
    x = 10, y = 102, width = (popupW - 30) / 2, height = 28
  }, popup)
  saveBtn:setStyleSheet("background-color: #1a1610; border: 1px solid #5a4b37; color: #d4a855; font-size: 10px; font-weight: bold; border-radius: 3px;")
  saveBtn:echo("<center>Save</center>")
  saveBtn:setClickCallback(function()
    local label = labelInput:getText()
    local cmd = cmdInput:getText()
    if label and label ~= "" and cmd and cmd ~= "" then
      self.customCommands[category] = self.customCommands[category] or {}
      table.insert(self.customCommands[category], { text = label, cmd = cmd })
      self:saveCustomCommands()
      cecho(string.format("<green>[ArjUI]<reset> Added '%s' to %s menu.\n", label, category))
      popup:hide()
      self.addCmdPopup = nil
    end
  end)
  
  -- Cancel button
  local cancelBtn = Geyser.Label:new({
    name = popup.name .. "_cancel",
    x = (popupW - 30) / 2 + 20, y = 102, width = (popupW - 30) / 2, height = 28
  }, popup)
  cancelBtn:setStyleSheet("background-color: #1a1610; border: 1px solid #5a4b37; color: #a09080; font-size: 10px; font-weight: bold; border-radius: 3px;")
  cancelBtn:echo("<center>Cancel</center>")
  cancelBtn:setClickCallback(function()
    popup:hide()
    self.addCmdPopup = nil
  end)
  
  self.addCmdPopup = popup
  labelInput:setFocus()
end

-- ============================================================
-- CUSTOM COMMANDS - ADD SPELL POPUP
-- ============================================================

function ArjUI:showAddSpellPopup(category)
  -- Clean up any existing popup
  if self.addCmdPopup then
    self.addCmdPopup:hide()
    self.addCmdPopup = nil
  end
  
  local w, h = getMainWindowSize()
  local popupW, popupH = 280, 140
  local popupX = (w - popupW) / 2
  local popupY = (h - popupH) / 2
  
  -- Main popup container
  local popup = Geyser.Label:new({
    name = "ArjUI_AddSpellPopup_" .. os.time(),
    x = popupX, y = popupY, width = popupW, height = popupH
  }, self.main)
  popup:setStyleSheet("background-color: #0f0e0c; border: 2px solid #8c6e46; border-radius: 4px;")
  popup:raise()
  
  -- Title
  local title = Geyser.Label:new({
    name = popup.name .. "_title",
    x = 0, y = 5, width = popupW, height = 20
  }, popup)
  title:setStyleSheet("background-color: transparent; color: #d4a855; font-size: 11px; font-weight: bold;")
  title:echo("<center>Add Spell to " .. category:upper() .. "</center>")
  
  -- Label field
  local labelLbl = Geyser.Label:new({
    name = popup.name .. "_labelLbl",
    x = 10, y = 30, width = 50, height = 22
  }, popup)
  labelLbl:setStyleSheet("background-color: transparent; color: #a09080; font-size: 10px;")
  labelLbl:echo("Label:")
  
  local labelInput = Geyser.CommandLine:new({
    name = popup.name .. "_labelInput",
    x = 65, y = 30, width = popupW - 80, height = 22
  }, popup)
  labelInput:setStyleSheet("background-color: #16140f; border: 1px solid #5a4b37; color: #d0d0d8; font-size: 10px;")
  
  -- Spell name field
  local spellLbl = Geyser.Label:new({
    name = popup.name .. "_spellLbl",
    x = 10, y = 58, width = 50, height = 22
  }, popup)
  spellLbl:setStyleSheet("background-color: transparent; color: #a09080; font-size: 10px;")
  spellLbl:echo("Spell:")
  
  local spellInput = Geyser.CommandLine:new({
    name = popup.name .. "_spellInput",
    x = 65, y = 58, width = popupW - 80, height = 22
  }, popup)
  spellInput:setStyleSheet("background-color: #16140f; border: 1px solid #5a4b37; color: #d0d0d8; font-size: 10px;")
  
  -- Help text
  local helpLbl = Geyser.Label:new({
    name = popup.name .. "_help",
    x = 10, y = 82, width = popupW - 20, height = 16
  }, popup)
  helpLbl:setStyleSheet("background-color: transparent; color: #606060; font-size: 9px;")
  helpLbl:echo("Sends: cast 'spell name' target")
  
  -- Save button
  local saveBtn = Geyser.Label:new({
    name = popup.name .. "_save",
    x = 10, y = 102, width = (popupW - 30) / 2, height = 28
  }, popup)
  saveBtn:setStyleSheet("background-color: #1a1610; border: 1px solid #5a4b37; color: #d4a855; font-size: 10px; font-weight: bold; border-radius: 3px;")
  saveBtn:echo("<center>Save</center>")
  saveBtn:setClickCallback(function()
    local label = labelInput:getText()
    local spell = spellInput:getText()
    if label and label ~= "" and spell and spell ~= "" then
      self.customCommands[category] = self.customCommands[category] or {}
      -- Store with spell flag so we know to format it specially
      table.insert(self.customCommands[category], { text = label, cmd = spell, isSpell = true })
      self:saveCustomCommands()
      cecho(string.format("<green>[ArjUI]<reset> Added spell '%s' to %s menu.\n", label, category))
      popup:hide()
      self.addCmdPopup = nil
    end
  end)
  
  -- Cancel button
  local cancelBtn = Geyser.Label:new({
    name = popup.name .. "_cancel",
    x = (popupW - 30) / 2 + 20, y = 102, width = (popupW - 30) / 2, height = 28
  }, popup)
  cancelBtn:setStyleSheet("background-color: #1a1610; border: 1px solid #5a4b37; color: #a09080; font-size: 10px; font-weight: bold; border-radius: 3px;")
  cancelBtn:echo("<center>Cancel</center>")
  cancelBtn:setClickCallback(function()
    popup:hide()
    self.addCmdPopup = nil
  end)
  
  self.addCmdPopup = popup
  labelInput:setFocus()
end

-- ============================================================
-- CUSTOM COMMANDS - REMOVE FROM MENU
-- ============================================================

function ArjUI:showRemoveCommandMenu(category)
  local commands = self.customCommands[category] or {}
  if #commands == 0 then
    cecho("<yellow>[ArjUI]<reset> No custom commands to remove.\n")
    return
  end
  
  local items = {}
  for i, cmd in ipairs(commands) do
    table.insert(items, {
      text = "✕ " .. cmd.text,
      cmd = "arjui_del_" .. category .. "_" .. i
    })
  end
  table.insert(items, { text = "───────────", cmd = "" })
  table.insert(items, { text = "Cancel", cmd = "" })
  
  self:showContextMenu(items)
end

-- ============================================================
-- CONTEXT MENU WITH CUSTOM COMMANDS
-- ============================================================

function ArjUI:getContextMenuItems(category, target)
  local items = {}
  
  -- Default commands based on category
  if category == "players" then
    items = {
      { text = "Look", cmd = "look " .. target },
      { text = "Assist", cmd = "assist " .. target },
      { text = "Follow", cmd = "follow " .. target },
      { text = "Rescue", cmd = "rescue " .. target },
      { text = "Consent", cmd = "consent " .. target },
      { text = "Group", cmd = "group " .. target },
    }
  elseif category == "mobs" then
    items = {
      { text = "Look", cmd = "look " .. target },
      { text = "Consider", cmd = "consider " .. target },
      { text = "Kill", cmd = "kill " .. target },
    }
  elseif category == "objects" then
    items = {
      { text = "Examine", cmd = "examine " .. target },
      { text = "Get", cmd = "get " .. target },
    }
  elseif category == "inventory" then
    items = {
      { text = "Examine", cmd = "examine " .. target },
      { text = "Drop", cmd = "drop " .. target },
      { text = "Wear", cmd = "wear " .. target },
      { text = "Wield", cmd = "wield " .. target },
      { text = "Hold", cmd = "hold " .. target },
    }
  elseif category == "equipment" then
    items = {
      { text = "Examine", cmd = "examine " .. target },
      { text = "Remove", cmd = "remove " .. target },
    }
  end
  
  -- Add custom commands (regular commands first, then spells)
  local customCmds = self.customCommands[category] or {}
  local hasRegular = false
  local hasSpells = false
  
  -- First pass: add regular commands
  for _, cmd in ipairs(customCmds) do
    if not cmd.isSpell then
      hasRegular = true
      local finalCmd = cmd.cmd .. " " .. target
      table.insert(items, { text = cmd.text, cmd = finalCmd })
    end
  end
  
  -- Second pass: add spells with separator if we have both
  for _, cmd in ipairs(customCmds) do
    if cmd.isSpell then
      if not hasSpells and hasRegular then
        -- Add separator before first spell if we had regular commands
        table.insert(items, { text = "───────────", cmd = "" })
      end
      hasSpells = true
      local finalCmd = "cast '" .. cmd.cmd .. "' " .. target
      table.insert(items, { text = "✨ " .. cmd.text, cmd = finalCmd })
    end
  end
  
  -- Add/Remove options
  table.insert(items, { text = "───────────", cmd = "" })
  table.insert(items, { text = "➕ Add Command", cmd = "arjui_add_" .. category })
  table.insert(items, { text = "✨ Add Spell", cmd = "arjui_spell_" .. category })
  if #(self.customCommands[category] or {}) > 0 then
    table.insert(items, { text = "➖ Remove Command", cmd = "arjui_remove_" .. category })
  end
  
  return items
end

-- ============================================================
-- PRIVATE MESSAGING SYSTEM
-- ============================================================

function ArjUI:openPrivateChat(playerName)
  local name=playerName:lower()
  local displayName=name:sub(1,1):upper()..name:sub(2)
  local id="tell:"..name
  local chat=self.privateChats[name] or {history={},unread=0}
  self.privateChats[name]=chat
  if not chat.window then
    local w,h=math.max(1,self.uiRoot:get_width()),math.max(1,self.uiRoot:get_height())
    local content=self:createPanel({id=id,title=displayName,private=true,
      home={math.max(0,1-320/w),math.max(0,1-240/h),math.min(1,300/w),math.min(1,220/h)},
      minimum={260,160}})
    chat.window=self.panels[id].frame
    chat.historyBox=makeConsole(content,"ArjUI_PrivateChat_"..name.."_history",0,0,"100%","100%-30px",9)
    chat.inputBox=Geyser.CommandLine:new({name="ArjUI_PrivateChat_"..name.."_input",
      x=0,y="100%-26px",width="100%-60px",height=24},content)
    chat.inputBox:setStyleSheet(self.styles.inputBar)
    local function submit(msg)
      if msg and msg~="" then send("tell "..name.." "..msg); chat.inputBox:clear() end
    end
    chat.inputBox:setAction(submit)
    chat.sendButton=makePanel(content,"ArjUI_PrivateChat_"..name.."_send","100%-55px","100%-26px",55,24,self.styles.header)
    chat.sendButton:echo("Send")
    chat.sendButton:setClickCallback(function() submit(chat.inputBox:getText()) end)
    chat.displayName=displayName
    for _,msg in ipairs(chat.history) do self:displayPrivateMessage(name,msg.sender,msg.text,msg.outgoing) end
  end
  self:panelAction(id,"show")
  self:addTellContact(displayName)
  self:renderTellContacts()
end

function ArjUI:addPrivateChatMessage(playerName, sender, text, outgoing)
  local name = playerName:lower()
  
  -- Initialize if needed
  self.privateChats[name] = self.privateChats[name] or { history = {}, unread = 0 }
  
  -- Add to history
  table.insert(self.privateChats[name].history, {
    sender = sender,
    text = text,
    outgoing = outgoing,
    time = os.date("%H:%M")
  })
  
  -- Keep history reasonable (last 100 messages)
  while #self.privateChats[name].history > 100 do
    table.remove(self.privateChats[name].history, 1)
  end
  
  -- Check if window exists and is visible using our visible flag
  local windowOpen = self.privateChats[name].window and self.privateChats[name].visible
  
  -- Retained consoles keep receiving data while hidden/minimized.
  if self.privateChats[name].historyBox then self:displayPrivateMessage(name, sender, text, outgoing) end
  if windowOpen then
    -- Window is open, so mark as read
    self.privateChats[name].unread = 0
  else
    -- Window not open or not visible, increment unread for incoming messages only
    if not outgoing then
      self.privateChats[name].unread = (self.privateChats[name].unread or 0) + 1
      self:renderTellContacts()
    end
  end
end

function ArjUI:displayPrivateMessage(playerName, sender, text, outgoing)
  local name = playerName:lower()
  local chat = self.privateChats[name]
  if not chat or not chat.historyBox then return end
  
  local time = os.date("%H:%M")
  if outgoing then
    chat.historyBox:cecho(string.format("<dim_gray>[%s] <medium_orchid>You<reset>: %s\n", time, text))
  else
    chat.historyBox:cecho(string.format("<dim_gray>[%s] <gold>%s<reset>: %s\n", time, sender, text))
  end
end

function ArjUI:addTellContact(playerName)
  local displayName = playerName:sub(1,1):upper() .. playerName:sub(2):lower()
  
  -- Check if already in contacts
  for _, contact in ipairs(self.tellContacts) do
    if contact:lower() == displayName:lower() then
      return
    end
  end
  
  -- Add to front of list (most recent first)
  table.insert(self.tellContacts, 1, displayName)
  
  -- Keep list reasonable
  while #self.tellContacts > 20 do
    table.remove(self.tellContacts)
  end
  
  self:renderTellContacts()
end

function ArjUI:handleIncomingTell(sender, text)
  local name = sender:lower()
  local displayName = sender:sub(1,1):upper() .. sender:sub(2):lower()
  
  -- Add to contacts
  self:addTellContact(displayName)
  
  -- Add message to history (this handles unread count internally)
  self:addPrivateChatMessage(name, displayName, text, false)
end

function ArjUI:renderTellContacts()
  if not self.tellsBox then return end
  
  self.tellsBox:clear()
  
  if #self.tellContacts == 0 then
    self.tellsBox:cecho("<dim_gray>No recent conversations.\n")
    self.tellsBox:cecho("<dim_gray>Tells will appear here.\n")
    return
  end
  
  self.tellsBox:cecho("<dim_gray>── Recent Conversations ──\n\n")
  
  for _, contact in ipairs(self.tellContacts) do
    local name = contact:lower()
    local unread = 0
    if self.privateChats[name] then
      unread = self.privateChats[name].unread or 0
    end
    
    local displayText
    if unread > 0 then
      displayText = string.format("<gold>%s<reset> <red>(%d new)<reset>\n", contact, unread)
    else
      displayText = string.format("<medium_orchid>%s<reset>\n", contact)
    end
    
    self.tellsBox:cechoLink(displayText, function()
      self:openPrivateChat(contact)
    end, "Click to open chat with " .. contact, true)
  end
end

-- ============================================================
-- GMCP HANDLERS
-- ============================================================

function ArjUI:registerGMCPHandlers()
  local h
  
  h = registerAnonymousEventHandler("gmcp.Char.Vitals", function() self:onCharVitals() end)
  table.insert(self.eventHandlers, h)
  h = registerAnonymousEventHandler("gmcp.Room.Info", function() self:onRoomInfo() end)
  table.insert(self.eventHandlers, h)
  h = registerAnonymousEventHandler("gmcp.Combat.Update", function() self:onCombatUpdate() end)
  table.insert(self.eventHandlers, h)
  h = registerAnonymousEventHandler("gmcp.Group.Status", function() self:onGroupStatus() end)
  table.insert(self.eventHandlers, h)
  h = registerAnonymousEventHandler("gmcp.Comm.Channel", function() self:onCommChannel() end)
  table.insert(self.eventHandlers, h)
  h = registerAnonymousEventHandler("gmcp.Char.Affects", function() self:onCharAffects() end)
  table.insert(self.eventHandlers, h)
  -- Ship.Info / Ship.Contacts: periodic while on a ship bridge
  h = registerAnonymousEventHandler("gmcp.Ship.Info", function() self:onShipInfo() end)
  table.insert(self.eventHandlers, h)
  h = registerAnonymousEventHandler("gmcp.Ship.Contacts", function() self:onShipContacts() end)
  table.insert(self.eventHandlers, h)
  
  -- Char.Status: sent once on character entry and on level change (self only)
  h = registerAnonymousEventHandler("gmcp.Char.Status", function() self:onCharStatus() end)
  table.insert(self.eventHandlers, h)
  -- Quest.Status: bartender quest state (login, accept, progress, complete)
  h = registerAnonymousEventHandler("gmcp.Quest.Status", function() self:onQuestStatus() end)
  table.insert(self.eventHandlers, h)
  
  -- Prompt-based refresh for immediate updates
  h = registerAnonymousEventHandler("sysDataSendRequest", function() 
    -- Refresh combat displays on every command sent
    self:renderTarget()
    self:renderTank()
  end)
  table.insert(self.eventHandlers, h)
  
  h = registerAnonymousEventHandler("sysProtocolEnabled", function(_, protocol)
    if protocol == "GMCP" then self:enableGMCP() end
  end)
  table.insert(self.eventHandlers, h)
  h = registerAnonymousEventHandler("sysConnectionEvent", function() self:endSession() end)
  table.insert(self.eventHandlers, h)
  h = registerAnonymousEventHandler("sysDisconnectionEvent", function() self:endSession() end)
  table.insert(self.eventHandlers, h)
  -- Installing into an already negotiated session must advertise the package too.
  if getConnectionInfo and select(3, getConnectionInfo()) and gmcp then self:enableGMCP() end

  -- Detect character login and render UI.
  -- Primary signal: first gmcp.Char.Status after connect (server sends it once on
  -- character entry, independent of prompt settings). Fallback: default prompt shape.
  self.loginTrigger = self:addRuntimeTrigger("^< \\d+h/\\d+H \\d+v/\\d+V Pos:", function()
    if ArjUI then ArjUI:onLoginDetected() end
  end)
  
  
  -- Room refresh triggers disabled - GMCP Room.Info handles this automatically
  -- self.dropTrigger = self:addRuntimeTrigger("^(You drop|.+ drops) ", function()
  --   self:after(0.3, function() if ArjUI then send("look", false) end end)
  -- end)
  -- self.getTrigger = self:addRuntimeTrigger("^(You get|You pick up|.+ gets) ", function()
  --   self:after(0.3, function() if ArjUI then send("look", false) end end)
  -- end)
  
  -- Trigger to detect when a mob dies (clears target and resets tank bar to self)
  self.deathTrigger = self:addRuntimeTrigger("^.+ is dead! R\\.I\\.P\\.$", function()
    -- Clear target
    ArjUI.state.target = nil
    ArjUI.state.targetHpPct = 100
    ArjUI.state.targetCond = nil
    ArjUI.state.targetPos = nil
    ArjUI.state.targetBleeding = false
    -- Reset tank bar to self (combat ended)
    ArjUI.state.iAmTank = true
    ArjUI.state.tank = nil
    ArjUI.state.tankCond = nil
    ArjUI.state.tankHpPct = nil
    ArjUI:renderTarget()
    ArjUI:renderTank()
  end)
  
  -- Trigger to detect flee (clears target and resets tank bar to self)
  self.fleeTrigger = self:addRuntimeTrigger("^You flee ", function()
    -- Clear target
    ArjUI.state.target = nil
    ArjUI.state.targetHpPct = 100
    ArjUI.state.targetCond = nil
    ArjUI.state.targetPos = nil
    ArjUI.state.targetBleeding = false
    -- Reset tank bar to self (combat ended for us)
    ArjUI.state.iAmTank = true
    ArjUI.state.tank = nil
    ArjUI.state.tankCond = nil
    ArjUI.state.tankHpPct = nil
    ArjUI:renderTarget()
    ArjUI:renderTank()
  end)
  
  -- Trigger to detect player death (clears all combat state)
  -- Matches account menu which appears after death
  self.playerDeathTrigger = self:addRuntimeTrigger("ACCOUNT MENU", function()
    ArjUI:endSession()
  end)
  
  -- Trigger to detect assist (sets assist target for YOU bar)
  self.assistTrigger = self:addRuntimeTrigger("^You are now assisting (.+)\\.$", function()
    local assistName = matches[2]
    if assistName and assistName ~= "" then
      ArjUI.state.assistTarget = assistName
      ArjUI.state.iAmTank = false
      ArjUI:updateAssistTarget()
      ArjUI:renderTank()
    end
  end)
  
  -- Trigger to detect stop assisting
  self.stopAssistTrigger = self:addRuntimeTrigger("^You are no longer assisting ", function()
    ArjUI.state.assistTarget = nil
    ArjUI.state.iAmTank = true
    ArjUI:renderTank()
  end)
  
  -- Time of day triggers (automatic announcements)
  self.timeDayTrigger = self:addRuntimeTrigger("^The day has begun\\.$", function()
    ArjUI.state.timeOfDay = "day"
    ArjUI:renderTime()
  end)
  self.timeNightTrigger = self:addRuntimeTrigger("^The night has begun\\.$", function()
    ArjUI.state.timeOfDay = "night"
    ArjUI:renderTime()
  end)
  self.timeDawnTrigger = self:addRuntimeTrigger("^The sun rises", function()
    ArjUI.state.timeOfDay = "dawn"
    ArjUI:renderTime()
  end)
  self.timeDuskTrigger = self:addRuntimeTrigger("^The sun sets", function()
    ArjUI.state.timeOfDay = "dusk"
    ArjUI:renderTime()
  end)
  
  -- Parse 'time' command output: "It is 9pm, on the Day of the Deception"
  -- Gag the output if it was from our silent auto-query
  self.timeCommandTrigger = self:addRuntimeTrigger("^It is (\\d+)(am|pm)", function()
    local hour = tonumber(matches[2])
    local ampm = matches[3]
    -- Convert to 24h for easier day/night detection
    if ampm == "pm" and hour ~= 12 then hour = hour + 12 end
    if ampm == "am" and hour == 12 then hour = 0 end
    -- Determine time of day: 6am-6pm = day, 6pm-6am = night, with dawn/dusk at transitions
    if hour >= 6 and hour < 7 then
      ArjUI.state.timeOfDay = "dawn"
    elseif hour >= 7 and hour < 18 then
      ArjUI.state.timeOfDay = "day"
    elseif hour >= 18 and hour < 19 then
      ArjUI.state.timeOfDay = "dusk"
    else
      ArjUI.state.timeOfDay = "night"
    end
    ArjUI:renderTime()
    -- Gag if this was from auto-query (within 3 seconds of login)
    if ArjUI.timeQuerySilent then
      deleteLine()
    end
  end)
  
  -- Gag the additional time output lines when silent
  self.timeGagTrigger1 = self:addRuntimeTrigger("^The \\d+.. Day of the ", function()
    if ArjUI.timeQuerySilent then deleteLine() end
  end)
  self.timeGagTrigger2 = self:addRuntimeTrigger("^Time elapsed since boot-up:", function()
    if ArjUI.timeQuerySilent then deleteLine() end
  end)
  self.timeGagTrigger3 = self:addRuntimeTrigger("^Current time is:", function()
    if ArjUI.timeQuerySilent then deleteLine() end
  end)
  self.timeGagTrigger4 = self:addRuntimeTrigger("^\\s+\\w+ \\w+ +\\d+ \\d+:\\d+:\\d+ \\d+", function()
    if ArjUI.timeQuerySilent then 
      deleteLine()
      -- Last line of time output - clear the silent flag
      ArjUI.timeQuerySilent = false
    end
  end)
  
  -- Trigger to parse combat prompt line for tank, target, and positions
  -- Format: < T: Seveiwyn TP: sta TC: excellent E: wolf EP: sta EC: small wounds>
  self.combatPromptTrigger = self:addRuntimeTrigger("^< T: (.+) TP: (\\w+) TC: ([^E]+) E: (.+) EP: (\\w+) EC: ([^>]+)>", function()
    local tankName = matches[2]:gsub("%s+$", "")  -- trim trailing space
    local tankPos = matches[3]
    local tankCond = matches[4]:gsub("%s+$", "")  -- trim trailing space
    local enemyName = matches[5]:gsub("%s+$", "")
    local enemyPos = matches[6]
    local enemyCond = matches[7]:gsub("%s+$", "")
    
    -- Update tank info (T: is who is tanking)
    if tankName and tankName ~= "" then
      local myName = ArjUI.playerName or ""
      if tankName:lower() == myName:lower() then
        -- I am the tank - show my own HP
        ArjUI.state.iAmTank = true
        ArjUI.state.assistTarget = nil
      else
        -- Someone else is tanking - show their info
        ArjUI.state.iAmTank = false
        ArjUI.state.tank = tankName
        ArjUI.state.tankPos = tankPos
        ArjUI.state.tankCond = tankCond
        ArjUI.state.tankHpPct = ArjUI:conditionToPercent(tankCond)
      end
      ArjUI:renderTank()
    end
    
    -- Update target info (E: is the enemy)
    if enemyName and enemyName ~= "" then
      ArjUI.state.target = enemyName
      ArjUI.state.targetPos = enemyPos
      ArjUI.state.targetCond = enemyCond
      ArjUI.state.targetHpPct = ArjUI:conditionToPercent(enemyCond)
      ArjUI:renderTarget()
    end
  end)
end

-- Called once per character login (from Char.Status or the prompt fallback)
function ArjUI:onLoginDetected()
  if self.initialDataRequested then return end
  self.initialDataRequested = true
  -- Render after short delay to allow any pending GMCP data to arrive
  self:after(0.5, function()
    if ArjUI then ArjUI:renderAll() end
  end)
  -- Query time silently on login
  self:after(1.0, function()
    ArjUI.timeQuerySilent = true
    send("time", false)
  end)
end

-- Convert condition text to approximate HP percentage
function ArjUI:conditionToPercent(cond)
  if not cond then return 100 end
  local c = cond:lower()
  if c:find("excellent") then return 100
  elseif c:find("few scratches") then return 90
  elseif c:find("small wounds") then return 80
  elseif c:find("few wounds") then return 70
  elseif c:find("several wounds") then return 60
  elseif c:find("big nasty") then return 40
  elseif c:find("nasty wounds") then return 50
  elseif c:find("pretty hurt") then return 30
  elseif c:find("awful") then return 20
  elseif c:find("bleeding") then return 5
  elseif c:find("dead") then return 0
  else return 50 end
end

function ArjUI:onCharVitals()
  if not gmcp or not gmcp.Char or not gmcp.Char.Vitals then return end
  local v = gmcp.Char.Vitals
  local pname = pick(v, "name", "char", "player")
  if pname and type(pname) == "string" and pname ~= "" then self.playerName = self.playerName or pname end
  self.state.hp = toNum(pick(v, "hp", "health")) or self.state.hp
  self.state.hpmax = toNum(pick(v, "maxHp", "maxhp", "max_health")) or self.state.hpmax
  self.state.mana = toNum(pick(v, "mana", "mp")) or self.state.mana
  self.state.manamax = toNum(pick(v, "maxMana", "maxmana", "maxMp")) or self.state.manamax
  self.state.move = toNum(pick(v, "move", "mv")) or self.state.move
  self.state.movemax = toNum(pick(v, "maxMove", "maxmove", "maxMv")) or self.state.movemax
  local newTnl = toNum(pick(v, "tnl", "toNextLevel"))
  if newTnl then
    if not self.state.tnlBaseline then self.state.tnlBaseline = newTnl
    elseif newTnl > self.state.tnl then self.state.tnlBaseline = newTnl end
    self.state.tnl = newTnl
  end
  local newExp = toNum(pick(v, "exp", "experience"))
  if newExp and self.trackExp then self:trackExp(newExp, newTnl) end
  if v.position then self.state.position = v.position end
  if v.usesMana ~= nil then self.state.usesMana = (v.usesMana == true) end
  self.state.fighting = (type(v.fighting) == "string" and v.fighting ~= "") and v.fighting or nil
  local coins = self.state.coins
  coins.platinum = toNum(v.platinum) or coins.platinum
  coins.gold = toNum(v.gold) or coins.gold
  coins.silver = toNum(v.silver) or coins.silver
  coins.copper = toNum(v.copper) or coins.copper
  self:renderVitals()
  self:renderTNLBar()
  self:renderTank()
  if self.activeTab == "stats" then self:renderStats() end
end

function ArjUI:onRoomInfo()
  if not gmcp or not gmcp.Room or not gmcp.Room.Info then return end
  local r = gmcp.Room.Info
  self.state.room = r.name or self.state.room
  self.state.coloredRoom = r.colored_name or r.name or self.state.room
  self.state.area = tostring(r.area or r.zone or self.state.area)
  self.state.coloredArea = r.colored_area or r.area or self.state.area
  self.state.roomId = r.num or self.state.roomId
  self.state.zoneId = r.zone or self.state.zoneId
  if r.exits then
    self.state.exits = {}
    self.state.exitsRaw = {}
    for dir, _ in pairs(r.exits) do
      local cleanDir = dir:gsub("#", ""):gsub("%s+", "")
      table.insert(self.state.exits, cleanDir:sub(1,1):upper())
      table.insert(self.state.exitsRaw, cleanDir:lower())
    end
    table.sort(self.state.exits)
  end
  self.state.doors = (type(r.doors) == "table") and r.doors or {}
  self.state.npcs = r.npcs or {}
  self.state.items = r.items or {}
  self.state.players = r.players or {}
  
  self:renderRoom()
  self:renderMobs()
  self:renderItems()
  self:renderPlayers()
  if self.activeTab == "stats" then self:renderStats() end
end

function ArjUI:onCombatUpdate()
  if not gmcp or not gmcp.Combat or not gmcp.Combat.Update then return end
  local c = gmcp.Combat.Update
  if type(c) ~= "table" then return end
  
  -- Per-round damage dealt by us (Combat.Update.round {attacker, damage, damageType, critical})
  if type(c.round) == "table" and c.round.damage and self.addDamage then
    self.damage.gmcpAvailable = true
    local atk = tostring(c.round.attacker or ""):lower()
    local me = (self.playerName or ""):lower()
    if atk == "you" or (me ~= "" and atk == me) then
      self:addDamage(toNum(c.round.damage), "gmcp")
    end
  end
  
  -- Handle tank info if provided (rescue, swap, flee changes)
  if type(c.tank) == "table" then
    local t = c.tank
    local tankName = t.name or ""
    local myName = self.playerName or ""
    
    if tankName:lower() == myName:lower() then
      -- I am the tank
      self.state.iAmTank = true
    else
      -- Someone else is tanking
      self.state.iAmTank = false
      self.state.tank = tankName
      self.state.tankPos = t.position or self.state.tankPos
      self.state.tankCond = t.health or t.condition or self.state.tankCond
      self.state.tankHpPct = toNum(pick(t, "healthPercent", "hpPercent", "hp_pct")) or self:conditionToPercent(self.state.tankCond)
    end
    self:renderTank()
  end
  
  -- Handle target/enemy info
  -- Mudlet decodes JSON null as a truthy sentinel, not Lua nil.
  if type(c.target) == "table" then
    local t = c.target
    self.state.target = t.name or "Unknown"
    self.state.targetHpPct = toNum(pick(t, "healthPercent", "hpPercent", "hp_pct")) or self.state.targetHpPct
    self.state.targetCond = t.health or self.state.targetCond
    self.state.targetPos = t.position or self.state.targetPos
    
    -- Track if target is bleeding to death (only exact match, for persistence)
    local condLower = (self.state.targetCond or ""):lower()
    if condLower:find("bleeding to death") then
      self.state.targetBleeding = true
    else
      self.state.targetBleeding = false
    end
    
    -- Clear the clear timer if we got fresh target data
    if self._targetClearTimer then 
      killTimer(self._targetClearTimer)
      self._targetClearTimer = nil
    end
  elseif c.target ~= nil then
    self.state.target = nil
    self.state.targetHpPct = 100
    self.state.targetCond, self.state.targetPos, self.state.targetBleeding = nil, nil, false
    self.state.fighting, self.state.tank, self.state.tankCond, self.state.tankHpPct = nil, nil, nil, nil
    self.state.assistTarget, self.state.iAmTank = nil, true
    self:endFight()
    self:renderTank()
  end
  self:renderTarget()
end

function ArjUI:onGroupStatus()
  if not gmcp or not gmcp.Group or not gmcp.Group.Status then return end
  local g = gmcp.Group.Status
  self.state.group = g.members or {}
  self.state.groupSize = toNum(g.size) or #self.state.group
  self.state.groupMax = toNum(g.maxSize) or 0
  self:renderGroup()
  self:renderTank()  -- Update tank when group changes
end

function ArjUI:onCharStatus()
  -- Handle Char.Status for position updates AND player alignment tracking
  if not gmcp or not gmcp.Char or not gmcp.Char.Status then return end
  local s = gmcp.Char.Status
  
  -- Track alignment for any player we receive status for
  if s.name and s.alignment then
    self.state.playerAlignments = self.state.playerAlignments or {}
    self.state.playerAlignments[s.name:lower()] = s.alignment:lower()
    self:renderPlayers()  -- Re-render players with updated alignment
  end
  
  -- Char.Status is only ever about ourselves: record identity fields
  if type(s.name) == "string" and s.name ~= "" then self.playerName = s.name end
  self.state.charLevel = toNum(s.level) or self.state.charLevel
  self.state.charClass = s.class and stripColors(s.class) or self.state.charClass
  self.state.charRace = s.race and stripColors(s.race) or self.state.charRace
  self.state.charGuild = s.guild and stripColors(s.guild) or self.state.charGuild
  self.state.charTitle = s.title and stripColors(s.title) or self.state.charTitle
  
  -- Update our own position if this is about us
  if s.position then self.state.position = s.position end
  self:renderVitals()
  self:renderTank()
  self:renderTarget()
  if self.activeTab == "stats" then self:renderStats() end
  
  -- First Char.Status after connect = character has entered the game
  self:onLoginDetected()
end

function ArjUI:onQuestStatus()
  if not gmcp or not gmcp.Quest or not gmcp.Quest.Status then return end
  local q = gmcp.Quest.Status
  if q.active == true then
    self.state.quest = {
      type = q.type, target = q.target or "",
      remaining = toNum(q.remaining),
      killCount = toNum(q.killCount), killRequired = toNum(q.killRequired),
      mapBought = q.mapBought == true,
    }
  else
    self.state.quest = nil
  end
  if self.activeTab == "stats" then self:renderStats() end
end

function ArjUI:onCommChannel()
  if not gmcp or not gmcp.Comm or not gmcp.Comm.Channel then return end
  local c = gmcp.Comm.Channel
  local channel = c.channel or "unknown"
  local sender = stripColors(c.sender or "Someone")
  local text = stripColors(c.text or "")
  
  -- Parse sender for tells - handle "You -> PlayerName" format for outgoing tells
  local actualSender = sender
  local isOutgoing = false
  if sender:match("^You %-> (.+)$") then
    actualSender = sender:match("^You %-> (.+)$")
    isOutgoing = true
  end
  
  -- Channel names as the server actually emits them (src/net/gmcp.c, chat_presentation.c):
  -- say, tell, gcc (guild), gsay (group), nchat, jchat, petition, wizmsg
  local colors = { tell = "<medium_orchid>", say = "<khaki>", group = "<medium_sea_green>", gsay = "<medium_sea_green>", gtell = "<medium_sea_green>", shout = "<indian_red>", auction = "<plum>", gossip = "<light_gray>", nchat = "<steel_blue>", jchat = "<cadet_blue>", guild = "<dark_orange>", gcc = "<dark_orange>", yell = "<tomato>", petition = "<gold>", wizmsg = "<orchid>" }
  local color = colors[channel] or "<dim_gray>"
  
  -- nchat/jchat carry the speaker's race-war alignment: colour the sender by it
  local senderColored = sender
  if c.alignment then
    local alignColors = { good = "<white>", evil = "<indian_red>", undead = "<medium_purple>", neutral = "<gray>" }
    local ac = alignColors[tostring(c.alignment):lower()]
    if ac then senderColored = ac .. sender .. color end
  end
  local stamp = ""
  if self.settings and self.settings.chatTimestamps then
    local ok, t = pcall(getTime, true, "hh:mm")
    if ok and t then stamp = "<dim_gray>" .. t .. " " end
  end
  local formatted = string.format("%s%s[%s] %s<reset>: %s\n", stamp, color, channel, senderColored, text)
  
  -- Always send to ALL tab
  self.chatBox:cecho(formatted)
  
  -- Route to specific tab based on channel
  local channelLower = channel:lower()
  if channelLower == "tell" or channelLower == "tells" then
    -- Route to private messaging system only (don't echo to TELLS tab)
    if isOutgoing then
      self:handleOutgoingTell(actualSender, text)
    else
      self:handleIncomingTell(actualSender, text)
    end
    return  -- Don't continue to other tabs
  elseif channelLower == "nchat" or channelLower == "newbie" or channelLower == "jchat" then
    self.nchatBox:cecho(formatted)
  elseif channelLower == "say" or channelLower == "yell" or channelLower == "shout" then
    self.roomBox:cecho(formatted)
  elseif channelLower == "gcc" or channelLower == "guild" or channelLower == "clan" then
    self.guildBox:cecho(formatted)
  elseif channelLower == "group" or channelLower == "gtell" or channelLower == "party" or channelLower == "gsay" then
    self.groupChatBox:cecho(formatted)
  end
end

function ArjUI:onCharAffects()
  if not gmcp or not gmcp.Char or not gmcp.Char.Affects then return end
  self.state.affects = gmcp.Char.Affects or {}
  self:renderAffects()
end

-- Debug function to show GMCP player data in chat console
function ArjUI:debugPlayers()
  self.chatBox:cecho("<cyan>── GMCP Room.Info.players ──\n")
  if not gmcp or not gmcp.Room or not gmcp.Room.Info or not gmcp.Room.Info.players then
    self.chatBox:cecho("<dim_gray>No player data available\n")
    return
  end
  local players = gmcp.Room.Info.players
  if #players == 0 then
    self.chatBox:cecho("<dim_gray>No players in room\n")
    return
  end
  for i, p in ipairs(players) do
    self.chatBox:cecho(string.format("<white>Player %d:\n", i))
    for k, v in pairs(p) do
      self.chatBox:cecho(string.format("<dim_gray>  %s = <yellow>%s\n", tostring(k), tostring(v)))
    end
  end
end

-- Register /debugplayers alias

-- ============================================================
-- RENDER FUNCTIONS
-- ============================================================

function ArjUI:getHpBarStyle(pct)
  local r1, g1, b1, r2, g2, b2
  if pct >= 75 then r1,g1,b1,r2,g2,b2 = 16,80,16,32,112,32
  elseif pct >= 50 then r1,g1,b1,r2,g2,b2 = 100,90,16,140,120,32
  elseif pct >= 25 then r1,g1,b1,r2,g2,b2 = 120,60,16,160,80,32
  else r1,g1,b1,r2,g2,b2 = 107,16,16,139,32,32 end
  return string.format("background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 rgb(%d,%d,%d),stop:0.5 rgb(%d,%d,%d),stop:1 rgb(%d,%d,%d)); border: none; border-radius: 2px;", r1,g1,b1,r2,g2,b2,r1,g1,b1)
end

function ArjUI:renderTNLBar()
  local tnl, base = self.state.tnl, self.state.tnlBaseline
  local last = self.state.lastExpGain
  local suffix = last and string.format("   (last +%d)", last) or ""
  if tnl and tnl > 0 and base and base > 0 then
    self.xpGauge:setValue(math.max(0, base - tnl), base, string.format("TNL: %d%s", tnl, suffix))
  elseif tnl and tnl > 0 then
    self.xpGauge:setValue(0, 100, string.format("TNL: %d%s", tnl, suffix))
  else
    self.xpGauge:setValue(0, 100, "TNL")
  end
end

function ArjUI:renderVitals()
  local s = self.state
  local hpPct = s.hpmax > 0 and math.floor((s.hp / s.hpmax) * 100) or 100
  self.hpGauge.front:setStyleSheet(self:getHpBarStyle(hpPct))
  self.hpGauge:setValue(s.hp, s.hpmax, string.format("HP %d/%d", s.hp, s.hpmax))
  if s.usesMana == false then
    self.mpGauge:setValue(0, 1, "MP n/a")
  else
    self.mpGauge:setValue(s.mana, s.manamax, string.format("MP %d/%d", s.mana, s.manamax))
  end
  self.mvGauge:setValue(s.move, s.movemax, string.format("MV %d/%d", s.move, s.movemax))
  
  local posText = string.upper(s.position or "Standing")
  self.posLabel:echo(posText)
  if posText ~= "STANDING" then
    self.posLabel:setStyleSheet(self.styles.posAlert)
  else
    self.posLabel:setStyleSheet(self.styles.pos)
  end
end

function ArjUI:renderRoom()
  -- Use colored area/room names if available
  local coloredArea = self.state.coloredArea or self.state.area or "Unknown Area"
  local coloredRoom = self.state.coloredRoom or self.state.room or ""
  self.areaLabel:decho(durisToDecho(coloredArea))
  self.roomLabel:decho(durisToDecho(coloredRoom))
  self.areaLabel:setToolTip(stripColors(tostring(coloredArea)))
  self.roomLabel:setToolTip(stripColors(tostring(coloredRoom)))
  self:renderExits()
end


function ArjUI:renderExits()
  -- Static exit button layout so positions never swap when exits update
  if not self.exitButtonsStatic then
    self.exitButtonsStatic = {}

    -- clear container once
    self.exitsWrap:echo("")

    -- Prefix label
    local prefix = Geyser.Label:new({ name = "ArjUI_ExitPrefix", x = 0, y = 0, width = 32, height = "100%" }, self.exitsWrap)
    prefix:setStyleSheet("background-color: transparent; color: #606070; font-size: 10px;")
    prefix:echo("Exits:")
    self.exitButtonsStatic.prefix = prefix

    -- Fixed slots using pixel offsets from prefix (more reliable for small panel)
    local slots = {
      n  = { x = 34,  label = "N",  cmd = "north" },
      e  = { x = 48,  label = "E",  cmd = "east"  },
      s  = { x = 62,  label = "S",  cmd = "south" },
      w  = { x = 76,  label = "W",  cmd = "west"  },
      u  = { x = 90,  label = "U",  cmd = "up"    },
      d  = { x = 104, label = "D",  cmd = "down"  },

      ne = { x = 120, label = "NE", cmd = "northeast" },
      nw = { x = 140, label = "NW", cmd = "northwest" },
      se = { x = 160, label = "SE", cmd = "southeast" },
      sw = { x = 180, label = "SW", cmd = "southwest" },

      ["in"]  = { x = 120, label = "IN",  cmd = "in"  },
      out = { x = 140, label = "OUT", cmd = "out" },
    }

    for key, info in pairs(slots) do
      local w = (info.label:len() == 1) and 12 or 18
      local btn = Geyser.Label:new({ name = "ArjUI_Exit_" .. key, x = info.x, y = 2, width = w, height = "85%" }, self.exitsWrap)
      btn:setStyleSheet(self.styles.exitButton)
      btn:echo("<center>" .. info.label .. "</center>")
      btn:setOnEnter(function() btn:setStyleSheet(self.styles.exitButtonHover); btn:setCursor("PointingHand") end)
      btn:setOnLeave(function() btn:setStyleSheet(self.styles.exitButton); btn:setCursor("Arrow") end)
      btn:hide()

      -- store intended send() command
      btn._cmd = info.cmd
      self.exitButtonsStatic[key] = btn
    end
  end

  -- Hide all buttons, then show only active exits
  for k, btn in pairs(self.exitButtonsStatic) do
    if k ~= "prefix" and btn and btn.hide then btn:hide() end
  end

  local exits = self.state.exitsRaw or {}
  if #exits == 0 then
    -- keep prefix visible; no exits
    return
  end

  -- exitsRaw contains full direction strings (lowercase). We map them to slots.
  for _, dir in ipairs(exits) do
    local d = (dir or ""):lower()

    -- map possible strings to our slot keys
    local keyMap = {
      north="n", n="n",
      east="e", e="e",
      south="s", s="s",
      west="w", w="w",
      up="u", u="u",
      down="d", d="d",
      northeast="ne", ne="ne",
      northwest="nw", nw="nw",
      southeast="se", se="se",
      southwest="sw", sw="sw",
      ["in"]="in",
      out="out",
    }

    local key = keyMap[d]
    local btn = key and self.exitButtonsStatic[key] or nil
    if btn then
      btn:show()
      local cmd = btn._cmd or d
      -- Room.Info.doors[dir] = { name, closed, locked } when the exit has a door
      local door = key and self.state.doors and self.state.doors[key] or nil
      local baseStyle = self.styles.exitButton
      if door and door.closed then
        baseStyle = door.locked and self.styles.exitButtonLocked or self.styles.exitButtonClosed
      end
      btn._baseStyle = baseStyle
      btn:setStyleSheet(baseStyle)
      btn:setOnLeave(function() btn:setStyleSheet(btn._baseStyle or self.styles.exitButton); btn:setCursor("Arrow") end)
      btn:setClickCallback(function() send(cmd) end)
    end
  end
end

function ArjUI:renderMobs()
  self.mobsBox:clear()
  local npcs = self.state.npcs or {}
  if #npcs == 0 then self.mobsBox:cecho("<dim_gray>(none)\n"); return end
  
  -- Track by keyword, preserve colored_name for display
  -- Room.Info.npcs[].fighting = "you" | player name | npc name | "someone" | "someone who has already left"
  local counts, order, coloredNames, fighting = {}, {}, {}, {}
  for _, npc in ipairs(npcs) do
    local keyword = npc.keyword or npc.name or "unknown"
    local colored = npc.colored_name or npc.name or keyword
    if keyword ~= "" then
      if not counts[keyword] then 
        counts[keyword] = 0
        table.insert(order, keyword)
        coloredNames[keyword] = colored
      end
      counts[keyword] = counts[keyword] + 1
      if type(npc.fighting) == "string" and npc.fighting ~= "" then
        -- prefer "you" over any other opponent when several share a keyword
        if npc.fighting == "you" or not fighting[keyword] then fighting[keyword] = npc.fighting end
      end
    end
  end
  
  for _, keyword in ipairs(order) do
    local count = counts[keyword]
    local colored = coloredNames[keyword] or keyword
    local coloredDisplay = durisToDecho(colored)
    local tag = ""
    local f = fighting[keyword]
    if f == "you" then
      tag = " <220,60,60>[vs YOU]"
    elseif f and not f:find("^someone") then
      tag = string.format(" <200,160,60>[vs %s]", stripColors(f):sub(1, 12))
    elseif f then
      tag = " <140,140,140>[fighting]"
    end
    local text = count > 1 and string.format("%s <128,128,128>(x%d)%s\n", coloredDisplay, count, tag) or string.format("%s%s\n", coloredDisplay, tag)
    self.mobsBox:dechoLink(text, function()
      self:showContextMenu(self:getContextMenuItems("mobs", keyword))
    end, "Click for options", true)
  end
end

function ArjUI:renderItems()
  self.objsBox:clear()
  local items = self.state.items or {}
  if #items == 0 then self.objsBox:cecho("<dim_gray>(none)\n"); return end
  
  -- Track by name (for commands), preserve colored_name for display
  local counts, order, coloredNames = {}, {}, {}
  for _, item in ipairs(items) do
    local name = item.name or "something"
    local colored = item.colored_name or name
    if not counts[name] then 
      counts[name] = 0
      table.insert(order, name)
      coloredNames[name] = colored
    end
    counts[name] = counts[name] + 1
  end
  
  for _, name in ipairs(order) do
    local count = counts[name]
    local colored = coloredNames[name] or name
    local coloredDisplay = durisToDecho(colored)
    local cmdName = normalizeTargetName(name)
    local text = count > 1 and string.format("%s <128,128,128>(x%d)\n", coloredDisplay, count) or string.format("%s\n", coloredDisplay)
    self.objsBox:dechoLink(text, function()
      local target = durisTargetKey(cmdName)
      self:showContextMenu(self:getContextMenuItems("objects", target))
    end, "Click for options", true)
  end
end

function ArjUI:renderPlayers()
  self.enemyBox:clear()
  local players = self.state.players or {}
  if #players == 0 then self.enemyBox:decho("<100,100,100>(none)\n"); return end
  
  local alignments = self.state.playerAlignments or {}
  
  for _, p in ipairs(players) do
    local name = p.name or "Someone"
    local displayName = normalizeTargetName(name)
    local cmdName = displayName  -- Use clean name for commands
    
    -- Check for alignment in player data from Room.Info, or from our tracked alignments
    local alignment = p.alignment or alignments[name:lower()] or "unknown"
    if type(alignment) == "string" then alignment = alignment:lower() end
    
    -- Color based on alignment: good=white, evil=red, neutral=gray
    local color
    if alignment == "evil" then
      color = "<220,60,60>"  -- Red for evil
    elseif alignment == "good" then
      color = "<220,220,220>"  -- White for good
    else
      color = "<140,140,140>"  -- Gray for neutral/unknown
    end
    
    -- Use unified context menu system for players
    local target = quoteIfNeeded(cmdName)
    self.enemyBox:dechoLink(string.format("%s%s\n", color, displayName), function()
      self:showContextMenu(self:getContextMenuItems("players", target))
    end, "Click for options", true)
  end
end

function ArjUI:renderTarget()
  if self.state.target then
    local pct = self.state.targetHpPct or 100
    local cond = self.state.targetCond or ""
    local condLower = cond:lower()
    
    -- Only show DEAD if condition explicitly contains "dead" as a word (not "bleeding to death")
    local isDead = (condLower == "dead" or condLower:find("^dead") or condLower:find("corpse"))
    
    if isDead then
      self.targetNameLabel:echo(self.state.target .. " [DEAD]")
      self.targetNameLabel:setStyleSheet(self.styles.targetDead)
      self.targetHpGauge.front:setStyleSheet(self.gaugeStyles.deadFront)
      self.targetHpGauge.back:setStyleSheet(self.gaugeStyles.deadBack)
      self.targetHpGauge:setValue(0, 100, "DEAD")
    else
      self.targetNameLabel:echo(self.state.target)
      self.targetNameLabel:setStyleSheet(self.styles.targetName)
      -- Use at least 1% so the bar shows something even when very low
      local displayPct = math.max(1, pct)
      self.targetHpGauge.front:setStyleSheet(self:getHpBarStyle(pct))
      self.targetHpGauge.back:setStyleSheet(self.gaugeStyles.targetBack)
      self.targetHpGauge:setValue(displayPct, 100, string.format("%d%% %s", pct, cond))
    end
    local tpos = upper3(self.state.targetPos)
    self.targetPosLabel:echo(tpos)
    self.targetPosLabel:setStyleSheet(tpos ~= "" and tpos ~= "STA" and self.styles.posAlert or self.styles.pos)
  else
    self.targetNameLabel:echo("No Target")
    self.targetNameLabel:setStyleSheet(self.styles.targetName)
    self.targetPosLabel:echo("")
    self.targetPosLabel:setStyleSheet(self.styles.pos)
    self.targetHpGauge.front:setStyleSheet(self.gaugeStyles.targetFront)
    self.targetHpGauge.back:setStyleSheet(self.gaugeStyles.targetBack)
    self.targetHpGauge:setValue(0, 100, "")
  end
end

-- Find group member by name and update assist target info
function ArjUI:updateAssistTarget()
  local assistName = self.state.assistTarget
  if not assistName then return end
  
  local members = self.state.group or {}
  for _, mem in ipairs(members) do
    local name = mem.name or ""
    if name:lower() == assistName:lower() or name:lower():find(assistName:lower()) then
      self.state.tank = mem.name
      self.state.tankHp = toNum(pick(mem, "hp", "health"))
      self.state.tankMaxHp = toNum(pick(mem, "maxHp", "maxhp", "max_health"))
      self.state.tankPos = mem.position
      self.state.tankCond = mem.condition or mem.health_desc
      return
    end
  end
end

function ArjUI:renderTank()
  local s = self.state
  
  -- If someone else is tanking (from combat prompt T:), show their info
  if not s.iAmTank and s.tank and s.tank ~= "" then
    local displayName = s.tank
    self.tankNameLabel:echo(displayName)
    self.tankNameLabel:setStyleSheet(self.styles.tankName)
    
    local tpos = upper3(s.tankPos)
    self.tankPosLabel:echo(tpos)
    self.tankPosLabel:setStyleSheet(tpos ~= "" and tpos ~= "STA" and self.styles.posAlert or self.styles.pos)
    
    -- Use tankHpPct from combat prompt condition parsing
    local pct = s.tankHpPct or 100
    local cond = s.tankCond or ""
    
    self.tankHpGauge.front:setStyleSheet(self:getHpBarStyle(pct))
    self.tankHpGauge:setValue(pct, 100, string.format("%d%% %s", pct, cond))
  else
    -- Show self (You) - I am the tank or no combat
    s.tank = self.playerName or "You"
    s.tankHp = s.hp
    s.tankMaxHp = s.hpmax
    s.tankPos = s.position
    s.iAmTank = true
    
    self.tankNameLabel:echo(s.tank or "You")
    self.tankNameLabel:setStyleSheet(self.styles.tankNameMe)
    
    local tpos = upper3(s.tankPos)
    self.tankPosLabel:echo(tpos)
    self.tankPosLabel:setStyleSheet(tpos ~= "" and tpos ~= "STA" and self.styles.posAlert or self.styles.pos)
    
    local thp = s.tankHp or s.hp or 0
    local tmax = s.tankMaxHp or s.hpmax or 1
    -- Handle negative HP (dying) - clamp to 0 for percentage but show actual value
    local displayHp = thp
    local pct = tmax > 0 and math.max(0, math.floor((thp / tmax) * 100)) or 0
    -- If HP is negative, show critical state
    if thp < 0 then pct = 0 end
    
    self.tankHpGauge.front:setStyleSheet(self:getHpBarStyle(pct))
    local hpText = string.format("HP %d/%d", displayHp, tmax)
    local pctText = string.format("%d%%", pct)
    self.tankHpGauge:setValue(math.max(0, thp), tmax, hpText .. "        " .. pctText)
  end
end

function ArjUI:clearGroupWidgets(shrinking)
  for _, w in pairs(self.groupWidgets or {}) do
    if w.container then
      -- Qt defers deletion and does not recompute ScrollBox extents on child
      -- removal. Hide departing rows first when shrinking to clamp scrolling.
      if shrinking then w.container:hide() end
      self:disposeWidget(w.container)
    end
  end
  self.groupWidgets = {}
end

function ArjUI:getGroupHpStyle(pct)
  if pct < 25 then
    return "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #6b1010,stop:0.5 #8b2020,stop:1 #6b1010); border: none; border-radius: 2px;"
  elseif pct < 50 then
    return "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #6b4010,stop:0.5 #8b5520,stop:1 #6b4010); border: none; border-radius: 2px;"
  elseif pct < 75 then
    return "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #4a6b10,stop:0.5 #608b20,stop:1 #4a6b10); border: none; border-radius: 2px;"
  else
    return "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #106b30,stop:0.5 #208b45,stop:1 #106b30); border: none; border-radius: 2px;"
  end
end

function ArjUI:renderGroup()
  local members = self.state.group or {}
  self:clearGroupWidgets(#members < (self.groupMemberCount or 0))
  self.groupMemberCount = #members
  
  -- Styles
  local headerStyle = "background-color: transparent; color: #50c878; font-size: 10px; font-weight: bold; qproperty-alignment: 'AlignLeft';"
  local nameStyle = "background-color: transparent; color: #d0d0d0; font-size: 9px; font-weight: bold; qproperty-alignment: 'AlignLeft';"
  local posStyle = "background-color: transparent; color: #888888; font-size: 9px; qproperty-alignment: 'AlignRight';"
  local posAlertStyle = "background-color: transparent; color: #ff6666; font-size: 9px; font-weight: bold; qproperty-alignment: 'AlignRight';"
  local gaugeBack = "background-color: #08080c; border: 1px solid #153015; border-radius: 3px;"
  local mvFront = "background-color: qlineargradient(x1:0,y1:0,x2:1,y2:0,stop:0 #105050,stop:0.5 #207070,stop:1 #105050); border: none; border-radius: 2px;"
  local gaugeText = "color: #e0e0e0; font-size: 8px; font-weight: bold;"
  
  if #members == 0 then 
    local soloLabel = Geyser.Label:new({ name = "ArjUI_GroupSolo", x = "2%", y = "2%", width = "90%", height = "40%" }, self.groupContainer)
    soloLabel:setStyleSheet(headerStyle)
    soloLabel:echo("── Group ──<br/>(solo)<br/>Type 'group &lt;name&gt;' to invite")
    self.groupWidgets.solo = { container = soloLabel }
    return 
  end
  
  -- Header
  local header = Geyser.Label:new({ name = "ArjUI_GroupHeader", x = "2%", y = 0, width = "90%", height = 22 }, self.groupContainer)
  header:setStyleSheet(headerStyle)
  local sizeText = tostring(self.state.groupSize or #members)
  if (self.state.groupMax or 0) > 0 then sizeText = sizeText .. "/" .. self.state.groupMax end
  header:echo("── Group (" .. sizeText .. ") ──")
  self.groupWidgets.header = { container = header }
  
  -- Keep rows readable at every group size; overflow scrolls within the panel.
  local yOffset = 26
  local rowHeight = 38
  
  -- Find the most hurt player (not NPC, in room) so their name can be highlighted
  local weakestIdx, weakestPct = nil, 100
  for i, mem in ipairs(members) do
    local hp = toNum(pick(mem, "hp", "health", "hitpoints"))
    local maxHp = toNum(pick(mem, "maxHp", "maxhp", "max_health", "hpmax"))
    if hp and maxHp and maxHp > 0 and mem.isNpc ~= true and mem.inRoom ~= false then
      local p = math.floor((hp / maxHp) * 100)
      if p < weakestPct then weakestIdx, weakestPct = i, p end
    end
  end
  if weakestPct >= 100 then weakestIdx = nil end
  
  for i, mem in ipairs(members) do
    local name = mem.name or "Unknown"
    local displayName = normalizeTargetName(name)
    local hp = toNum(pick(mem, "hp", "health", "hitpoints"))
    local maxHp = toNum(pick(mem, "maxHp", "maxhp", "max_health", "hpmax"))
    local pos = mem.position or "sta"
    local cond = mem.condition or mem.health_desc or ""
    
    -- Calculate HP% - use condition if no numeric HP available
    local hpPct
    if hp and maxHp and maxHp > 0 then
      hpPct = math.floor((hp / maxHp) * 100)
    elseif hp and hp > 0 and hp <= 100 then
      -- HP might already be a percentage
      hpPct = hp
    else
      hpPct = 100
    end
    
    local posUpper = (pos or ""):upper():sub(1,3)
    local isAlert = posUpper ~= "STA" and posUpper ~= ""
    local inRoom = (mem.inRoom ~= false)  -- Group.Status.members[].inRoom
    local mv = toNum(pick(mem, "move", "mv"))
    local maxMv = toNum(pick(mem, "maxMove", "maxmove", "maxMv"))
    local mvPct = (mv and maxMv and maxMv > 0) and math.floor((mv / maxMv) * 100) or nil
    
    -- Container for this member (percentage-based positioning)
    local memContainer = Geyser.Container:new({ 
      name = "ArjUI_GroupMem_" .. i, 
      x = "2%", y = yOffset,
      width = "90%", height = rowHeight
    }, self.groupContainer)
    
    -- Name label (left)
    local nameLabel = Geyser.Label:new({ name = "ArjUI_GroupName_" .. i, x = 0, y = 0, width = "52%", height = "45%" }, memContainer)
    local thisNameStyle = nameStyle
    if not inRoom then thisNameStyle = nameStyle:gsub("#d0d0d0", "#707070")
    elseif i == weakestIdx then thisNameStyle = nameStyle:gsub("#d0d0d0", "#ff8080") end
    nameLabel:setStyleSheet(thisNameStyle)
    nameLabel:echo(displayName:sub(1, mem.isNpc and 13 or 14) .. (mem.isNpc and "*" or ""))
    nameLabel:setToolTip(displayName)
    nameLabel:setClickCallback(function()
      self:showContextMenu(self:getContextMenuItems("players", name))
    end)
    nameLabel:setOnEnter(function() nameLabel:setCursor("PointingHand") end)
    nameLabel:setOnLeave(function() nameLabel:setCursor("Arrow") end)
    
    -- Moves (middle) - coloured by how spent they are
    local mvLabel = Geyser.Label:new({ name = "ArjUI_GroupMv_" .. i, x = "52%", y = 0, width = "20%", height = "45%" }, memContainer)
    if mvPct then
      local mvColor = mvPct < 33 and "#ff6060" or (mvPct < 70 and "#d4a855" or "#60a080")
      mvLabel:setStyleSheet((posStyle:gsub("#888888", mvColor)))
      mvLabel:echo(mvPct .. "mv")
    else
      mvLabel:setStyleSheet(posStyle)
      mvLabel:echo("")
    end
    
    -- Position label (right)
    local posLabel = Geyser.Label:new({ name = "ArjUI_GroupPos_" .. i, x = "72%", y = 0, width = "28%", height = "45%" }, memContainer)
    posLabel:setStyleSheet(isAlert and posAlertStyle or posStyle)
    posLabel:echo(inRoom and ("[" .. posUpper .. "]") or "[AWAY]")
    
    -- HP gauge with condition text
    local hpGauge = Geyser.Gauge:new({ name = "ArjUI_GroupHP_" .. i, x = 0, y = "50%", width = "100%", height = "45%" }, memContainer)
    hpGauge.front:setStyleSheet(self:getGroupHpStyle(hpPct))
    hpGauge.back:setStyleSheet(gaugeBack)
    hpGauge.text:setStyleSheet(gaugeText)
    local hpText
    if hp and maxHp and maxHp > 0 then
      local missing = maxHp - hp
      hpText = missing > 0 and string.format("%d/%d  -%d", hp, maxHp, missing) or string.format("%d/%d", hp, maxHp)
    elseif cond ~= "" then
      hpText = string.format("%d%% %s", hpPct, cond)
    else
      hpText = string.format("HP %d%%", hpPct)
    end
    hpGauge:setValue(hpPct, 100, hpText)
    
    self.groupWidgets[i] = { 
      container = memContainer, 
      nameLabel = nameLabel, 
      mvLabel = mvLabel,
      posLabel = posLabel,
      hpGauge = hpGauge
    }
    
    yOffset = yOffset + rowHeight + 4
  end
end

-- TAB SWITCHING
function ArjUI:switchTab(tabName)
  if self.activeTab == tabName then
    -- If clicking same tab, refresh the data
    self:requestTabData(tabName)
    return
  end
  
  -- Hide current panel
  if self.tabPanels[self.activeTab] then
    self.tabPanels[self.activeTab]:hide()
  end
  
  -- Show new panel
  self.activeTab = tabName
  if self.tabPanels[tabName] then
    self.tabPanels[tabName]:show()
  end
  
  self:updateTabStyles()
  self:renderActiveTab()
  
  -- Auto-request data if tab is empty
  local hasData = false
  if tabName == "stats" then hasData = self.state.statsRaw and #self.state.statsRaw > 0
  elseif tabName == "skills" then hasData = self.state.skillsRaw and #self.state.skillsRaw > 0
  elseif tabName == "inv" then hasData = self.state.invRaw and #self.state.invRaw > 0
  elseif tabName == "eq" then hasData = self.state.eqRaw and #self.state.eqRaw > 0
  elseif tabName == "group" then hasData = true  -- Group always has data from GMCP
  elseif tabName == "ship" then hasData = self.state.ship and (self.state.ship.contacts or self.state.ship.textContacts) and true or false
  end
  
  if not hasData then
    self:requestTabData(tabName)
  end
end

function ArjUI:updateTabStyles()
  local activeStyle = "background-color: #16140f; border: 1px solid #5a4b37; border-top: 1px solid #8c6e46; border-bottom: none; color: #e6e6e6; font-size: 8px; font-weight: bold;"
  local inactiveStyle = "background-color: #0a0908; border: 1px solid #3c3832; color: #706050; font-size: 8px;"
  
  for name, btn in pairs(self.tabButtons) do
    if name == self.activeTab then
      btn:setStyleSheet(activeStyle)
    else
      btn:setStyleSheet(inactiveStyle)
    end
  end
end

-- CHAT TAB SWITCHING
function ArjUI:switchChatTab(tabName)
  if self.activeChatTab == tabName then return end
  
  -- Hide current panel
  if self.chatPanels[self.activeChatTab] then
    self.chatPanels[self.activeChatTab]:hide()
  end
  
  -- Show new panel
  self.activeChatTab = tabName
  if self.chatPanels[tabName] then
    self.chatPanels[tabName]:show()
  end
  
  self:updateChatTabStyles()
end

function ArjUI:updateChatTabStyles()
  local activeStyle = "background-color: #16140f; border: 1px solid #5a4b37; border-top: 1px solid #8c6e46; border-bottom: none; color: #e6e6e6; font-size: 7px; font-weight: bold;"
  local inactiveStyle = "background-color: #0a0908; border: 1px solid #3c3832; color: #706050; font-size: 7px;"
  
  for name, btn in pairs(self.chatTabs) do
    if name == self.activeChatTab then
      btn:setStyleSheet(activeStyle)
    else
      btn:setStyleSheet(inactiveStyle)
    end
  end
end

function ArjUI:renderActiveTab()
  if self.activeTab == "group" then
    self:renderGroup()
  elseif self.activeTab == "stats" then
    self:renderStats()
  elseif self.activeTab == "inv" then
    self:renderInventory()
  elseif self.activeTab == "eq" then
    self:renderEq()
  elseif self.activeTab == "who" then
    self:renderWho()
  elseif self.activeTab == "ship" then
    self:renderShip()
  end
end

function ArjUI:renderStats()
  self.statsBox:clear()
  local s = self.state
  self.statsBox:cecho("<dim_gray>── Live Stats ──\n\n")
  -- Identity (Char.Status: sent on login and level change)
  if self.playerName or s.charLevel then
    local ident = self.playerName or "You"
    if s.charLevel then ident = ident .. string.format(" <dim_gray>L<white>%d", s.charLevel) end
    if s.charClass and s.charClass ~= "" then ident = ident .. " <gold>" .. s.charClass end
    if s.charRace and s.charRace ~= "" then ident = ident .. " <dim_gray>(" .. s.charRace .. ")" end
    self.statsBox:cecho("<white>" .. ident .. "\n")
    if s.charGuild and s.charGuild ~= "" then
      self.statsBox:cecho("<dim_gray>Guild: <dark_orange>" .. s.charGuild .. "\n")
    end
    self.statsBox:cecho("\n")
  end
  self.statsBox:cecho(string.format("<medium_sea_green>HP: <white>%d<dim_gray>/<white>%d\n", s.hp or 0, s.hpmax or 0))
  if s.usesMana == false then
    self.statsBox:cecho("<steel_blue>Mana: <dim_gray>n/a\n")
  else
    self.statsBox:cecho(string.format("<steel_blue>Mana: <white>%d<dim_gray>/<white>%d\n", s.mana or 0, s.manamax or 0))
  end
  self.statsBox:cecho(string.format("<khaki>Move: <white>%d<dim_gray>/<white>%d\n", s.move or 0, s.movemax or 0))
  self.statsBox:cecho(string.format("<medium_orchid>TNL: <white>%d\n", s.tnl or 0))
  self.statsBox:cecho(string.format("<dim_gray>Position: <white>%s\n", s.position or "unknown"))
  if s.fighting then
    self.statsBox:cecho(string.format("<dim_gray>Fighting: <indian_red>%s\n", s.fighting))
  end
  -- Coins (Char.Vitals: platinum/gold/silver/copper)
  local c = s.coins or {}
  self.statsBox:cecho(string.format("<dim_gray>Coins: <white>%dp <gold>%dg <light_gray>%ds <sandy_brown>%dc\n",
    c.platinum or 0, c.gold or 0, c.silver or 0, c.copper or 0))
  self.statsBox:cecho(string.format("<dim_gray>Area: <cyan>%s\n", s.area or "Unknown"))
  self.statsBox:cecho(string.format("<dim_gray>Room: <white>%s\n", s.room or "Unknown"))
  -- Quest (Quest.Status)
  local q = s.quest
  if q then
    local line = stripColors(q.target)
    if q.type == "kill" and q.killRequired then
      line = string.format("%s <dim_gray>(%d/%d)", line, q.killCount or 0, q.killRequired)
    end
    if q.remaining then line = line .. string.format(" <dim_gray>(%d more today)", q.remaining) end
    if q.mapBought then line = line .. " <dim_gray>[map]" end
    self.statsBox:cecho("\n<dim_gray>Quest: <gold>" .. line .. "\n")
  end
  self.statsBox:cecho("\n<dim_gray>Click tab to send 'score'\n")
end

function ArjUI:renderInventory()
  self.invBox:clear()
  local inv = self.state.inventory
  
  if inv and inv.lines and #inv.lines > 0 then
    if inv.header then
      self.invBox:decho("<128,128,128>" .. stripColors(inv.header) .. "\n\n")
    end
    for _, itemLine in ipairs(inv.lines) do
      local coloredLine = durisToDecho(itemLine)
      self.invBox:decho(coloredLine .. "\n")
    end
  else
    self.invBox:cecho("<dim_gray>── Inventory ──\n\n")
    self.invBox:cecho("<dim_gray>(click tab to refresh)\n")
  end
end

function ArjUI:renderEq()
  self.eqBox:clear()
  local eq = self.state.equipment
  
  if eq and eq.lines and #eq.lines > 0 then
    self.eqBox:decho("<128,128,128>── Equipment ──\n\n")
    for _, eqLine in ipairs(eq.lines) do
      local coloredLine = durisToDecho(eqLine)
      self.eqBox:decho(coloredLine .. "\n")
    end
  else
    self.eqBox:cecho("<dim_gray>── Equipment ──\n\n")
    self.eqBox:cecho(eq and "<dim_gray>You aren't wearing anything!\n" or "<dim_gray>(click tab to refresh)\n")
  end
end

function ArjUI:renderWho()
  self.whoBox:clear()
  local who = self.state.whoList
  
  if who and who.lines and #who.lines > 0 then
    self.whoBox:decho("<128,128,128>── Who's Online ──\n\n")
    for _, whoLine in ipairs(who.lines) do
      local coloredLine = durisToDecho(whoLine)
      self.whoBox:decho(coloredLine .. "\n")
    end
  else
    self.whoBox:cecho("<dim_gray>── Who's Online ──\n\n")
    self.whoBox:cecho("<dim_gray>(click tab to refresh)\n")
  end
end

function ArjUI:renderAffects()
  -- Render buffs (positive affects) to buffsBox
  self.buffsBox:clear()
  -- Render debuffs (negative affects) to debuffsBox  
  self.debuffsBox:clear()
  
  local affects = self.state.affects or {}
  local buffs = {}
  local debuffs = {}
  
  -- Known debuff patterns (negative effects)
  local debuffPatterns = {
    "blind", "poison", "curse", "disease", "plague", "slow", "weak", 
    "fear", "stun", "paralyze", "silence", "confuse", "charm", "sleep",
    "bleed", "burn", "frost", "shock", "drain", "doom", "hex", "jinx"
  }
  
  local function isDebuff(name)
    local lower = name:lower()
    for _, pattern in ipairs(debuffPatterns) do
      if lower:find(pattern) then return true end
    end
    return false
  end
  
  -- Process affects into buffs/debuffs
  local function processAffect(name, duration)
    if type(name) ~= "string" then return end
    local entry = { name = name, duration = duration }
    if isDebuff(name) then
      table.insert(debuffs, entry)
    else
      table.insert(buffs, entry)
    end
  end
  
  if #affects > 0 then
    for _, aff in ipairs(affects) do
      local name = aff.name or aff
      local duration = aff.duration or aff.time or aff.remaining
      processAffect(name, duration)
    end
  else
    for name, info in pairs(affects) do
      local duration = type(info) == "table" and info.duration or (type(info) == "number" and info or nil)
      processAffect(name, duration)
    end
  end
  
  -- Render buffs in horizontal flow (columns)
  -- Format: "name (Xm)" with proper spacing between items
  local maxCols = 2    -- 2 columns with good spacing
  local colWidth = 18  -- wider columns for readability
  
  if #buffs == 0 then
    self.buffsBox:cecho("<dim_gray>(none)\n")
  else
    local col = 0
    for _, buff in ipairs(buffs) do
      local mins = buff.duration and tonumber(buff.duration) and math.floor(tonumber(buff.duration) / 60) or nil
      local text
      if mins and mins > 0 then
        local name = buff.name:sub(1, 10)  -- truncate name to 10 chars
        text = string.format("%s (%dm)", name, mins)
      else
        text = buff.name:sub(1, 14)
      end
      -- Pad to column width with space between columns
      text = text .. string.rep(" ", math.max(1, colWidth - #text))
      self.buffsBox:cecho(string.format("<medium_sea_green>%s", text))
      col = col + 1
      if col >= maxCols then
        self.buffsBox:echo("\n")
        col = 0
      end
    end
    if col > 0 then self.buffsBox:echo("\n") end
  end
  
  -- Render debuffs in horizontal flow (columns)
  if #debuffs == 0 then
    self.debuffsBox:cecho("<dim_gray>(none)\n")
  else
    local col = 0
    for _, debuff in ipairs(debuffs) do
      local mins = debuff.duration and tonumber(debuff.duration) and math.floor(tonumber(debuff.duration) / 60) or nil
      local text
      if mins and mins > 0 then
        local name = debuff.name:sub(1, 10)  -- truncate name to 10 chars
        text = string.format("%s (%dm)", name, mins)
      else
        text = debuff.name:sub(1, 14)
      end
      -- Pad to column width with space between columns
      text = text .. string.rep(" ", math.max(1, colWidth - #text))
      self.debuffsBox:cecho(string.format("<indian_red>%s", text))
      col = col + 1
      if col >= maxCols then
        self.debuffsBox:echo("\n")
        col = 0
      end
    end
    if col > 0 then self.debuffsBox:echo("\n") end
  end
end

function ArjUI:renderTime()
  if not self.timeLabel then return end
  local t = self.state.timeOfDay or "day"
  local icon, color, text
  if t == "day" then
    icon, color, text = "☀", "#e0c060", "Day"
  elseif t == "night" then
    icon, color, text = "☾", "#8080c0", "Night"
  elseif t == "dawn" then
    icon, color, text = "🌅", "#e0a060", "Dawn"
  elseif t == "dusk" then
    icon, color, text = "🌇", "#c08060", "Dusk"
  else
    icon, color, text = "☀", "#a0a0b0", "Day"
  end
  self.timeLabel:setStyleSheet(string.format(
    "background-color: transparent; color: %s; font-size: 10px; qproperty-alignment: 'AlignCenter';", color))
  self.timeLabel:echo(icon .. " " .. text)
end

function ArjUI:renderAll()
  self:renderVitals()
  self:renderTNLBar()
  self:renderRoom()
  self:renderMobs()
  self:renderItems()
  self:renderPlayers()
  self:renderTarget()
  self:renderTank()
  self:renderGroup()
  self:renderAffects()
  self:renderTellContacts()
  self:renderTime()
end

-- ============================================================
-- COMMAND OUTPUT CAPTURE SYSTEM
-- ============================================================
-- Capture system for inv/eq/who output using registerAnonymousEventHandler
function ArjUI:setupCaptureTriggers()
  -- Use sysDataSendRequest to detect when we send commands, then capture output
  -- Instead, we'll use a line-by-line approach with the main trigger system
  
  -- Kill any existing capture triggers
  if self.captureTriggerIds then
    for _, id in ipairs(self.captureTriggerIds) do
      killTrigger(id)
    end
  end
  self.captureTriggerIds = {}
  
  -- Inventory header trigger
  local invId = tempTrigger("You are carrying:", function()
    ArjUI.state.invCapture = { lines = {}, header = matches[1] or line }
    ArjUI.state.capturing = "inv"
    ArjUI.state.captureCount = 0
    ArjUI.state.capturedLines = {}  -- Reset dedup hash
  end)
  table.insert(self.captureTriggerIds, invId)
  
  -- Equipment header trigger
  local eqId = tempTrigger("You are using:", function()
    ArjUI.state.eqCapture = { lines = {}, header = matches[1] or line }
    ArjUI.state.capturing = "eq"
    ArjUI.state.captureCount = 0
    ArjUI.state.capturedLines = {}  -- Reset dedup hash
  end)
  table.insert(self.captureTriggerIds, eqId)

  local emptyEqId = tempRegexTrigger("^You aren't wearing anything!$", function()
    ArjUI.state.equipment = { lines = {} }
    ArjUI.state.capturing = nil
    ArjUI:renderEq()
  end)
  table.insert(self.captureTriggerIds, emptyEqId)
  
  -- Who header trigger
  local whoId = tempTrigger("Listing of the Gods", function()
    ArjUI.state.whoCapture = { lines = {} }
    ArjUI.state.capturing = "who"
    ArjUI.state.captureCount = 0
    ArjUI.state.capturedLines = {}  -- Reset dedup hash
  end)
  table.insert(self.captureTriggerIds, whoId)
  
  -- Generic line capture - fires on every line when capturing
  -- Use a hash to prevent duplicates
  local lineId = tempRegexTrigger(".+", function()
    if not ArjUI.state.capturing then return end
    local currentLine = matches[1] or line
    
    -- Check for prompt (end of capture)
    if (isPrompt and isPrompt()) or currentLine:match("^%s*<%s*%d+h") then
      ArjUI:finishCapture()
      return
    end
    
    -- Capture based on type
    if ArjUI.state.capturing == "inv" then
      -- Duris item short descriptions need not start with an article. Keep
      -- capitalized names, bare names and grouped counts such as "[2] boots".
      if currentLine:match("%S") and not currentLine:match("^You are carrying:") then
        table.insert(ArjUI.state.invCapture.lines, currentLine)
        ArjUI.state.captureCount = (ArjUI.state.captureCount or 0) + 1
      end
    elseif ArjUI.state.capturing == "eq" then
      if currentLine:match("^<[^>]+>") then
        table.insert(ArjUI.state.eqCapture.lines, currentLine)
        ArjUI.state.captureCount = (ArjUI.state.captureCount or 0) + 1
      end
    elseif ArjUI.state.capturing == "who" then
      -- Capture player lines [level class], listing headers, counts, etc.
      if currentLine:match("^%s*%[") or currentLine:match("^Listing of the Mortals") or 
         currentLine:match("^There are %d+") or currentLine:match("^Total visible") or 
         currentLine:match("^Record number") or currentLine:match("^<None>") or
         currentLine:match("^There are .* online") then
        table.insert(ArjUI.state.whoCapture.lines, currentLine)
        ArjUI.state.captureCount = (ArjUI.state.captureCount or 0) + 1
      end
    end
  end)
  table.insert(self.captureTriggerIds, lineId)
  
  -- Outgoing tell capture removed - GMCP handles outgoing tells via "You -> PlayerName" format
  -- No need for text trigger since GMCP Comm.Channel already captures both incoming and outgoing
end

-- Handle outgoing tells (sent by player)
function ArjUI:handleOutgoingTell(target, text)
  local name = target:lower()
  local displayName = target:sub(1,1):upper() .. target:sub(2):lower()
  
  -- Add to contacts
  self:addTellContact(displayName)
  
  -- Add message to history as outgoing
  self:addPrivateChatMessage(name, "You", text, true)
end

function ArjUI:finishCapture()
  local captureType = self.state.capturing
  self.state.capturing = nil
  
  if captureType == "inv" then
    self.state.inventory = self.state.invCapture
    self:renderInventory()
  elseif captureType == "eq" then
    self.state.equipment = self.state.eqCapture
    self:renderEq()
  elseif captureType == "who" then
    self.state.whoList = self.state.whoCapture
    self:renderWho()
  end
end

-- Request data when clicking on a tab - sends command to main console
function ArjUI:requestTabData(tabName)
  if tabName == "stats" then
    send("score")
  elseif tabName == "who" then
    send("who")
  elseif tabName == "inv" then
    send("inv")
  elseif tabName == "eq" then
    send("eq")
  elseif tabName == "ship" then
    send("look contacts")
  end
end

-- ============================================================
-- SETTINGS (persisted to arjui_settings.json)
-- ============================================================

ArjUI.settingsDefaults = {
  compactHeader = false,  -- smaller header, without the illustrated frame
  keypad = true,          -- numpad movement keys
  chatTimestamps = true,  -- [hh:mm] prefix on chat lines
  damageTracker = true,   -- per-fight / session damage tracking
  scanFormat = true,      -- rewrite 'scan' output into aligned columns
  alerts = true,          -- console banners for notable events
  expTracker = true,      -- '+exp' notices with kills-to-level estimate
}

function ArjUI:loadSettings()
  self.settings = {}
  for k, v in pairs(self.settingsDefaults) do self.settings[k] = v end
  local path = getMudletHomeDir() .. "/arjui_settings.json"
  local f = io.open(path, "r")
  if f then
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(yajl.to_value, content)
    if ok and type(data) == "table" then
      for k, v in pairs(data) do
        if self.settingsDefaults[k] ~= nil then self.settings[k] = (v == true) end
      end
    end
  end
end

function ArjUI:saveSettings()
  local path = getMudletHomeDir() .. "/arjui_settings.json"
  local ok, json = pcall(yajl.to_string, self.settings or self.settingsDefaults)
  if ok then
    local f = io.open(path, "w")
    if f then f:write(json); f:close() end
  end
end

function ArjUI:setSetting(key, on)
  if self.settingsDefaults[key] == nil then return false end
  self.settings[key] = on
  self:saveSettings()
  if key == "keypad" then self:setupKeypad() end
  if key == "compactHeader" then
    self:applyBackground()
    self:layout()
  end
  return true
end

local function fmtNum(n)
  n = math.floor(tonumber(n) or 0)
  local s = tostring(n)
  local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return (out:gsub("^,", ""))
end

local function fmtDuration(seconds)
  seconds = math.max(0, math.floor(seconds or 0))
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = seconds % 60
  if h > 0 then return string.format("%dh%02dm%02ds", h, m, s) end
  if m > 0 then return string.format("%dm%02ds", m, s) end
  return string.format("%ds", s)
end

function ArjUI:note(text)
  if self.console then self.console:cecho(text .. "<reset>\n") else cecho(text .. "<reset>\n") end
end

-- ============================================================
-- PORTED INTELLIGENCE
-- Display-only helpers adapted from the community "lielz scripts"
-- collection (2015-2024). Nothing here sends game commands on its own
-- except the numpad keys, which only fire when the player presses them.
-- ============================================================

function ArjUI:teardownPorted()
  for _, id in ipairs(self.portTriggers or {}) do pcall(function() killTrigger(id) end) end
  self.portTriggers = {}
  for _, id in ipairs(self.portKeys or {}) do pcall(function() killKey(id) end) end
  self.portKeys = {}
  if self.scanTimer then pcall(function() killTimer(self.scanTimer) end); self.scanTimer = nil end
end

function ArjUI:setupPorted()
  self:teardownPorted()
  self.portTriggers = {}
  self.portKeys = {}
  self:setupExpTracker()
  self:setupDamageTracker()
  self:setupScanFormatter()
  self:setupAlerts()
  self:setupShipText()
  self:setupKeypad()
end

local function addTrigger(self, pattern, fn)
  local id = tempRegexTrigger(pattern, fn)
  table.insert(self.portTriggers, id)
  return id
end

-- ------------------------------------------------------------
-- EXPERIENCE TRACKER (GMCP Char.Vitals exp/tnl)
-- ------------------------------------------------------------

function ArjUI:setupExpTracker()
  self.state.exp = nil
  self.state.lastExpGain = nil
  self.state.sessionExp = 0
end

function ArjUI:trackExp(exp, tnl)
  local prev = self.state.exp
  self.state.exp = exp
  if not prev then return end
  local gained = exp - prev
  if gained <= 0 then return end
  self.state.lastExpGain = gained
  self.state.sessionExp = (self.state.sessionExp or 0) + gained
  if not (self.settings and self.settings.expTracker) then return end
  local msg = string.format("<gold>[+%s exp]", fmtNum(gained))
  if tnl and tnl > 0 then
    local more = math.ceil(tnl / gained)
    msg = msg .. string.format(" <dim_gray>%s to level, about %d more like that", fmtNum(tnl), more)
  end
  self:note(msg)
end

-- ------------------------------------------------------------
-- DAMAGE TRACKER
-- Sources: GMCP Combat.Update.round (preferred) or the server's
-- "[Damage: N ]" display lines on servers without rounds. Once a round
-- stream is observed it remains authoritative across fights: the server may
-- flush the final text damage AFTER its GMCP combat-end packet.
-- ------------------------------------------------------------

function ArjUI:setupDamageTracker()
  self.damage = self.damage or {
    fight = 0, fightHits = 0,
    session = 0, sessionHits = 0, sessionStart = os.time(),
    lastHit = 0, source = nil,
  }
  addTrigger(self, "\\[Damage:\\s*(\\d+)\\s*\\]", function()
    local damage = ArjUI.damage
    if damage.source == "gmcp" or (damage.gmcpAvailable and damage.source ~= "text") then return end
    for n in string.gmatch(line or "", "%[Damage:%s*(%d+)%s*%]") do
      ArjUI:addDamage(tonumber(n), "text")
    end
  end)
  addTrigger(self, "^GMCP data streaming disabled\\.$", function()
    ArjUI.damage.gmcpAvailable, ArjUI.damage.source = false, nil
  end)
  addTrigger(self, "^You receive your share of experience\\.$", function() ArjUI:endFight() end)
  addTrigger(self, "^.+ is dead! R\\.I\\.P\\.$", function() ArjUI:endFight() end)
  self:renderDamage()
end

function ArjUI:addDamage(n, source)
  if not n or n <= 0 then return end
  if not (self.settings and self.settings.damageTracker) then return end
  local d = self.damage
  if d.source and d.source ~= source then return end
  d.source = source
  d.fight = d.fight + n
  d.fightHits = d.fightHits + 1
  d.session = d.session + n
  d.sessionHits = d.sessionHits + 1
  d.lastHit = n
  if n > (d.lastBest or 0) then d.lastBest = n end
  self:renderDamage()
end

function ArjUI:endFight()
  local d = self.damage
  if not d or d.fight <= 0 then return end
  if self.settings and self.settings.damageTracker then
    self:note(string.format("<gold>[Fight damage: %s in %d hits, best %s]", fmtNum(d.fight), d.fightHits, fmtNum(d.lastBest or 0)))
  end
  d.fight, d.fightHits, d.lastBest = 0, 0, 0
  d.source = nil
  self:renderDamage()
end

function ArjUI:renderDamage()
  if not self.damageLabel then return end
  local d = self.damage or { fight = 0 }
  if d.fight > 0 then
    self.damageLabel:echo(string.format("<center>⚔ %s</center>", fmtNum(d.fight)))
  else
    self.damageLabel:echo("<center>⚔ DMG</center>")
  end
end

function ArjUI:reportDamage(reset)
  local d = self.damage
  if reset then
    self.damage = { fight = 0, fightHits = 0, session = 0, sessionHits = 0, sessionStart = os.time(), lastHit = 0, source = d and d.source or nil, gmcpAvailable = d and d.gmcpAvailable or nil }
    self:renderDamage()
    self:note("<cyan>[ArjUI] Damage counters reset.")
    return
  end
  local elapsed = os.time() - (d.sessionStart or os.time())
  local dps = elapsed > 0 and d.session / elapsed or 0
  self:note(string.format("<gold>[Damage] <white>%s<dim_gray> total in %s (%d hits, %.1f dmg/s). Current fight: <white>%s<dim_gray>. Source: %s",
    fmtNum(d.session), fmtDuration(elapsed), d.sessionHits, dps, fmtNum(d.fight), d.source or "none yet"))
end

-- ------------------------------------------------------------
-- SCAN FORMATTER
-- "A Drow Elf who is not far off to your east." becomes
-- "[E ] 2  A Drow Elf" with distance and direction coloured, and a
-- per-direction summary line follows the last scan line.
-- ------------------------------------------------------------

local scanDistance = {
  ["close by"]            = { 1, 255, 80, 80 },
  ["not far off"]         = { 2, 255, 150, 60 },
  ["a brief walk away"]   = { 3, 100, 210, 100 },
  ["rather far off"]      = { 4, 90, 150, 255 },
  ["in the distance"]     = { 5, 180, 120, 230 },
  ["almost out of sight"] = { 6, 130, 130, 200 },
}
local scanDirShort = {
  north = "N", south = "S", east = "E", west = "W",
  northeast = "NE", northwest = "NW", southeast = "SE", southwest = "SW",
  above = "U", below = "D",
}
local scanDirOrder = { "N", "NE", "E", "SE", "S", "SW", "W", "NW", "U", "D" }

function ArjUI:setupScanFormatter()
  self.scanCounts = {}
  addTrigger(self, "^You quickly scan the area\\.$", function() ArjUI.scanCounts = {} end)
  addTrigger(self, "^(.+) who is (close by|not far off|a brief walk away|rather far off|in the distance|almost out of sight) (?:to your (north|south|east|west|northeast|northwest|southeast|southwest)|(above|below)(?: you)?)\\.?$", function()
    if not (ArjUI.settings and ArjUI.settings.scanFormat) then return end
    local who, dist = matches[2], matches[3]
    local dir = (matches[4] and matches[4] ~= "") and matches[4] or matches[5]
    local d = scanDistance[dist]
    local short = scanDirShort[dir or ""]
    if not d or not short then return end
    local tag = string.format("[%-2s]", short)
    local text = string.format("%s %d  %s", tag, d[1], who)
    selectCurrentLine()
    replace(text)
    selectSection(0, #tag)
    setFgColor(150, 200, 255)
    selectSection(#tag + 1, 1)
    setFgColor(d[2], d[3], d[4])
    deselect()
    local c = ArjUI.scanCounts[short] or { n = 0, nearest = 99 }
    c.n = c.n + 1
    if d[1] < c.nearest then c.nearest = d[1] end
    ArjUI.scanCounts[short] = c
    if ArjUI.scanTimer then pcall(function() killTimer(ArjUI.scanTimer) end) end
    ArjUI.scanTimer = tempTimer(0.4, function() if ArjUI then ArjUI:summarizeScan() end end)
  end)
end

function ArjUI:summarizeScan()
  self.scanTimer = nil
  local parts, plain, total = {}, {}, 0
  for _, dir in ipairs(scanDirOrder) do
    local c = self.scanCounts[dir]
    if c then
      total = total + c.n
      table.insert(parts, string.format("<white>%s<dim_gray>:%d (nearest %d)", dir, c.n, c.nearest))
      table.insert(plain, string.format("%s:%d (nearest %d)", dir, c.n, c.nearest))
    end
  end
  self.scanCounts = {}
  if total == 0 then return end
  self:note(string.format("<cyan>[Scan] <white>%d<dim_gray> seen · %s", total, table.concat(parts, " · ")))
  if ArjAuto and ArjAuto.onScanSummary then pcall(function() ArjAuto:onScanSummary(total, plain) end) end
end

-- ------------------------------------------------------------
-- ALERT BANNERS
-- ------------------------------------------------------------

ArjUI.alertPatterns = {
  { "^Your glowing sanctuary fades\\.$",                         "SANCTUARY DOWN",        "<white:red>" },
  { "^Your burning hellfire fades\\.$",                          "HELLFIRE DOWN",         "<white:red>" },
  { "^You feel your skin soften and return to normal\\.$",       "STONE SKIN DOWN",       "<white:dark_red>" },
  { "^Your heroic urges slowly fade away\\.$",                   "HEROISM DOWN",          "<white:dark_red>" },
  { "^You feel yourself return to normal as your rage abates\\.$", "RAGE OUT",            "<white:dark_red>" },
  { "^Your battle frenzy fades\\.$",                             "WAR CRY OUT",           "<white:dark_red>" },
  { "knocks your weapon from your grasp!",                       "YOU WERE DISARMED",     "<yellow:red>" },
  { "forces your weapon out of your hands with a fancy disarming maneuver\\.", "YOU WERE DISARMED", "<yellow:red>" },
  { "^You make a grave error in judgement, and lose control of your weapon\\.", "YOU DROPPED YOUR WEAPON", "<yellow:red>" },
  { "^You fail miserably in your attempt to disarm",             "DISARM FAILED",         "<white:dark_red>" },
  { "^You make a great effort, and send ",                       "DISARM SUCCESS",        "<white:dark_green>" },
  { "^You feel an icy eye watching you\\.$",                     "SOMEONE IS SCRYING YOU", "<white:purple>" },
  { "^You finish your song\\.$",                                 "SONG FINISHED",         "<white:blue>" },
  { "^Uh oh\\.\\. how did the song go, anyway\\?$",              "SONG FAILED",           "<white:red>" },
  { "^You feel your skill in (.+) improving\\.$",                "SKILL UP: %1",          "<black:gold>" },
  { "^(.+) has set off your frost beacon at (.+)$",              "FROST BEACON: %1 at %2", "<black:cyan>" },
  { "^There are (.+) tracks going (.+)\\.$",                     "TRACKS: %1 going %2",   "<black:khaki>" },
}

function ArjUI:setupAlerts()
  for _, a in ipairs(self.alertPatterns) do
    local pattern, label, style = a[1], a[2], a[3]
    addTrigger(self, pattern, function()
      if not (ArjUI.settings and ArjUI.settings.alerts) then return end
      local text = label:gsub("%%(%d)", function(i) return matches[tonumber(i) + 1] or "" end)
      ArjUI:note(string.format("\n%s ══ %s ══", style, text))
    end)
  end
end

-- ------------------------------------------------------------
-- SHIP PANEL
-- GMCP Ship.Info / Ship.Contacts when the server sends them, with the
-- text "Contact listing" output as a fallback. Click the SHIP tab to
-- send 'look contacts'.
-- ------------------------------------------------------------

function ArjUI:resetShip(departed)
  self.state.ship = { skills = {}, departed = departed == true }
  self.shipSelection = nil
end

local function shipCopy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for k,v in pairs(value) do copy[k] = shipCopy(v) end
  return copy
end

function ArjUI:acceptShipContacts(packet)
  local s = self.state.ship
  s.contacts = shipCopy(type(packet.contacts) == "table" and packet.contacts or packet)
  s.heading, s.speed = packet.heading, packet.speed
  s.textContacts, s.textCapture, s.target, s.targetName = nil, nil, nil, nil
  for _,contact in ipairs(s.contacts) do
    if type(contact) == "table" and contact.you_targeting == true then s.target, s.targetName = contact.id, contact.name end
  end
end

function ArjUI:setupShipText()
  if not self.state.ship then self:resetShip() end
  local ship = function() return ArjUI.state.ship end
  local function fallback() local s=ship(); return not s.info and not s.departed and s end
  addTrigger(self, "^Contact listing\\s+H:\\s*(\\S+)\\s+S:\\s*(\\S+)", function()
    local s = fallback(); if not s then return end
    s.heading, s.speed = matches[2], matches[3]
    s.textContacts = {}
    s.textCapture = true
    ArjUI:renderShipIfActive()
  end)
  addTrigger(self, "^\\[([^\\]]+)\\]\\s+(.+?)\\s+X:\\s*(-?\\d+)\\s+Y:\\s*(-?\\d+)\\s+R:\\s*(\\S+)\\s+B:\\s*(\\S+)\\s+H:\\s*(\\S+)\\s+S:\\s*(\\S+)\\s*\\|([FPRS*])([FPRS*])([FSDA]?)\\s*$", function()
    local s = fallback(); if not s or not s.textCapture then return end
    s.textContacts = s.textContacts or {}
    local side = "unknown"
    selectString("[", 1)
    if isAnsiFgColor(11) then side = "good" elseif isAnsiFgColor(9) then side = "evil"
    elseif isAnsiFgColor(8) then side = "undead" elseif isAnsiFgColor(13) then side = "squid" end
    selectString(matches[2],1); local targeting=isAnsiFgColor(15)
    selectString(matches[3],1); local ours=isAnsiFgColor(10)
    deselect()
    table.insert(s.textContacts, {
      id = matches[2], name = matches[3], x = matches[4], y = matches[5],
      range = tonumber(matches[6]) or matches[6], bearing = matches[7], heading = matches[8], speed = matches[9],
      facing = matches[10], pointing = matches[11], arc=matches[10]..matches[11],
      status=({F="flying",S="sinking",D="docked",A="anchored"})[matches[12]], side = side,
      targeting_you=targeting,you_targeting=ours,
    })
    if ours then s.target=matches[2] end
    ArjUI:renderShipIfActive()
  end)
  addTrigger(self, "^You board (.+)$", function() if ship().info then return end; ArjUI:resetShip(); ship().name = matches[2]; ship().status = "aboard"; ArjUI:renderShipIfActive() end)
  addTrigger(self, "^You disembark this ship\\.$", function() ArjUI:resetShip(true); ArjUI:renderShipIfActive() end)
  addTrigger(self, "^Your ship has completed docking procedures\\.$", function() local s=fallback(); if s then s.status = "docked"; ArjUI:renderShipIfActive() end end)
  addTrigger(self, "^The first officer reports everything is in order and the ship is ready to go\\.$", function() local s=fallback(); if s then s.status = "under way"; ArjUI:renderShipIfActive() end end)
  addTrigger(self, "^Captain:\\s*(\\w+)", function() local s=fallback(); if s then s.captain = matches[2]; ArjUI:renderShipIfActive() end end)
  addTrigger(self, "(?:Speed Range:\\s*0-(\\d+)|^This ship can only go from 0 to (\\d+)\\.$)", function()
    if not fallback() then return end
    local v = matches[2]
    if not v or v == "" then v = matches[3] end
    ship().maxSpeed = v
    ArjUI:renderShipIfActive()
  end)
  addTrigger(self, "^(Deck|Guns|Repair) skill:\\s+(\\d+)", function()
    if ship().departed then return end
    local s, name, val = ship(), matches[2], tonumber(matches[3])
    local prev = s.skills[name]
    if prev and val > prev then ArjUI:note(string.format("<cyan>[Ship] %s skill +%d (now %d)", name, val - prev, val)) end
    s.skills[name] = val
    ArjUI:renderShipIfActive()
  end)
  addTrigger(self, "^Locked onto \\[(.+)\\]: (.+)$", function() local s=fallback(); if s then s.target = matches[2]; s.targetName=matches[3]; ArjUI:renderShipIfActive() end end)
  addTrigger(self, "^Target Cleared\\.$", function() local s=fallback(); if s then s.target = nil; s.targetName=nil; ArjUI:renderShipIfActive() end end)
end

function ArjUI:onShipInfo()
  if not gmcp or not gmcp.Ship or not gmcp.Ship.Info then return end
  if not self.state.ship then self:resetShip() end
  local info = gmcp.Ship.Info
  if type(info) ~= "table" then return end
  if next(info) == nil then self:resetShip(true) else
    local s = self.state.ship
    local key = type(info.shipKey) == "string" and info.shipKey or nil
    local pending = s.pendingContacts
    if key ~= s.shipKey or (not key and s.info and info.id ~= nil and s.info.id ~= nil and
        (info.id ~= s.info.id or (info.id=="**" and info.name ~= s.info.name))) then
      self:resetShip(); s = self.state.ship
    end
    s.info, s.shipKey, s.departed = shipCopy(info), key, false
    s.name, s.captain, s.status = nil, info.captain, nil
    s.maxSpeed = toNum(pick(info,"maxSpeed","max_speed","speedMax"))
    if pending and pending.shipKey == key then self:acceptShipContacts(pending) end
    s.pendingContacts = nil
  end
  self:renderShipIfActive()
end

function ArjUI:onShipContacts()
  if not gmcp or not gmcp.Ship or not gmcp.Ship.Contacts then return end
  if not self.state.ship then self:resetShip() end
  local c = gmcp.Ship.Contacts
  if type(c) ~= "table" then return end
  local s = self.state.ship
  if type(c.shipKey) == "string" and c.shipKey ~= s.shipKey then
    s.pendingContacts = shipCopy(c)
    return
  end
  if s.shipKey and c.shipKey == nil and next(c.contacts or c) ~= nil then return end
  self:acceptShipContacts(c)
  self:renderShipIfActive()
end

function ArjUI:renderShipIfActive()
  if self.activeTab == "ship" and self:panelIsVisible("character") then self:renderShip() end
end

local function sortedKeys(t)
  local keys = {}
  for k in pairs(t) do table.insert(keys, k) end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  return keys
end

local function shipSideColor(contact)
  local side = tostring(pick(contact, "race", "side", "alignment", "racewar", "faction") or ""):lower()
  if contact.sunk == true then return "<royal_blue>" end
  if side:find("evil") then return "<indian_red>" end
  if side:find("good") then return "<khaki>" end
  if side == "undead" then return "<medium_purple>" end
  if contact.hostile == true then return "<indian_red>" end
  return "<light_gray>"
end

function ArjUI:renderShip()
  if not self.shipBox or self.activeTab ~= "ship" or not self:panelIsVisible("character") then return end
  local box = self.shipBox
  box.shipScrollTop = box.shipScrollTop or math.max(0, box:getScroll() - getRowCount(box.name))
  box:clear()
  local s = self.state.ship or {}
  box:cecho("<dim_gray>── Ship ──\n")

  local info = type(s.info) == "table" and s.info or {}
  local bridge = type(info.bridge) == "table" and info.bridge or {}
  local shown = false
  -- Local presentation helpers: unknown is not zero; false is a real value.
  -- Strip both server colors and cecho markup in supplied names and values.
  local function text(value)
    if value == nil then return "?" end
    return stripColors(tostring(value))
  end
  local function section(title)
    box:cecho("\n<gold>" .. title .. "\n")
    shown = true
  end
  local function row(label, value)
    if value ~= nil then
      box:cecho("<dim_gray>" .. label .. ": <light_gray>")
      box:echo(text(value) .. "\n")
      shown = true
    end
  end
  local function pair(current, maximum, color)
    local accent = "<light_gray>"
    local condition = ""
    local n, m = tonumber(current), tonumber(maximum)
    if color and n and m and m > 0 then
      accent = n < math.floor(m/3) and "<indian_red>" or (n < math.floor(m*2/3) and "<khaki>" or "<dark_sea_green>")
      condition = n < math.floor(m/3) and " (Critical)" or (n < math.floor(m*2/3) and " (Damaged)" or " (Sound)")
    end
    return accent .. cecho2string(text(current)) .. "/" .. cecho2string(text(maximum)) .. condition
  end
  local function slots(items)
    local list = {}
    for _, item in ipairs(items) do if type(item) == "table" then list[#list+1] = item end end
    table.sort(list, function(a, b) return (tonumber(a.slot) or math.huge) < (tonumber(b.slot) or math.huge) end)
    return list
  end
  local function readiness(item)
    if item.ready == true then return "<dim_gray>Timer: <dark_sea_green>Ready\n" end
    if item.ready == false then return "<dim_gray>Timer: <khaki>Not ready\n" end
    return ""
  end
  local name = pick(info, "name", "ship", "shipName") or s.name
  if name then box:cecho("<white>"); box:echo(text(name) .. "\n"); shown = true end
  row("ID", info.id)
  row("Status", info.status or s.status)
  row("Captain", info.captain or s.captain)
  row("Frags", info.frags)
  local heading = s.heading or pick(info, "heading", "course")
  local speed = s.speed or info.speed
  local maximum = pick(info, "maxSpeed", "max_speed", "speedMax") or s.maxSpeed
  if heading ~= nil or speed ~= nil or maximum ~= nil then
    box:cecho("<yellow>H:" .. text(heading) .. "  S:" .. text(speed) .. "/" .. text(maximum) .. "\n")
    shown = true
  end
  row("Contact range", info.contactRange)
  row("Ordered heading", bridge.setHeading)
  row("Ordered speed", bridge.setSpeed)
  local target = type(info.bridge) == "table" and bridge.target or nil
  if type(target) == "table" then row("Locked on", "[" .. text(target.id) .. "] " .. text(target.name))
  elseif bridge.target == nil then row("Locked on", s.target and (text(s.target) .. " " .. text(s.targetName or ""))) end
  if not s.info and name then row("Source", "Text-derived fallback") end

  if info.armor or info.internal or info.sail ~= nil or info.maxSail ~= nil then
    section("Condition")
    for _, arc in ipairs({{"bow", "Forward"}, {"port", "Port"}, {"starboard", "Starboard"}, {"stern", "Rear"}}) do
      local armor = type(info.armor) == "table" and info.armor[arc[1]]
      local hull = type(info.internal) == "table" and info.internal[arc[1]]
      if type(armor) == "table" or type(hull) == "table" then
        armor, hull = type(armor) == "table" and armor or {}, type(hull) == "table" and hull or {}
        box:cecho("<white>" .. arc[2] .. "<dim_gray> Armor " .. pair(armor[1], armor[2], true) .. "\n")
        box:cecho("<dim_gray>  Hull " .. pair(hull[1], hull[2], true) .. "\n")
      end
    end
    if info.sail ~= nil or info.maxSail ~= nil then box:cecho("<dim_gray>Sail: " .. pair(info.sail, info.maxSail) .. "\n") end
  end
  if type(info.weapons) == "table" then
    section("Weapons")
    if #info.weapons == 0 then row("Weapons", "None") end
    for _, weapon in ipairs(slots(info.weapons)) do
      box:cecho("<white>"); box:echo("[" .. text(weapon.slot) .. "] " .. text(weapon.name) .. "\n")
      row("Position", weapon.positionLabel or ({bow="Forward", stern="Rear"})[weapon.position] or weapon.position)
      if weapon.ammo ~= nil or weapon.maxAmmo ~= nil then
        box:cecho("<dim_gray>Ammo: " .. pair(weapon.ammo, weapon.maxAmmo) .. (tonumber(weapon.ammo) == 0 and "<indian_red> (empty)" or "") .. "\n")
      end
      if weapon.damage ~= nil then
        box:cecho("<dim_gray>Damage: " .. ((tonumber(weapon.damage) or 0) > 0 and "<indian_red>" or "<light_gray>") .. text(weapon.damage) .. "\n")
      end
      box:cecho(readiness(weapon))
      row("Server status", weapon.statusText)
      row("Timer count", weapon.timer)
      if weapon.destroyed ~= nil then row("Destroyed", weapon.destroyed and "Yes (bridge ammo **)" or "No") end
    end
  end
  if info.crewType or info.crewStamina ~= nil or info.maxCrewStamina ~= nil or info.people ~= nil or info.maxPeople ~= nil
      or info.repairStock ~= nil or info.chiefs or info.skills or info.skillMods or next(s.skills or {}) then
    section("Crew and supplies")
    row("Crew", info.crewType)
    if info.crewStamina ~= nil or info.maxCrewStamina ~= nil then box:cecho("<dim_gray>Stamina: " .. pair(bridge.displayCrewStamina or info.crewStamina, info.maxCrewStamina) .. "\n") end
    row("Raw stamina", info.crewStamina)
    row("Fatigue", bridge.crewStaminaBand)
    if info.people ~= nil or info.maxPeople ~= nil then box:cecho("<dim_gray>Passengers: " .. pair(info.people, info.maxPeople) .. "\n") end
    row("Repair stock", info.repairStock)
    for _, skill in ipairs({{"sail", "Deck"}, {"guns", "Guns"}, {"repair", "Repair"}}) do
      local key, label = skill[1], skill[2]
      local chief = type(info.chiefs) == "table" and info.chiefs[key] or nil
      row(label .. " chief", chief == "" and "None" or chief)
      row(label .. " skill", pick(info.skills, key) or pick(s.skills, label))
      local modifier = tonumber(pick(info.skillMods, key))
      if modifier then row(label .. " modifier", string.format("%+d", modifier)) end
    end
  end
  if type(info.equipment) == "table" then
    section("Equipment")
    if #info.equipment == 0 then row("Equipment", "None") end
    for _, item in ipairs(slots(info.equipment)) do
      box:cecho("<white>"); box:echo("[" .. text(item.slot) .. "] " .. text(item.name) .. "\n"); box:cecho(readiness(item))
      row("Damage", item.damage); row("Server status", item.statusText); row("Timer count", item.timer)
    end
  end
  if type(info.cargo) == "table" or next(bridge) then
    section("Cargo")
    row("Hull weight", bridge.hullWeight)
    if type(bridge.load) == "table" then row("Weight load", text(bridge.load.current).."/"..text(bridge.load.max)) end
    local cargo = type(info.cargo) == "table" and info.cargo or {}
    if cargo.current ~= nil or cargo.max ~= nil then box:cecho("<dim_gray>Crates: " .. pair(cargo.current, cargo.max) .. "\n") end
    if type(cargo.items) == "table" then
      if #cargo.items == 0 then row("Cargo", "None") end
      for _, item in ipairs(slots(cargo.items)) do
        box:cecho("<white>"); box:echo("[" .. text(item.slot) .. "] " .. text(item.name) .. (item.contraband == true and " (contraband)" or "") .. "\n")
        row("Crates", item.crates)
        row("Invoice price", item.invoicePrice)
      end
    end
  end

  local contacts = s.contacts
  if type(contacts) ~= "table" then contacts = s.textContacts end
  if type(contacts) == "table" and #contacts > 0 then
    local list = {}
    for _, c in ipairs(contacts) do if type(c) == "table" then table.insert(list, c) end end
    table.sort(list, function(a, b)
      local ra = tonumber(pick(a, "range", "distance", "r")) or 9999
      local rb = tonumber(pick(b, "range", "distance", "r")) or 9999
      if ra ~= rb then return ra < rb end
      return tostring(pick(a,"id","num","number") or "") < tostring(pick(b,"id","num","number") or "")
    end)
    box:cecho(string.format("\n<dim_gray>Contacts (%d)\n", #list))
    for _, c in ipairs(list) do
      local id = pick(c, "id", "num", "number")
      local name = pick(c, "name", "ship") or "?"
      local color = shipSideColor(c)
      local bits = {}
      local b, h, r, sp = pick(c, "bearing", "b"), pick(c, "heading", "h"), pick(c, "range", "distance", "r"), pick(c, "speed", "s")
      if b then table.insert(bits, "B:" .. tostring(b)) end
      if h then table.insert(bits, "H:" .. tostring(h)) end
      if r then table.insert(bits, "R:" .. tostring(r)) end
      if sp then table.insert(bits, "S:" .. tostring(sp)) end
      if c.x ~= nil then table.insert(bits, "X:" .. tostring(c.x)) end
      if c.y ~= nil then table.insert(bits, "Y:" .. tostring(c.y)) end
      if c.arc then
        local ours,theirs=tostring(c.arc):match("^([FPRS])([FPRS])$")
        local names={F="Forward",P="Port",R="Rear",S="Starboard"}
        table.insert(bits,"arc:"..tostring(c.arc)..(ours and " (our "..names[ours].." / their "..names[theirs]..")" or ""))
      end
      table.insert(bits,"Allegiance:"..tostring(pick(c,"race","side","alignment","racewar","faction") or "unknown"))
      if c.status and c.status ~= "" then table.insert(bits, c.status) end
      if c.targeting_you then table.insert(bits, "targeting you") end
      if c.you_targeting then table.insert(bits, "our lock") end
      if c.facing and c.pointing then table.insert(bits, "(" .. c.facing .. "|" .. c.pointing .. ")") end
      if #bits == 0 then
        for _, k in ipairs(sortedKeys(c)) do
          if k ~= "name" and k ~= "id" and type(c[k]) ~= "table" then table.insert(bits, k .. "=" .. tostring(c[k])) end
        end
      end
      box:cecho(color)
      box:echo(string.format("%s[%s] %s%s %s\n", c.you_targeting and "*" or "", text(id or "-"), text(name), c.sunk and " (sunk)" or "", text(table.concat(bits, " "))))
    end
    shown = true
  elseif type(contacts) == "table" and shown then
    section("Contacts (0)")
    row("Contacts", "None")
  end

  if not shown then
    box:cecho("<dim_gray>(no ship data)\n\nBoard a ship and click SHIP\nto look at contacts.\n")
  end
  -- A contact refresh must not pull the reader away from weapons or cargo.
  -- clear() closes Mudlet's split scrollback. Wait for its geometry to settle;
  -- coalesce consecutive Info/Contacts events into one restoration.
  self:after(0, function()
    if self.shipBox ~= box or box.shipScrollTop == nil then return end
    local top = box.shipScrollTop
    box.shipScrollTop = nil
    local lines, rows = getLastLineNumber(box.name) + 1, getRowCount(box.name)
    if self:panelIsVisible("character") and self.activeTab=="ship" and lines - top > rows then box:scrollTo(top + rows) end
  end)
end

-- ------------------------------------------------------------
-- NUMPAD MOVEMENT KEYS
-- 8/2/4/6 = n/s/w/e, 7/9/1/3 = nw/ne/sw/se, - = up, + = down,
-- 5 = look, / = scan, 0 = flee
-- ------------------------------------------------------------

ArjUI.keypadMap = {
  { 56, "north" }, { 50, "south" }, { 52, "west" }, { 54, "east" },
  { 55, "northwest" }, { 57, "northeast" }, { 49, "southwest" }, { 51, "southeast" },
  { 45, "up" }, { 43, "down" }, { 53, "look" }, { 47, "scan" }, { 48, "flee" },
}

function ArjUI:setupKeypad()
  for _, id in ipairs(self.portKeys or {}) do pcall(function() killKey(id) end) end
  self.portKeys = {}
  if not (self.settings and self.settings.keypad) then return end
  local keypad = (mudlet and mudlet.keymodifier and mudlet.keymodifier.Keypad) or 536870912
  for _, k in ipairs(self.keypadMap) do
    local cmd = k[2]
    local ok, id = pcall(tempKey, keypad, k[1], function() send(cmd) end)
    if ok and id then table.insert(self.portKeys, id) end
  end
end

-- ------------------------------------------------------------
-- HELP
-- ------------------------------------------------------------

function ArjUI:showHelp()
  self:note("<gold>══ Arjinius Client commands ══")
  self:note("<white>ui on / ui off<dim_gray>        build or hide the interface")
  self:note("<white>ui debug<dim_gray>              show which GMCP tables have arrived")
  self:note("<white>ui damage<dim_gray>             session damage report; <white>ui damage reset<dim_gray> clears it")
  self:note("<white>ui layout<dim_gray>             panel controls and reset; right-click a panel title for actions")
  self:note("<white>ui set<dim_gray>                list toggles; <white>ui set <name> on|off<dim_gray> changes one")
  self:note("<white>ui set compactHeader on|off<dim_gray>  collapse or restore the illustrated header")
  self:note("<white>mapper<dim_gray>                mapper help")
  self:note("<white>auto<dim_gray>                  automation and utility aliases (ArjAuto)")
  self:note("<dim_gray>Numpad: 8/2/4/6 move, 7/9/1/3 diagonals, - up, + down, 5 look, / scan, 0 flee")
end

function ArjUI:showSettings()
  self:note("<gold>══ Toggles (ui set <name> on|off) ══")
  local desc = {
    compactHeader = "smaller header without the illustrated frame",
    keypad = "numpad movement keys", chatTimestamps = "[hh:mm] on chat lines",
    damageTracker = "damage counter in the target panel", scanFormat = "aligned, coloured scan output",
    alerts = "banners for sanc/rage/disarm/scry/skill-up", expTracker = "+exp notices with kills-to-level",
  }
  for _, k in ipairs(sortedKeys(self.settingsDefaults)) do
    local on = self.settings[k]
    self:note(string.format("%s%-16s<dim_gray> %s  %s", on and "<green>" or "<indian_red>", k, on and "on " or "off", desc[k] or ""))
  end
end

-- ============================================================
-- ROUTEALL TRIGGER & ALIASES
-- ============================================================

function ArjUI:setupRouteAll()
  -- Kill existing routeall trigger if any
  if self.routeAllTriggerId then
    pcall(function() killTrigger(self.routeAllTriggerId) end)
    self.routeAllTriggerId = nil
  end
  -- Also kill by name in case it persists
  if exists("ArjUI_RouteAll", "trigger") > 0 then
    pcall(function() killTrigger("ArjUI_RouteAll") end)
  end
  -- Kill event handler if exists
  if self.routeAllHandler then
    pcall(function() killAnonymousEventHandler(self.routeAllHandler) end)
    self.routeAllHandler = nil
  end
  
  -- Create a regex trigger that matches every line
  -- Pattern "^.*$" matches entire line (same as working manual trigger)
  self.routeAllTriggerId = tempRegexTrigger("^.*$", function()
    if ArjUI and ArjUI.console and not ArjUI.hidden then
      selectCurrentLine()
      copy()
      appendBuffer("ArjUI_Console")
      deleteLine()
    end
  end)
end

function ArjUI:setupAliases()
  -- Kill existing aliases if any
  if self.uiOnAlias then pcall(function() killAlias(self.uiOnAlias) end) end
  if self.uiOffAlias then pcall(function() killAlias(self.uiOffAlias) end) end
  if self.debugAlias then pcall(function() killAlias(self.debugAlias) end) end
  for _, id in ipairs(self.portAliases or {}) do pcall(function() killAlias(id) end) end
  self.portAliases = {}
  
  -- Hide/show retains state and widgets rather than rebuilding callbacks.
  self.uiOnAlias = tempAlias("^ui on$", function()
    ArjUI:setVisible(true)
    cecho("<green>[ArjUI]<reset> UI enabled.\n")
  end)
  
  -- ui off - kill the UI and restore default Mudlet
  self.uiOffAlias = tempAlias("^ui off$", function()
    ArjUI:setVisible(false)
    cecho("<yellow>[ArjUI]<reset> UI disabled. Type 'ui on' to re-enable.\n")
  end)
  
  -- ui debug - show GMCP data status in ArjUI console
  self.debugAlias = tempAlias("^ui debug$", function()
    if ArjUI and ArjUI.console then
      ArjUI.console:cecho("\n<gold>══ GMCP Debug Info ══<reset>\n")
      ArjUI.console:cecho("<cyan>Char.Vitals:<reset> " .. (gmcp and gmcp.Char and gmcp.Char.Vitals and "YES" or "NO") .. "\n")
      ArjUI.console:cecho("<cyan>Char.Status:<reset> " .. (gmcp and gmcp.Char and gmcp.Char.Status and "YES" or "NO") .. "\n")
      ArjUI.console:cecho("<cyan>Char.Affects:<reset> " .. (gmcp and gmcp.Char and gmcp.Char.Affects and "YES" or "NO") .. "\n")
      ArjUI.console:cecho("<cyan>Room.Info:<reset> " .. (gmcp and gmcp.Room and gmcp.Room.Info and "YES" or "NO") .. "\n")
      ArjUI.console:cecho("<cyan>Group.Status:<reset> " .. (gmcp and gmcp.Group and gmcp.Group.Status and "YES" or "NO") .. "\n")
      if gmcp and gmcp.Char and gmcp.Char.Affects then
        local count = 0
        if type(gmcp.Char.Affects) == "table" then
          for _ in pairs(gmcp.Char.Affects) do count = count + 1 end
        end
        ArjUI.console:cecho("<cyan>Affects count:<reset> " .. count .. "\n")
      end
      ArjUI.console:cecho("<cyan>initialDataRequested:<reset> " .. tostring(ArjUI.initialDataRequested) .. "\n")
      ArjUI.console:cecho("<cyan>Ship.Info:<reset> " .. (gmcp and gmcp.Ship and gmcp.Ship.Info and "YES" or "NO") .. "\n")
      ArjUI.console:cecho("<cyan>Ship.Contacts:<reset> " .. (gmcp and gmcp.Ship and gmcp.Ship.Contacts and "YES" or "NO") .. "\n")
      ArjUI.console:cecho("<gold>═══════════════════════<reset>\n\n")
    end
  end)
  
  table.insert(self.portAliases, tempAlias("^ui layout(?: (reset|lock|unlock))?$", function() ArjUI:layoutCommand(matches[2]) end))
  table.insert(self.portAliases, tempAlias("^ui panel ([a-z0-9_:]+) (show|hide|minimize|restore|maximize|dock|float|lock|unlock)$", function()
    ArjUI:panelAction(matches[2],matches[3])
  end))
  -- ui help
  table.insert(self.portAliases, tempAlias("^/debugplayers$", function() ArjUI:debugPlayers() end))
  table.insert(self.portAliases, tempAlias("^ui help$", function() ArjUI:showHelp() end))
  -- ui damage [reset]
  table.insert(self.portAliases, tempAlias("^ui damage$", function() ArjUI:reportDamage(false) end))
  table.insert(self.portAliases, tempAlias("^ui damage reset$", function() ArjUI:reportDamage(true) end))
  -- ui set [<name> on|off]
  table.insert(self.portAliases, tempAlias("^ui set$", function() ArjUI:showSettings() end))
  table.insert(self.portAliases, tempAlias("^ui set (\\w+) (on|off)$", function()
    local key, val = matches[2], matches[3] == "on"
    if ArjUI:setSetting(key, val) then
      ArjUI:note(string.format("<cyan>[ArjUI] %s is now %s.", key, val and "on" or "off"))
    else
      ArjUI:note("<indian_red>[ArjUI] Unknown toggle '" .. key .. "'. Type 'ui set' to list them.")
    end
  end))
end

-- ============================================================
-- BOOT
-- ============================================================

-- Auto-initialize on script load
ArjUI:init()
ArjUI:setupCaptureTriggers()
ArjUI:setupRouteAll()
ArjUI:setupAliases()
table.insert(ArjUI.eventHandlers, registerAnonymousEventHandler("sysUninstallPackage", function(_, name)
  if name ~= "Arjinius Client" then return end
  if ArjAuto then ArjAuto:kill() end
  if ArjMapper then ArjMapper:kill() end
  ArjUI:kill()
end))
