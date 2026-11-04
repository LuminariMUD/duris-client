"""Loopback replay of payloads produced by the Duris executable contract test."""
import json
from pathlib import Path
import socket
import socketserver
import threading
import time


class GMCPServer:
    def __init__(self, log):
        self.log = Path(log)
        self.received = []
        self.sockets = []
        packets = json.loads((Path(__file__).parent / 'fixtures/server-gmcp.json').read_text())['phases']
        owner = self

        class Handler(socketserver.BaseRequestHandler):
            def handle(self):
                owner.sockets.append(self.request)
                self.request.sendall(b'\xff\xfb\xc9')  # WILL GMCP
                data = b''
                command = bytearray()
                preparation = 'Char.SpellPreparation'
                versioned = {"Duris.Time 1", preparation + " 1"}
                supports = set()
                interests = set()
                buckets = {}
                playing = False
                spell_reply_pending = False
                estimate = {"state": "complete", "estimatedSeconds": 0}

                def allow(family):
                    now = time.monotonic()
                    refill, tokens = buckets.get(family, (now, 2))
                    elapsed = int(now - refill)
                    tokens = min(2, tokens + elapsed)
                    buckets[family] = (refill + elapsed, max(0, tokens - 1))
                    return tokens > 0

                def names(modules):
                    return sorted(module.split(" ")[0] for module in modules)

                def packet(package, payload):
                    data = package + ' ' + json.dumps(payload, separators=(',', ':'))
                    frame = b'\xff\xfa\xc9' + data.encode('utf-8') + b'\xff\xf0'
                    # Deliberately fragment a frame to exercise the client decoder.
                    self.request.sendall(frame[:5])
                    self.request.sendall(frame[5:])

                def capabilities(active):
                    packet('Duris.Capabilities', {
                        'version': 1, 'enabled': True,
                        'features': {'Duris.Capabilities': 1, 'Duris.Subscribe': 1,
                                     'Duris.Time': 1, preparation: 1},
                        'supported': names(supports & versioned),
                        'interested': names(interests),
                        'active': names(interests) if active else [],
                    })

                def preparation_snapshot():
                    if playing and preparation + ' 1' in interests:
                        packet(preparation, estimate)

                def set_estimate(state, seconds):
                    estimate.update(state=state, estimatedSeconds=seconds)
                    capabilities(playing)
                    preparation_snapshot()

                def spell_catalog():
                    self.request.sendall(
                        b'>====[ Tester | Druid | Max Circle 5 ]====<\r\n'
                        b'1st CIRCLE:\r\ncure light\r\ncommune is your spell interface\r\n'
                        b'See: spells <class or specialization> | spells info <spell name>\r\n'
                        b'Custom HP prompt>\xff\xf9')

                while True:
                    chunk = self.request.recv(16384)
                    if not chunk:
                        break
                    data += chunk
                    while data:
                        if data[0] == 255:
                            if len(data) < 3:
                                break
                            if data[1] == 250:
                                end = data.find(b'\xff\xf0', 3)
                                if end < 0:
                                    break
                                if data[2] == 201:
                                    message = data[3:end].decode('utf-8')
                                    owner.received.append(message)
                                    owner.log.write_text(json.dumps(owner.received, indent=2))
                                    package, _, payload = message.partition(' ')
                                    if package in {'Core.Supports.Set', 'Core.Supports.Add',
                                                   'Core.Supports.Remove'} and allow('supports'):
                                        had_capabilities = 'Duris.Capabilities 1' in supports
                                        modules = set(json.loads(payload))
                                        if package == 'Core.Supports.Set':
                                            supports = modules
                                        elif package == 'Core.Supports.Add':
                                            supports.update(modules)
                                        else:
                                            supports.difference_update(modules)
                                        interests.intersection_update(supports)
                                        if had_capabilities or 'Duris.Capabilities 1' in supports:
                                            capabilities(playing)
                                    elif (package == 'Duris.Subscribe' and allow('subscribe')
                                          and 'Duris.Capabilities 1' in supports):
                                        interests = set(json.loads(payload)) & supports & versioned
                                        capabilities(playing)
                                        preparation_snapshot()
                                data = data[end+2:]
                            else:
                                data = data[3:]
                            continue
                        byte, data = data[0], data[1:]
                        if byte == 10:
                            phase = command.decode('utf-8').strip()
                            command.clear()
                            if phase == 'inventory':
                                self.request.sendall(b'You are carrying:\r\na bronze sword\r\nCustom HP prompt>\xff\xf9')
                            for captured in packets.get(phase, []):
                                packet(captured['package'], captured['data'])
                            if phase == 'snapshot':
                                playing = True
                                capabilities(playing)
                                preparation_snapshot()
                            # Synthetic snapshots match the versioned preparation contract.
                            if phase == 'prep-active':
                                set_estimate('active', 2)
                            if phase == 'prep-paused':
                                set_estimate('paused', 17)
                            if phase == 'prep-complete':
                                set_estimate('complete', 0)
                            if phase == 'prep-inactive':
                                capabilities(False)
                            if phase == 'prep-wont':
                                self.request.sendall(b'\xff\xfc\xc9')  # WONT GMCP
                            if phase == 'probe-interests':
                                packet('Test.Interests', {'names': names(interests)})
                            if phase == 'spells':
                                # A previous command's reply and prompt arrive first.
                                self.request.sendall(b'Unrelated output.\r\nCustom HP prompt>\xff\xf9')
                                spell_reply_pending = True
                            if phase == 'time' and spell_reply_pending:
                                spell_catalog()
                                spell_reply_pending = False
                            if phase == 'commune':
                                self.request.sendall(
                                    b'Unrelated output.\r\nCustom HP prompt>\xff\xf9'
                                    b'You currently have the following spell slots available:\r\n'
                                    b'  1st circle:  2 of  3\r\nCustom HP prompt>\xff\xf9')
                            if phase == 'clear':
                                self.request.sendall(b'[Damage: 8]\r\n')
                        else:
                            command.append(byte)

        class Server(socketserver.ThreadingTCPServer):
            daemon_threads = True

            def handle_error(self, *_):
                pass  # Shutdown may interrupt recv on an owned test connection.

        self.server = Server(('127.0.0.1', 0), Handler)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def close(self):
        for connection in self.sockets:
            try:
                connection.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=3)
