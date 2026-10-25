"""Controller failure semantics; actual Lua failures are tested in Mudlet too."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch, MagicMock

spec = importlib.util.spec_from_file_location("mudlet_test", Path(__file__).resolve().parents[2] / "scripts/mudlet_test.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RunnerTests(unittest.TestCase):
    def test_old_mudlet_cannot_launch_with_unsupported_profile_isolation(self):
        with patch.object(runner.shutil, "which", return_value="/usr/bin/mudlet"), patch.object(runner, "command", return_value="mudlet 4.19.1"):
            with self.assertRaisesRegex(RuntimeError, "requires Mudlet 5.0"):
                runner.doctor()

    def test_drag_releases_button_after_pointer_failure(self):
        calls = []
        def xdo(*args):
            calls.append(args)
            if len(calls) == 3:
                raise RuntimeError("pointer failed")
        with patch.object(runner, "xdo", side_effect=xdo):
            with self.assertRaisesRegex(RuntimeError, "pointer failed"):
                runner.pointer_action("123", {"type":"drag", "x":10, "y":20, "to_x":50, "to_y":70}, 2)
        self.assertEqual(calls[0], ("mousemove", "--window", "123", "20", "80"))
        self.assertEqual(calls[-1], ("mouseup", "1"))

    def test_right_click_uses_requested_button(self):
        with patch.object(runner, "xdo") as xdo:
            runner.pointer_action("123", {"type":"click", "x":10, "y":20, "button":3}, 1)
        self.assertEqual(xdo.call_args.args, ("click", "3"))

    def test_drag_waits_for_native_delivery_and_releases_after_timeout(self):
        with patch.object(runner, "xdo") as xdo, \
             patch.object(runner, "wait_for", side_effect=TimeoutError("no native move")) as wait:
            with tempfile.TemporaryDirectory() as directory:
                with self.assertRaisesRegex(TimeoutError, "no native move"):
                    runner.pointer_action("123", {"type":"drag", "x":10, "y":20,
                        "to_x":50, "to_y":70, "ack":str(Path(directory)/"pointer.json")}, 1)
            wait.assert_called_once()
            self.assertEqual(xdo.call_args.args, ("mouseup", "1"))

    def test_missing_dependencies_fail(self):
        with patch.object(runner.shutil, "which", return_value=None):
            with self.assertRaisesRegex(RuntimeError, "Missing prerequisites.*luac5.1"):
                runner.doctor()

    def test_stale_and_partial_acknowledgments_are_ignored(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ready.json"
            for value in ['{', json.dumps({"run_id":"old","scenario":"lowhp"}), json.dumps({"run_id":"new","scenario":"wrong"})]:
                path.write_text(value)
                self.assertIsNone(runner.acknowledgment(path, "new", "lowhp"))
            path.write_text(json.dumps({"run_id":"new","scenario":"lowhp","status":"FAIL"}))
            self.assertEqual(runner.acknowledgment(path,"new","lowhp")["status"], "FAIL")

    def test_no_readiness_is_a_bounded_failure(self):
        started = time.monotonic()
        with self.assertRaises(TimeoutError):
            runner.wait_for(lambda: None, .15)
        self.assertLess(time.monotonic()-started, 1)

    def test_exited_process_fails_without_waiting_for_timeout(self):
        process = subprocess.Popen([sys.executable, "-c", "raise SystemExit(7)"])
        process.wait(timeout=5)
        with self.assertRaisesRegex(RuntimeError, "exited.*7"):
            runner.wait_for(lambda: None, 10, process)

    def test_cleanup_only_stops_the_owned_process(self):
        owned = subprocess.Popen([sys.executable,"-c","import time; time.sleep(60)"])
        unrelated = subprocess.Popen([sys.executable,"-c","import time; time.sleep(60)"])
        try:
            runner.stop_process(owned)
            self.assertIsNotNone(owned.poll())
            self.assertIsNone(unrelated.poll())
        finally:
            runner.stop_process(unrelated)

    def test_invalid_archive_is_not_a_candidate(self):
        import zipfile
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/"wrong.mpackage"
            path.write_bytes(b"not an archive")
            with self.assertRaises(zipfile.BadZipFile):
                runner.verify_candidate(path)

    def test_error_after_passing_fixture_still_fails_the_run(self):
        with tempfile.TemporaryDirectory() as directory:
            run = Path(directory)
            runner.write_json(run/'run.json', {'run_id':'test', 'scenario':'lowhp',
                'mudlet':'mudlet', 'timeout':1, 'size':'1366x768', 'scale':1,
                'candidate':{'sha256':'test'}})
            child = MagicMock()
            child.pid = 12345
            child.poll.return_value = 0
            child.returncode = 0
            def input_action(*args):
                if args == ('key', 'alt+e'):
                    raise RuntimeError('editor capture failed after fixture passed')
                return '123'
            acknowledgments = ['123', {}, {}, {'status':'PASS', 'errors':[]}, {'errors':[]}]
            with patch.object(runner.subprocess, 'Popen', return_value=child), \
                 patch.object(runner, 'wait_for', side_effect=acknowledgments), \
                 patch.object(runner, 'enter'), patch.object(runner, 'capture'), \
                 patch.object(runner, 'geometry', return_value={}), \
                 patch.object(runner.signal, 'signal'), \
                 patch.object(runner, 'xdo', side_effect=input_action):
                self.assertEqual(runner.session(run), 1)
            result = json.loads((run/'results.json').read_text())
            self.assertEqual(result['automated_status'], 'FAIL')
            self.assertIn('editor capture failed', result['error'])


if __name__ == "__main__":
    unittest.main()
