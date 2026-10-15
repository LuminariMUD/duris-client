#!/usr/bin/env python3
"""Validate release assets locally; CI adds --publish after all checks pass.

Uses Python's standard library, build.py, Lua 5.1, and (for publishing) git/gh.
Published releases and existing tags are never overwritten. Interrupted uploads
remain drafts and can be retried by rerunning CI.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.error import HTTPError
from urllib.request import Request, urlopen
import zipfile

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = "LuminariMUD/duris-client"
PACKAGE = "duris-client.mpackage"
SEMVER = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")


def version_tuple(value):
    if not SEMVER.fullmatch(value):
        raise ValueError(f"Invalid version {value!r}; expected MAJOR.MINOR.PATCH")
    return tuple(map(int, value.split(".")))


def command(*args, root=ROOT):
    result = subprocess.run(args, cwd=root, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError(f"{args[0]} failed ({result.returncode}):\n"
                           f"{result.stdout}{result.stderr}")
    return result.stdout.strip()


def release_notes(changelog, version):
    sections = re.split(r"^## ", changelog, flags=re.M)[1:]
    matches = []
    for section in sections:
        heading, _, body = section.partition("\n")
        if re.fullmatch(re.escape(version) + r" - \d{4}-\d{2}-\d{2}", heading):
            matches.append(body.strip())
    if len(matches) != 1 or not matches[0]:
        raise ValueError(f"CHANGELOG.md needs one nonempty '## {version} - YYYY-MM-DD' section")
    return matches[0] + (
        "\n\n## Install\n\nDownload `duris-client.mpackage` below, then in Mudlet "
        "open **Package Manager** (`Alt+O`), choose **Install New Package**, and "
        "select the file. Requires Mudlet 4.19.1+ with GMCP enabled.\n"
    )


def archive_contents(path):
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError(f"Duplicate paths in {path}")
        return {name: archive.read(name) for name in names}


def asset_names(version):
    return [PACKAGE, f"duris-client-{version}.mpackage", "SHA256SUMS.txt"]


def prepare(root, output, version, changelog=None):
    version_tuple(version)
    notes = release_notes(changelog if changelog is not None else
                          (root / "CHANGELOG.md").read_text(), version)
    if not shutil.which("luac5.1"):
        raise RuntimeError("Install lua5.1 before preparing a release")
    output.mkdir(parents=True, exist_ok=True)
    package = output / PACKAGE
    if package.resolve() == (root / PACKAGE).resolve():
        raise ValueError("Release output must be separate from the committed package")
    print(command(sys.executable, "build.py", "-o", str(package), root=root))
    # ZIP timestamps vary; compare every member's name and bytes instead.
    if archive_contents(package) != archive_contents(root / PACKAGE):
        raise ValueError("Committed package is stale; run python3 build.py and commit it")
    shutil.copyfile(package, output / asset_names(version)[1])
    checksums = []
    for name in asset_names(version)[:2]:
        digest = hashlib.sha256((output / name).read_bytes()).hexdigest()
        checksums.append(f"{digest}  {name}\n")
    (output / "SHA256SUMS.txt").write_text("".join(checksums))
    (output / "notes.md").write_text(notes)


def api_release(endpoint):
    request = Request(f"https://api.github.com/repos/{REPOSITORY}/releases/{endpoint}",
                      headers={"Authorization": f"Bearer {os.environ['GH_TOKEN']}",
                               "Accept": "application/vnd.github+json",
                               "X-GitHub-Api-Version": "2022-11-28"})
    try:
        with urlopen(request, timeout=30) as response:
            return json.load(response)
    except HTTPError as error:
        if error.code == 404:
            return None
        raise  # Authentication, rate limits, and service errors must stop publishing.


def publish(root, output, version):
    if (os.environ.get("GITHUB_REPOSITORY") != REPOSITORY or
            os.environ.get("GITHUB_REF") != "refs/heads/master" or
            os.environ.get("GITHUB_EVENT_NAME") not in {"push", "workflow_dispatch"}):
        raise RuntimeError("Publishing is restricted to CI on the repository's master branch")
    head = command("git", "rev-parse", "HEAD", root=root)
    if head != os.environ.get("GITHUB_SHA"):
        raise RuntimeError("Checkout does not match the commit tested by CI")
    tag = f"v{version}"
    latest = api_release("latest")
    if latest and version_tuple(latest["tag_name"].removeprefix("v")) > version_tuple(version):
        print(f"Skipping {tag}: {latest['tag_name']} is already published")
        return
    existing = api_release(f"tags/{tag}")
    command("git", "fetch", "origin", "--tags", root=root)
    tagged = bool(command("git", "tag", "--list", tag, root=root))
    changelog = None
    if tagged:
        changed = command("git", "diff", "--name-only", tag, head, "--",
                          "src", "VERSION", "build.py", root=root)
        if changed:
            raise ValueError(f"{tag} already tags different package sources; bump VERSION:\n{changed}")
        changelog = command("git", "show", f"{tag}:CHANGELOG.md", root=root)
    elif existing:
        raise ValueError(f"Release {tag} exists but its tag is missing; restore the original tag")

    if existing and not existing["draft"]:
        uploaded = {asset["name"] for asset in existing["assets"] if asset["state"] == "uploaded"}
        if not set(asset_names(version)) <= uploaded:
            raise ValueError(f"Published {tag} is missing assets; inspect it before repairing")
        print(f"{tag} is already published; leaving it unchanged")
        return

    prepare(root, output, version, changelog)
    if not tagged:
        command("git", "-c", "user.name=github-actions[bot]", "-c",
                "user.email=41898282+github-actions[bot]@users.noreply.github.com",
                "tag", "-a", tag, head, "-m", f"Duris Client {version}", root=root)
        command("git", "push", "origin", f"refs/tags/{tag}", root=root)
    if not existing:
        command("gh", "release", "create", tag, "--repo", REPOSITORY,
                "--draft", "--verify-tag", "--title", f"Duris Client {version}",
                "--notes-file", str(output / "notes.md"), root=root)
    # Only drafts can reach this point. Upload failure leaves a recoverable draft.
    command("gh", "release", "upload", tag, "--repo", REPOSITORY, "--clobber",
            *(str(output / name) for name in asset_names(version)), root=root)
    command("gh", "release", "edit", tag, "--repo", REPOSITORY,
            "--notes-file", str(output / "notes.md"), "--draft=false", "--latest",
            "--verify-tag", root=root)
    print(f"Published https://github.com/{REPOSITORY}/releases/tag/{tag}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--publish", action="store_true", help="CI only: tag and publish after validation")
    args = parser.parse_args()
    version = (ROOT / "VERSION").read_text().strip()
    version_tuple(version)
    output = args.output.resolve()
    if args.publish:
        publish(ROOT, output, version)
    else:
        prepare(ROOT, output, version)
        print(f"Validated release {version}: {output}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, zipfile.BadZipFile) as error:
        sys.exit(str(error))
