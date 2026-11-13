-- luacheck configuration for src/scripts (Mudlet runs Lua 5.1).
-- Global reads come from tests/lint/lua_globals.txt, the same list the
-- stdlib globals test enforces, so there is a single place to add an API.
std = "lua51"
globals = { "ArjUI", "ArjMapper", "ArjAuto" }
read_globals = {}
do
  local f = io.open("tests/lint/lua_globals.txt")
  if f then
    for line in f:lines() do
      local name = line:match("^%s*([%a_][%w_]*)%s*$")
      if name and name ~= "ArjUI" and name ~= "ArjMapper" and name ~= "ArjAuto" then
        read_globals[#read_globals + 1] = name
      end
    end
    f:close()
  end
end
-- ArjUI:disposeWidget removes destroyed frames from Geyser's registry.
read_globals.Adjustable = { fields = { Container = { fields = {
  all = { read_only = false, other_fields = true },
  all_windows = { read_only = false, other_fields = true },
}, other_fields = true } } }

max_line_length = false
-- Style-only warnings are not enforced: whitespace (611-614) and unused
-- callback arguments (212), which Mudlet/Geyser signatures dictate.
ignore = { "611", "612", "613", "614", "212" }
exclude_files = { "tests/lint/fixtures/*.lua" }
