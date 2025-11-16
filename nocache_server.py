#!/usr/bin/env python3
"""
Simple HTTP server with no-cache headers to force browsers to fetch fresh content.
This ensures that changes to Flutter web apps are immediately visible.
"""

import http.server
import socketserver
import os
import sys

PORT = 5060

class NoCacheHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with aggressive no-cache headers"""
    
    def end_headers(self):
        # CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        
        # Aggressive no-cache headers
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        
        # Call parent
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests for CORS"""
        self.send_response(200)
        self.end_headers()

if __name__ == '__main__':
    # Change to build/web directory
    web_dir = os.path.join(os.path.dirname(__file__), 'build', 'web')
    os.chdir(web_dir)
    
    print(f"🚀 Starting Flutter web server on port {PORT}")
    print(f"📁 Serving directory: {os.getcwd()}")
    print(f"🔗 URL: http://localhost:{PORT}/")
    print(f"⚡ No-cache headers enabled - changes will be immediately visible")
    print(f"\nPress Ctrl+C to stop the server\n")
    
    with socketserver.TCPServer(("0.0.0.0", PORT), NoCacheHTTPRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n👋 Server stopped")
            sys.exit(0)
