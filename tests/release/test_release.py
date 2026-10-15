"""Validate release contents and exercise publishing without network mutations."""

import hashlib
import io
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError
import zipfile

from scripts import release


VERSION = "1.3.5"
TAG = "v1.3.5"
CHANGELOG = "## 1.3.5 - 2026-10-15\n\n- New artwork.\n\n## 1.3.4 - 2026-10-15\n\n- Black background.\n"


class ValidationTests(unittest.TestCase):
    def test_versions_sort_numerically_and_reject_ambiguous_forms(self):
        self.assertGreater(release.version_tuple("1.10.0"), release.version_tuple("1.9.9"))
        for value in ("v1.3.5", "01.3.5", "1.3", "1.3.5-rc.1", "1.3.5\n"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                release.version_tuple(value)

    def test_notes_include_only_requested_version(self):
        notes = release.release_notes(CHANGELOG, VERSION)
        self.assertIn("New artwork.", notes)
        self.assertIn("## Install", notes)
        self.assertNotIn("Black background.", notes)

    def test_missing_empty_or_duplicate_notes_fail(self):
        for changelog in ("", "## 1.3.5 - 2026-10-15\n", CHANGELOG + CHANGELOG):
            with self.subTest(changelog=changelog), self.assertRaises(ValueError):
                release.release_notes(changelog, VERSION)

    @staticmethod
    def write_archive(path, payload, year):
        with zipfile.ZipFile(path, "w") as archive:
            info = zipfile.ZipInfo("config.lua", date_time=(year, 1, 1, 0, 0, 0))
            archive.writestr(info, payload)

    def test_prepare_checks_payload_ignores_timestamps_and_writes_checksums(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / "dist"
            (root / "CHANGELOG.md").write_text(CHANGELOG)
            self.write_archive(root / release.PACKAGE, "version = [[1.3.5]]", 2025)

            def build(*args, **kwargs):
                self.write_archive(output / release.PACKAGE, "version = [[1.3.5]]", 2026)
                return "built"

            with patch.object(release.shutil, "which", return_value="luac5.1"), \
                    patch.object(release, "command", side_effect=build):
                release.prepare(root, output, VERSION)
            package, versioned, checksums = [output / name for name in release.asset_names(VERSION)]
            self.assertEqual(package.read_bytes(), versioned.read_bytes())
            for line in checksums.read_text().splitlines():
                digest, name = line.split()
                self.assertEqual(digest, hashlib.sha256((output / name).read_bytes()).hexdigest())
            self.assertIn("New artwork.", (output / "notes.md").read_text())

            self.write_archive(root / release.PACKAGE, "stale package", 2025)
            with patch.object(release.shutil, "which", return_value="luac5.1"), \
                    patch.object(release, "command", side_effect=build), \
                    self.assertRaisesRegex(ValueError, "stale"):
                release.prepare(root, output, VERSION)

    def test_api_only_treats_404_as_missing(self):
        with patch.dict(os.environ, {"GH_TOKEN": "test-token"}):
            for code in (404, 401, 403, 429, 500):
                error = HTTPError("https://api.github.com", code, "test", {}, io.BytesIO())
                with self.subTest(code=code), patch.object(release, "urlopen", side_effect=error):
                    if code == 404:
                        self.assertIsNone(release.api_release("latest"))
                    else:
                        with self.assertRaises(HTTPError):
                            release.api_release("latest")


class PublishingTests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, {
            "GITHUB_REPOSITORY": release.REPOSITORY,
            "GITHUB_REF": "refs/heads/master",
            "GITHUB_EVENT_NAME": "push",
            "GITHUB_SHA": "tested-commit",
        })
        self.env.start()
        self.addCleanup(self.env.stop)
        self.calls = []
        self.tagged = False
        self.changed = ""
        self.upload_fails = False
        self.latest = {"tag_name": "v1.3.0"}
        self.existing = None
        for name, options in (
                ("command", {"side_effect": self.command}),
                ("api_release", {"side_effect": lambda path: self.latest if path == "latest" else self.existing}),
                ("prepare", {})):
            mocker = patch.object(release, name, **options)
            setattr(self, name + "_mock", mocker.start())
            self.addCleanup(mocker.stop)

    def command(self, *args, **kwargs):
        self.calls.append(args)
        if args[:3] == ("git", "rev-parse", "HEAD"):
            return "tested-commit"
        if args[:3] == ("git", "tag", "--list"):
            return TAG if self.tagged else ""
        if args[:2] == ("git", "diff"):
            return self.changed
        if args[:2] == ("git", "show"):
            return CHANGELOG
        if args[:3] == ("gh", "release", "upload") and self.upload_fails:
            raise RuntimeError("upload failed")
        return ""

    def publish(self):
        release.publish(Path("/repo"), Path("/release"), VERSION)

    def gh_calls(self):
        return [args for args in self.calls if args[0] == "gh"]

    def test_new_release_tags_tested_commit_and_uploads_before_publishing(self):
        self.publish()
        tag_call = next(args for args in self.calls if "-a" in args)
        self.assertEqual(tag_call[tag_call.index("-a") + 1:][:2], (TAG, "tested-commit"))
        create, upload, publish = self.gh_calls()
        self.assertEqual(create[2], "create")
        self.assertIn("--draft", create)
        self.assertIn("--verify-tag", create)
        self.assertEqual(upload[2], "upload")
        self.assertEqual(publish[2], "edit")
        self.assertIn("--draft=false", publish)
        self.assertIn("--latest", publish)

    def test_complete_release_is_left_unchanged(self):
        self.tagged = True
        self.existing = {"draft": False, "assets": [
            {"name": name, "state": "uploaded"} for name in release.asset_names(VERSION)]}
        self.publish()
        self.assertEqual(self.gh_calls(), [])
        self.prepare_mock.assert_not_called()

    def test_draft_resumes_without_retagging(self):
        self.tagged = True
        self.existing = {"draft": True}
        self.publish()
        self.assertEqual([args[2] for args in self.gh_calls()], ["upload", "edit"])
        self.assertFalse(any("-a" in args for args in self.calls))
        self.prepare_mock.assert_called_once_with(Path("/repo"), Path("/release"), VERSION, CHANGELOG)

    def test_existing_tag_without_release_can_resume(self):
        self.tagged = True
        self.publish()
        self.assertEqual([args[2] for args in self.gh_calls()], ["create", "upload", "edit"])
        self.assertFalse(any("-a" in args for args in self.calls))

    def test_failed_upload_does_not_publish(self):
        self.upload_fails = True
        with self.assertRaisesRegex(RuntimeError, "upload failed"):
            self.publish()
        self.assertEqual([args[2] for args in self.gh_calls()], ["create", "upload"])

    def test_reused_version_with_changed_sources_fails_before_upload(self):
        self.tagged = True
        self.changed = "src/scripts/ArjUI.lua"
        with self.assertRaisesRegex(ValueError, "bump VERSION"):
            self.publish()
        self.assertEqual(self.gh_calls(), [])
        self.prepare_mock.assert_not_called()

    def test_stale_run_cannot_replace_newer_latest(self):
        self.latest = {"tag_name": "v1.10.0"}
        self.publish()
        self.assertEqual(self.gh_calls(), [])
        self.prepare_mock.assert_not_called()

    def test_first_release_handles_no_latest(self):
        self.latest = None
        self.publish()
        self.assertEqual([args[2] for args in self.gh_calls()], ["create", "upload", "edit"])

    def test_missing_tag_or_published_asset_requires_inspection(self):
        self.existing = {"draft": False, "assets": []}
        with self.assertRaisesRegex(ValueError, "tag is missing"):
            self.publish()
        self.tagged = True
        with self.assertRaisesRegex(ValueError, "missing assets"):
            self.publish()
        self.assertEqual(self.gh_calls(), [])

    def test_pull_requests_forks_and_different_checkouts_cannot_publish(self):
        for key, value in (("GITHUB_EVENT_NAME", "pull_request"),
                           ("GITHUB_REPOSITORY", "other/fork"),
                           ("GITHUB_REF", "refs/heads/feature"),
                           ("GITHUB_SHA", "untested-commit")):
            with self.subTest(key=key), patch.dict(os.environ, {key: value}), self.assertRaises(RuntimeError):
                self.publish()
        self.assertEqual(self.gh_calls(), [])
        self.api_release_mock.assert_not_called()


if __name__ == "__main__":
    unittest.main()
