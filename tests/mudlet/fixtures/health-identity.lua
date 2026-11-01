local T = DurisTest
local playerHp, playerMax = 800, 1000

local function vitals(hp)
  playerHp = hp or playerHp
  T.emit("Char.Vitals", {hp=playerHp, maxHp=playerMax, mana=100, maxMana=100,
    move=100, maxMove=100, position="standing"})
end

local function playerUnchanged()
  T.check(ArjUI.state.hp == playerHp and ArjUI.state.hpmax == playerMax, "combat data preserves player HP state")
  T.check(ArjUI.hpGauge.value == playerHp / playerMax * 100, "player fill uses only Char.Vitals")
  T.check(ArjUI.hpGauge.text.message == string.format("YOU HP %d/%d", playerHp, playerMax), "player bar explicitly identifies YOU")
  T.check(ArjUI.hpGauge.front.stylesheet == ArjUI:getHpBarStyle(playerHp / playerMax * 100), "pet/enemy health cannot recolor player HP")
  T.check(math.abs(ArjUI.hpGauge.front:get_width() - ArjUI.hpGauge.back:get_width() * playerHp / playerMax) <= 1,
    "rendered player fill remains proportional to own HP")
end

local function tank(name, pct, own)
  T.check(ArjUI.tankNameLabel.message == (own and "You: " or "Tank: ") .. name, "tank header identifies whose HP is shown")
  T.check(ArjUI.tankHpGauge.value == pct, "tank fill belongs to the named combatant")
  T.check(ArjUI.state.iAmTank == own, "tank role agrees with character identity")
end

local function target(name, pct)
  T.check(ArjUI.state.target == name and ArjUI.state.targetHpPct == pct, "enemy identity and condition remain in target state")
  T.check(ArjUI.targetNameLabel.message == "Target: " .. name, "enemy header explicitly identifies the target")
  T.check(ArjUI.targetHpGauge.value == math.max(1, pct), "target fill uses enemy health")
end

