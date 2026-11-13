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
T.check((not ArjUI.backdrop.hidden)==not compact, "background matches saved header mode")
T.check(ArjUI.frameArt.stylesheet:find("border-image",1,true),"slim frame in both modes")
if compact then T.check(ArjUI.bg.stylesheet:find("qlineargradient",1,true),"compact background uses gradient") end
local _,height=getMainWindowSize()
T.check(math.abs(ArjUI.uiRoot:get_y()-math.max(24,height*.028))<2,"initial slim geometry matches saved header mode")
T.check(ArjUI.creditBox.message:find(T.config.candidate.version,1,true), "footer version")
T.check(not ArjUI.inputBar, "native command line is the only input")
T.check(T.lines("ArjUI_Console"):find("Visual test: plain incoming text.",1,true), "text routed once to package console")
for key in pairs(ArjAuto.toggleDefaults) do T.check(ArjAuto.settings[key]==false, key.." defaults off") end
-- ui debug: a self-describing report for bug reports.
local report=table.concat(ArjUI:debugReportLines(),"\n")
T.check(report:find("Package: Arjinius Client "..T.config.candidate.version,1,true),"debug report names the package version")
T.check(report:find("Mudlet: 5.",1,true),"debug report names the Mudlet version")
T.check(report:find("Char%.Vitals%s+%d+s ago"),"debug report times received GMCP: "..report)
T.check(report:find("Ship%.Info%s+never"),"debug report marks GMCP that never arrived")
T.check(report:find("Artwork: frame found, backdrop found",1,true),"debug report finds the artwork")
T.check(report:find("ArjUI resources: %d+ handlers, %d+ timers"),"debug report counts owned resources")
local function resources()
 local text=table.concat(ArjUI:debugReportLines(),"\n")
 local timers,keys=text:match("ArjUI resources: %d+ handlers, (%d+) timers, %d+ triggers, %d+ aliases, (%d+) keys")
 return tonumber(timers),tonumber(keys)
end
local timers,keys=resources()
T.check(timers>=1 and ArjUI.mirrorTimer,"debug report includes the live mirror timer")
killTimer(ArjUI.mirrorTimer); ArjUI.mirrorTimer=nil
local stoppedTimers=resources()
T.check(stoppedTimers==timers-1,"debug timer count drops when the mirror timer stops")
ArjUI:setupRouteAll()
T.check(resources()==timers,"debug timer count recovers when mirroring restarts")
local searchKeys=#ArjUI.searchKeys
T.check(searchKeys==2,"search key bindings are live before hiding UI")
ArjUI:setVisible(false)
local _,hiddenKeys=resources()
T.check(hiddenKeys==keys-searchKeys,"debug key count drops when UI search bindings are removed")
ArjUI:setVisible(true)
local _,shownKeys=resources()
T.check(shownKeys==keys,"debug key count recovers when UI search bindings return")
expandAlias("ui debug")
T.check(T.lines("ArjUI_Console"):find("Arjinius Client diagnostics",1,true),"ui debug prints the report")
