#!/usr/bin/env python3
"""Run registered offline scenarios; a zero exit code covers behavior, not visuals."""
import argparse
import concurrent.futures
import json
import re
from pathlib import Path
import subprocess
import sys

from mudlet_test import DEFAULT_ROOT, ROOT, write_json


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=DEFAULT_ROOT)
    parser.add_argument('--jobs', type=int, choices=[1, 2, 3], default=2)
    args = parser.parse_args()
    args.root = args.root.expanduser().resolve()
    registry = json.loads((ROOT / 'tests/mudlet/scenarios.json').read_text())
    cases = [(name, None) for name in registry['offline']]
    cases += [(name, None) for name in registry['negative']]
    cases += [('lowhp', fault) for fault in registry['faults']]

    def run(case):
        scenario, fault = case
        case_root = args.root / (fault or scenario)
        cmd = [sys.executable, str(ROOT / 'scripts/mudlet_test.py'), 'run',
               '--scenario', scenario, '--root', str(case_root), '--timeout', '140' if scenario == 'layout' else '70']
        if fault:
            cmd += ['--fault', fault, '--timeout', '8']
        process = subprocess.run(cmd, text=True, capture_output=True, timeout=420)
        output = process.stdout.strip().splitlines()
        path = Path(output[0]) / 'results.json' if output else None
        if path and (path.parent.parent != case_root or not path.is_file()):
            path = None
        result = json.loads(path.read_text()) if path else {}
        if fault:
            passed = (process.returncode == 1 and result.get('automated_status') == 'FAIL'
                      and 'Timed out waiting' in result.get('error', '') and result.get('normal_shutdown'))
            if fault != 'no-readiness':
                console = path.parent / 'failure-console.txt' if path else None
                expected = 'wrong isolated profile' if fault == 'wrong-profile' else 'wrong candidate'
                passed = passed and console and console.exists() and expected in re.sub(r'\s+', ' ', console.read_text())
        elif scenario in registry['negative']:
            expected = 'DELIBERATE_' + scenario.split('-')[0].upper() + '_FAILURE'
            evidence = str(result.get('error', '')) + str(result.get('errors', []))
            console = path.parent / 'main-console.txt' if path else None
            if console and console.exists():
                evidence += console.read_text()
            passed = process.returncode == 1 and result.get('automated_status') == 'FAIL' and expected in re.sub(r'\s+', '', evidence)
        else:
            passed = process.returncode == 0 and result.get('automated_status') == 'PASS'
        passed = bool(passed and result.get('cleanup') and result.get('normal_shutdown'))
        summary = {'case': fault or scenario, 'passed': passed, 'run': str(path.parent) if path else None,
                   'exit_code': process.returncode, 'stderr': process.stderr.strip()}
        print(json.dumps(summary), flush=True)
        return summary

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        results = list(pool.map(run, cases))
    args.root.mkdir(parents=True, exist_ok=True)
    write_json(args.root / 'suite-results.json', {'cases': results, 'visual_review': 'NOT RUN'})
    return 0 if all(r['passed'] for r in results) else 1


if __name__ == '__main__':
    sys.exit(main())
