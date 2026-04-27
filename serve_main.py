import http.server
import socketserver
import os
from pathlib import Path

PORT = 8080

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

if __name__ == '__main__':
    build_dir = Path('build/web')
    if not build_dir.exists():
        print(f"Error: {build_dir} does not exist")
        exit(1)
    
    os.chdir(build_dir)
    
    with ReusableTCPServer(("", PORT), CORSRequestHandler) as httpd:
        print(f"Serving Main App from {build_dir}")
        print(f"Server running at http://localhost:{PORT}")
        print(f"Press Ctrl+C to stop")
        httpd.serve_forever()
