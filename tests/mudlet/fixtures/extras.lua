local T=DurisTest
-- Room details tooltip, wilderness legend and the opt-in chat gag (both
-- arrival orders of Comm.Channel and its text line).
ArjUI.initialDataRequested=true
T.emit("Char.Status",{name="VisualTester",level=25,class="Warrior",race="Human"})
local function console() return T.lines("ArjUI_Console") end
local function count(text,needle) local n=0; for _ in text:gmatch(needle:gsub("%p","%%%0")) do n=n+1 end; return n end
T.steps({
 {name="room-details",run=function()
  T.emit("Room.Info",{num=90010,zone=9001,name="A quiet glade",area="Bronze Tower",terrain=3,coords={x=3,y=-2,z=0},exits={north=90011}})
  T.check(ArjUI:roomDetails()=="Room 90010 · zone 9001 · Forest · (3, -2, 0)","room details: "..ArjUI:roomDetails())
  T.check(ArjUI.roomLabel.toolTip=="A quiet glade\nRoom 90010 · zone 9001 · Forest · (3, -2, 0)","room name tooltip carries the details")
  T.emit("Room.Info",{num=0,zone=0,name="Wilderness",area="Wilds",terrain=38,coords={},exits={north=true}})
  T.check(ArjUI:roomDetails()=="Snowy Forest","wilderness shows only its terrain: "..ArjUI:roomDetails())
  T.emit("Room.Info",{num=12,zone=1,name="Odd",area="X",terrain=77,exits={}})
  T.check(ArjUI:roomDetails()=="Room 12 · zone 1 · terrain 77","unknown terrain number is shown raw")
  T.check(table.concat(ArjUI:debugReportLines(),"\n"):find("Room: Room 12",1,true),"ui debug reports the room")
 end},
 {name="legend",run=function()
  local lines=ArjMapper:legendLines()
  T.check(#lines==#ArjMapper.LEGEND and #lines==7,"one legend line per category")
  T.check(lines[1]:find("snowy forest",1,true) and lines[1]:find("<",1,true),"legend entries are coloured and labelled")
  expandAlias("mapper legend")
  local text=console()
  T.check(text:find("Wilderness map legend",1,true) and text:find("your ship",1,true),"mapper legend prints")
  T.check(not text:find("&+",1,true) and not text:find("&=",1,true),"no raw colour codes leak into the legend")
 end},
 {name="gag-off-by-default",run=function()
  T.check(ArjUI.settings.chatGag==false,"chatGag defaults off")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="KEEP-ZERO"})
  feedTriggers("Companion tells your racewar: 'KEEP-ZERO'\n")
  T.check(console():find("KEEP-ZERO",1,true),"without chatGag the chat line stays in GAME OUTPUT")
 end},
 {name="gag-both-orders",run=function()
  expandAlias("ui set chatGag on")
  T.check(ArjUI.settings.chatGag,"ui set chatGag on")
  -- GMCP first, then the text line.
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="GAG-ONE"})
  feedTriggers("Companion tells your racewar: 'GAG-ONE'\n")
  T.check(not console():find("GAG-ONE",1,true),"GMCP-first chat line is not mirrored")
  T.check(T.lines("main"):find("GAG-ONE",1,true),"the main window (and Mudlet's log) keeps it")
  -- Text line first, then GMCP.
  feedTriggers("Companion tells your racewar: 'GAG-TWO'\n")
  T.check(console():find("GAG-TWO",1,true),"text-first line is shown until its GMCP arrives")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="GAG-TWO"})
  T.check(not console():find("GAG-TWO",1,true),"text-first chat line is removed when GMCP arrives")
  T.check(T.lines("ArjUI_ChatBox"):find("GAG-TWO",1,true),"the chat tab still has the message")
 end},
 {name="gag-preserves-output",run=function()
  local full="You say 'PRESENTED'"
  T.emit("Comm.Channel",{channel="say",sender="You",text="PRESENTED",presentation={version=1,text=full,
   underline=false,runs={{0,#full,0,0}},channelId=11,channel="chat.say",policy="preserve"}})
  feedTriggers(full.."\n")
  T.check(not console():find(full,1,true),"validated full terminal presentations correlate the text copy")
  feedTriggers("The north passage leads to a room where Companion waits.\n")
  T.emit("Comm.Channel",{channel="say",sender="You",text="north"})
  T.check(console():find("The north passage leads to a room where Companion waits.",1,true),"outgoing chat cannot erase room text containing its body")
  feedTriggers("You say 'north'\n")
  T.check(not console():find("You say 'north'",1,true),"the actual outgoing chat copy is hidden")
  T.emit("Comm.Channel",{channel="tell",sender="Someone",text="north"})
  feedTriggers("Someone walks north.\n")
  T.check(console():find("Someone walks north.",1,true),"anonymous chat cannot erase an unrelated named line")
  feedTriggers("Someone tells you 'north'\n")
  T.check(not console():find("Someone tells you 'north'",1,true),"an anonymous tell is matched as a complete chat line")
  feedTriggers("Companion tells your racewar: 'OLD-TEXT'\n")
  local original=getTimestamp
  getTimestamp=function(name,row)
   local text=(getLines(name,row,row+1) or {})[1] or ""
   if name=="ArjUI_Console" and text:find("OLD-TEXT",1,true) then return os.date("%H:%M:%S",os.time()-10)..".000 " end
   return original(name,row)
  end
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="OLD-TEXT"})
  getTimestamp=original
  T.check(console():find("OLD-TEXT",1,true),"a new GMCP message cannot erase an older identical line")
  feedTriggers("Companion tells your racewar: 'OLD-TEXT'\n")
  T.check(count(console(),"OLD-TEXT")==1,"only the new text copy is hidden after an older match is rejected")
 end},
 {name="gag-wrapped-and-search",run=function()
  local message="WRAPPED-CHAT "..string.rep("long message body ",90).."WRAPPED-TAIL"
  feedTriggers("Companion tells your racewar: '"..message.."'\n")
  feedTriggers("AFTER-CHAT SEARCH-HIGHLIGHT\n")
  ArjUI:searchOutput("older","SEARCH-HIGHLIGHT")
  T.check(ArjUI.outputSearch.mark,"search highlight is active before deleting earlier wrapped rows")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text=message})
  T.check(not console():find("WRAPPED-CHAT",1,true) and not console():find("WRAPPED-TAIL",1,true),"text-first chat removes every wrapped row")
  T.check(ArjUI.outputSearch.mark.row==ArjUI.outputSearch.row,"saved search highlight follows deletion of earlier rows")
  local mark=ArjUI.outputSearch.mark
  ArjUI:clearSearchHighlight()
  moveCursor("ArjUI_Console",mark.x,mark.row); selectSection("ArjUI_Console",mark.x,1)
  local r,g,b=getBgColor("ArjUI_Console"); deselect("ArjUI_Console"); moveCursorEnd("ArjUI_Console")
  T.check(not (r==201 and g==162 and b==39),"clearing search removes the shifted highlight")
  T.check(T.lines("main"):gsub("\n",""):find("WRAPPED-TAIL",1,true),"main-window history retains wrapped chat")
  feedTriggers("Companion tells your racewar: 'DELAYED-TEXT-COPY'\n")
  for i=1,12 do feedTriggers("Intervening game output "..i.."\n") end
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="DELAYED-TEXT-COPY"})
  T.check(not console():find("DELAYED-TEXT-COPY",1,true),"intervening output within the time window does not hide an eligible text-first copy from matching")
 end},
 {name="gag-toggle-and-session",run=function()
  for i=1,12 do T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="BURST-CHAT-"..i.."-END"}) end
  for i=1,12 do feedTriggers("Companion tells your racewar: 'BURST-CHAT-"..i.."-END'\n") end
  T.check(not console():find("BURST-CHAT-",1,true),"a burst of GMCP-first messages does not evict unmatched copies")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="PENDING-OFF"})
  expandAlias("ui set chatGag off")
  feedTriggers("Companion tells your racewar: 'PENDING-OFF'\n")
  T.check(console():find("PENDING-OFF",1,true),"turning chatGag off cancels queued gags")
  expandAlias("ui set chatGag on")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="OLD-SESSION"})
  ArjUI:endSession()
  T.check(not ArjUI.chatGagQueue or #ArjUI.chatGagQueue==0,"ending a session clears queued gags")
 end},
 {name="gag-is-narrow",run=function()
  T.emit("Comm.Channel",{channel="say",sender="Companion",text="hello there"})
  feedTriggers("Stranger says 'hello there'\n")
  T.check(console():find("Stranger says 'hello there'",1,true),"a line from another speaker is kept")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="TWICE"})
  feedTriggers("Companion tells your racewar: 'TWICE'\n")
  feedTriggers("Companion tells your racewar: 'TWICE'\n")
  T.check(count(console(),"Companion tells your racewar: 'TWICE'")==1,"one message hides at most one line")
  feedTriggers("Plain room text GAG-THREE\n")
  T.check(console():find("GAG-THREE",1,true),"ordinary text is untouched")
  ArjUI.CHAT_GAG_SECONDS=0
  T.emit("Comm.Channel",{channel="nchat",sender="Late",text="EXPIRED"})
  ArjUI.chatGagQueue[#ArjUI.chatGagQueue].at=getEpoch()-1
  feedTriggers("Late tells your racewar: 'EXPIRED'\n")
  T.check(console():find("EXPIRED",1,true),"an expired GMCP copy hides nothing")
  ArjUI.CHAT_GAG_SECONDS=3
  expandAlias("ui set chatGag off")
 end},
})
