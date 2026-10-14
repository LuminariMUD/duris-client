local T=DurisTest
ArjUI.initialDataRequested=true
T.emit("Char.Status",{name="VisualTester"})
T.emit("Char.Vitals",{hp=800,maxHp=1000,mana=100,maxMana=100,move=80,maxMove=100})
T.steps({
 {name="combat-affects",run=function()
  T.emit("Combat.Update",{target={name="bronze guardian",healthPercent=40,health="big nasty wounds",position="standing"},round={attacker="VisualTester",damage=73,damageType="slash",critical=false}})
  feedTriggers("[Damage: 73]\n")
  T.check(ArjUI.damage.fight==73,"GMCP damage not duplicated by text")
  feedTriggers("< T: Defender TP: sta TC: excellent E: bronze guardian EP: sta EC: big nasty wounds>\n")
  T.check(ArjUI.state.tank=="Defender" and ArjUI.state.target=="bronze guardian","prompt tank and target")
  T.emit("Char.Affects",{{name="sanctuary",duration=600},{name="heroism with a long name",duration=3600},{name="poison",duration=120},{name="stone skin",duration=60}})
  T.check(T.lines("ArjUI_BuffsBox"):find("sanctuary",1,true),"buff rendered")
  T.check(T.lines("ArjUI_DebuffsBox"):find("poison",1,true),"debuff rendered")
 end},
 {name="combat-end",run=function()
  feedTriggers("A bronze guardian is dead! R.I.P.\n")
  T.emit("Combat.Update",yajl.to_value('{"target":null,"tank":null}'))
  T.emit("Char.Affects",{})
  T.check(ArjUI.state.target==nil and ArjUI.damage.fight==0,"JSON null clears combat target and fight damage resets")
  T.check(T.lines("ArjUI_BuffsBox"):find("(none)",1,true),"expired affects cleared")
 end},
 {name="text-damage-next-fight",run=function()
  feedTriggers("[Damage: 21]\n")
  T.check(ArjUI.damage.fight==21,"next fight can use text damage fallback")
  T.emit("Combat.Update",{round={attacker="VisualTester",damage=21}})
  T.check(ArjUI.damage.fight==21,"text-first damage not duplicated by later GMCP")
 end}
})
