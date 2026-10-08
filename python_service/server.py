"""
server.py - REST API Server for Sheep Farm Management & Data Synchronization
Built with Python standard library http.server (Runs out-of-the-box with 0 pip install dependencies!)
"""

import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from db_manager import DatabaseManager

db = DatabaseManager()

class SheepApiHandler(BaseHTTPRequestHandler):
    def _set_headers(self, status_code=200, content_type="application/json"):
        self.send_response(status_code)
        self.send_header("Content-Type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(204)

    def _read_json_body(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length > 0:
            body = self.rfile.read(content_length).decode("utf-8")
            return json.loads(body)
        return {}

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        try:
            if path == "/" or path == "/index.html":
                import os
                web_path = os.path.join(os.path.dirname(__file__), "web", "index.html")
                if os.path.exists(web_path):
                    self._set_headers(200, "text/html; charset=utf-8")
                    with open(web_path, "rb") as f:
                        self.wfile.write(f.read())
                    return
                self._set_headers()
                self.wfile.write(json.dumps({"status": "running", "service": "Sheep Farm Manager API", "version": "1.0.0"}).encode())

            elif path == "/api/health":
                self._set_headers()
                self.wfile.write(json.dumps({"status": "running", "service": "Sheep Farm Manager API", "version": "1.0.0"}).encode())

            elif path == "/api/sheep":
                status = query.get("status", [None])[0]
                sheep_list = db.get_all_sheep(status)
                self._set_headers()
                self.wfile.write(json.dumps(sheep_list).encode())

            elif path == "/api/stats":
                stats = db.get_sheep_stats()
                fin_summary = db.get_financial_summary()
                self._set_headers()
                self.wfile.write(json.dumps({"sheep": stats, "finances": fin_summary}).encode())

            elif path == "/api/breeding":
                records = db.get_all_breeding_records()
                self._set_headers()
                self.wfile.write(json.dumps(records).encode())

            elif path == "/api/finances":
                records = db.get_all_financial_records()
                self._set_headers()
                self.wfile.write(json.dumps(records).encode())

            elif path == "/api/finances/summary":
                summary = db.get_financial_summary()
                self._set_headers()
                self.wfile.write(json.dumps(summary).encode())

            elif path == "/api/reminders":
                tasks = db.get_upcoming_health_tasks()
                self._set_headers()
                self.wfile.write(json.dumps(tasks).encode())

            elif path == "/api/sync/export":
                backup = db.export_full_backup()
                self._set_headers()
                self.wfile.write(json.dumps(backup, indent=2).encode())

            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"error": f"Path {path} not found"}).encode())

        except Exception as e:
            self._set_headers(500)
            self.wfile.write(json.dumps({"error": str(e)}).encode())

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        try:
            data = self._read_json_body()

            if path == "/api/sheep":
                sheep_id = db.insert_sheep(data)
                self._set_headers(201)
                self.wfile.write(json.dumps({"success": True, "id": sheep_id}).encode())

            elif path == "/api/health":
                rec_id = db.insert_health_record(data)
                self._set_headers(201)
                self.wfile.write(json.dumps({"success": True, "id": rec_id}).encode())

            elif path == "/api/breeding":
                rec_id = db.insert_breeding_record(data)
                self._set_headers(201)
                self.wfile.write(json.dumps({"success": True, "id": rec_id}).encode())

            elif path == "/api/finances":
                rec_id = db.insert_financial_record(data)
                self._set_headers(201)
                self.wfile.write(json.dumps({"success": True, "id": rec_id}).encode())

            elif path == "/api/sync/import":
                success = db.import_full_backup(data)
                self._set_headers(200)
                self.wfile.write(json.dumps({"success": success, "message": "Database successfully synced!"}).encode())

            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"error": f"Endpoint {path} not found"}).encode())

        except Exception as e:
            self._set_headers(500)
            self.wfile.write(json.dumps({"error": str(e)}).encode())

    def do_DELETE(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        try:
            if path == "/api/sheep":
                sheep_id = query.get("id", [None])[0]
                if sheep_id:
                    deleted = db.delete_sheep(sheep_id)
                    self._set_headers()
                    self.wfile.write(json.dumps({"success": deleted}).encode())
                else:
                    self._set_headers(400)
                    self.wfile.write(json.dumps({"error": "Missing 'id' query parameter"}).encode())
            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"error": "Not found"}).encode())
        except Exception as e:
            self._set_headers(500)
            self.wfile.write(json.dumps({"error": str(e)}).encode())

import sys
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

def run_server(port=8080):
    server_address = ("", port)
    httpd = HTTPServer(server_address, SheepApiHandler)
    print("==================================================")
    print("[*] Sheep Farm Management REST API Server Started!")
    print(f"[*] Local access:   http://localhost:{port}")
    print(f"[*] Network mobile: http://192.168.1.8:{port}")
    print(f"[*] Live Web App:   http://localhost:{port}/")
    print("==================================================")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.server_close()

if __name__ == "__main__":
    run_server(8080)
