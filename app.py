from flask import Flask, request, jsonify
import sqlite3
from datetime import datetime

app = Flask(__name__)

# 初始化数据库（新增了请假表）
def init_db():
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        # 现有的打卡表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS punch_card (
                record_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                clock_in_time TEXT,
                clock_out_time TEXT
            )
        ''')
        # 新增：请假表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS leave_request (
                leave_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                leave_type TEXT,
                start_date TEXT,
                end_date TEXT,
                status TEXT DEFAULT 'Pending'
            )
        ''')
        conn.commit()

init_db()

# --- Week 2: 打卡 API ---
@app.route('/api/clock-in', methods=['POST'])
def clock_in():
    data = request.get_json()
    staff_id = data.get('staff_id')
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('INSERT INTO punch_card (staff_id, clock_in_time) VALUES (?, ?)', (staff_id, current_time))
        conn.commit()
    return jsonify({"status": "success", "time": current_time}), 200

@app.route('/api/clock-out', methods=['POST'])
def clock_out():
    data = request.get_json()
    staff_id = data.get('staff_id')
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE punch_card SET clock_out_time = ? 
            WHERE record_id = (SELECT record_id FROM punch_card WHERE staff_id = ? AND clock_out_time IS NULL ORDER BY record_id DESC LIMIT 1)
        ''', (current_time, staff_id))
        conn.commit()
    return jsonify({"status": "success", "time": current_time, "total_hours": 9}), 200

# --- Week 3 新增: 请假申请 API ---
@app.route('/api/leave', methods=['POST'])
def apply_leave():
    data = request.get_json()
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO leave_request (staff_id, leave_type, start_date, end_date) 
            VALUES (?, ?, ?, ?)
        ''', (data['staff_id'], data['leave_type'], data['start_date'], data['end_date']))
        conn.commit()
    return jsonify({"status": "success", "message": "Leave application submitted successfully!"}), 200

# --- Week 3 新增: 薪水单计算 API ---
@app.route('/api/payslip', methods=['POST'])
def get_payslip():
    # 模拟从数据库汇总工时计算底薪与抽成 (Haidilao 逻辑)
    return jsonify({
        "basic_salary": 2800.00,
        "ot_pay": 450.00,
        "bonus": 200.00,
        "epf_socso_deduction": 315.00,
        "net_pay": 3135.00
    }), 200

if __name__ == '__main__':
    app.run(debug=True)