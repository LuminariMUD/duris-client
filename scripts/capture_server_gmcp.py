#!/usr/bin/env python3
"""Refresh loopback Mudlet fixtures from the Duris executable GMCP contract test."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--server', type=Path, required=True)
args = parser.parse_args()
server = args.server.resolve()
with tempfile.TemporaryDirectory(prefix='duris-gmcp-capture-') as directory:
    output = Path(directory) / 'wire.jsonl'
    subprocess.run(['python3', str(server/'tests/async/test_gui_gmcp_contract.py'),
                    '--output', str(output)], cwd=server, check=True)
    phases = {}
    for line in output.read_text().splitlines():
        phase, package, data = line.split(' ', 2)
        phases.setdefault(phase, []).append({'package': package, 'data': json.loads(data)})
files = ['src/net/gmcp.c', 'src/core/json_utils.c', 'src/core/structs.h', 'src/combat/fight.c',
         'tests/async/gui_gmcp_contract_harness.cpp', 'tests/async/test_gui_gmcp_contract.py']
fixture = {'provenance': {
    'description': 'Production functions with isolated world/mechanics dependencies; no live player data.',
    'server_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=server, text=True).strip(),
    'source_sha256': {name: hashlib.sha256((server/name).read_bytes()).hexdigest() for name in files}},
    'phases': phases}
(ROOT/'tests/mudlet/fixtures/server-gmcp.json').write_text(json.dumps(fixture, indent=2)+'\n')
