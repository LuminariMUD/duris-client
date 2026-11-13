local T=DurisTest
-- Spell-casting progress in the VITALS PREP slot, driven by the server's text
-- lines (Duris src/net/sparser.c). Expiry delays are shortened for the test.
ArjUI.initialDataRequested=true
ArjUI.CAST_RESULT_SECONDS=.4
ArjUI.CAST_IDLE_SECONDS=.6
T.emit("Char.Status",{name="VisualTester",level=25,class="Conjurer",race="Human"})
T.emit("Char.Vitals",{hp=900,maxHp=1000,mana=0,maxMana=0,move=120,maxMove=120,usesMana=false})
local function prep() return ArjUI.prepLabel.message or "" end
local function tip() return ArjUI.prepLabel.toolTip or "" end
T.steps({
 {name="cast-progress",run=function()
  T.check(prep():find("PREP",1,true),"PREP slot shows preparation before casting: "..prep())
  raiseEvent("sysDataSendRequest","cast 'magic missile' orc")
  feedTriggers("You start chanting...\n")
  T.check(prep():find("magic miss…",1,true),"start line shows the typed spell: "..prep())
  feedTriggers("Casting: magic missile ***\n")
  T.check(prep():find("magic miss… ***",1,true),"progress shows remaining steps: "..prep())
  T.check(tip()=="Casting magic missile — 3 steps left.","progress tooltip: "..tip())
  feedTriggers("Casting: magic missile *\n")
  T.check(prep():find("magic miss… *",1,true) and not prep():find("**",1,true),"progress counts down")
 end},
 {name="cast-complete",wait=.7,run=function()
  feedTriggers("You complete your spell...\n")
  T.check(prep():find("magic miss… OK",1,true),"completion shown: "..prep())
 end,verify=function()
  T.check(prep():find("PREP",1,true) and not ArjUI.state.cast,"completion clears back to PREP: "..prep())
 end},
 {name="progress-without-start",run=function()
  -- Psionicists see progress lines without a chant line; abort text differs by class.
  feedTriggers("Casting: mind blast **\n")
  T.check(prep():find("mind blast **",1,true),"progress alone starts the display: "..prep())
  feedTriggers("You abort your mental image before it has become reality!\n")
  T.check(prep():find("ABORTED",1,true) and tip()=="Cast of mind blast aborted.","abort shown: "..tip())
 end},
 {name="unresolved-cast-expires",wait=1,run=function()
  feedTriggers("With the absence of sound, you begin using your hands to channel the weave...\n")
  T.check(prep():find("CASTING",1,true),"silent cast without a known spell: "..prep())
 end,verify=function()
  T.check(not ArjUI.state.cast and prep():find("PREP",1,true),"a cast with no outcome clears itself")
 end},
 {name="session-end-clears",run=function()
  feedTriggers("You call forth your prepared spell...\n")
  feedTriggers("Casting: fireball \n")
  T.check(prep():find("fireball",1,true) and tip()=="Casting fireball — 0 steps left.","zero-star progress: "..tip())
  ArjUI:endSession()
  T.check(not ArjUI.state.cast and not ArjUI.castTimer,"session end drops the cast")
  ArjUI:renderSpellPreparation()
  T.check(prep():find("PREP",1,true),"PREP restored after session end")
  -- Lines that merely mention casting do not match.
  feedTriggers("Someone says 'Casting: fireball ***'\n")
  T.check(not ArjUI.state.cast,"quoted text is not a cast")
  -- Leave a visible cast for the screenshot.
  ArjUI.CAST_IDLE_SECONDS=30
  raiseEvent("sysDataSendRequest","c 'lightning bolt' orc")
  feedTriggers("You start chanting...\n")
  feedTriggers("Casting: lightning bolt ****\n")
 end},
})