T.steps({
  {name="late-player-identity", run=function()
    ArjUI:endSession()
    ArjUI.initialDataRequested = true
    vitals()
    feedTriggers("< T: Elowen TP: sta TC: awful E: Elder EP: sta EC: bleeding, close to death>\n")
    T.emit("Char.Status", {name="Elowen", class="Necromancer", race="Human"})
  end, verify=function()
    -- Before the fix the tank bar still shows 20% for our healthy character.
    T.check(ArjUI.tankHpGauge.value == 80, "late identity replaces guessed self condition with own vitals")
    tank("Elowen", 80, true)
    target("Elder", 5)
    playerUnchanged()
  end},
  {name="enemy-name-containing-prompt-fields", run=function()
    feedTriggers("< T: Elowen TP: sta TC: excellent E: Elder TP: sta TC: awful E: Echo EP: sta EC: bleeding, close to death>\n")
  end, verify=function()
    tank("Elowen", 80, true)
    target("Elder TP: sta TC: awful E: Echo", 5)
    playerUnchanged()
  end},
  {name="critical-pet-tanking", run=function()
    T.emit("Group.Status", {members={
      {name="Elowen", hp=800, maxHp=1000, isNpc=false, inRoom=true},
      {name="Ember", hp=5, maxHp=100, isNpc=true, inRoom=true}
    }})
    feedTriggers("< T: Ember TP: sta TC: bleeding, close to death E: Elder EP: sta EC: awful>\n")
  end, verify=function()
    tank("Ember", 5, false)
    target("Elder", 20)
    playerUnchanged()
  end},
  {name="capital-E-condition", run=function()
    feedTriggers("< T: Ember TP: sit TC: Excellent E: Elder E: Watcher EP: sta EC: awful>\n")
  end, verify=function()
    tank("Ember", 100, false)
    target("Elder E: Watcher", 20)
    playerUnchanged()
  end},
  {name="gmcp-pet-and-dying-enemy", run=function()
    T.emit("Combat.Update", {tank={name="Ember", healthPercent=3, health="awful", position="standing"},
      target={name="Elder", healthPercent=0, health="bleeding to death", position="sitting"}})
  end, verify=function()
    tank("Ember", 3, false)
    target("Elder", 0)
    playerUnchanged()
  end},
  {name="new-tank-without-health", run=function()
    T.emit("Combat.Update", {tank={name="Eldric", position="standing"}})
  end, verify=function()
    T.check(ArjUI.tankNameLabel.message == "Tank: Eldric", "tank replacement changes its owner label")
    T.check(ArjUI.tankHpGauge.text.message == "HP unknown", "replacement tank never inherits previous pet health")
    T.check(ArjUI.state.tankHpPct == nil, "unknown tank percentage remains unknown")
    playerUnchanged()
  end},
  {name="combatant-named-you-is-not-player", run=function()
    T.emit("Combat.Update", {tank={name="You", healthPercent=1, health="awful"}})
  end, verify=function()
    tank("You", 1, false)
    playerUnchanged()
  end},
  {name="partial-numeric-health-without-maximum", run=function()
    T.emit("Combat.Update", {tank={name="You", hp=50}})
  end, verify=function()
    T.check(ArjUI.tankHpGauge.text.message == "HP unknown", "new numeric HP without a maximum cannot reuse an old percentage")
    T.check(ArjUI.state.tankCond == nil, "changed health cannot retain a stale condition description")
    playerUnchanged()
  end},
  {name="numeric-health-maximum-arrives", run=function()
    T.emit("Combat.Update", {tank={name="You", maxHp=100}})
  end, verify=function()
    tank("You", 50, false)
    T.check(ArjUI.tankHpGauge.text.message:find("50/100", 1, true), "same-combatant maximum completes its own numeric health")
    playerUnchanged()
  end},
  {name="same-tank-partial-update", run=function()
    T.emit("Combat.Update", {tank={name="Eldric", healthPercent=75, health="small wounds"}})
    T.emit("Combat.Update", {tank={name="Eldric", position="sitting"}})
  end, verify=function()
    tank("Eldric", 75, false)
    T.check(ArjUI.tankPosLabel.message == "SIT", "same-combatant partial packet retains its health")
    playerUnchanged()
  end},
  {name="normalized-self-tank", run=function()
    T.emit("Combat.Update", {tank={name="  eLoWeN  ", healthPercent=1, health="awful", position="sitting"}})
  end, verify=function()
    tank("Elowen", 80, true)
    playerUnchanged()
  end},
  {name="explicit-tank-clear", run=function()
    T.emit("Combat.Update", {tank={name="Ember", healthPercent=1, health="awful"}})
    T.emit("Combat.Update", yajl.to_value('{"tank":null}'))
  end, verify=function()
    tank("Elowen", 80, true)
    playerUnchanged()
  end},
  {name="assist-switch-from-critical-pet", run=function()
    T.emit("Combat.Update", {tank={name="Ember", healthPercent=1, health="awful"}})
    T.emit("Group.Status", {members={
      {name="Eldric", hp=750, maxHp=1000, position="standing", isNpc=false, inRoom=true},
      {name="Ember", hp=1, maxHp=100, position="standing", isNpc=true, inRoom=true}
    }})
    feedTriggers("You are now assisting Eldric.\n")
  end, verify=function()
    tank("Eldric", 75, false)
    T.check(ArjUI.tankHpGauge.text.message:find("750/1000", 1, true), "assist health comes from the selected group member")
    playerUnchanged()
  end},
  {name="assisted-group-health-update", run=function()
    T.emit("Group.Status", {members={{name="Eldric", hp=400, maxHp=1000,
      position="sitting", isNpc=false, inRoom=true}}})
  end, verify=function()
    tank("Eldric", 40, false)
    T.check(ArjUI.tankHpGauge.text.message:find("400/1000", 1, true), "assisted member health refreshes with Group.Status")
    playerUnchanged()
  end},
  {name="assist-member-missing", run=function()
    T.emit("Group.Status", {members={{name="Eldricson", hp=1, maxHp=1000,
      position="standing", isNpc=false, inRoom=true}}})
  end, verify=function()
    T.check(ArjUI.tankNameLabel.message == "Tank: Eldric", "similar group names cannot replace the assisted character")
    T.check(ArjUI.tankHpGauge.text.message == "HP unknown", "missing assisted member never inherits another character's health")
    playerUnchanged()
  end},
  {name="combat-prompt-overrides-assist", run=function()
    feedTriggers("< T: Ember TP: sta TC: awful E: Elder EP: sta EC: small wounds>\n")
    T.emit("Group.Status", {members={{name="Eldric", hp=1, maxHp=1000, isNpc=false, inRoom=true}}})
  end, verify=function()
    tank("Ember", 20, false)
    playerUnchanged()
  end},
  {name="own-healing-while-pet-critical", run=function()
    vitals(900)
    T.emit("Combat.Update", {target={name="Elder", healthPercent=1, health="awful"}})
  end, verify=function()
    tank("Ember", 20, false)
    target("Elder", 1)
    playerUnchanged()
  end},
  {name="enemy-death-does-not-change-player", run=function()
    T.emit("Combat.Update", {target={name="Elder", healthPercent=0, health="dead"}})
  end, verify=function()
    T.check(ArjUI.targetNameLabel.message == "Target: Elder [DEAD]" and ArjUI.targetHpGauge.value == 0,
      "explicit enemy death belongs only to the target bar")
    tank("Ember", 20, false)
    playerUnchanged()
  end},
  {name="explicit-combat-end", run=function()
    T.emit("Combat.Update", yajl.to_value('{"tank":null,"target":null}'))
  end, verify=function()
    tank("Elowen", 90, true)
    T.check(ArjUI.state.target == nil, "combat end clears enemy ownership")
    playerUnchanged()
  end},
  {name="death-clears-assist-before-group-update", run=function()
    feedTriggers("You are now assisting Eldric.\n")
    feedTriggers("Elder is dead! R.I.P.\n")
    T.emit("Group.Status", {members={{name="Eldric", hp=1, maxHp=1000, isNpc=false, inRoom=true}}})
  end, verify=function()
    tank("Elowen", 90, true)
    T.check(ArjUI.state.assistTarget == nil, "death discards the previous assist selection")
    T.check(ArjUI.state.target == nil, "death keeps the enemy display cleared")
    playerUnchanged()
  end},
  {name="flee-clears-assist-before-group-update", run=function()
    T.emit("Combat.Update", {target={name="Elder", healthPercent=1, health="awful"}})
    feedTriggers("You are now assisting Eldric.\n")
    feedTriggers("You flee west.\n")
    T.emit("Group.Status", {members={{name="Eldric", hp=1, maxHp=1000, isNpc=false, inRoom=true}}})
  end, verify=function()
    tank("Elowen", 90, true)
    T.check(ArjUI.state.assistTarget == nil, "flee discards the previous assist selection")
    T.check(ArjUI.state.target == nil, "flee keeps the enemy display cleared")
    playerUnchanged()
  end},
  {name="injured-player-with-healthy-pet", run=function()
    vitals(50)
    T.emit("Combat.Update", {tank={name="Ember", healthPercent=100, health="excellent"},
      target={name="Elder", healthPercent=100, health="excellent"}})
  end, verify=function()
    tank("Ember", 100, false)
    target("Elder", 100)
    playerUnchanged()
  end},
  {name="session-reset", run=function()
    ArjUI:endSession()
    ArjUI.initialDataRequested = true
    T.emit("Char.Status", {name="Newhero"})
    vitals(800)
  end, verify=function()
    tank("Newhero", 80, true)
    T.check(ArjUI.state.assistTarget == nil and ArjUI.state.target == nil, "new character has no stale combat owner")
    playerUnchanged()
  end}
})
