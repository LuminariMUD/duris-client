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
  feedTriggers("Companion nchats 'KEEP-ZERO'\n")
  T.check(console():find("KEEP-ZERO",1,true),"without chatGag the chat line stays in GAME OUTPUT")
 end},
 {name="gag-both-orders",run=function()
  expandAlias("ui set chatGag on")
  T.check(ArjUI.settings.chatGag,"ui set chatGag on")
  -- GMCP first, then the text line.
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="GAG-ONE"})
  feedTriggers("Companion nchats 'GAG-ONE'\n")
  T.check(not console():find("GAG-ONE",1,true),"GMCP-first chat line is not mirrored")
  T.check(T.lines("main"):find("GAG-ONE",1,true),"the main window (and Mudlet's log) keeps it")
  -- Text line first, then GMCP.
  feedTriggers("Companion nchats 'GAG-TWO'\n")
  T.check(console():find("GAG-TWO",1,true),"text-first line is shown until its GMCP arrives")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="GAG-TWO"})
  T.check(not console():find("GAG-TWO",1,true),"text-first chat line is removed when GMCP arrives")
  T.check(T.lines("ArjUI_ChatBox"):find("GAG-TWO",1,true),"the chat tab still has the message")
 end},
 {name="gag-is-narrow",run=function()
  T.emit("Comm.Channel",{channel="say",sender="Companion",text="hello there"})
  feedTriggers("Stranger says 'hello there'\n")
  T.check(console():find("Stranger says 'hello there'",1,true),"a line from another speaker is kept")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="TWICE"})
  feedTriggers("Companion nchats 'TWICE'\n")
  feedTriggers("Companion nchats 'TWICE'\n")
  T.check(count(console(),"Companion nchats 'TWICE'")==1,"one message hides at most one line")
  feedTriggers("Plain room text GAG-THREE\n")
  T.check(console():find("GAG-THREE",1,true),"ordinary text is untouched")
  ArjUI.CHAT_GAG_SECONDS=0
  T.emit("Comm.Channel",{channel="nchat",sender="Late",text="EXPIRED"})
  ArjUI.chatGagQueue[#ArjUI.chatGagQueue].at=getEpoch()-1
  feedTriggers("Late nchats 'EXPIRED'\n")
  T.check(console():find("EXPIRED",1,true),"an expired GMCP copy hides nothing")
  ArjUI.CHAT_GAG_SECONDS=3
  expandAlias("ui set chatGag off")
 end},
})
