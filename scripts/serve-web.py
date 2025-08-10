#!/usr/bin/env python3
import http.server
import socketserver
import argparse
import os
from functools import partial

class HeaderedHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Required for SharedArrayBuffer / cross-origin isolation
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def guess_type(self, path):
        # Ensure correct MIME for WASM
        if path.endswith(".wasm"):
            return "application/wasm"
        return super().guess_type(path)


def main():
    parser = argparse.ArgumentParser(description="Serve a directory with COOP/COEP headers")
    parser.add_argument("directory", nargs="?", default=os.getcwd(), help="Directory to serve")
    parser.add_argument("port", nargs="?", type=int, default=8080, help="Port to listen on")
    args = parser.parse_args()

    directory = os.path.abspath(args.directory)
    handler = partial(HeaderedHandler, directory=directory)

    # Ensure address can be reused immediately after stopping
    socketserver.TCPServer.allow_reuse_address = True
    try:
        with socketserver.TCPServer(("0.0.0.0", args.port), handler) as httpd:
            print(f"Serving {directory} on http://0.0.0.0:{args.port} (Ctrl+C to stop)")
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                pass
            finally:
                httpd.server_close()
    except OSError as e:
        if getattr(e, 'errno', None) == 98:
            print(f"Error: Port {args.port} is already in use. Try another port, e.g.:\n\n  python3 scripts/serve-web.py {directory} 8081\n\nOr kill the process using the port.")
        else:
            raise

if __name__ == "__main__":
    main()
