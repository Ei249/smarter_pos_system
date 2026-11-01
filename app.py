# cSpell:ignore socso Haidilao KWSP PERKESO
from flask import Flask, request, jsonify  # type: ignore
import sqlite3
from datetime import datetime

app = Flask(__name__)

def init_db():
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS punch_card (
                record_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                clock_in_time TEXT,
                clock_out_time TEXT,
                total_hours REAL
            )
        ''')
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS leave_request (
                leave_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                leave_type TEXT,
                start_date TEXT,
                end_date TEXT,
                reason TEXT,
                status TEXT DEFAULT 'Pending'
            )
        ''')
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

# 1. 查询当前打卡状态 API
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
        cursor.execute('SELECT record_id FROM punch_card WHERE staff_id = ? AND clock_out_time IS NULL', (staff_id,))
        if cursor.fetchone():
            return jsonify({"status": "error", "message": "Already clocked in!"}), 400

        cursor.execute('INSERT INTO punch_card (staff_id, clock_in_time) VALUES (?, ?)', (staff_id, current_time))
        conn.commit()
    return jsonify({"status": "success", "time": current_time}), 200

# 3. 下班打卡 API
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

# 5. 提交请假与获取请假列表 API (Week 4: 返回 leave_id 供主管审批)
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
            SELECT leave_id, leave_type, start_date, end_date, reason, status 
            FROM leave_request WHERE staff_id = ? ORDER BY leave_id DESC
        ''', (data.get('staff_id', 1),))
        rows = cursor.fetchall()
    leave_list = [{
        "id": r[0],
        "type": r[1],
        "start": r[2],
        "end": r[3],
        "reason": r[4] or "-",
        "status": r[5]
    } for r in rows]
    return jsonify({"status": "success", "data": leave_list}), 200

# Week 4 新增: 主管审批请假 API (Approve / Reject)
@app.route('/api/leave-approve', methods=['POST'])
def approve_leave():
    data = request.get_json()
    leave_id = data.get('leave_id')
    new_status = data.get('status')  # 'Approved' or 'Rejected'
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('UPDATE leave_request SET status = ? WHERE leave_id = ?', (new_status, leave_id))
        conn.commit()
    return jsonify({"status": "success", "new_status": new_status}), 200

# 6. 多层级薪水单 API (Week 4: 2026年10月与真实打卡数据实时联动 + 16个月完整记录)
@app.route('/api/payslips-all', methods=['POST'])
def get_all_payslips():
    data = request.get_json() or {}
    staff_id = data.get('staff_id', 1)

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        # 统计该员工已完成打卡的次数与累计工时
        cursor.execute('SELECT COUNT(*), COALESCE(SUM(total_hours), 0) FROM punch_card WHERE staff_id = ? AND clock_out_time IS NOT NULL', (staff_id,))
        shift_count, recorded_hours = cursor.fetchone()
        # 检查是否有已批准的无薪假 (UP)
        cursor.execute("SELECT COUNT(*) FROM leave_request WHERE staff_id = ? AND status = 'Approved' AND leave_type LIKE 'UP%'", (staff_id,))
        unpaid_leave_count = cursor.fetchone()[0]

    # 动态计算 2026年10月 薪资：每次打卡模拟增加 RM 25 加班津贴，若请无薪假则扣除全勤奖
    dynamic_ot = round(450.00 + (shift_count * 25.00) + (recorded_hours * 12.50), 2)
    dynamic_bonus = 0.00 if unpaid_leave_count > 0 else 150.00
    basic = 2800.00
    commission = 380.00
    epf = 308.00
    socso = 19.75
    eis = 4.50
    oct_net_pay = round(basic + dynamic_ot + commission + dynamic_bonus - epf - socso - eis, 2)

    payslip_db = {
        "2026": [
            {
                "month": "October", "month_num": "10", "status": "Live Calc", "pay_date": "2026-10-31",
                "basic_salary": basic, "ot_pay": dynamic_ot, "commission": commission, "attendance_bonus": dynamic_bonus,
                "epf": epf, "socso": socso, "eis": eis, "net_pay": oct_net_pay
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
            },
            {
                "month": "July", "month_num": "07", "status": "Paid", "pay_date": "2026-07-31",
                "basic_salary": 2800.00, "ot_pay": 280.00, "commission": 390.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 3287.75
            },
            {
                "month": "June", "month_num": "06", "status": "Paid", "pay_date": "2026-06-30",
                "basic_salary": 2800.00, "ot_pay": 400.00, "commission": 460.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 3477.75
            },
            {
                "month": "May", "month_num": "05", "status": "Paid", "pay_date": "2026-05-31",
                "basic_salary": 2800.00, "ot_pay": 490.00, "commission": 480.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 3587.75
            },
            {
                "month": "April", "month_num": "04", "status": "Paid", "pay_date": "2026-04-30",
                "basic_salary": 2800.00, "ot_pay": 180.00, "commission": 340.00, "attendance_bonus": 0.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 2987.75
            },
            {
                "month": "March", "month_num": "03", "status": "Paid", "pay_date": "2026-03-31",
                "basic_salary": 2800.00, "ot_pay": 350.00, "commission": 420.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 3387.75
            },
            {
                "month": "February", "month_num": "02", "status": "Paid", "pay_date": "2026-02-28",
                "basic_salary": 2800.00, "ot_pay": 780.00, "commission": 750.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 4147.75
            },
            {
                "month": "January", "month_num": "01", "status": "Paid", "pay_date": "2026-01-31",
                "basic_salary": 2800.00, "ot_pay": 410.00, "commission": 440.00, "attendance_bonus": 150.00,
                "epf": 308.00, "socso": 19.75, "eis": 4.50, "net_pay": 3467.75
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
            },
            {
                "month": "October", "month_num": "10", "status": "Paid", "pay_date": "2025-10-31",
                "basic_salary": 2600.00, "ot_pay": 310.00, "commission": 390.00, "attendance_bonus": 150.00,
                "epf": 286.00, "socso": 18.25, "eis": 4.20, "net_pay": 3141.55
            },
            {
                "month": "September", "month_num": "09", "status": "Paid", "pay_date": "2025-09-30",
                "basic_salary": 2600.00, "ot_pay": 290.00, "commission": 360.00, "attendance_bonus": 150.00,
                "epf": 286.00, "socso": 18.25, "eis": 4.20, "net_pay": 3091.55
            },
            {
                "month": "August", "month_num": "08", "status": "Paid", "pay_date": "2025-08-31",
                "basic_salary": 2600.00, "ot_pay": 420.00, "commission": 450.00, "attendance_bonus": 150.00,
                "epf": 286.00, "socso": 18.25, "eis": 4.20, "net_pay": 3311.55
            },
            {
                "month": "July", "month_num": "07", "status": "Paid", "pay_date": "2025-07-31",
                "basic_salary": 2600.00, "ot_pay": 200.00, "commission": 310.00, "attendance_bonus": 150.00,
                "epf": 286.00, "socso": 18.25, "eis": 4.20, "net_pay": 2951.55
            }
        ]
    }
    return jsonify({"status": "success", "data": payslip_db}), 200

if __name__ == '__main__':
    app.run(debug=True)