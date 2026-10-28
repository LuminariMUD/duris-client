-- Synthetic bids and color-stripped do_dice() output from Duris tradeskill.c.
local T=DurisTest
ArjUI.initialDataRequested=true
ArjUI.playerName='VisualTester'
local function stored()
  local f=assert(io.open(ArjAuto:path()))
  local text=f:read('*a'); f:close()
  return text
end
local function roll(name,index,sides,result)
  feedTriggers(string.format("Result for %s's roll #%d of a %d sided die: %d.\n",name,index,sides,result))
end
local function bid(names,score)
  ArjAuto.bidScores={}
  expandAlias('split start')
  for _,name in ipairs(names) do
    ArjAuto.bidScores[name]=score
    feedTriggers(name.." group-says 'bid'\n")
  end
  ArjAuto:save()
end
T.steps({
  {name='interleaved-paid-split',run=function()
    bid({'A','B'},10)
    local before=stored()
    expandAlias('split roll')
    T.check(T.commands[#T.commands].command=='dice 1 20','paid alias requests weighted die')
    for _,case in ipairs({{'Companion',1,6,2},{'Companion',1,20,2},
        {'VisualTester',1,6,2},{'VisualTester',2,20,2},
        {'VisualTester',1,20,0},{'VisualTester',1,20,21}}) do
      roll(unpack(case))
      T.check(ArjAuto.split.caught==0 and ArjAuto.split.pending==1 and stored()==before,'unrelated or invalid roll leaves split and persisted scores untouched')
    end
    roll('VisualTester',1,20,2)
    local data=yajl.to_value(stored())
    T.check(ArjAuto.split.pending==0 and data.bidScores.A==8 and data.bidScores.B==11,'only matching result awards and persists paid scores')
    local after=stored()
    roll('VisualTester',1,20,2)
    T.check(stored()==after,'completed roll cannot award twice')
  end},
  {name='uniform-large-split',run=function()
    bid({'A','B','C','D','E','F'},20)
    expandAlias('split roll')
    T.check(T.commands[#T.commands].command=='dice 2 100','120 tickets use independent base-100 digits')
    local counts,tickets,rejected={},{},0
    -- Enumerate every equally likely pair through the production ticket mapper.
    for value=0,9999 do
      local ticket=ArjAuto:splitTicket(value)
      if ticket then
        tickets[ticket]=(tickets[ticket] or 0)+1
        local winner=ArjAuto.split.dice[ticket]
        counts[winner]=(counts[winner] or 0)+1
      else rejected=rejected+1 end
    end
    for ticket=1,120 do T.check(tickets[ticket]==83,'uniform accepted outcomes for ticket '..ticket) end
    for _,name in ipairs(ArjAuto.split.bids) do T.check(counts[name]==1660,'equal weighted odds for '..name) end
    T.check(rejected==40,'incomplete bucket is rejected')
    local before=stored()
    roll('VisualTester',2,100,100)
    T.check(ArjAuto.split.caught==0,'out-of-order second die ignored')
    roll('VisualTester',1,100,100)
    roll('VisualTester',1,100,100)
    roll('Companion',2,100,100)
    T.check(ArjAuto.split.caught==1 and stored()==before,'duplicate and foreign digits cannot complete a split')
    local commandCount=#T.commands
    expandAlias('split roll')
    T.check(#T.commands==commandCount,'second roll cannot overlap outstanding dice')
    roll('VisualTester',2,100,100)
    T.check(ArjAuto.split.caught==0 and ArjAuto.split.pending==2 and stored()==before,'rejected pair retries without awarding or spending')
    T.check(#T.commands==commandCount+1 and T.commands[#T.commands].command=='dice 2 100','rejection requests fresh independent digits')
    roll('VisualTester',1,100,1)
    roll('VisualTester',2,100,1)
    local data=yajl.to_value(stored())
    T.check(ArjAuto.split.pending==0 and data.bidScores.A==14 and data.bidScores.F==20,'accepted retry persists one weighted award')
  end},
  {name='free-split-and-session-reset',run=function()
    bid({'A','B'},10)
    local before=stored()
    expandAlias('split free')
    T.check(T.commands[#T.commands].command=='dice 1 2','free alias gives each bidder one ticket')
    roll('VisualTester',1,2,2)
    T.check(ArjAuto.split.pending==0 and ArjAuto.split.result==2 and stored()==before,'free award leaves persisted scores untouched')
    bid({'A','B'},10)
    expandAlias('split roll')
    raiseEvent('sysDisconnectionEvent')
    ArjUI.playerName='VisualTester'
    roll('VisualTester',1,20,2)
    T.check(ArjAuto.split.pending==0 and stored()==before,'session reset discards outstanding split')
    ArjUI.playerName=nil
    expandAlias('split start')
    feedTriggers("A group-says 'bid'\n")
    local count=#T.commands
    expandAlias('split roll')
    T.check(#T.commands==count,'missing character identity cannot start an uncorrelated roll')
  end},
})
