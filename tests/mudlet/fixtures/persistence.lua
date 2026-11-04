local T=DurisTest
local profile=getMudletHomeDir().."/"

local function read(path)
  local file=assert(io.open(path,"rb"))
  local text=file:read("*a")
  file:close()
  return text
end

local function checkFailure(path,save,fault)
  local previous=read(path)
  local open=io.open
  local injected=false
  io.open=function(name,mode)
    local file,err=open(name,mode)
    if (name==path or name==path..".tmp") and (mode=="w" or mode=="wb") and file then
      injected=true
      return {
        write=function(_,text)
          assert(file:write(text:sub(1,8)))
          if fault=="write" then return nil,"injected partial write" end
          return file
        end,
        close=function()
          assert(file:close())
          if fault=="close" then return nil,"injected failed close" end
          return true
        end,
      }
    end
    return file,err
  end
  local ok,result=pcall(save)
  io.open=open
  assert(ok,result)
  T.check(injected and result==false,fault.." failure reported for "..path:match("[^/]+$"))
  T.check(read(path)==previous,fault.." failure preserves previous profile data")
  T.check(not io.open(path..".tmp","rb"),fault.." failure removes staged file")
end

T.steps({
  {name="automation-scores",run=function()
    local path=ArjAuto:path()
    ArjAuto.bidScores.Companion=13
    ArjAuto.loginCommands={"look"}
    ArjAuto.rescueList={companion=true}
    T.check(ArjAuto:save(),"automation seed save")
    ArjAuto.bidScores.Companion=5
    for _,fault in ipairs({"write","close"}) do
      checkFailure(path,function() return ArjAuto:save() end,fault)
    end
    ArjAuto:load()
    T.check(ArjAuto.bidScores.Companion==13 and ArjAuto.loginCommands[1]=="look"
      and ArjAuto.rescueList.companion,"reload preserves scores and automation")
  end},
  {name="custom-commands",run=function()
    local path=profile.."arjui_custom_commands.json"
    ArjUI.customCommands.mobs={{text="Look",cmd="look"}}
    T.check(ArjUI:saveCustomCommands(),"custom command seed save")
    ArjUI.customCommands.mobs={{text="New",cmd="consider"}}
    for _,fault in ipairs({"write","close"}) do
      checkFailure(path,function() return ArjUI:saveCustomCommands() end,fault)
    end
    ArjUI:loadCustomCommands()
    T.check(ArjUI.customCommands.mobs[1].cmd=="look","reload preserves custom commands")
  end},
  {name="ui-settings",run=function()
    local path=profile.."arjui_settings.json"
    T.check(ArjUI:setSetting("compactHeader",true),"settings seed save")
    for _,fault in ipairs({"write","close"}) do
      checkFailure(path,function() return ArjUI:setSetting("compactHeader",false) end,fault)
    end
    T.check(ArjUI.settings.compactHeader,"failed change keeps the previous UI setting")
    ArjUI:loadSettings()
    T.check(ArjUI.settings.compactHeader,"reload preserves UI settings")
  end},
})
