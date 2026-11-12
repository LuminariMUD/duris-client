local T=DurisTest
-- Sound alerts: defaults, the real media call, latch/cooldown rules, routing,
-- commands and persistence. Playback is recorded after the first real call,
-- because the isolated desktop has no audio device to listen to.
ArjUI.initialDataRequested=true
T.emit("Char.Status",{name="VisualTester",level=25,class="Warrior",race="Human"})
local played,stopped={},{}
local function vitals(hp,move) T.emit("Char.Vitals",{hp=hp,maxHp=1000,move=move or 120,maxMove=120,usesMana=false}) end
local function count(key) local n=0; for _,c in ipairs(played) do if c.key=="arjui-"..key then n=n+1 end end; return n end
local function settingsFile()
 local f=io.open(getMudletHomeDir().."/arjui_settings.json"); local text=f and f:read("*a") or ""; if f then f:close() end
 return yajl.to_value(text)
end
T.steps({
 {name="defaults-and-real-call",run=function()
  local s=ArjUI.sound
  T.check(s.enabled==false and s.volume==70,"sound starts off at volume 70")
  T.check(s.channels.tell and s.channels.lowhp and s.channels.lowmove and s.channels.alert and not s.channels.chat,"channel defaults")
  T.check(ArjUI:soundPath("duris-tell.wav"),"packaged sound files are installed")
  -- The real API accepts the table form (Mudlet 4.15+) without raising.
  T.check(ArjUI:playSound("tell",true),"ui sound test reaches Mudlet's playSoundFile")
  ArjUI:stopSounds()
  playSoundFile=function(t) played[#played+1]=t; return true end
  stopSounds=function(t) stopped[#stopped+1]=t; return true end
  ArjUI.soundLast={}
 end},
 {name="off-by-default",run=function()
  vitals(900); vitals(100,5)
  T.emit("Comm.Channel",{channel="tell",sender="Companion",text="quiet"})
  T.check(#played==0,"nothing plays until ui sound on")
 end},
 {name="enable-and-latch",run=function()
  expandAlias("ui sound on")
  T.check(ArjUI.sound.enabled and settingsFile().sound.enabled==true,"ui sound on is saved")
  vitals(900)
  vitals(200)
  T.check(count("lowhp")==1 and played[1].tag=="arjui" and played[1].volume==70 and played[1].name:find("duris%-lowhp%.wav$"),"crossing below 25% plays low HP once")
  vitals(150); vitals(300)
  T.check(count("lowhp")==1,"no repeat while below the 40% reset level")
  vitals(500); vitals(100)
  T.check(count("lowhp")==1,"re-armed alert still respects the 10 s cooldown")
  ArjUI.soundLast.lowhp=nil
  vitals(500); vitals(100)
  T.check(count("lowhp")==2,"re-armed after recovery plays again")
  vitals(900,120); vitals(900,10)
  T.check(count("lowmove")==1,"low movement plays once")
 end},
 {name="tells-chat-alerts",run=function()
  T.emit("Comm.Channel",{channel="tell",sender="Companion",text="hello"})
  T.emit("Comm.Channel",{channel="tell",sender="Companion",text="again"})
  T.check(count("tell")==1,"tell plays, a second within 2 s does not")
  T.emit("Comm.Channel",{channel="tell",sender="You -> Companion",text="reply"})
  T.check(count("tell")==1,"outgoing tells are silent")
  expandAlias("ui sound chat on")
  ArjUI:switchChatTab("all")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="seen in ALL"})
  T.check(count("chat")==0,"no chat sound for a line you are reading")
  ArjUI:switchChatTab("room")
  T.emit("Comm.Channel",{channel="nchat",sender="VisualTester",text="my own line"})
  T.check(count("chat")==0,"your own channel line is silent")
  T.emit("Comm.Channel",{channel="nchat",sender="Companion",text="hidden tab"})
  T.check(count("chat")==1,"line in another tab plays chat")
  ArjUI:switchChatTab("all")
  feedTriggers("Your glowing sanctuary fades.\n")
  T.check(count("alert")==1,"alert banner plays")
 end},
 {name="commands-and-persistence",run=function()
  expandAlias("ui sound volume 30")
  expandAlias("ui sound hp 30 50")
  expandAlias("ui sound hp 50 40")
  expandAlias("ui sound lowmove off")
  T.check(ArjUI.sound.volume==30 and ArjUI.sound.hp.alert==30 and ArjUI.sound.hp.reset==50,"volume and thresholds change; an inverted pair is rejected")
  T.check(not ArjUI.sound.channels.lowmove,"channel switch")
  expandAlias("ui sound stop")
  T.check(#stopped>=1 and stopped[#stopped].tag=="arjui","stop only targets this package's tag")
  local before=#played
  expandAlias("ui sound test lowmove")
  T.check(#played==before+1 and played[#played].volume==30,"test plays a disabled channel at the current volume")
  ArjUI:loadSettings()
  local s=ArjUI.sound
  T.check(s.enabled and s.volume==30 and s.hp.alert==30 and s.hp.reset==50 and s.channels.chat and not s.channels.lowmove,"sound settings survive reload")
  local n=ArjUI:normalizeSound({enabled="yes",volume="loud",hp={alert=80,reset=10},channels={tell=false}})
  T.check(n.enabled==false and n.volume==70 and n.hp.alert==25 and n.hp.reset==40 and n.channels.tell==false,"corrupt saved values fall back to defaults")
  expandAlias("ui sound")
  T.check(T.lines("ArjUI_Console"):find("Sound alerts: on, volume 30",1,true),"ui sound shows status")
 end},
})
