local T=DurisTest
ArjUI.initialDataRequested=true
T.steps({
 {name="bridge-contract",run=function()
  ArjUI:switchTab("ship")
  T.emit("Ship.Contacts",{shipKey="1:9007199254740993",heading=0,speed=0,contacts={
   {id="**",name="Dock one",x=51,y=50,range=2,bearing=90,arc="SF",you_targeting=false},
   {id="**",name="Dock two",x=50,y=49,range=2,bearing=0,arc="PS",you_targeting=true,targeting_you=true}}})
  T.check(ArjUI.state.ship.contacts==nil,"contacts-first waits for matching Info")
  T.emit("Ship.Info",{shipKey="1:9007199254740993",name="A <red> & literal ship",id="**",captain="O'Neil",frags=0,maxSpeed=50,
   bridge={hullWeight=330000,load={current=80,max=165},setHeading=359,setSpeed=8,displayCrewStamina=-20,crewStaminaBand="fatigued",target={id="ZZ",name="Unseen <target>"}},
   crewStamina=-400,maxCrewStamina=800,
   weapons={{slot=0,name="Damaged gun",position="port",positionLabel="Port",ammo=0,maxAmmo=12,damage=100,destroyed=true,ready=true,timer=0,statusText="Badly Damaged"}},
   equipment={{slot=1,name="Levistone",damage=21,timer=6,ready=false,statusText="Badly Damaged"}},cargo={current=5,max=70,items={{slot=2,name="Forbidden relics",crates=5,invoicePrice=156000,contraband=true}}}})
  local out=T.lines("ArjUI_ShipBox")
  for _,fact in ipairs({"A <red> & literal ship","Hull weight: 330000","Weight load: 80/165","Ordered heading: 359","Ordered speed: 8","Stamina: -20/800","Raw stamina: -400","Fatigue: fatigued","[ZZ] Unseen <target>","Damage: 100","Timer: Ready","Timer count: 6","Server status: Badly Damaged","bridge ammo **","Invoice price: 156000","X:51","Y:50","our Starboard / their Forward","our lock","targeting you"}) do T.check(out:find(fact,1,true),"bridge fact "..fact) end
  T.check(#ArjUI.state.ship.contacts==2,"duplicate displayed IDs are retained")
  T.check(ArjAuto:targetContact().name=="Dock two","target flag disambiguates duplicate ID for automation")
 end},
 {name="unseen-lock",run=function()
  T.emit("Ship.Contacts",{shipKey="1:9007199254740993",heading=359,speed=3,contacts={}})
  T.check(T.lines("ArjUI_ShipBox"):find("Unseen <target>",1,true),"explicit unseen target survives empty Contacts")
  T.check(ArjAuto:targetContact()==nil,"unseen display target has no automation bearing")
 end},
 {name="bridge-change",run=function()
  T.emit("Ship.Contacts",{shipKey="2:2",heading=180,speed=4,contacts={}})
  T.check(ArjUI.state.ship.heading==359,"other vessel Contacts cannot alter current navigation")
  T.emit("Ship.Info",{shipKey="2:2",name="Second docked ship",id="**",bridge={target=yajl.null}})
  T.check(ArjUI.state.ship.heading==180 and ArjUI.state.ship.maxSpeed==nil,"matching Contacts-first accepted on bridge change")
  local out=T.lines("ArjUI_ShipBox")
  T.check(not out:find("330000",1,true) and not out:find("Unseen",1,true),"bridge replacement clears old facts and target")
  T.emit("Ship.Contacts",{shipKey="1:9007199254740993",heading=90,speed=99,contacts={{id="OLD"}}})
  T.check(ArjUI.state.ship.heading==180,"late previous-vessel Contacts stay isolated")
 end},
 {name="legacy-rollout",run=function()
  T.emit("Ship.Info",{name="Old server ship",weapons={}})
  T.check(ArjUI.state.ship.heading==nil,"untagged rollout retires keyed navigation")
  T.emit("Ship.Contacts",{heading=0,speed=0,contacts={{id="**",bearing=10},{id="**",bearing=20}}})
  ArjUI.state.ship.target="**"
  T.check(ArjAuto:targetContact()==nil,"ambiguous legacy designation cannot drive relative orders")
  T.emit("Ship.Contacts",{contacts={}})
  T.check(ArjUI.state.ship.target==nil,"legacy empty Contacts clears lock")
 end},
 {name="authoritative-departure",run=function()
  T.emit("Ship.Info",{})
  feedTriggers("Captain: Ghost\nContact listing H: 99 S: 99\n[**] Ghost X: 1 Y: 2 R: 3 B: 4 H: 5 S: 6 |SFS\nLocked onto [OLD]: Ghost\n")
  T.check(not T.lines("ArjUI_ShipBox"):find("Ghost",1,true),"late fallback cannot revive cleared ship")
  ArjUI:resetShip()
  feedTriggers("You board Text ship\nContact listing H: 0 S: 0\n[**] Text contact X: 51 Y: 49 R: 2 B: 20 H: 60 S: 4 |SFS\n")
  local c=ArjUI.state.ship.textContacts[1]
  T.check(c.id=="**" and c.status=="sinking" and not c.sunk and c.arc=="SF","real contact suffix and docked ID grammar")
 end}
})
