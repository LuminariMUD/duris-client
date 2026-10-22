local T = DurisTest
ArjUI.initialDataRequested = true -- Login/time behavior has its own scenario.
T.emit("Char.Status", {name="VisualTester",level=25,class="Psionicist",race="Human",alignment="good",guild="",title="Visual test"})
T.emit("Char.Vitals", {hp=150,maxHp=1000,mana=350,maxMana=500,move=60,maxMove=120,exp=10000,tnl=5000,
 platinum=1,gold=2,silver=3,copper=4,position="standing",usesMana=true})
T.emit("Group.Status", {size=2,maxSize=8,members={
 {name="VisualTester",hp=150,maxHp=1000,move=60,maxMove=120,position="standing",rank="head",isNpc=false,inRoom=true},
 {name="A deliberately long companion name",hp=900,maxHp=1000,move=100,maxMove=120,position="sitting",rank="back",isNpc=false,inRoom=true}}})
feedTriggers("Visual test: plain incoming text.\n")
T.check(ArjUI.playerName=="VisualTester", "character identity")
T.check(ArjUI.state.hp/ArjUI.state.hpmax==.15, "HP 15 percent")
T.check(ArjUI.state.mana/ArjUI.state.manamax==.7, "mana 70 percent")
T.check(ArjUI.state.move/ArjUI.state.movemax==.5, "movement 50 percent")
T.check(#ArjUI.state.group==2, "two group members")
local compact=ArjUI.settings.compactHeader
T.check(not not ArjUI.bg.stylesheet:find("border-image",1,true)==not compact, "background matches saved header mode")
if compact then T.check(ArjUI.bg.stylesheet:find("qlineargradient",1,true),"compact background uses gradient") end
local _,height=getMainWindowSize()
T.check(math.abs(ArjUI.uiRoot:get_y()-height*(compact and .028 or .105))<2,"initial geometry matches saved header mode")
T.check(ArjUI.creditBox.message:find(T.config.candidate.version,1,true), "footer version")
T.check(not ArjUI.inputBar, "native command line is the only input")
T.check(T.lines("ArjUI_Console"):find("Visual test: plain incoming text.",1,true), "text routed once to package console")
for key in pairs(ArjAuto.toggleDefaults) do T.check(ArjAuto.settings[key]==false, key.." defaults off") end
