"""
db_manager.py - SQLite Database Management for Sheep Farm Manager (Python Suite)
Matches the exact schema and structures of the Flutter SQLite database for seamless sync.
"""

import sqlite3
import json
from datetime import datetime
from typing import List, Dict, Any, Optional

DB_FILE = "sheep_farm.db"

class DatabaseManager:
    def __init__(self, db_path: str = DB_FILE):
        self.db_path = db_path
        self._init_db()

    def _get_connection(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        with self._get_connection() as conn:
            cursor = conn.cursor()
            # Sheep table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS sheep (
                    id TEXT PRIMARY KEY,
                    tagNumber TEXT NOT NULL,
                    name TEXT,
                    breed TEXT,
                    gender TEXT NOT NULL,
                    dateOfBirth TEXT NOT NULL,
                    weight REAL,
                    color TEXT,
                    status TEXT DEFAULT 'Active',
                    motherId TEXT,
                    fatherId TEXT,
                    photoPath TEXT,
                    notes TEXT,
                    dateAdded TEXT NOT NULL,
                    lastUpdated TEXT NOT NULL
                )
            ''')

            # Health records table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS health_records (
                    id TEXT PRIMARY KEY,
                    sheepId TEXT NOT NULL,
                    type TEXT NOT NULL,
                    description TEXT NOT NULL,
                    medicine TEXT,
                    dosage REAL,
                    dosageUnit TEXT,
                    veterinarian TEXT,
                    cost REAL,
                    date TEXT NOT NULL,
                    nextDueDate TEXT,
                    status TEXT DEFAULT 'Completed',
                    notes TEXT,
                    createdAt TEXT NOT NULL,
                    FOREIGN KEY (sheepId) REFERENCES sheep(id)
                )
            ''')

            # Weight records
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS weight_records (
                    id TEXT PRIMARY KEY,
                    sheepId TEXT NOT NULL,
                    weight REAL NOT NULL,
                    date TEXT NOT NULL,
                    notes TEXT,
                    FOREIGN KEY (sheepId) REFERENCES sheep(id)
                )
            ''')

            # Breeding records
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS breeding_records (
                    id TEXT PRIMARY KEY,
                    eweId TEXT NOT NULL,
                    ramId TEXT,
                    matingDate TEXT NOT NULL,
                    expectedLambingDate TEXT,
                    actualLambingDate TEXT,
                    status TEXT DEFAULT 'Mated',
                    lambsBorn INTEGER,
                    lambsSurvived INTEGER,
                    notes TEXT,
                    createdAt TEXT NOT NULL,
                    FOREIGN KEY (eweId) REFERENCES sheep(id)
                )
            ''')

            # Financial records
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS financial_records (
                    id TEXT PRIMARY KEY,
                    type TEXT NOT NULL,
                    category TEXT NOT NULL,
                    description TEXT NOT NULL,
                    amount REAL NOT NULL,
                    date TEXT NOT NULL,
                    sheepId TEXT,
                    notes TEXT,
                    createdAt TEXT NOT NULL
                )
            ''')

            # Feed records
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS feed_records (
                    id TEXT PRIMARY KEY,
                    feedType TEXT NOT NULL,
                    quantity REAL NOT NULL,
                    costPerKg REAL,
                    date TEXT NOT NULL,
                    notes TEXT,
                    createdAt TEXT NOT NULL
                )
            ''')
            conn.commit()

    # ================= SHEEP CRUD =================
    def insert_sheep(self, data: Dict[str, Any]) -> str:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT OR REPLACE INTO sheep 
                (id, tagNumber, name, breed, gender, dateOfBirth, weight, color, status, motherId, fatherId, photoPath, notes, dateAdded, lastUpdated)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                data['id'], data['tagNumber'], data.get('name', ''), data.get('breed', ''),
                data['gender'], data['dateOfBirth'], data.get('weight', 0.0), data.get('color', ''),
                data.get('status', 'Active'), data.get('motherId'), data.get('fatherId'),
                data.get('photoPath'), data.get('notes'), data['dateAdded'], data['lastUpdated']
            ))
            conn.commit()
            return data['id']

    def get_all_sheep(self, status: Optional[str] = None) -> List[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            if status and status != 'All':
                cursor.execute('SELECT * FROM sheep WHERE status = ? ORDER BY dateAdded DESC', (status,))
            else:
                cursor.execute('SELECT * FROM sheep ORDER BY dateAdded DESC')
            return [dict(row) for row in cursor.fetchall()]

    def get_sheep_by_id(self, sheep_id: str) -> Optional[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM sheep WHERE id = ?', (sheep_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def delete_sheep(self, sheep_id: str) -> bool:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('DELETE FROM sheep WHERE id = ?', (sheep_id,))
            conn.commit()
            return cursor.rowcount > 0

    def get_sheep_stats(self) -> Dict[str, int]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT 
                    COUNT(*) as total,
                    SUM(CASE WHEN gender = 'Female' AND status = 'Active' THEN 1 ELSE 0 END) as ewes,
                    SUM(CASE WHEN gender = 'Male' AND status = 'Active' THEN 1 ELSE 0 END) as rams,
                    SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) as active,
                    SUM(CASE WHEN status = 'Sold' THEN 1 ELSE 0 END) as sold,
                    SUM(CASE WHEN status = 'Deceased' THEN 1 ELSE 0 END) as deceased
                FROM sheep
            ''')
            row = cursor.fetchone()
            return {
                'total': row['total'] or 0,
                'ewes': row['ewes'] or 0,
                'rams': row['rams'] or 0,
                'active': row['active'] or 0,
                'sold': row['sold'] or 0,
                'deceased': row['deceased'] or 0,
            }

    # ================= HEALTH CRUD =================
    def insert_health_record(self, data: Dict[str, Any]) -> str:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT OR REPLACE INTO health_records
                (id, sheepId, type, description, medicine, dosage, dosageUnit, veterinarian, cost, date, nextDueDate, status, notes, createdAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                data['id'], data['sheepId'], data['type'], data['description'],
                data.get('medicine'), data.get('dosage'), data.get('dosageUnit'),
                data.get('veterinarian'), data.get('cost'), data['date'],
                data.get('nextDueDate'), data.get('status', 'Completed'),
                data.get('notes'), data['createdAt']
            ))
            conn.commit()
            return data['id']

    def get_upcoming_health_tasks(self, days_ahead: int = 30) -> List[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT h.*, s.tagNumber, s.name as sheepName
                FROM health_records h
                LEFT JOIN sheep s ON h.sheepId = s.id
                WHERE h.nextDueDate IS NOT NULL AND date(h.nextDueDate) >= date('now')
                ORDER BY h.nextDueDate ASC
            ''')
            return [dict(row) for row in cursor.fetchall()]

    # ================= BREEDING CRUD =================
    def insert_breeding_record(self, data: Dict[str, Any]) -> str:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT OR REPLACE INTO breeding_records
                (id, eweId, ramId, matingDate, expectedLambingDate, actualLambingDate, status, lambsBorn, lambsSurvived, notes, createdAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                data['id'], data['eweId'], data.get('ramId'), data['matingDate'],
                data.get('expectedLambingDate'), data.get('actualLambingDate'),
                data.get('status', 'Mated'), data.get('lambsBorn'), data.get('lambsSurvived'),
                data.get('notes'), data['createdAt']
            ))
            conn.commit()
            return data['id']

    def get_all_breeding_records(self) -> List[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT b.*, e.tagNumber as eweTag, e.name as eweName, r.tagNumber as ramTag
                FROM breeding_records b
                LEFT JOIN sheep e ON b.eweId = e.id
                LEFT JOIN sheep r ON b.ramId = r.id
                ORDER BY b.matingDate DESC
            ''')
            return [dict(row) for row in cursor.fetchall()]

    # ================= FINANCIAL CRUD =================
    def insert_financial_record(self, data: Dict[str, Any]) -> str:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT OR REPLACE INTO financial_records
                (id, type, category, description, amount, date, sheepId, notes, createdAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                data['id'], data['type'], data['category'], data['description'],
                data['amount'], data['date'], data.get('sheepId'), data.get('notes'),
                data['createdAt']
            ))
            conn.commit()
            return data['id']

    def get_all_financial_records(self) -> List[Dict[str, Any]]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM financial_records ORDER BY date DESC')
            return [dict(row) for row in cursor.fetchall()]

    def get_financial_summary(self) -> Dict[str, float]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT 
                    SUM(CASE WHEN type = 'Income' THEN amount ELSE 0 END) as totalIncome,
                    SUM(CASE WHEN type = 'Expense' THEN amount ELSE 0 END) as totalExpense
                FROM financial_records
            ''')
            row = cursor.fetchone()
            income = float(row['totalIncome'] or 0.0)
            expense = float(row['totalExpense'] or 0.0)
            return {
                'income': income,
                'expense': expense,
                'net_profit': income - expense
            }

    # ================= BACKUP SYNC =================
    def export_full_backup(self) -> Dict[str, Any]:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            tables = ['sheep', 'health_records', 'weight_records', 'breeding_records', 'financial_records', 'feed_records']
            backup = {}
            for t in tables:
                cursor.execute(f'SELECT * FROM {t}')
                backup[t] = [dict(r) for r in cursor.fetchall()]
            backup['exportedAt'] = datetime.utcnow().isoformat()
            backup['version'] = '1.0.0'
            return backup

    def import_full_backup(self, data: Dict[str, Any]) -> bool:
        with self._get_connection() as conn:
            cursor = conn.cursor()
            tables = ['sheep', 'health_records', 'weight_records', 'breeding_records', 'financial_records', 'feed_records']
            for t in tables:
                cursor.execute(f'DELETE FROM {t}')
                if t in data and isinstance(data[t], list):
                    for row in data[t]:
                        cols = ', '.join(row.keys())
                        placeholders = ', '.join(['?'] * len(row))
                        cursor.execute(f'INSERT INTO {t} ({cols}) VALUES ({placeholders})', list(row.values()))
            conn.commit()
            return True
