from datetime import datetime
import sqlite3
from typing import Optional, List, Tuple, Dict


class Database:
    def __init__(self, database: str = 'data.db'):
        self._db_path = database
        self._init_tables()

    def _connect(self):
        return sqlite3.connect(self._db_path)

    def _init_tables(self):
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('PRAGMA foreign_keys = ON;')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS User (
                cookie TEXT PRIMARY KEY
            );
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS ImageResult (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                image_base64 TEXT NOT NULL,
                emoji TEXT NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS History (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                cookie TEXT NOT NULL,
                image_result_id INTEGER NOT NULL,
                FOREIGN KEY (cookie) REFERENCES User(cookie),
                FOREIGN KEY (image_result_id) REFERENCES ImageResult(id)
            );
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS Feedback (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                cookie TEXT NOT NULL,
                image_result_id INTEGER NOT NULL,
                rating INTEGER CHECK(rating BETWEEN 1 AND 5),
                comment TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (cookie) REFERENCES User(cookie),
                FOREIGN KEY (image_result_id) REFERENCES ImageResult(id)
            );
        ''')

        conn.commit()
        conn.close()

    def insert_user(self, cookie: str):
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('INSERT OR IGNORE INTO User (cookie) VALUES (?);', (cookie,))
        conn.commit()
        conn.close()

    def insert_image_result(self, image_base64: str, emoji: str) -> int:
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('INSERT INTO ImageResult (image_base64, emoji) VALUES (?, ?);',
                       (image_base64, emoji))
        image_id = cursor.lastrowid
        conn.commit()
        conn.close()
        return image_id

    def insert_history(self, cookie: str, image_result_id: int):
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('INSERT INTO History (cookie, image_result_id) VALUES (?, ?);',
                       (cookie, image_result_id))
        conn.commit()
        conn.close()

    def insert_feedback(self, cookie: str, image_result_id: int, rating: int, comment: Optional[str]):
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO Feedback (cookie, image_result_id, rating, comment)
            VALUES (?, ?, ?, ?);
        ''', (cookie, image_result_id, rating, comment))
        conn.commit()
        conn.close()

    def get_history_by_cookie(self, cookie: str) -> List[Tuple]:
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('''
            SELECT h.id, i.image_base64, i.emoji, i.timestamp
            FROM History h
            JOIN ImageResult i ON h.image_result_id = i.id
            WHERE h.cookie = ?
            ORDER BY i.timestamp DESC;
        ''', (cookie,))
        rows = cursor.fetchall()
        conn.close()
        return rows
    
    def get_history_by_cookie_paged(self, cookie: str, offset: int, limit: int) -> List[Tuple]:
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('''
            SELECT h.id, i.image_base64, i.emoji, i.timestamp
            FROM History h
            JOIN ImageResult i ON h.image_result_id = i.id
            WHERE h.cookie = ?
            ORDER BY i.timestamp DESC
            LIMIT ? OFFSET ?;
        ''', (cookie, limit, offset))
        rows = cursor.fetchall()
        conn.close()
        return rows

    def get_all_history_paged(self, offset: int, limit: int) -> List[Tuple]:
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('''
            SELECT h.cookie, h.id, i.image_base64, i.emoji, i.timestamp
            FROM History h
            JOIN ImageResult i ON h.image_result_id = i.id
            ORDER BY i.timestamp DESC
            LIMIT ? OFFSET ?;
        ''', (limit, offset))
        rows = cursor.fetchall()
        conn.close()
        return rows
    
    def get_history_count_by_cookie(self, cookie: str) -> int:
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('SELECT COUNT(*) FROM History WHERE cookie = ?;', (cookie,))
        count = cursor.fetchone()[0]
        conn.close()
        return count

    def get_total_history_count(self) -> int:
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('SELECT COUNT(*) FROM History;')
        count = cursor.fetchone()[0]
        conn.close()
        return count


    def get_all_history(self):
        conn = self._connect()
        cursor = conn.cursor()
        cursor.execute('''
            SELECT h.cookie, h.id, i.image_base64, i.emoji, i.timestamp
            FROM History h
            JOIN ImageResult i ON h.image_result_id = i.id
            ORDER BY i.timestamp DESC;
        ''')
        rows = cursor.fetchall()
        conn.close()
        return rows 

