"""Loopback-only map responses for real Mudlet HTTP download tests."""
import http.server
import json
from pathlib import Path
import threading
import time


class MapServer:
    def __init__(self, log):
        self.requests = []
        self.log = Path(log)
        owner = self

        class Handler(http.server.BaseHTTPRequestHandler):
            def log_message(self, *_):
                pass

            def do_GET(self):
                owner.requests.append(self.path)
                owner.log.write_text(json.dumps(owner.requests, indent=2))
                zone = self.path.split("/")[-2]
                if zone == "9002":
                    time.sleep(1)
                if zone == "9006":
                    time.sleep(17)
                if zone == "9004":
                    self.send_error(503)
                    return
                if zone == "9003":
                    data = b"invalid JSON"
                elif zone == "9005":
                    data = b'{"nodes":"invalid"}'
                elif zone == "9007":
                    data = b'{"nodes":[{"id":90010}],"edges":[{"from":90010,"to":90011,"direction":42}]}'
                else:
                    data = (Path(__file__).parent / "fixtures/zone.json").read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                try:
                    self.wfile.write(data)
                except BrokenPipeError:
                    pass

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.base = f"http://127.0.0.1:{self.server.server_port}/zones/"
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def close(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=3)
