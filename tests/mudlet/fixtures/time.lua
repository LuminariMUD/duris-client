-- do_time() output shape: Duris bca944c4, src/cmd/actinf.c:7009-7085.
-- Values are synthetic; feedTriggers exercises the real Mudlet trigger engine.
local T=DurisTest
local recordedSend=send
send=function(command, echo)
  recordedSend(command, echo)
  -- Keep the native sysDataSendRequest event, even in this disconnected profile.
  return T.originalSend(command, false)
end

local sequence=0
local function reply(hour)
  sequence=sequence+1
  return {
    'It is '..hour..', on the Day of the Deception',
    'The 14th Day of the Winter Wolf, Year '..(1600+sequence)..'.',
    'Time elapsed since boot-up: '..sequence..':10:20',
    'Current time is: Wed Oct 28 15:00:'..string.format('%02d',sequence)..' 2026 (UTC)',
  }
end
local function feed(lines)
  for _,text in ipairs(lines) do feedTriggers(text..'\n') end
  feedTriggers('Time reply boundary\n')
end
local function visible(lines, expected, description)
  -- main is emptied by route-all even when the player can see the output.
  local buffer=T.lines('ArjUI_Console')
  for i,text in ipairs(lines) do
    T.check((buffer:find(text,1,true)~=nil)==expected,description..' line '..i)
  end
end
local function login()
  raiseEvent('sysConnectionEvent')
  T.emit('Char.Status',{name='VisualTester'})
end

