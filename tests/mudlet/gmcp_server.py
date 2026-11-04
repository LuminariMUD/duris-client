"""Loopback replay of payloads produced by the Duris executable contract test."""
import json
from pathlib import Path
import socket
import socketserver
import threading


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
                supported = False
                subscribed = False

                def packet(package, payload):
                    data = package + ' ' + json.dumps(payload, separators=(',', ':'))
                    frame = b'\xff\xfa\xc9' + data.encode('utf-8') + b'\xff\xf0'
                    # Deliberately fragment a frame to exercise the client decoder.
                    self.request.sendall(frame[:5])
                    self.request.sendall(frame[5:])

                def capabilities(active):
                    packet('Duris.Capabilities', {
                        'version': 1, 'enabled': True,
                        'features': {'Duris.Capabilities': 1, 'Duris.Subscribe': 1, preparation: 1},
                        'supported': [preparation],
                        'interested': [preparation] if subscribed else [],
                        'active': [preparation] if active else [],
                    })
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
                                    if package == 'Core.Supports.Add':
                                        modules = json.loads(payload)
                                        supported = {'Duris.Capabilities 1', preparation + ' 1'} <= set(modules)
                                        if supported:
                                            capabilities(False)
                                    elif package == 'Duris.Subscribe' and supported:
                                        subscribed = preparation + ' 1' in json.loads(payload)
                                        capabilities(subscribed)
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
                            # Synthetic snapshots match the versioned preparation contract.
                            if subscribed and phase == 'prep-active':
                                capabilities(True)
                                packet(preparation, {'state': 'active', 'estimatedSeconds': 2})
                            if subscribed and phase == 'prep-paused':
                                packet(preparation, {'state': 'paused', 'estimatedSeconds': 17})
                            if subscribed and phase == 'prep-complete':
                                packet(preparation, {'state': 'complete', 'estimatedSeconds': 0})
                            if subscribed and phase == 'prep-inactive':
                                capabilities(False)
                            if subscribed and phase == 'prep-wont':
                                self.request.sendall(b'\xff\xfc\xc9')  # WONT GMCP
                            if phase == 'spells':
                                self.request.sendall(
                                    b'>====[ Tester | Druid | Max Circle 5 ]====<\r\n'
                                    b'1st CIRCLE:\r\ncure light\r\ncommune is your spell interface\r\n'
                                    b'See: spells <class or specialization> | spells info <spell name>\r\n'
                                    b'Custom HP prompt>\xff\xf9')
                            if phase == 'commune':
                                self.request.sendall(
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
