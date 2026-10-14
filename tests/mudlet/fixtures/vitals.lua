local T=DurisTest
ArjUI.initialDataRequested=true
T.steps({
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
  T.check(ArjUI.state.lastExpGain==100,"experience delta")
  ArjUI:switchTab("stats")
 end}
})
