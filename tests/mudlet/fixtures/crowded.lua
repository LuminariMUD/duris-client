local T=DurisTest
ArjUI.initialDataRequested=true
local group={}
local npcs,items,players={},{},{}
for i=1,12 do
 group[i]={name="CompanionWithLongName"..i,hp=i*70,maxHp=1000,move=i*9,maxMove=120,rank=i==1 and "head" or "back",position=i==3 and "sitting" or "standing",inRoom=i~=4,isNpc=i==5}
 npcs[i]={name="a sentinel "..i,colored_name="&+RAn ornate sentinel "..i,fighting=i==1 and "you" or "Companion"}
 items[i]={name="a bronze relic "..i,colored_name="&+Ya bronze relic "..i}
 players[i]={name="Visitor"..i,alignment=i%2==0 and "good" or "evil"}
end
T.steps({
 {name="full-group-room",wait=.8,run=function()
  T.emit("Char.Status",{name="VisualTester",level=25,class="Warrior",race="Human"})
  T.emit("Char.Vitals",{hp=750,maxHp=1000,move=120,maxMove=120,usesMana=false})
  T.emit("Group.Status",{members=group,size=12,maxSize=12})
  T.emit("Room.Info",{num=90010,zone=9001,name="A long hall beneath the tower of ancient bronze and forgotten kings",area="A deliberately long area name for wrapping",exits={north=90011,["east #"]=90012},doors={east="locked"},npcs=npcs,items=items,players=players})
  T.check(#ArjUI.state.group==12 and #ArjUI.state.npcs==12 and #ArjUI.state.items==12 and #ArjUI.state.players==12,"crowded payload retained")
 end,actions=function()
  return {{type="scroll",x=ArjUI.tabContent:get_x()+80,y=ArjUI.tabContent:get_y()+100}}
 end},
 {name="member-removal",run=function()
  T.emit("Group.Status",{members={group[1],group[2]},size=2,maxSize=12})
  T.check(#ArjUI.state.group==2,"group member removal")
 end},
 {name="solo-empty-room",run=function()
  T.emit("Group.Status",{members={},size=0,maxSize=12})
  T.emit("Room.Info",{num=90011,zone=9001,name="Empty northern hall",area="Bronze Tower",exits={south=90010}})
  T.check(#ArjUI.state.group==0 and #ArjUI.state.npcs==0 and #ArjUI.state.items==0 and #ArjUI.state.players==0,"empty payload clears room and group")
 end}
})
