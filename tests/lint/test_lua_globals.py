"""Reject accidental Lua globals: writes outside the three namespaces, and
reads of names that are not known Mudlet/Geyser/Lua APIs (usually typos).

Uses the bytecode listing from Lua 5.1's luac, so there is no new dependency.
"""

import os
import unittest

import luatools

ALLOWLIST = luatools.ROOT / "tests" / "lint" / "lua_globals.txt"


def allowed_reads():
    names = set()
    for row in ALLOWLIST.read_text(encoding="utf-8").splitlines():
        row = row.strip()
        if row and not row.startswith("#"):
            names.add(row)
    return names


class LuaGlobalsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.luac = luatools.find_luac51()
        if not cls.luac:
            if os.environ.get("CI"):
                raise AssertionError("CI needs Lua 5.1's luac (apt package lua5.1)")
            raise unittest.SkipTest("Lua 5.1 luac not installed")

    def test_only_namespaces_are_assigned_globally(self):
        bad = []
        for path in luatools.lua_files():
            for op, name, line in luatools.global_accesses(self.luac, path):
                if op == "SETGLOBAL" and name not in luatools.NAMESPACES:
                    bad.append(f"{path.name}:{line}: assigns global {name!r} (missing `local`?)")
        self.assertEqual(bad, [], "\n" + "\n".join(bad))

    def test_global_reads_are_known_apis(self):
        allowed = allowed_reads() | luatools.NAMESPACES
        bad = []
        for path in luatools.lua_files():
            for op, name, line in luatools.global_accesses(self.luac, path):
                if op == "GETGLOBAL" and name not in allowed:
                    bad.append(f"{path.name}:{line}: reads unknown global {name!r}")
        self.assertEqual(
            bad, [],
            "\n" + "\n".join(bad) + "\nFix the typo or, for a real API, add it to tests/lint/lua_globals.txt",
        )

    def test_allowlist_has_no_stale_entries(self):
        used = set()
        for path in luatools.lua_files():
            used.update(name for op, name, _ in luatools.global_accesses(self.luac, path) if op == "GETGLOBAL")
        stale = sorted(allowed_reads() - used)
        self.assertEqual(stale, [], f"remove unused names from {ALLOWLIST.name}: {stale}")


if __name__ == "__main__":
    unittest.main()
