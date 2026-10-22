local T=DurisTest
ArjUI.initialDataRequested=true
local asset=getMudletHomeDir().."/Arjinius Client/duris-v1.png"
T.steps({
 {name="fallback",run=function()
  assert(os.rename(asset,asset..".hidden"))
  ArjUI:applyBackground()
  assert(os.rename(asset..".hidden",asset))
  T.check(not ArjUI.bg.stylesheet:find("border-image",1,true),"missing asset uses gradient fallback")
 end},
 {name="text-wrapping",wait=.6,run=function()
  ArjUI:applyBackground()
  T.check(ArjUI.bg.stylesheet:find("border-image",1,true),"restored asset is loaded")
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
  T.check(not ArjUI.bg.stylesheet:find("border-image",1,true),"compact omits present artwork")
  assert(os.rename(asset,asset..".hidden"))
  ArjUI:applyBackground()
  assert(os.rename(asset..".hidden",asset))
  T.check(ArjUI.bg.stylesheet:find("qlineargradient",1,true),"compact works without artwork")
  ArjUI:applyBackground()
  T.check(not ArjUI.bg.stylesheet:find("border-image",1,true),"asset restoration preserves compact mode")
  feedTriggers("\27[31mANSI red text\27[0m followed by "..string.rep("a readable long description ",14).."END-OF-COMPACT-LINE\n")
 end,verify=function()
  T.check(T.lines("ArjUI_Console"):gsub("\n",""):find("END-OF-COMPACT-LINE",1,true),"compact long line retained across wrapped rows")
 end},
 {name="full-artwork-restored",run=function()
  expandAlias("ui set compactHeader off")
  T.check(ArjUI.bg.stylesheet:find("border-image",1,true),"full mode restores present artwork after compact")
 end}
})
