from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from threading import Thread
from .database import Database
import socket

class BackPlug:
    def __init__(self):
        self._app = Flask(__name__, static_folder='../frontend')
        CORS(self._app)

        self._db = Database()

        self._app.add_url_rule('/', 'home', self.home)
        self._app.add_url_rule('/send_image', 'send_to_server', self.send_to_server, methods=['POST'])
        self._app.add_url_rule('/shutdown', 'shutdown', self.shutdown, methods=['POST'])
        self._app.add_url_rule('/history', 'get_history', self.get_history, methods=['POST'])
        self._app.add_url_rule('/history_all', 'get_all_history', self.get_all_history, methods=['POST'])
        self._app.add_url_rule('/feedback', 'send_feedback', self.send_feedback, methods=['POST'])

    def home(self):
        return send_from_directory('../frontend', 'index.html')

    def send_to_server(self):
        data = request.get_json()
        image_base64 = data.get('image_base64', '')
        user_name = data.get('user_name')
        
        try:
            prompt = data.get('prompt')
        except:
            prompt = ''
        message = f'{prompt}:{image_base64}'

        if not user_name:
            user_name = 'unnamed'

        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.connect(('localhost', 8888))
                s.sendall(message.encode('utf-8'))
                emoji = s.recv(1024).decode('utf-8')
        except Exception as e:
            return jsonify({"status": "error", "error": str(e)})

        if not 'Error' in emoji:
            self._db.insert_user(user_name)
            image_id = self._db.insert_image_result(image_base64, emoji)
            self._db.insert_history(user_name, image_id)

            return jsonify({"status": "ok", "emoji": emoji, "history_id": image_id})
        return jsonify({"status": "error", "error": emoji})

    def get_history(self):
        data = request.get_json()
        user_name = data.get('user_name')
        offset = int(data.get('offset', 0))
        limit = int(data.get('limit', 10))

        if not user_name:
            return jsonify({"status": "error", "error": "Missing user name"}), 400

        try:
            history = self._db.get_history_by_cookie_paged(user_name, offset, limit)
            total = self._db.get_history_count_by_cookie(user_name)
            
            result = [
                {
                    "user_name": user_name,
                    "history_id": row[0],
                    "image_base64": row[1],
                    "emoji": row[2],
                    "timestamp": row[3]
                }
                for row in history
            ]
            return jsonify({"status": "ok", "total": total, "history": result})
        except Exception as e:
            return jsonify({"status": "error", "error": str(e)}), 500
    
    def get_all_history(self):
        try:
            data = request.get_json()
            offset = int(data.get('offset', 0))
            limit = int(data.get('limit', 10))

            history = self._db.get_all_history_paged(offset, limit)
            total = self._db.get_total_history_count()

            result = [
                {
                    "user_name": row[0],
                    "history_id": row[1],
                    "image_base64": row[2],
                    "emoji": row[3],
                    "timestamp": row[4]
                }
                for row in history
            ]
            return jsonify({"status": "ok", "total": total, "history": result})
        except Exception as e:
            return jsonify({"status": "error", "error": str(e)}), 500


    def send_feedback(self):
        data = request.get_json()
        user_name = data.get('user_name')
        image_result_id = data.get("image_result_id")
        rating = data.get("rating")
        comment = data.get("comment", "")

        if not user_name:
            user_name = 'unnamed'
        if not isinstance(image_result_id, int) or not (1 <= rating <= 5):
            return jsonify({"status": "error", "error": "Invalid rating or image_result_id"}), 400

        try:
            self._db.insert_feedback(user_name, image_result_id, rating, comment)
            return jsonify({"status": "ok", "message": "Feedback received"})
        except Exception as e:
            return jsonify({"status": "error", "error": str(e)}), 500

    def start(self, host='0.0.0.0', port='8080'):
        self._app.run(host=host, port=port)

    def start_nowait(self, host='0.0.0.0', port='8080'):
        Thread(target=self.start, args=(host, port), daemon=True).start()

    def shutdown(self):
        func = request.environ.get('werkzeug.server.shutdown')
        if func is None:
            return jsonify({"status": "error", "error": "Not running with the Werkzeug Server"})
        func()
        return jsonify({"status": "ok", "message": "Server shutting down..."})
