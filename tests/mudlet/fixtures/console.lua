local T=DurisTest
ArjUI.initialDataRequested=true
local function count(text,needle)
 local n=0
 for _ in text:gmatch(needle:gsub("%-","%%-")) do n=n+1 end
 return n
end
local function lineIndex(text,needle)
 local i=0
 for line in (text.."\n"):gmatch("(.-)\n") do
  if line:find(needle,1,true) then return i end
  i=i+1
 end
end
T.steps({
 {name="center-width",run=function()
  -- The root reaches the frame rail; only the center column takes the extra width.
  local w=getMainWindowSize()
  local old=w*.95
  local function width(id) return ArjUI.panels[id].frame:get_width() end
  for id,share in pairs({map=.165,room=.165,vitals=.165,character=.26,players=.26,chat=.26}) do
   T.check(math.abs(width(id)-share*old)<3,id.." keeps its pre-widening width")
  end
  T.check(width("output")>.57*old+(ArjUI.uiRoot:get_width()-old)*.9,"GAME OUTPUT takes the reclaimed width")
  local out=ArjUI.panels.output.frame
  local target=ArjUI.panels.target.frame
  T.check(math.abs((out:get_x()+out:get_width())-(target:get_x()+target:get_width()))<3,"TANK/TARGET span the widened center")
 end},
 {name="scrollbar",run=function()
  T.check(ArjUI.console.scrollBar==true,"GAME OUTPUT has a vertical scrollbar")
  T.check(ArjUI.console:get_height()>200,"GAME OUTPUT keeps its height with the scrollbar")
  for i=1,120 do feedTriggers(string.format("CONSOLE-FILL-%03d plain scrollback line\n",i)) end
 end},
 {name="command-echo",wait=.4,run=function()
  feedTriggers("CONSOLE-BEFORE-COMMAND\n")
  -- Real Host::send echoes into the hidden main window before sending.
  T.originalSend("consoleprobe-command")
  echo("CONSOLE-SCRIPT-ECHO\n")
  feedTriggers("CONSOLE-AFTER-COMMAND\n")
 end,verify=function()
  local text=T.lines("ArjUI_Console")
  local before,cmd,script,after=lineIndex(text,"CONSOLE-BEFORE-COMMAND"),lineIndex(text,"consoleprobe-command"),
   lineIndex(text,"CONSOLE-SCRIPT-ECHO"),lineIndex(text,"CONSOLE-AFTER-COMMAND")
  T.check(cmd and script,"echoed command and script echo reach GAME OUTPUT")
  T.check(before and cmd and after and before<cmd and cmd<script and script<after,"echoes keep their order between server lines")
  T.check(count(text,"consoleprobe-command")==1 and count(text,"CONSOLE-SCRIPT-ECHO")==1,"each echo is mirrored once")
  T.check(count(text,"CONSOLE-AFTER-COMMAND")==1 and count(text,"CONSOLE-FILL-120")==1,"server lines are still routed once")
  T.check(after==script+1,"no blank line is inserted around mirrored echoes")
 end},
 {name="wrapped-echo",wait=.4,run=function()
  T.originalSend("consolewrap "..string.rep("abcdefghi ",25).."WRAP-END")
  feedTriggers("CONSOLE-LONG-SERVER "..string.rep("lorem ipsum ",30).."SERVER-END\n")
  feedTriggers("CONSOLE-AFTER-LONG\n")
 end,verify=function()
  local text=T.lines("ArjUI_Console")
  local cmd=lineIndex(text,"consolewrap")
  local finish=lineIndex(text,"WRAP-END")
  local joined=cmd and finish and finish>cmd
  for row=(cmd or 0)+1,(finish or 0) do
   joined=joined and tostring(getTimestamp("ArjUI_Console",row)):sub(1,1)=="-"
  end
  T.check(joined,"a long echoed command stays one GAME OUTPUT line, wrapped only by the panel")
  T.check(count(text,"SERVER-END")==1 and text:gsub("\n",""):find("lorem ipsum lorem",1,true),"a long server line is routed once")
  T.check(count(text,"consolewrap")==1,"wrapped rows of routed and echoed lines are not mirrored twice")
  T.check(lineIndex(text,"CONSOLE-AFTER-LONG")==lineIndex(text,"SERVER-END")+1,"nothing is mirrored between routed server lines")
  T.check(T.lines("main"):find("CONSOLE-AFTER-LONG",1,true),"server lines stay in the covered main window")
 end},
 {name="prompt-echo",wait=.4,run=function()
  feedTriggers("<100h 50m> \255\249")
  T.originalSend("consoleprompt-cmd")
  feedTriggers("CONSOLE-PROMPT-REPLY\n")
 end,verify=function()
  local text=T.lines("ArjUI_Console")
  local prompt,cmd,reply=lineIndex(text,"<100h 50m>"),lineIndex(text,"consoleprompt-cmd"),lineIndex(text,"CONSOLE-PROMPT-REPLY")
  T.check(prompt and cmd and reply and prompt<=cmd and cmd<reply,"a command typed at a GA prompt shows between prompt and reply")
  T.check(count(text,"<100h 50m>")==1 and count(text,"consoleprompt-cmd")==1,"prompt and command appear once")
 end},
 {name="logging",wait=.6,run=function()
  local ok,_,path=startLogging(true)
  T.logPath=path
  feedTriggers("CONSOLE-LOGGED-SERVER\n")
  T.originalSend("consolelogged-cmd")
  feedTriggers("CONSOLE-LOGGED-REPLY\n")
  tempTimer(.3,function() startLogging(false) end)
 end,verify=function()
  local f=assert(io.open(T.logPath)); local log=f:read("*a"); f:close()
  local a,b,c=log:find("CONSOLE-LOGGED-SERVER",1,true),log:find("consolelogged-cmd",1,true),log:find("CONSOLE-LOGGED-REPLY",1,true)
  T.check(a and b and c and a<b and b<c,"Mudlet's log records server lines and commands in order")
 end},
 {name="timestamps",wait=.3,run=function()
  expandAlias("ui set timestamps on")
  T.check(ArjUI.settings.timestamps==true,"timestamps toggle turns on")
  expandAlias("ui set timestamps off")
  T.check(ArjUI.settings.timestamps==false,"timestamps toggle turns off")
 end},
 {name="alias-order",wait=.4,run=function()
  expandAlias("ui set")
 end,verify=function()
  local text=T.lines("ArjUI_Console")
  local cmd,reply=nil,lineIndex(text,"Toggles (ui set")
  local i=0
  for line in (text.."\n"):gmatch("(.-)\n") do if line=="ui set" then cmd=i end; i=i+1 end
  T.check(cmd and reply and cmd<reply,"an alias's echoed command precedes its reply")
 end},
 {name="find",wait=.4,run=function()
  expandAlias("ui find CONSOLE-FILL-007")
 end,verify=function()
  local text=T.lines("ArjUI_Console")
  T.check(text:find("Latest 1 match for 'CONSOLE-FILL-007'",1,true),"find reports the match")
  T.check(text:find("line %d+: CONSOLE%-FILL%-007"),"find lists the matching line")
 end},
 {name="find-scroll",wait=.6,run=function()
  ArjUI:scrollOutputTo(lineIndex(T.lines("ArjUI_Console"),"CONSOLE-FILL-007"))
 end,verify=function()
  local top=getScroll("ArjUI_Console")
  T.check(top<60,"a listed match scrolls GAME OUTPUT back to it")
 end},
 {name="find-missing",wait=.4,run=function()
  scrollTo("ArjUI_Console")
  expandAlias("ui find no-such-console-text")
 end,verify=function()
  T.check(T.lines("ArjUI_Console"):find("No GAME OUTPUT line contains 'no-such-console-text'",1,true),"find reports no match")
 end},
 {name="link-click",wait=.4,run=function()
  -- A script's link written to the main window keeps working in GAME OUTPUT.
  ArjUI.testLinkClicked=nil
  scrollTo("ArjUI_Console")
  echoLink("main","CONSOLE-LINK-TARGET click me",[[ArjUI.testLinkClicked=true]],"test link",true)
  echo("main","\n")
  ArjUI:mirrorMain()
 end,verify=function()
  T.check(T.lines("ArjUI_Console"):find("CONSOLE-LINK-TARGET",1,true),"link text is mirrored")
 end,actions=function()
  local c=ArjUI.console
  local _,fh=calcFontSize(c.name)
  local cw=calcFontSize(c.name)
  local rows=math.floor(c:get_height()/fh)
  local acts={}
  -- The newest line is one of the last two rows (the last may be the open line).
  for back=1,2 do acts[#acts+1]={type="click",x=c:get_x()+cw*4,y=c:get_y()+(rows-back)*fh+fh/2} end
  return acts
 end},
 {name="wrapped-link",wait=.4,run=function()
  T.check(ArjUI.testLinkClicked==true,"clicking a GAME OUTPUT link runs it")
  -- A link on a line the main window wraps still works once the rows are joined.
  ArjUI.testLinkClicked=nil
  scrollTo("ArjUI_Console")
  -- Long enough to wrap in the main window, short enough for one GAME OUTPUT row.
  echo("main",string.rep("wrapped link prefix ",4).."padpadpad ")
  echoLink("main","CONSOLE-WRAPPED-LINK",[[ArjUI.testLinkClicked=true]],"wrapped test link",true)
  echo("main","\n")
 end,verify=function()
  local text=T.lines("ArjUI_Console")
  T.check(count(text,"CONSOLE-WRAPPED-LINK")==1,"the wrapped link is mirrored once, without a server line or command after it")
  T.check(text:gsub("\n",""):find("padpadpad CONSOLE-WRAPPED-LINK",1,true),"wrapped main rows are joined into one GAME OUTPUT line")
  local main=getLines("main",0,getLastLineNumber("main")+1)
  local wrapped=false
  for _,row in ipairs(main) do if row:find("WRAPPED-LINK",1,true) and not row:find("padpadpad",1,true) then wrapped=true end end
  T.check(wrapped,"the main window wrapped the link line")
 end,actions=function()
  local c=ArjUI.console
  local _,fh=calcFontSize(c.name)
  local cw=calcFontSize(c.name)
  local rows=math.floor(c:get_height()/fh)
  local text=T.lines(c.name)
  local line=text:match("([^\n]*CONSOLE%-WRAPPED%-LINK[^\n]*)") or ""
  local at=(line:find("CONSOLE-WRAPPED-LINK",1,true) or 1)-1
  local acts={}
  for back=1,2 do acts[#acts+1]={type="click",x=c:get_x()+cw*(at+3),y=c:get_y()+(rows-back)*fh+fh/2} end
  return acts
 end},
 {name="context-copy",run=function()
  T.check(ArjUI.testLinkClicked==true,"clicking a link on a wrapped main-window line runs it")
  setClipboardText("")
 end,actions=function()
  local c=ArjUI.console
  local x,y=c:get_x()+c:get_width()/2,c:get_y()+c:get_height()/3
  return {{type="click",button=3,x=x,y=y},{type="key",key="Down"},{type="key",key="Down"},{type="key",key="Down"},
   {type="key",key="Down"},{type="key",key="Return"},
   {type="click",button=3,x=x,y=y},{type="key",key="Down"},{type="key",key="Return"}}
 end},
 {name="clipboard",run=function()
  local clip=getClipboardText() or ""
  T.check(clip:find("CONSOLE-FILL-050",1,true) and clip:find("CONSOLE-LINK-TARGET",1,true),
   "right-click Select all then Copy puts GAME OUTPUT text on the clipboard")
 end},
 {name="search-api",run=function()
  local function rowOf(text) return lineIndex(T.lines("ArjUI_Console"),text) end
  local function bgAt(row,x) moveCursor("ArjUI_Console",x,row); selectSection("ArjUI_Console",x,1)
   local r,g,b=getBgColor("ArjUI_Console"); deselect("ArjUI_Console"); moveCursorEnd("ArjUI_Console"); return r..","..g..","..b end
  ArjUI:searchOutput("older","FILL-05")
  T.check(ArjUI.outputSearch.row==rowOf("CONSOLE-FILL-059"),"search starts at the newest match")
  T.check(bgAt(ArjUI.outputSearch.row,8)=="201,162,39","the match is highlighted")
  local first=ArjUI.outputSearch.row
  ArjUI:searchOutput("older")
  T.check(ArjUI.outputSearch.row==rowOf("CONSOLE-FILL-058"),"older steps up")
  T.check(bgAt(first,8)=="0,0,0","the previous highlight is restored")
  ArjUI:searchOutput("newer")
  T.check(ArjUI.outputSearch.row==first,"newer steps back down")
  -- Mudlet's own F3 shortcut is paused only while the UI covers the main window.
  setConfig("f3SearchEnabled",true); ArjUI:bindSearchKeys(true)
  T.check(getConfig("f3SearchEnabled")==false,"Mudlet's F3 search pauses while the UI is shown")
  ArjUI:setVisible(false)
  T.check(getConfig("f3SearchEnabled")==true,"hiding the UI restores Mudlet's F3 search")
  ArjUI:setVisible(true)
  T.check(getConfig("f3SearchEnabled")==false,"showing the UI pauses it again")
  ArjUI:bindSearchKeys(false); setConfig("f3SearchEnabled",false); ArjUI:bindSearchKeys(true)
  ArjUI:searchOutput("older","")
 end},
 {name="search-typed",wait=.4,run=function() scrollTo("ArjUI_Console"); clearCmdLine("ArjUI_OutputSearch") end,actions=function()
  local acts={T.click(ArjUI.searchBox)}
  for _,k in ipairs({"f","i","l","l","minus","0","4","Return"}) do acts[#acts+1]={type="key",key=k} end
  return acts
 end},
 {name="search-keys",run=function()
  T.check(ArjUI.outputSearch.query=="fill-04","typing in the search box sets the query")
  T.check(ArjUI.outputSearch.row==lineIndex(T.lines("ArjUI_Console"),"CONSOLE-FILL-049"),"Enter finds the newest match")
  T.check(getScroll("ArjUI_Console")<getLastLineNumber("ArjUI_Console"),"the match is scrolled into view")
 end,actions=function() return {{type="key",key="shift+F3"},{type="key",key="shift+F3"},{type="key",key="F3"}} end},
 {name="search-keys-result",run=function()
  T.check(ArjUI.outputSearch.row==lineIndex(T.lines("ArjUI_Console"),"CONSOLE-FILL-048"),"Shift+F3 twice then F3 lands on the expected match")
 end},
 {name="search-trim",wait=.4,run=function()
  -- A long session trims GAME OUTPUT's oldest lines and renumbers the rest.
  ArjUI:searchOutput("older","CONSOLE-FILL-11")
  T.check(ArjUI.outputSearch.row==lineIndex(T.lines("ArjUI_Console"),"CONSOLE-FILL-119"),"search finds the newest fill match")
  setConsoleBufferSize("ArjUI_Console",getLastLineNumber("ArjUI_Console")+20,40)
  for i=1,30 do feedTriggers(string.format("CONSOLE-TRIM-%03d\n",i)) end
 end,verify=function()
  T.check((ArjUI.outputTrim or 0)>0,"GAME OUTPUT trimmed its oldest lines")
  local text=T.lines("ArjUI_Console")
  T.check(ArjUI.outputSearch.row==lineIndex(text,"CONSOLE-FILL-119"),"the search position follows its line after a trim")
  local marked=ArjUI.outputSearch.row
  ArjUI:searchOutput("older")
  T.check(ArjUI.outputSearch.row==lineIndex(text,"CONSOLE-FILL-118"),"the next search continues from the trimmed position")
  moveCursor("ArjUI_Console",8,marked); selectSection("ArjUI_Console",8,1)
  local r,g,b=getBgColor("ArjUI_Console"); deselect("ArjUI_Console"); moveCursorEnd("ArjUI_Console")
  T.check(r..","..g..","..b=="0,0,0","the earlier highlight is removed after a trim")
  ArjUI:searchOutput("older","")
 end},
 {name="f3-restart",run=function()
  -- Mudlet saves its settings on exit without running the UI's teardown.
  setConfig("f3SearchEnabled",true); ArjUI:bindSearchKeys(true)
  T.check(getConfig("f3SearchEnabled")==false,"F3 is paused while the UI is shown")
  ArjUI.f3Paused,ArjUI.f3Restore=nil,nil -- nothing in memory survives a restart
  ArjUI:loadSettings(); ArjUI:bindSearchKeys(true)
  ArjUI:setVisible(false)
  T.check(getConfig("f3SearchEnabled")==true,"a pause saved in an earlier session is still restored")
  ArjUI:setVisible(true); ArjUI:setVisible(false)
  T.check(getConfig("f3SearchEnabled")==true,"the restored setting is not paused twice")
  ArjUI:setVisible(true)
 end},
})
