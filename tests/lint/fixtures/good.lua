-- Patterns the lint must accept. Mentions inside strings and comments, such as
-- os.execute("x") or tempTimer(1, "code"), never count.
local Good = { handlers = {}, timers = {} }
local note = "never call os.execute( or loadstring( here"
local doc = [[tempTimer(1, "send('look')") is the string form]]
Good.timer = tempTimer(0.5, function() end)
local id = tempRegexTrigger("^You (\\w+)$", function() end)
table.insert(Good.handlers, registerAnonymousEventHandler("sysLoadEvent", function() end))
Good.timers[tempTimer(1, function() end)] = true
local function arm(fn) return tempTimer(1, fn) end
Good.alias = tempAlias("^x$", function()
  send("look")
end)
Good.mapper:load(id)
local payload = self:download(url)

local escaped = "C:\\u{2654} -- \\z" -- comment with "\u{2654}" is ignored
local glyph, it = "♔", "it's \"quoted\""
return Good, note, doc, arm, payload, escaped, glyph, it
