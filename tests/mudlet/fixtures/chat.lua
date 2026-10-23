local T=DurisTest
local routing={say="ArjUI_RoomBox",tell="ArjUI_ChatBox",gcc="ArjUI_GuildBox",gsay="ArjUI_GroupChatBox",nchat="ArjUI_NchatBox",jchat="ArjUI_NchatBox",petition="ArjUI_ChatBox",wizmsg="ArjUI_ChatBox"}
local steps={}
for _,channel in ipairs({"say","tell","gcc","gsay","nchat","jchat","petition","wizmsg"}) do
 local ch=channel
 steps[#steps+1]={name=ch,run=function()
  T.emit("Comm.Channel",{channel=ch,sender="Companion",text="MESSAGE-"..ch.." "..string.rep("Long chat text. ",18),alignment="good"})
  T.check(T.lines(routing[ch]):gsub("\n",""):find("MESSAGE-"..ch,1,true),ch.." routed")
  local tab=({say="room",tell="tells",gcc="guild",gsay="group",nchat="nchat",jchat="nchat"})[ch] or "all"
  ArjUI:switchChatTab(tab)
 end}
end
steps[#steps+1]={name="outgoing-tell",run=function()
 T.emit("Comm.Channel",{channel="tell",sender="You -> Companion",text="Outgoing fixture"})
 T.check(ArjUI.privateChats.companion and #ArjUI.privateChats.companion.history==2,"incoming/outgoing tell history")
 ArjUI:openPrivateChat("Companion")
end}
steps[#steps+1]={name="tell-while-ui-off",run=function()
 expandAlias("ui off")
 T.emit("Comm.Channel",{channel="tell",sender="Companion",text="UNREAD-WHILE-OFF"})
 local chat=ArjUI.privateChats.companion
 T.check(not chat.visible and chat.unread==1,"hidden tell remains unread")
 expandAlias("ui on")
 T.check(chat.visible and chat.unread==0,"visible private frame acknowledges tell on dashboard reveal")
 ArjUI:openPrivateChat("Companion")
 T.check(chat.visible and chat.unread==0,"opening conversation reads hidden tell")
 T.check(T.lines(chat.historyBox.name):find("UNREAD-WHILE-OFF",1,true),"hidden tell appears on reopen")
end}
T.steps(steps)
