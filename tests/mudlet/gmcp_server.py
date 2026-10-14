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
                                    owner.received.append(data[3:end].decode('utf-8'))
                                    owner.log.write_text(json.dumps(owner.received, indent=2))
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
                            for packet in packets.get(phase, []):
                                payload = packet['package'] + ' ' + json.dumps(packet['data'], separators=(',', ':'))
                                frame = b'\xff\xfa\xc9' + payload.encode('utf-8') + b'\xff\xf0'
                                # Deliberately fragment a frame to exercise the client decoder.
                                self.request.sendall(frame[:5])
                                self.request.sendall(frame[5:])
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
