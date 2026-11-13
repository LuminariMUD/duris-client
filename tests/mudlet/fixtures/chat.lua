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
steps[#steps+1]={name="hidden-channel-unread",run=function()
 ArjUI:switchChatTab("all")
 for _,mode in ipairs({"hide","minimize","cover","ui-off"}) do
  if mode=="cover" then ArjUI:panelAction("output","maximize")
  elseif mode=="ui-off" then expandAlias("ui off")
  else ArjUI:panelAction("chat",mode) end
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="HIDDEN-"..mode})
  T.check(ArjUI.chatUnread.all==1,mode..": selected hidden tab retains unread messages")
  if mode=="ui-off" then
   expandAlias("ui layout reset")
   T.check(ArjUI.chatUnread.all==1,"resetting the layout while UI is off does not acknowledge messages")
  end
  ArjUI:switchChatTab("nchat")
  T.check((ArjUI.chatUnread.nchat or 0)>0,mode..": selecting a hidden tab does not acknowledge it")
  if mode=="cover" then ArjUI:panelAction("output","maximize")
  elseif mode=="ui-off" then expandAlias("ui on")
  else ArjUI:panelAction("chat","show") end
  T.check(not ArjUI.chatUnread.nchat and ArjUI.chatUnread.all==1,mode..": revealing acknowledges only the visible tab")
  ArjUI:switchChatTab("all")
 end
end}
steps[#steps+1]={name="channel-unread",run=function()
 ArjUI:switchChatTab("all")
 T.check(not ArjUI.chatUnread.all,"reading ALL clears its count")
 T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="UNREAD-1"})
 T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="UNREAD-2"})
 T.emit("Comm.Channel",{channel="gcc",sender="Companion",text="UNREAD-3"})
 T.check(ArjUI.chatUnread.nchat==2 and ArjUI.chatUnread.guild==1 and not ArjUI.chatUnread.all,"hidden channel tabs count, the active tab does not")
 T.check(ArjUI.chatTabs.nchat.arjLabel=="•NCHAT" and ArjUI.chatTabs.nchat.arjTip=="2 new messages" and ArjUI.chatTabs.guild.arjTip=="1 new message","unread tabs marked with counts in tooltips")
 T.check(ArjUI.chatTabs.room.arjLabel=="ROOM" and not ArjUI.chatTabs.room.arjTip,"quiet tab keeps its plain label")
 ArjUI:switchChatTab("nchat")
 T.check(not ArjUI.chatUnread.nchat and ArjUI.chatTabs.nchat.arjLabel=="NCHAT" and not ArjUI.chatTabs.nchat.arjTip,"opening a tab clears its count")
 T.emit("Comm.Channel",{channel="say",sender="Companion",text="UNREAD-4"})
 T.check(ArjUI.chatUnread.all==1 and ArjUI.chatUnread.room==1 and ArjUI.chatTabs.all.arjLabel=="•ALL","ALL counts while another tab is open")
 for i=1,101 do ArjUI:noteChatUnread("group") end
 T.check(ArjUI.chatTabs.group.arjLabel=="•GROUP" and ArjUI.chatTabs.group.arjTip=="101 new messages","large counts stay compact")
 expandAlias("ui off")
 T.emit("Comm.Channel",{channel="tell",sender="Stranger",text="TELL-UNREAD"})
 expandAlias("ui on")
 T.check(ArjUI:chatTabUnread("tells")==1 and ArjUI.chatTabs.tells.arjLabel=="•TELLS","TELLS shows unread private conversations")
 ArjUI:openPrivateChat("Stranger")
 T.check(ArjUI:chatTabUnread("tells")==0 and ArjUI.chatTabs.tells.arjLabel=="TELLS","reading the conversation clears TELLS")
 ArjUI:switchChatTab("all")
 -- Leave ROOM, GUILD and GROUP marked for the screenshot.
 ArjUI:panelAction("tell:stranger","hide"); ArjUI:panelAction("tell:companion","hide")
end}
T.steps(steps)
