local T=DurisTest
local routing={say="ArjUI_RoomBox",tell="ArjUI_ChatBox",gcc="ArjUI_GuildBox",gsay="ArjUI_GroupChatBox",nchat="ArjUI_NchatBox",jchat="ArjUI_NchatBox",petition="ArjUI_ChatBox",wizmsg="ArjUI_ChatBox"}
local steps={}
for _,channel in ipairs({"say","tell","gcc","gsay","nchat","jchat","petition","wizmsg"}) do
 local ch=channel
 steps[#steps+1]={name=ch,run=function()
  T.emit("Comm.Channel",{channel=ch,sender="Companion",text="MESSAGE-"..ch.." "..string.rep("Long chat text. ",18),alignment="good"})
  T.check(T.lines(routing[ch]):find("MESSAGE-"..ch,1,true),ch.." routed")
  local tab=({say="room",tell="tells",gcc="guild",gsay="group",nchat="nchat",jchat="nchat"})[ch] or "all"
  ArjUI:switchChatTab(tab)
 end}
end
steps[#steps+1]={name="outgoing-tell",run=function()
 T.emit("Comm.Channel",{channel="tell",sender="You -> Companion",text="Outgoing fixture"})
 T.check(ArjUI.privateChats.companion and #ArjUI.privateChats.companion.history==2,"incoming/outgoing tell history")
 ArjUI:openPrivateChat("Companion")
end}
T.steps(steps)
