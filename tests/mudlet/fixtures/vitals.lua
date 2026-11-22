local T=DurisTest
ArjUI.initialDataRequested=true

local function status(level)
  T.emit("Char.Status",{name="VisualTester",level=level,class="Psionicist",race="Human"})
end

local function xp(exp,tnl)
  T.emit("Char.Vitals",{exp=exp,tnl=tnl})
end

local function checkXP(percent,label)
  local gauge=ArjUI.xpGauge
  T.check(math.abs(gauge.value-percent)<0.00001,"XP fill is "..percent.."% (got "..gauge.value..")")
  T.check(gauge.text.message==label,"XP label is "..label.." (got "..gauge.text.message..")")
end

local function reconnect()
  raiseEvent("sysDisconnectionEvent")
  checkXP(0,"TNL: —")
  raiseEvent("sysConnectionEvent")
  ArjUI.initialDataRequested=true
end

T.steps({
 {name="xp-unavailable",run=function()
  checkXP(0,"TNL: —")
  local gauge,room,search,console=ArjUI.xpGauge,ArjUI.roomLabel,ArjUI.searchBox,ArjUI.console
  T.check(gauge:get_height()>=16 and gauge:get_y()+gauge:get_height()<=room:get_y(),
    "XP label has enough space above the room row")
  T.check(search:get_y()+search:get_height()<=console:get_y(),"search row stays above the console")
 end},
 {name="full",run=function()
  T.emit("Char.Status",{name="VisualTester",level=25,class="Psionicist",race="Human",title="A deliberately long title for layout verification"})
  T.emit("Char.Vitals",{hp=1000,maxHp=1000,mana=500,maxMana=500,move=120,maxMove=120,exp=1000,tnl=9000,usesMana=true})
  T.check(ArjUI.hpGauge.value==100,"full HP gauge")
 end},
 {name="zero-nonmana",run=function()
  T.emit("Char.Vitals",{hp=0,maxHp=1000,mana=0,maxMana=0,move=0,maxMove=120,usesMana=false,position="sleeping"})
  T.check(ArjUI.hpGauge.value==0,"zero health gauge")
  T.check(ArjUI.mpGauge.text.message:find("n/a",1,true),"non-mana class")
 end},
 {name="zero-maxima",run=function()
  T.emit("Char.Vitals",{hp=0,maxHp=0,mana=0,maxMana=0,move=0,maxMove=0,usesMana=true})
  T.check(ArjUI.hpGauge.value==ArjUI.hpGauge.value,"zero maxima do not produce NaN")
 end},
 {name="missing-maxima-stats",run=function()
  T.emit("Char.Vitals",{hp=120,maxHp=1000,mana=10,maxMana=500,move=30,maxMove=120})
  T.emit("Char.Vitals",{hp=250,mana=200,move=60,exp=1100,tnl=8900,platinum=1,gold=2,silver=3,copper=4})
  T.check(ArjUI.state.hpmax==1000 and ArjUI.state.manamax==500,"missing maxima retain prior data")
  ArjUI:switchTab("stats")
 end,verify=function()
  T.check(ArjUI.state.lastExpGain==100,"experience delta")
  checkXP(11,"TNL: 8900   (last +100)")
 end},
 {name="xp-login",run=function()
  reconnect()
  status(25)
  xp(800000,800000)
  checkXP(50,"TNL: 800000")
 end},
 {name="xp-gain",run=function()
  xp(960000,640000)
 end,verify=function()
  checkXP(60,"TNL: 640000   (last +160000)")
  T.check(T.lines("ArjUI_Console"):find("[+160,000 exp] 640,000 to level",1,true),
    "ordinary gain still prints the correct XP notice")
 end},
 {name="xp-loss",run=function()
  xp(880000,720000)
  checkXP(55,"TNL: 720000   (last +160000)")
 end},
 {name="xp-recovery",run=function()
  xp(960000,640000)
 end,verify=function()
  checkXP(60,"TNL: 640000   (last +80000)")
 end},
 {name="xp-reconnect",run=function()
  reconnect()
  status(25)
  xp(960000,640000)
  checkXP(60,"TNL: 640000")
 end},
 {name="xp-partial",run=function()
  T.emit("Char.Vitals",{hp=80})
  checkXP(60,"TNL: 640000")
  xp(nil,610000)
  checkXP(0,"TNL: 610000")
  T.emit("Char.Vitals",{experience="960000",toNextLevel="640000"})
  checkXP(60,"TNL: 640000")
 end},
 {name="xp-level-up",run=function()
  xp(1560000,40000)
 end,verify=function()
  checkXP(97.5,"TNL: 40000   (last +600000)")
  -- An affect update can send the new Vitals before the level is announced.
  xp(80000,1520000)
  status(26)
  checkXP(5,"TNL: 1520000")
  xp(80000,1520000)
 end},
 {name="xp-level-loss",run=function()
  xp(10000,1590000)
  status(25)
  xp(1590000,10000)
 end,verify=function()
  checkXP(99.375,"TNL: 10000")
  T.check(not T.lines("ArjUI_Console"):find("[+1,580,000 exp]",1,true),"no false award on level loss")
 end},
 {name="xp-vitals-before-level",run=function()
  reconnect()
  status(25)
  xp(10000,1590000)
  xp(80000,1520000)
  status(26)
 end,verify=function()
  checkXP(5,"TNL: 1520000")
  T.check(not T.lines("ArjUI_Console"):find("[+70,000 exp]",1,true),"skip gain when the burst changes level")
 end},
 {name="xp-split-level-loss",run=function()
  reconnect()
  status(30)
  xp(10000,2990000)
  -- Aggregate required XP changes across level bands. Let the Vitals handler
  -- settle before delivering the Status packet for the new level.
  xp(1590000,10000)
 end,verify=function()
  T.check(not T.lines("ArjUI_Console"):find("[+1,580,000 exp]",1,true),
    "a changed XP threshold suppresses a false gain before Status arrives")
  status(29)
  checkXP(99.375,"TNL: 10000")
 end},
 {name="xp-threshold",run=function()
  reconnect()
  status(50)
  xp(39000000,1000000)
  xp(40000000,0)
 end,verify=function()
  checkXP(100,"TNL: 0 (XP ready)   (last +1000000)")
 end},
 {name="xp-max-level",run=function()
  reconnect()
  xp(500000,0)
  checkXP(0,"TNL: 0")
  status(56)
  checkXP(0,"TNL: n/a")
  T.check(T.lines("ArjUI_StatsBox"):find("TNL: n/a\n",1,true),
    "live stats uses the same TNL state as the output gauge")
 end},
 {name="xp-gmcp-disabled",run=function()
  xp(510000,0)
  raiseEvent("sysProtocolDisabled","GMCP")
 end,verify=function()
  checkXP(0,"TNL: —")
  T.check(T.lines("ArjUI_StatsBox"):find("TNL: —\n",1,true),
    "live stats uses the same TNL state as the output gauge")
  T.check(not ArjUI.state.lastExpGain,"a queued gain does not survive loss of GMCP")
 end}
})
