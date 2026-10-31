local T = DurisTest
ArjUI.initialDataRequested = true
T.emit("Char.Status", {name="VampTester", level=50, class="Anti-Paladin", race="Human"})

local maxHp = 1000
local previousGroupGauge

local function update(hp)
  T.emit("Char.Vitals", {hp=hp, maxHp=maxHp, mana=100, maxMana=100,
    move=100, maxMove=100, position="standing", usesMana=true})
  T.emit("Group.Status", {size=1, maxSize=8, members={
    {name="VampTester", hp=hp, maxHp=maxHp, move=100, maxMove=100,
      position="standing", inRoom=true, isNpc=false}
  }})
  T.emit("Combat.Update", {target={name="Vamped opponent",
    healthPercent=math.max(0, math.floor(hp * 100 / maxHp)), health="excellent", position="standing"}})
end

local function verify(hp)
  local pct = math.max(0, math.floor(hp * 100 / maxHp))
  local fill = math.min(100, pct) / 100
  local gauges = {
    player=ArjUI.hpGauge,
    tank=ArjUI.tankHpGauge,
    target=ArjUI.targetHpGauge,
    group=ArjUI.groupWidgets[1].hpGauge
  }

  for name, gauge in pairs(gauges) do
    -- Target intentionally retains a 1% sliver at zero HP until marked dead.
    local expected = name == "target" and math.max(.01, fill) or fill
    local frontWidth, backWidth = gauge.front:get_width(), gauge.back:get_width()
    T.check(frontWidth >= 0 and frontWidth <= backWidth + 1,
      name .. " HP fill stays inside its gauge at " .. hp .. "/" .. maxHp)
    T.check(math.abs(frontWidth - backWidth * expected) <= 1,
      name .. " HP fill has the expected rendered width at " .. hp .. "/" .. maxHp)
    T.check(math.abs(gauge.front:get_x() - gauge.back:get_x()) <= 1,
      name .. " HP fill stays aligned with its background")
  end

  local actualHp = string.format("%d/%d", hp, maxHp)
  for _, name in ipairs({"player", "tank", "group"}) do
    T.check(gauges[name].text.message:find(actualHp, 1, true),
      name .. " label preserves actual HP " .. actualHp)
  end
  local actualPct = string.format("%d%%", pct)
  T.check(gauges.tank.text.message:find(actualPct, 1, true), "tank label preserves actual HP percentage")
  T.check(gauges.target.text.message:find(actualPct, 1, true), "target label preserves actual HP percentage")
  T.check(ArjUI.state.hp == hp and ArjUI.state.hpmax == maxHp, "player state preserves actual HP")
  T.check(ArjUI.state.tankHp == hp and ArjUI.state.tankMaxHp == maxHp, "self-tank state preserves actual HP")
  T.check(ArjUI.state.group[1].hp == hp and ArjUI.state.group[1].maxHp == maxHp,
    "group state preserves actual HP")
  T.check(ArjUI.state.targetHpPct == pct, "target state preserves actual percentage")
  T.check(gmcp.Char.Vitals.hp == hp and gmcp.Group.Status.members[1].hp == hp,
    "presentation leaves incoming GMCP values intact")
  if previousGroupGauge then
    T.check(gauges.group ~= previousGroupGauge, "replacement group rows also contain HP fills")
  end
  previousGroupGauge = gauges.group
end

local steps = {}
for _, case in ipairs({
  {name="full-health", hp=1000},
  {name="vamped-110-percent", hp=1100},
  {name="vamped-150-percent", hp=1500},
  {name="vamped-250-percent", hp=2500},
  {name="back-to-full", hp=1000},
  {name="hurt-50-percent", hp=500},
  {name="zero-health", hp=0},
  {name="negative-health", hp=-5},
  {name="recovered-75-percent", hp=750}
}) do
  local hp = case.hp
  steps[#steps+1] = {name=case.name, run=function() update(hp) end, verify=function() verify(hp) end}
end
T.steps(steps)