local automatic=reply('9pm')
local manual=reply('9am')
local staff=reply('6pm')
local late=reply('12am')
local partial=reply('10pm')
local afterPartial=reply('6am')
local interrupted=reply('11am')
local interruptedStaff=reply('3pm')
local commandsBeforeClick
T.steps({
  {name='login-time-query',run=login,wait=1.3,verify=function()
    T.check(#T.commands==1 and T.commands[1].command=='time','one automatic login time query')
    T.check(ArjUI.timeQuerySilent,'automatic query is silent after native send event')
  end},
  {name='automatic-time-reply',run=function()
    feed(automatic)
    visible(automatic,false,'automatic reply hidden')
    T.check(not ArjUI.timeQuerySilent,'current server reply completes silent query')
    T.check(ArjUI.state.timeOfDay=='night','automatic reply updates HUD')
  end},
  {name='manual-time-reply',run=function()
    -- expandAlias follows the command-line path and reaches the native send event.
    expandAlias('time')
    feed(manual)
    visible(manual,true,'manual reply visible')
    T.check(ArjUI.state.timeOfDay=='day','manual reply updates HUD')
    commandsBeforeClick=#T.commands
  end,actions=function() return {T.click(ArjUI.timeLabel)} end},
  {name='clicked-staff-time-reply',run=function()
    T.check(#T.commands==commandsBeforeClick+1 and T.commands[#T.commands].command=='time','HUD click sends one time request')
    feed(staff)
    feedTriggers('Kvark time: 1793199630\nShutdown in 15 minutes.\n')
    visible(staff,true,'clicked reply visible')
    visible({'Kvark time: 1793199630','Shutdown in 15 minutes.'},true,'staff and shutdown output preserved')
    T.check(ArjUI.state.timeOfDay=='dusk','HUD request updates time of day')
  end},
  {name='missing-time-reply',run=login,wait=1.3,verify=function()
    T.check(ArjUI.timeQuerySilent,'missing reply initially silent')
  end},
  {name='missing-time-reply-timeout',run=function() end,wait=3.2,verify=function()
    T.check(not ArjUI.timeQuerySilent,'missing reply cannot leave gagging enabled')
    -- No new send: verify timeout itself restores visibility for a late reply.
    feed(late)
    visible(late,true,'late reply visible after timeout')
    T.check(ArjUI.state.timeOfDay=='night','late reply still updates HUD')
  end},
  {name='partial-time-reply',run=login,wait=1.3,verify=function()
    feed({partial[1],partial[2]})
    visible({partial[1],partial[2]},false,'partial automatic reply hidden')
    T.check(ArjUI.timeQuerySilent,'partial reply still pending')
  end},
  {name='partial-time-reply-timeout',run=function() end,wait=3.2,verify=function()
    T.check(not ArjUI.timeQuerySilent,'partial reply cannot leave gagging enabled')
    feed(afterPartial)
    visible(afterPartial,true,'subsequent reply visible after partial timeout')
    T.check(ArjUI.state.timeOfDay=='dawn','subsequent reply updates HUD')
  end},
  {name='manual-command-during-query',run=login,wait=1.3,verify=function()
    T.check(ArjUI.timeQuerySilent,'query pending before manual command')
    expandAlias('time')
    T.check(not ArjUI.timeQuerySilent,'native command-line send cancels gagging')
    feed(interrupted)
    visible(interrupted,true,'manual reply visible while automatic query was pending')
  end},
  {name='hud-click-during-query',run=login,wait=1.3,verify=function()
    T.check(ArjUI.timeQuerySilent,'query pending before HUD click')
    commandsBeforeClick=#T.commands
  end,actions=function() return {T.click(ArjUI.timeLabel)} end},
  {name='hud-reply-during-query',run=function()
    T.check(#T.commands==commandsBeforeClick+1 and T.commands[#T.commands].command=='time','pending-query HUD click sends one request')
    T.check(not ArjUI.timeQuerySilent,'HUD send cancels pending gagging')
    feed(interruptedStaff)
    visible(interruptedStaff,true,'HUD reply visible while automatic query was pending')
  end},
  {name='disconnect-during-query',run=login,wait=1.3,verify=function()
    T.check(ArjUI.timeQuerySilent,'query pending before disconnect')
  end},
  {name='new-session-query',run=function()
    raiseEvent('sysDisconnectionEvent')
    T.check(not ArjUI.timeQuerySilent and next(ArjUI.timers)==nil,'disconnect clears gagging and timers')
    T.emit('Char.Status',{name='VisualTester'})
  end,wait=2.8,verify=function()
    T.check(ArjUI.timeQuerySilent,'old timeout cannot clear new session query')
    feed(reply('4pm'))
    T.check(not ArjUI.timeQuerySilent,'new session reply completes normally')
  end},
  {name='manual-before-login-timer',run=login,wait=.8,verify=function()
    T.check(ArjUI.timeQueryTimer and not ArjUI.timeQuerySilent,'automatic query is still delayed')
    commandsBeforeClick=#T.commands
    expandAlias('time')
    T.check(not ArjUI.timeQueryTimer,'manual time cancels the delayed query')
  end},
  {name='overlapping-manual-reply',run=function() end,wait=.35,verify=function()
    T.check(#T.commands==commandsBeforeClick and not ArjUI.timeQuerySilent,'canceled automatic query never sends or arms gagging')
    local lines=reply('5pm')
    feed(lines)
    visible(lines,true,'manual reply arriving after original timer deadline stays visible')
    T.check(ArjUI.state.timeOfDay=='dusk','early manual request initializes HUD')
  end},
  {name='hud-before-login-timer',run=login,wait=.1,verify=function()
    T.check(ArjUI.timeQueryTimer and not ArjUI.timeQuerySilent,'automatic query delayed before physical HUD click')
    commandsBeforeClick=#T.commands
  end,actions=function() return {T.click(ArjUI.timeLabel)} end},
  {name='early-hud-reply',run=function() end,wait=1.1,verify=function()
    T.check(#T.commands==commandsBeforeClick+1 and T.commands[#T.commands].command=='time','early HUD click sends only its own request')
    T.check(not ArjUI.timeQueryTimer and not ArjUI.timeQuerySilent,'early HUD click cancels delayed suppression')
    local lines=reply('8am')
    feed(lines)
    visible(lines,true,'early HUD reply stays visible')
    T.check(ArjUI.state.timeOfDay=='dawn','early HUD request initializes HUD')
  end},
  {name='server-clock-phases',run=function()
    for hour=0,23 do
      local phase=hour>=4 and hour<9 and 'dawn' or hour>=9 and hour<16 and 'day' or hour>=16 and hour<19 and 'dusk' or 'night'
      feed(reply((hour%12==0 and 12 or hour%12)..(hour<12 and 'am' or 'pm')))
      T.check(ArjUI.state.timeOfDay==phase,'server query phase at hour '..hour)
    end
    -- Actual color-stripped astralMsgs from src/world/weather.c.
    for _,entry in ipairs({
      {'The first hint of daylight can be seen on the northern horizon.','dawn'},
      {'The first rays of sunlight signal that day is approaching.','dawn'},
      {'The sun rises over the northern horizon.','dawn'},
      {'The day has begun.','day'},
      {'The sun hangs low on the southern sky.','day'},
      {'The sun starts to set in the south.','dusk'},
      {'Shadows stretch across the land as the sun limps towards the horizon.','dusk'},
      {'The sun vanishes behind the southern horizon.','dusk'},
      {'The night has begun.','night'},
    }) do
      feed({entry[1]})
      T.check(ArjUI.state.timeOfDay==entry[2],'server announcement: '..entry[1])
    end
    send=recordedSend
  end},
})
