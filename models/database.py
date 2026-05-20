import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'database.db')

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS licenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            license_number TEXT NOT NULL,
            expiry TEXT NOT NULL,
            status TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()

# Initialize DB on load
init_db()

def save_result(data):
    """
    Handles saving results.
    """
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO licenses (license_number, expiry, status)
        VALUES (?, ?, ?)
    ''', (
        data.get('license_number', 'UNKNOWN'),
        data.get('expiry', 'UNKNOWN'),
        data.get('status', 'ERROR')
    ))
    conn.commit()
    conn.close()
