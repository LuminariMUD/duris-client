"""Check relative links and #anchors in the repository's Markdown files.

External URLs are not fetched. Anchors match GitHub heading slugs or explicit
<a id="..."> / name="..." targets. docs/archive/ is a frozen snapshot and is
skipped.
"""

import re
import unittest
from urllib.parse import unquote

import luatools

ROOT = luatools.ROOT
SKIP_DIRS = {".git", "build", "node_modules", "__pycache__"}
SKIP_PREFIXES = ("docs/archive/",)
# Links to machine-local evidence (Mudlet run directories, absolute paths)
# that only exist on the machine that produced a test record.
LOCAL_EVIDENCE = re.compile(r"^(/|~|file:)|\.local/share/duris-client-dev/")

INLINE_LINK = re.compile(r"(?<!\\)!?\[(?:[^\[\]]|\[[^\]]*\])*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
REF_DEF = re.compile(r"^\s{0,3}\[[^\]]+\]:\s*<?(\S+?)>?(?:\s+.*)?$", re.M)
HTML_ID = re.compile(r"""<a\s+[^>]*(?:id|name)\s*=\s*["']([^"']+)["']""", re.I)
HEADING = re.compile(r"^\s{0,3}(#{1,6})\s+(.*?)\s*#*\s*$", re.M)
FENCE = re.compile(r"^\s*(```|~~~).*?^\s*\1\s*$", re.M | re.S)
INLINE_CODE = re.compile(r"(`+)(?:(?!\1).)+?\1", re.S)


def markdown_files():
    for path in sorted(ROOT.rglob("*.md")):
        rel = path.relative_to(ROOT).as_posix()
        if set(path.relative_to(ROOT).parts) & SKIP_DIRS or rel.startswith(SKIP_PREFIXES):
            continue
        yield path


def without_code(text):
    text = FENCE.sub(lambda m: "\n" * m.group(0).count("\n"), text)
    return INLINE_CODE.sub(lambda m: " " * len(m.group(0)), text)


def slugify(heading):
    """GitHub's heading anchor algorithm (close enough for these docs)."""
    text = re.sub(r"<[^>]+>", "", heading)              # inline HTML
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)  # links -> text
    text = text.replace("`", "").strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


_anchor_cache = {}


def anchors(path):
    if path not in _anchor_cache:
        text = path.read_text(encoding="utf-8")
        found, seen = set(HTML_ID.findall(text)), {}
        for m in HEADING.finditer(without_code(text)):
            slug = slugify(m.group(2))
            n = seen.get(slug, 0)
            seen[slug] = n + 1
            found.add(slug if n == 0 else f"{slug}-{n}")
        _anchor_cache[path] = found
    return _anchor_cache[path]


def broken_links(path):
    text = without_code(path.read_text(encoding="utf-8"))
    targets = [(m.start(), m.group(1)) for m in INLINE_LINK.finditer(text)]
    targets += [(m.start(), m.group(1)) for m in REF_DEF.finditer(text)]
    problems = []
    for pos, target in targets:
        if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I) and not target.startswith("file:"):
            continue  # http:, https:, mailto:, ...
        if LOCAL_EVIDENCE.search(target):
            continue
        file_part, _, anchor = target.partition("#")
        dest = (path.parent / unquote(file_part)).resolve() if file_part else path
        line = text.count("\n", 0, pos) + 1
        where = f"{path.relative_to(ROOT).as_posix()}:{line}"
        if not dest.exists():
            problems.append(f"{where}: missing {target}")
        elif anchor and dest.suffix == ".md" and unquote(anchor) not in anchors(dest):
            problems.append(f"{where}: no anchor #{anchor} in {dest.relative_to(ROOT).as_posix()}")
    return problems


class SlugTests(unittest.TestCase):
    def test_github_slugs(self):
        self.assertEqual(slugify("Foundation: Understanding Mudlet Packages"),
                         "foundation-understanding-mudlet-packages")
        self.assertEqual(slugify("`ui set` & friends (2.x)"), "ui-set--friends-2x")
        self.assertEqual(slugify("R1. Opt-in sound alerts (M)"), "r1-opt-in-sound-alerts-m")


class DocLinkTests(unittest.TestCase):
    def test_relative_links_and_anchors_resolve(self):
        problems = []
        for path in markdown_files():
            problems += broken_links(path)
        self.assertEqual(problems, [], "\n" + "\n".join(problems))


if __name__ == "__main__":
    unittest.main()
