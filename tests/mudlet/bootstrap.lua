-- Test companion only. Never included in the player package.
DurisTest = { assertions = {}, commands = {} }
local T = DurisTest
T.run = assert(os.getenv("DURIS_TEST_RUN"), "DURIS_TEST_RUN missing")
local file = assert(io.open(T.run .. "/run.json"))
T.config = yajl.to_value(file:read("*a")); file:close()

function T.write(name, value)
  value.run_id = T.config.run_id
  local f = assert(io.open(T.run .. "/" .. name .. ".tmp", "w"))
  f:write(yajl.to_string(value)); f:close()
  assert(os.rename(T.run .. "/" .. name .. ".tmp", T.run .. "/" .. name .. ".json"))
end

function T.check(value, description)
  T.assertions[#T.assertions+1] = {description=description, passed=not not value}
  assert(value, description)
end

function T.emit(event, data)
  gmcp = gmcp or {}
  local parent, key = event:match("^([^.]+)%.(.+)$")
  gmcp[parent] = gmcp[parent] or {}
  gmcp[parent][key] = data
  raiseEvent("gmcp." .. event)
end

function T.lines(name)
  return table.concat(getLines(name or "main", 0, getLastLineNumber(name or "main")+1) or {}, "\n")
end

function T.collect()
  tempTimer(.7, function()
    local buffer = T.lines("main")
    local f=assert(io.open(T.run.."/main-console.txt","w")); f:write(buffer); f:close()
    local errors={}
    local collecting=false
    for line in buffer:gmatch("[^\n]+") do
      if line:find("[  LUA  ]",1,true) then
        errors[#errors+1]=line; collecting=true
      elseif collecting and line:match("^%s") then
        errors[#errors]=errors[#errors].."\n"..line
      else collecting=false end
    end
    T.write("errors", {scenario="errors", errors=errors})
  end)
end

function T.save() saveProfile() end

function T.finish(ok, err)
  T.write("result", {scenario=T.config.scenario, status=ok and "PASS" or "FAIL",
    assertions=T.assertions, commands=T.commands, error=err})
end

function T.steps(steps)
  T.async, T.sequence, T.step = true, steps, 0
  T.resume()
end

function T.resume()
  T.step = T.step + 1
  local step = T.sequence[T.step]
  if not step then T.finish(true); return end
  local ok, err = xpcall(step.run, debug.traceback)
  if not ok then T.finish(false, err); return end
  tempTimer(step.wait or .15, function()
    if step.verify then
      local ok, err = xpcall(step.verify, debug.traceback)
      if not ok then T.finish(false, err); return end
    end
    T.write("checkpoint", {scenario=T.config.scenario, step=T.step, name=step.name,
      actions=step.actions and step.actions() or {}})
  end)
end

function T.click(widget)
  return {type="click", x=widget:get_x()+widget:get_width()/2, y=widget:get_y()+widget:get_height()/2}
end

function T.dispatch(id)
  T.assertions, T.commands = {}, {}
  local ok, err = xpcall(function()
    T.check(id == T.config.scenario, "requested scenario matches this run")
    T.check(getProfileName()=="Duris-Visual" and getMudletHomeDir()==T.config.profile, "isolated profile")
    T.check(select(3,getConnectionInfo())==false, "disconnected")
    T.check(ArjUI.VERSION==T.config.candidate.version, "candidate version")
    local scenario = assert(loadfile(getMudletHomeDir().."/Duris Test Companion/fixtures/"..id..".lua"))
    scenario()
  end, debug.traceback)
  if not ok or not T.async then T.finish(ok, err) end
end

-- Defer initialization until all saved scripts have loaded. After replacement,
-- Mudlet may serialize the companion before the candidate in the profile XML.
tempTimer(.1, function()
-- Instrument outgoing commands only in this offline profile.
T.originalSend = send
send = function(command, echo)
  T.commands[#T.commands+1]={command=command, echo=echo}
  return true
end
T.originalDownload = downloadFile
downloadFile = function(path, url, ...)
  assert(url:sub(1,#T.config.map_base)==T.config.map_base, "offline test attempted a public map request")
  return T.originalDownload(path, url, ...)
end
ArjMapper.config.apiBase = T.config.map_base
T.alias = tempAlias("^duris-test ([a-z0-9-]+)$", function() T.dispatch(matches[2]) end)
T.write("ready", {scenario="ready"})
end)
