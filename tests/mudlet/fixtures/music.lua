local T=DurisTest
-- Music player: header placement, empty and filled playlists, the real
-- Mudlet media calls, sysMediaFinished filtering, pause/resume (and the
-- 4.19.1 stop fallback), commands, persistence and a real title click.
-- After the real calls, playback is recorded: the desktop has no audio device.
-- The bundled playlist is checked first; later steps play only test files
-- from the profile folder so their order is known.
ArjUI.initialDataRequested=true
T.emit("Char.Status",{name="VisualTester",level=25,class="Warrior",race="Human"})
local played,stopped,paused={},{},{}
local folder=ArjUI:musicUserFolder()
local function settingsFile()
 local f=io.open(getMudletHomeDir().."/arjui_settings.json"); local text=f and f:read("*a") or ""; if f then f:close() end
 return yajl.to_value(text)
end
local function copy(from,to)
 local i=assert(io.open(from,"rb")); local data=i:read("*a"); i:close()
 local o=assert(io.open(to,"wb")); o:write(data); o:close()
end
local function finished(file,started,...)
 ArjUI.musicNow.started=started or getEpoch()-5
 raiseEvent("sysMediaFinished",file,folder.."/"..file,...)
end
local function current() return ArjUI.musicTracks[ArjUI.musicIndex] end
local realPlay,realStop,realPause=playMusicFile,stopMusic,pauseMusic
local bundledFolders=ArjUI.musicFolders
local empty=getMudletHomeDir().."/music-test-empty"
T.steps({
 {name="empty-header",run=function()
  local w,h=getMainWindowSize()
  local insetX,banner,rootW=ArjUI:workspaceGeometry(w,h)
  local t,reset=ArjUI.musicTitle,ArjUI.resetLayoutButton
  T.check(ArjUI.music.volume==40 and ArjUI.music.shuffle and ArjUI.music.show,"music defaults: volume 40, shuffle on, shown")
  local tr=ArjUI.musicTracks
  T.check(#tr==15 and ArjUI.musicState=="stopped","the 15 bundled tracks are listed and nothing plays")
  local bad
  for i,t in ipairs(tr) do
    if not (t.file:match("^%d%d %- .+%.mp3$") and t.path:find("/Arjinius Client/music/",1,true) and not t.title:match("^%d")) then bad=t.file end
    local nextTitle=tr[i%#tr+1].title
    if t.title:gsub(" II$","")==nextTitle:gsub(" II$","") then bad=t.title.." / "..nextTitle end
  end
  T.check(not bad,"bundled tracks are numbered MP3s with clean titles; no song's two takes are adjacent ("..tostring(bad)..")")
  T.check(tr[1].title=="The Deep Gaol of Ur-Malek","the shipped order starts with The Deep Gaol of Ur-Malek")
  T.check(t:get_x()+t:get_width()==insetX+rootW,"the title ends at the workspace's right edge")
  T.check(t:get_y()==reset:get_y() and t:get_y()+t:get_height()<=banner,"the strip sits in the header band, level with Reset layout")
  T.check(ArjUI.musicPrev:get_x()>reset:get_x()+reset:get_width(),"the strip clears the layout buttons")
  T.check(ArjUI.musicPrev:get_x()+3*ArjUI.MUSIC_BUTTON+3*ArjUI.MUSIC_GAP==t:get_x(),"previous, play and next sit left of the title")
  ArjUI.musicFolders=function() return {empty} end
  ArjUI:scanMusic()
  T.check(#ArjUI.musicTracks==0,"a profile without music folders has an empty playlist")
  expandAlias("ui music play")
  T.check(ArjUI.musicState=="stopped" and T.lines("ArjUI_Console"):find("no tracks",1,true),"play with no tracks explains where files go")
 end},
 {name="bundled-real-play",wait=2.5,run=function()
  ArjUI.musicFolders=bundledFolders
  ArjUI:scanMusic()
  T.check(ArjUI:musicPlayIndex(4),"Mudlet accepts a bundled MP3")
 end,verify=function()
  -- An undecodable file ends at once, which the player turns into a stop.
  T.check(ArjUI.musicState=="playing" and current().title=="Trance of the Wild","a bundled MP3 is still playing after two seconds")
  if getPlayingMusic then
    local list=getPlayingMusic() or {}
    local names=yajl.to_string(list)
    T.check(names:find("Trance of the Wild",1,true),"Mudlet reports the bundled track as playing ("..names..")")
  end
  expandAlias("ui music 4")
  T.check(ArjUI.musicState=="playing" and current().title=="Trance of the Wild",
    "reselecting an already playing track after two seconds keeps it playing")
  ArjUI:musicStop()
  ArjUI.musicFolders=function() return {empty} end
  ArjUI:scanMusic()
 end},
 {name="tracks-real-calls",run=function()
  if lfs.attributes(folder,"mode")~="directory" then assert(lfs.mkdir(folder)) end
  local wav=assert(ArjUI:soundPath("duris-tell.wav"))
  copy(wav,folder.."/02_Second_Song.wav"); copy(wav,folder.."/01 - First Theme.wav"); copy(wav,folder.."/.hidden.wav")
  local f=io.open(folder.."/notes.txt","w"); f:write("not music"); f:close()
  ArjUI.musicFolders=function() return {folder} end
  expandAlias("ui music shuffle off")
  expandAlias("ui music rescan")
  local tr=ArjUI.musicTracks
  T.check(#tr==2 and tr[1].title=="First Theme" and tr[2].title=="Second Song","rescan finds audio files in name order with readable titles; skips text and dot files")
  T.check(T.lines("ArjUI_Console"):find("2 tracks found",1,true),"rescan reports the count")
  -- The real API accepts these table forms without raising.
  T.check(ArjUI:musicPlayIndex(1) and ArjUI.musicState=="playing","the real playMusicFile call starts track 1")
  T.check(settingsFile().music.track=="01 - First Theme.wav","the current track is remembered")
  if realPause then
    ArjUI:musicToggle()
    T.check(ArjUI.musicState=="paused","the real pauseMusic call pauses")
    ArjUI:musicToggle()
    T.check(ArjUI.musicState=="playing","play again resumes")
  else
    T.skip("this Mudlet has no pauseMusic")
  end
  ArjUI:musicStop()
  T.check(ArjUI.musicState=="stopped","the real stopMusic call stops")
  ArjUI:musicPlayIndex(1)
 end,verify=function()
  T.check(ArjUI.musicPlay:get_x() and ArjUI.musicState=="playing","the playing state is on screen for the screenshot")
 end},
 {name="finish-rules",run=function()
  ArjUI:musicStop()
  local active
  playMusicFile=function(t) active=t; played[#played+1]=t; return true end
  stopMusic=function(t)
    stopped[#stopped+1]=t
    if active then
      local path=active.name
      active=nil
      raiseEvent("sysMediaFinished",path:match("[^/]+$"),path)
    end
    return true
  end
  pauseMusic=function(t) paused[#paused+1]=t; return true end
  ArjUI:musicPlayIndex(1)
  local p=played[1]
  T.check(p and p.key and p.tag=="arjui-music" and p.volume==40 and p.loops==1 and p.name:find("01 %- First Theme%.wav$"),
    "play sends the track with a playback key and the music tag")
  finished("02_Second_Song.wav")
  T.check(current().file=="01 - First Theme.wav","a finish for another file is ignored")
  finished("01 - First Theme.wav",nil,"sound","arjui-tell","arjui")
  finished("01 - First Theme.wav",nil,"music","","")
  T.check(#played==1,"another sound or unkeyed music with the same name is ignored")
  local realPlaying=getPlayingMusic
  getPlayingMusic=function(filter)
    T.check(filter.key==p.key,"legacy finish checks the active playback key")
    return {{key=p.key}}
  end
  finished("01 - First Theme.wav")
  getPlayingMusic=realPlaying
  T.check(#played==1,"a legacy finish from other media leaves a live track alone")
  expandAlias("ui music 1")
  T.check(#played==2 and played[2].key~=p.key and ArjUI.musicState=="playing",
    "reselecting stops the old playback before its synchronous legacy finish")
  finished("01 - First Theme.wav",nil,"music",p.key,"arjui-music")
  T.check(#played==2 and ArjUI.musicState=="playing","a delayed keyed finish for the old playback is ignored")
  ArjUI:musicStep(1)
  finished("02_Second_Song.wav",getEpoch(),"music",played[3].key,"arjui-music")
  T.check(ArjUI.musicState=="stopped" and #played==3,"an immediate finish without a start stops instead of skipping on")
  T.check(T.lines("ArjUI_Console"):find("could not play 02_Second_Song.wav",1,true),"and says the file could not be played")
  ArjUI:musicPlayIndex(1)
  raiseEvent("sysMediaStarted","01 - First Theme.wav",folder.."/01 - First Theme.wav","music",played[4].key,"arjui-music")
  finished("01 - First Theme.wav",getEpoch(),"music",played[4].key,"arjui-music")
  T.check(#played==5 and current().file=="02_Second_Song.wav","a confirmed short track advances on finish")
  finished("02_Second_Song.wav")
  T.check(#played==6 and current().file=="01 - First Theme.wav","a legacy finish advances and wraps the playlist")
  ArjUI:musicStop()
  T.check(stopped[#stopped].tag=="arjui-music","stop targets only the music tag")
  raiseEvent("sysMediaFinished","01 - First Theme.wav",folder.."/01 - First Theme.wav")
  T.check(#played==6,"after a stop, a late finish does not restart playback")
 end},
 {name="pause-and-fallback",run=function()
  expandAlias("ui music 2")
  T.check(current().file=="02_Second_Song.wav" and ArjUI.musicState=="playing","ui music <number> plays that track")
  expandAlias("ui music pause")
  T.check(ArjUI.musicState=="paused" and paused[#paused].tag=="arjui-music","pause uses pauseMusic")
  finished("02_Second_Song.wav")
  T.check(current().file=="02_Second_Song.wav" and ArjUI.musicState=="paused","no advance while paused")
  local n=#played
  local key=played[n].key
  expandAlias("ui music play")
  T.check(#played==n+1 and played[#played].key==key and played[#played].continue and ArjUI.musicState=="playing",
    "play resumes the paused track with the same key")
  local stubPause=pauseMusic
  pauseMusic=function() return nil,"fixture pause failure" end
  expandAlias("ui music pause")
  T.check(ArjUI.musicState=="playing","an API pause failure does not report paused")
  pauseMusic=stubPause
  pauseMusic=nil
  ArjUI:musicToggle()
  T.check(ArjUI.musicState=="stopped","without pauseMusic (Mudlet 4.19.1) pause stops")
  ArjUI:musicToggle()
  T.check(ArjUI.musicState=="playing" and played[#played].name:find("02_Second_Song%.wav$"),"and play restarts the same track")
  pauseMusic=function(t) paused[#paused+1]=t; return true end
  expandAlias("ui music next")
  T.check(current().file=="01 - First Theme.wav","next wraps")
  expandAlias("ui music prev")
  T.check(current().file=="02_Second_Song.wav","prev wraps back")
 end},
 {name="mute-and-missing-files",run=function()
  expandAlias("ui music volume 0")
  T.check(ArjUI.musicState=="stopped" and settingsFile().music.volume==0,"zero volume stops playback and persists")
  local n=#played
  expandAlias("ui music play")
  expandAlias("ui music next")
  expandAlias("ui music 1")
  T.check(#played==n and ArjUI.musicState=="stopped","muted playback never requests a preload")
  expandAlias("ui music volume 25")
  T.check(#played==n,"raising volume does not start music")
  expandAlias("ui music 1")
  T.check(#played==n+1 and played[#played].volume==25,"play works after unmuting")
  local missing=ArjUI.musicTracks[2].path
  assert(os.rename(missing,missing..".bak"))
  expandAlias("ui music 2")
  T.check(#played==n+1 and current().file=="01 - First Theme.wav","a missing selection does not replace the current track")
  finished("01 - First Theme.wav")
  T.check(ArjUI.musicState=="stopped" and #played==n+1,"automatic advance to a missing file clears playback")
  assert(os.rename(missing..".bak",missing))
  local stubPlay=playMusicFile
  playMusicFile=function() return nil,"fixture play failure" end
  expandAlias("ui music 1")
  T.check(ArjUI.musicState=="stopped" and T.lines("ArjUI_Console"):find("fixture play failure",1,true),
    "a failed play reports the cause and clears playback")
  playMusicFile=stubPlay
 end},
 {name="commands-persistence",run=function()
  expandAlias("ui music volume 25")
  expandAlias("ui music shuffle on")
  T.check(ArjUI.music.volume==25 and ArjUI.music.shuffle,"volume and shuffle change")
  expandAlias("ui music next")
  T.check(played[#played].volume==25,"the new volume applies to the next track")
  for _=1,6 do
    local before=ArjUI.musicIndex
    ArjUI:musicStep(1)
    T.check(ArjUI.musicIndex~=before,"shuffle never repeats the track that just played")
  end
  expandAlias("ui music hide")
  T.check(not ArjUI.music.show and ArjUI.musicTitle.hidden,"ui music hide hides the strip")
  expandAlias("ui music 9")
  T.check(T.lines("ArjUI_Console"):find("no track 9",1,true),"an out-of-range number is refused")
  expandAlias("ui music dance now please")
  T.check(T.lines("ArjUI_Console"):find("[music] unknown command",1,true),"unknown commands point to usage")
  ArjUI:loadSettings()
  local m=ArjUI.music
  T.check(m.volume==25 and m.shuffle and not m.show and m.track,"music settings survive reload")
  local n=ArjUI:normalizeMusic({volume="loud",shuffle="yes",show=0,track=7})
  T.check(n.volume==40 and n.shuffle==true and n.show==true and n.track==nil,"corrupt saved values fall back to defaults")
  T.check(ArjUI:normalizeMusic({shuffle=false}).shuffle==false,"a saved shuffle off is kept")
  expandAlias("ui music show")
  expandAlias("ui music shuffle off")
  T.check(ArjUI.music.show and not ArjUI.musicTitle.hidden,"ui music show brings it back")
  expandAlias("ui music")
  T.check(T.lines("ArjUI_Console"):find("Music: playing, volume 25, shuffle off",1,true),"ui music shows status and the track list")
  ArjUI:renderMusic()
 end},
 {name="title-click",run=function() end,actions=function() return {T.click(ArjUI.musicTitle)} end},
 {name="menu-and-narrow",run=function()
  T.check(ArjUI.currentMenu~=nil,"a real click on the title opens the music menu")
  if ArjUI.currentMenu then ArjUI:disposeWidget(ArjUI.currentMenu); ArjUI.currentMenu=nil end
  local w,h=getMainWindowSize()
  local insetX,banner,rootW=ArjUI:workspaceGeometry(w,h)
  ArjUI:layoutMusic(insetX,banner-24,420)
  T.check(ArjUI.musicFits and ArjUI.musicTitleWidth<ArjUI.MUSIC_TITLE_MAX,"a narrow window shortens the title first")
  ArjUI:layoutMusic(insetX,banner-24,300)
  T.check(not ArjUI.musicFits and ArjUI.musicTitle.hidden,"a window too narrow for the strip hides it")
  ArjUI:layout()
  T.check(ArjUI.musicFits and not ArjUI.musicTitle.hidden and ArjUI.musicTitleWidth==ArjUI.MUSIC_TITLE_MAX,"a normal layout restores it")
  expandAlias("ui debug")
  T.check(T.lines("ArjUI_Console"):find("Music: playing, 2 tracks, volume 25",1,true),"ui debug reports the player")
  ArjUI.musicFolders=bundledFolders
  local n=#played
  ArjUI.musicNow.started=getEpoch()-5
  ArjUI:kill()
  T.check(stopped[#stopped].tag=="arjui-music" and ArjUI.musicState=="stopped" and #played==n,
    "kill stops our music without starting a track inside the synchronous finish callback")
  playMusicFile,stopMusic,pauseMusic=realPlay,realStop,realPause
  ArjUI:init(); ArjUI:setupAliases()
  T.check(ArjUI.musicState=="stopped" and #ArjUI.musicTracks==17 and current().file==ArjUI.music.track,"after a reload the bundled and personal tracks are listed, the last track is selected, and nothing plays")
  T.check(ArjUI.musicTracks[16].title=="First Theme","personal tracks follow the bundled ones")
 end},
})
