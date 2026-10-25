local T=DurisTest
ArjUI.initialDataRequested=true
local w,h=getMainWindowSize()
T.write("presentation-geometry",{logical={width=w,height=h},
 root={x=ArjUI.uiRoot:get_x(),y=ArjUI.uiRoot:get_y(),width=ArjUI.uiRoot:get_width(),height=ArjUI.uiRoot:get_height()},
 scene={width=ArjUI.backdrop:get_width(),height=ArjUI.backdrop:get_height(),style=ArjUI.backdrop.stylesheet},
 frameStyle=ArjUI.frameArt.stylesheet})
local home=getMudletHomeDir().."/Arjinius Client/"
local scene=home.."duris-backdrop-stormwatch.png"
local frame=home.."duris-frame-slim.png"
local function withAbsent(path,corrupt,check)
 assert(os.rename(path,path..".hidden"))
 if corrupt then local f=assert(io.open(path,"w"));f:write("not a PNG");f:close() end
 ArjUI:applyBackground()
 local ok,err=xpcall(check,debug.traceback)
 if corrupt then os.remove(path) end
 assert(os.rename(path..".hidden",path))
 assert(ok,err)
end
T.steps({
 {name="missing-scene",run=function()
  withAbsent(scene,false,function()
   T.check(ArjUI.backdrop.hidden and ArjUI.artwork.frame,"missing scene retains frame over gradient")
  end)
 end},
 {name="corrupt-scene",run=function()
  withAbsent(scene,true,function()
   T.check(ArjUI.backdrop.hidden and ArjUI.artwork.frame,"corrupt scene retains frame over gradient")
  end)
 end},
 {name="missing-frame",run=function()
  withAbsent(frame,false,function()
   T.check(not ArjUI.backdrop.hidden and not ArjUI.frameArt.stylesheet:find("border-image",1,true),"missing frame retains scene with native border")
  end)
 end},
 {name="corrupt-frame",run=function()
  withAbsent(frame,true,function()
   T.check(not ArjUI.backdrop.hidden and not ArjUI.artwork.frame,"corrupt frame retains scene with native border")
  end)
 end},
 {name="text-wrapping",wait=.6,run=function()
  ArjUI:applyBackground()
  T.check(ArjUI.backdrop.stylesheet:find("border-image",1,true) and not ArjUI.backdrop.hidden,"restored asset is loaded")
  feedTriggers("You quickly scan the area.\nA Drow Elf who is not far off to your east.\n")
  feedTriggers("Your glowing sanctuary fades.\n")
  feedTriggers("\27[31mANSI red text\27[0m followed by "..string.rep("a readable long description ",14).."END-OF-LONG-LINE\n")
 end,verify=function()
  local text=T.lines("ArjUI_Console")
  T.check(text:find("[E ]",1,true) and text:find("[Scan]",1,true),"scan formatting and summary")
  T.check(text:find("SANCTUARY DOWN",1,true),"alert banner")
  T.check(text:gsub("\n",""):find("END-OF-LONG-LINE",1,true),"long line retained across wrapped rows")
  T.check(#T.commands==0,"text helpers do not send with automation off")
 end},
 {name="compact-artwork",run=function()
  expandAlias("ui set compactHeader on")
  T.check(ArjUI.backdrop.hidden and ArjUI.artwork.frame,"quiet mode retains slim frame")
  withAbsent(scene,false,function() T.check(ArjUI.backdrop.hidden,"quiet works without scenery") end)
  ArjUI:applyBackground()
  T.check(ArjUI.backdrop.hidden,"asset restoration preserves quiet mode")
  feedTriggers("\27[31mANSI red text\27[0m followed by "..string.rep("a readable long description ",14).."END-OF-COMPACT-LINE\n")
 end,verify=function()
  T.check(T.lines("ArjUI_Console"):gsub("\n",""):find("END-OF-COMPACT-LINE",1,true),"compact long line retained across wrapped rows")
 end},
 {name="full-artwork-restored",run=function()
  expandAlias("ui set compactHeader off")
  T.check(ArjUI.backdrop.stylesheet:find("border-image",1,true) and not ArjUI.backdrop.hidden,"full mode restores present artwork after compact")
 end},
 {name="scenic-default",run=function() ArjUI:resetLayout();ArjUI:setSetting("compactHeader",false) end},
 {name="scenic-sparse",run=function()
  for _,def in ipairs(ArjUI.panelDefinitions) do if not def.essential then ArjUI:panelAction(def.id,"hide") end end
  local p=ArjUI.panels.output
  p.state.mode="floating";p.state.rect={.02,.12,.38,.6};ArjUI:applyPanelLayout()
 end},
 {name="scenic-maximized",run=function() ArjUI:panelAction("output","maximize") end},
 {name="quiet-default",run=function() ArjUI:resetLayout();ArjUI:setSetting("compactHeader",true) end},
 {name="quiet-sparse",run=function()
  for _,def in ipairs(ArjUI.panelDefinitions) do if not def.essential then ArjUI:panelAction(def.id,"hide") end end
  local p=ArjUI.panels.output
  p.state.mode="floating";p.state.rect={.02,.12,.38,.6};ArjUI:applyPanelLayout()
 end},
 {name="quiet-maximized",run=function() ArjUI:panelAction("output","maximize") end},
 {name="presentation-reset",run=function() ArjUI:resetLayout();ArjUI:setSetting("compactHeader",false) end}
})
