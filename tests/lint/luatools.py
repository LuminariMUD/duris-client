"""Shared helpers for the Lua lint tests (stdlib only)."""

import os
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "src" / "scripts"
NAMESPACES = {"ArjUI", "ArjMapper", "ArjAuto"}


def lua_files():
    return sorted(SCRIPTS.glob("*.lua"))


def find_luac51():
    """Return a luac binary that really is Lua 5.1, or None.

    Mudlet embeds Lua 5.1. A 5.3/5.4 luac accepts `goto`, `//` and bitwise
    operators that Mudlet then rejects at load time.
    """
    for cand in ("luac5.1", "luac"):
        path = shutil.which(cand)
        if not path:
            continue
        r = subprocess.run([path, "-v"], capture_output=True, text=True)
        if "Lua 5.1" in (r.stdout + r.stderr):
            return path
    return None


GLOBAL_OP = re.compile(r"\b(GETGLOBAL|SETGLOBAL)\b.*;\s*([A-Za-z_][A-Za-z0-9_]*)\s*$")


def global_accesses(luac, path):
    """Yield (op, name, line) for every global read/write in a Lua 5.1 file."""
    r = subprocess.run([luac, "-p", "-l", os.fspath(path)], capture_output=True, text=True, check=True)
    for row in r.stdout.splitlines():
        m = GLOBAL_OP.search(row)
        if not m:
            continue
        line = re.search(r"\[(\d+)\]", row)
        yield m.group(1), m.group(2), int(line.group(1)) if line else 0


def strip_lua(text):
    """Blank out comments and string contents, preserving line structure.

    Quotes and long-bracket delimiters are kept so callers can still tell a
    string literal from code, but nothing inside a string or comment can match
    a code pattern.
    """
    out = []
    i, n = 0, len(text)

    def long_bracket(at):
        m = re.match(r"\[(=*)\[", text[at:])
        return m.group(1) if m else None

    while i < n:
        c = text[i]
        if text.startswith("--", i):
            eq = long_bracket(i + 2)
            if eq is not None:
                end = text.find("]" + eq + "]", i)
                end = n if end < 0 else end + len(eq) + 2
            else:
                end = text.find("\n", i)
                end = n if end < 0 else end
            out.append(re.sub(r"[^\n]", " ", text[i:end]))
            i = end
            continue
        eq = long_bracket(i) if c == "[" else None
        if eq is not None:
            close = "]" + eq + "]"
            end = text.find(close, i + len(eq) + 2)
            end = n if end < 0 else end
            out.append("[" + eq + "[" + re.sub(r"[^\n]", " ", text[i + len(eq) + 2:end]) + close)
            i = end + len(close)
            continue
        if c in "\"'":
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            out.append(c + " " * (min(j, n) - i - 1) + (c if j < n else ""))
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def call_args(code, open_paren):
    """Split the top-level arguments of a call whose '(' is at open_paren.

    `code` must already be stripped with strip_lua. Returns (args, end_index).
    """
    depth, start, args = 0, open_paren + 1, []
    for k in range(open_paren, len(code)):
        ch = code[k]
        if ch in "({[":
            depth += 1
        elif ch in ")}]":
            depth -= 1
            if depth == 0:
                args.append(code[start:k].strip())
                return [a for a in args if a], k
        elif ch == "," and depth == 1:
            args.append(code[start:k].strip())
            start = k + 1
    return args, len(code)


def line_of(code, index):
    return code.count("\n", 0, index) + 1
