from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.parse
from manga_ocr import MangaOcr

mocr = MangaOcr()


class SimpleHandler(BaseHTTPRequestHandler):
    def do_HEAD(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()

    def do_GET(self):
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        image_path = params.get("q", [""])[0]

        result_text = mocr(image_path)

        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(result_text.encode())


def run(server_class=HTTPServer, handler_class=SimpleHandler):
    server_address = ('127.0.0.1', 8081)
    httpd = server_class(server_address, handler_class)
    print("Starting server on port 8081...")
    httpd.serve_forever()


if __name__ == "__main__":
    run()
