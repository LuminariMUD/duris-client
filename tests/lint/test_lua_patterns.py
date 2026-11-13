"""Regression locks for risky Lua patterns in src/scripts.

* No dynamic code or shell execution.
* No string-code callbacks to Mudlet temp* functions (they compile at runtime
  and escape the package's error handling).
* Every handler/timer/trigger/alias/key id is stored, so kill()/uninstall can
  remove it. A discarded id leaks for the rest of the session.

The checks are tested against tests/lint/fixtures/{bad,good}.lua.
"""

import re
import unittest

import luatools

FIXTURES = luatools.ROOT / "tests" / "lint" / "fixtures"

FORBIDDEN = re.compile(r"(?<![\w.:])(os\.execute|io\.popen|loadstring|loadfile|dofile|load)\s*\(")
TEMP_CALLS = ("tempTimer", "tempTrigger", "tempRegexTrigger", "tempAlias", "tempKey",
              "tempLineTrigger", "tempBeginOfLineTrigger", "tempExactMatchTrigger")
OWNED_CALLS = TEMP_CALLS + ("registerAnonymousEventHandler",)
CALL = re.compile(r"(?<![\w.:])(" + "|".join(OWNED_CALLS) + r")\s*\(")
# What may precede an owned call: an assignment, a return, or an
# argument position (table.insert(list, ...), f(..., call(...))).
STORED_BEFORE = re.compile(r"(=|\breturn|,|\(|\[)\s*$")


def violations(text, name="<lua>"):
    code = luatools.strip_lua(text)
    found = []
    for m in FORBIDDEN.finditer(code):
        found.append(f"{name}:{luatools.line_of(code, m.start())}: forbidden {m.group(1)}()")
    for m in CALL.finditer(code):
        fn, line = m.group(1), luatools.line_of(code, m.start())
        args, _ = luatools.call_args(code, m.end() - 1)
        callback = 2 if fn == "tempLineTrigger" or (fn == "tempKey" and len(args) == 3) else 1
        if fn in TEMP_CALLS and len(args) > callback and re.match(r"""^("|'|\[=*\[)""", args[callback]):
            found.append(f"{name}:{line}: {fn} with a string-code callback; pass a function")
        before = code[:m.start()]
        if not STORED_BEFORE.search(before):
            found.append(f"{name}:{line}: {fn} result discarded; store the id so it can be killed")
    return found


class FixtureTests(unittest.TestCase):
    def test_bad_fixture_trips_every_rule(self):
        found = violations((FIXTURES / "bad.lua").read_text(encoding="utf-8"), "bad.lua")
        expected = (FIXTURES / "bad.expected").read_text(encoding="utf-8").split()
        self.assertEqual(sorted(int(f.split(":")[1]) for f in found), sorted(map(int, expected)),
                         "\n" + "\n".join(found))

    def test_good_fixture_is_clean(self):
        found = violations((FIXTURES / "good.lua").read_text(encoding="utf-8"), "good.lua")
        self.assertEqual(found, [], "\n" + "\n".join(found))


class PackageTests(unittest.TestCase):
    def test_package_scripts_are_clean(self):
        found = []
        for path in luatools.lua_files():
            found += violations(path.read_text(encoding="utf-8"), path.name)
        self.assertEqual(found, [], "\n" + "\n".join(found))


if __name__ == "__main__":
    unittest.main()
