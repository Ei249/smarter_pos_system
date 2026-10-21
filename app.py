# cSpell:ignore socso Haidilao
from flask import Flask, request, jsonify  # type: ignore
import sqlite3
from datetime import datetime

app = Flask(__name__)

def init_db():
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        # 打卡表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS punch_card (
                record_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                clock_in_time TEXT,
                clock_out_time TEXT,
                total_hours REAL
            )
        ''')
        # 请假表 (新增 reason 字段)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS leave_request (
                leave_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                leave_type TEXT,
                start_date TEXT,
                end_date TEXT,
                reason TEXT,
                status TEXT DEFAULT 'Approved'
            )
        ''')
        # 自动检查并补充旧表可能缺失的列 (防止报错)
        cursor.execute("PRAGMA table_info(punch_card)")
        columns = [col[1] for col in cursor.fetchall()]
        if 'total_hours' not in columns:
            cursor.execute('ALTER TABLE punch_card ADD COLUMN total_hours REAL')

        cursor.execute("PRAGMA table_info(leave_request)")
        leave_cols = [col[1] for col in cursor.fetchall()]
        if 'reason' not in leave_cols:
            cursor.execute('ALTER TABLE leave_request ADD COLUMN reason TEXT')

        conn.commit()

init_db()

# 1. 查询当前打卡状态 API (解决切页面状态丢失问题)
@app.route('/api/status', methods=['POST'])
def get_status():
    data = request.get_json()
    staff_id = data.get('staff_id', 1)
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT record_id, clock_in_time FROM punch_card 
            WHERE staff_id = ? AND clock_out_time IS NULL 
            ORDER BY record_id DESC LIMIT 1
        ''', (staff_id,))
        active_record = cursor.fetchone()

    if active_record:
        return jsonify({
            "is_clocked_in": True,
            "clock_in_time": active_record[1]
        }), 200
    else:
        return jsonify({"is_clocked_in": False}), 200

# 2. 上班打卡 API
@app.route('/api/clock-in', methods=['POST'])
def clock_in():
    data = request.get_json()
    staff_id = data.get('staff_id', 1)
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        # 防止重复 Clock in
        cursor.execute('SELECT record_id FROM punch_card WHERE staff_id = ? AND clock_out_time IS NULL', (staff_id,))
        if cursor.fetchone():
            return jsonify({"status": "error", "message": "Already clocked in!"}), 400

        cursor.execute('INSERT INTO punch_card (staff_id, clock_in_time) VALUES (?, ?)', (staff_id, current_time))
        conn.commit()
    return jsonify({"status": "success", "time": current_time}), 200

# 3. 下班打卡 API (带真实工时计算)
@app.route('/api/clock-out', methods=['POST'])
def clock_out():
    data = request.get_json()
    staff_id = data.get('staff_id', 1)
    now = datetime.now()
    current_time = now.strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT record_id, clock_in_time FROM punch_card 
            WHERE staff_id = ? AND clock_out_time IS NULL 
            ORDER BY record_id DESC LIMIT 1
        ''', (staff_id,))
        row = cursor.fetchone()

        if not row:
            return jsonify({"status": "error", "message": "No active clock-in session found."}), 400

        record_id, clock_in_str = row
        clock_in_dt = datetime.strptime(clock_in_str, "%Y-%m-%d %H:%M:%S")
        # 计算真实小时数 (保留2位小数)
        diff_hours = round((now - clock_in_dt).total_seconds() / 3600, 2)

        cursor.execute('''
            UPDATE punch_card 
            SET clock_out_time = ?, total_hours = ?
            WHERE record_id = ?
        ''', (current_time, diff_hours, record_id))
        conn.commit()

    return jsonify({
        "status": "success", 
        "time": current_time, 
        "total_hours": diff_hours
    }), 200

# 4. 历史考勤记录 API
@app.route('/api/history', methods=['POST'])
def get_history():
    data = request.get_json()
    staff_id = data.get('staff_id', 1)
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT clock_in_time, clock_out_time, total_hours 
            FROM punch_card WHERE staff_id = ? 
            ORDER BY record_id DESC LIMIT 20
        ''', (staff_id,))
        records = cursor.fetchall()
        
    history_list = [{
        "in": r[0], 
        "out": r[1] if r[1] else "Active Shift",
        "hours": r[2] if r[2] is not None else 0.0
    } for r in records]
    return jsonify({"status": "success", "data": history_list}), 200

# 5. 提交请假与获取请假列表 API
@app.route('/api/leave', methods=['POST'])
def apply_leave():
    data = request.get_json()
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO leave_request (staff_id, leave_type, start_date, end_date, reason, status) 
            VALUES (?, ?, ?, ?, ?, 'Pending')
        ''', (data['staff_id'], data['leave_type'], data['start_date'], data['end_date'], data.get('reason', '')))
        conn.commit()
    return jsonify({"status": "success", "message": "Leave application submitted!"}), 200

@app.route('/api/leave-list', methods=['POST'])
def get_leave_list():
    data = request.get_json()
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT leave_type, start_date, end_date, reason, status 
            FROM leave_request WHERE staff_id = ? ORDER BY leave_id DESC
        ''', (data.get('staff_id', 1),))
        rows = cursor.fetchall()
    leave_list = [{"type": r[0], "start": r[1], "end": r[2], "reason": r[3] or "-", "status": r[4]} for r in rows]
    return jsonify({"status": "success", "data": leave_list}), 200

# 6. 多层级薪水单 API (按年份、月份结构化返回)
@app.route('/api/payslips-all', methods=['POST'])
def get_all_payslips():
    # 模拟真实的多年份、多月份海底捞薪资数据
    payslip_db = {
        "2026": [
            {
                "month": "October", "month_num": "10", "status": "Paid", "pay_date": "2026-10-31",
                "basic_salary": 2800.00, "ot_pay": 450.00, "commission": 380.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 3447.75
            },
            {
                "month": "September", "month_num": "09", "status": "Paid", "pay_date": "2026-09-30",
                "basic_salary": 2800.00, "ot_pay": 320.00, "commission": 410.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 3347.75
            },
            {
                "month": "August", "month_num": "08", "status": "Paid", "pay_date": "2026-08-31",
                "basic_salary": 2800.00, "ot_pay": 510.00, "commission": 520.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 3647.75
            }
        ],
        "2025": [
            {
                "month": "December", "month_num": "12", "status": "Paid", "pay_date": "2025-12-31",
                "basic_salary": 2600.00, "ot_pay": 600.00, "commission": 800.00, "attendance_bonus": 150.00,
                "epf": 286.00, "socso": 18.25, "eis": 4.20, "net_pay": 3841.55
            },
            {
                "month": "November", "month_num": "11", "status": "Paid", "pay_date": "2025-11-30",
                "basic_salary": 2600.00, "ot_pay": 250.00, "commission": 350.00, "attendance_bonus": 150.00,
                "epf": 286.00, "socso": 18.25, "eis": 4.20, "net_pay": 3041.55
            }
        ]
    }
    return jsonify({"status": "success", "data": payslip_db}), 200

if __name__ == '__main__':
    app.run(debug=True)