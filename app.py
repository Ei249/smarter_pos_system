# cSpell:ignore socso Haidilao KWSP PERKESO Sutera Utama Maybank Johor Bahru CIMB executemany Berhad
from flask import Flask, request, jsonify  # type: ignore
import sqlite3
from datetime import datetime

app = Flask(__name__)

@app.after_request
def add_no_cache_headers(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

def init_db():
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()

        # 1. 员工与权限表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                staff_id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE,
                password TEXT,
                full_name TEXT,
                role_level INTEGER,
                role_title TEXT,
                branch TEXT,
                basic_salary REAL,
                custom_bonus REAL DEFAULT 150.0,
                bank_info TEXT,
                epf_no TEXT
            )
        ''')
        cursor.execute('SELECT COUNT(*) FROM users')
        if cursor.fetchone()[0] == 0:
            default_users = [
                ('staff', '1234', 'Ng Zhe Wei', 1, 'Service Crew (L1)', 'Sutera Utama Branch', 2800.00, 150.00, 'Public Bank (**** 8821)', 'KWSP-99482104'),
                ('manager', '1234', 'Eugene Tang', 2, 'Branch Manager (L2)', 'Sutera Utama Branch', 4800.00, 500.00, 'Maybank (**** 3319)', 'KWSP-88120391'),
                ('admin', '1234', 'See Lin', 3, 'HR Director (L3)', 'Johor Bahru HQ', 7500.00, 1000.00, 'CIMB Bank (**** 1029)', 'KWSP-77219002')
            ]
            cursor.executemany('''
                INSERT INTO users (username, password, full_name, role_level, role_title, branch, basic_salary, custom_bonus, bank_info, epf_no)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', default_users)

        # 2. 传统打卡表与“一进一出”独立事件流水表
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
            CREATE TABLE IF NOT EXISTS attendance_events (
                event_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                event_type TEXT,
                event_time TEXT,
                shift_hours REAL DEFAULT 0.0,
                location TEXT DEFAULT 'JB Sutera Terminal #01'
            )
        ''')
        cursor.execute('SELECT COUNT(*) FROM attendance_events')
        if cursor.fetchone()[0] == 0:
            demo_events = [
                (1, 'IN', '2026-10-30 09:58:12', 0.0, 'Sutera Biometric Gate A'),
                (1, 'OUT', '2026-10-30 19:02:45', 9.08, 'Sutera Biometric Gate A'),
                (1, 'IN', '2026-10-31 13:55:04', 0.0, 'Sutera Biometric Gate A'),
                (1, 'OUT', '2026-10-31 23:10:19', 9.25, 'Sutera Biometric Gate A'),
            ]
            cursor.executemany('''
                INSERT INTO attendance_events (staff_id, event_type, event_time, shift_hours, location)
                VALUES (?, ?, ?, ?, ?)
            ''', demo_events)

        # 3. 请假表 (升级：加入 reviewer_name, review_remark, reviewed_at 实名审批字段)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS leave_request (
                leave_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                leave_type TEXT,
                start_date TEXT,
                end_date TEXT,
                reason TEXT,
                status TEXT DEFAULT 'Pending',
                reviewer_name TEXT DEFAULT '',
                review_remark TEXT DEFAULT '',
                reviewed_at TEXT DEFAULT ''
            )
        ''')
        cursor.execute("PRAGMA table_info(leave_request)")
        l_cols = [col[1] for col in cursor.fetchall()]
        if 'reviewer_name' not in l_cols:
            cursor.execute("ALTER TABLE leave_request ADD COLUMN reviewer_name TEXT DEFAULT ''")
        if 'review_remark' not in l_cols:
            cursor.execute("ALTER TABLE leave_request ADD COLUMN review_remark TEXT DEFAULT ''")
        if 'reviewed_at' not in l_cols:
            cursor.execute("ALTER TABLE leave_request ADD COLUMN reviewed_at TEXT DEFAULT ''")

        # 4. 新增：商业级费用报销表 (Expense Claims)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS expense_claims (
                claim_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                category TEXT,
                amount REAL,
                description TEXT,
                claim_date TEXT,
                status TEXT DEFAULT 'Pending',
                reviewer_name TEXT DEFAULT '',
                review_remark TEXT DEFAULT ''
            )
        ''')

        # 5. 新增：门店公告表 (Branch Announcements)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS announcements (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT,
                content TEXT,
                author TEXT,
                created_at TEXT
            )
        ''')
        cursor.execute('SELECT COUNT(*) FROM announcements')
        if cursor.fetchone()[0] == 0:
            cursor.execute('''
                INSERT INTO announcements (title, content, author, created_at)
                VALUES (?, ?, ?, ?)
            ''', (
                'Deepavali & Weekend Peak Shift Notice',
                'Double OT allowance applies for closing shifts this Friday & Saturday. Please clock in 10 mins early.',
                'Eugene Tang (Branch Manager)',
                '2026-11-01'
            ))

        conn.commit()

init_db()

# --- API 1: 登录 ---
@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username', '').strip().lower()
    password = data.get('password', '').strip()

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT staff_id, username, full_name, role_level, role_title, branch, basic_salary, custom_bonus, bank_info, epf_no
            FROM users WHERE LOWER(username) = ? AND password = ?
        ''', (username, password))
        user = cursor.fetchone()

    if user:
        return jsonify({
            "status": "success",
            "user": {
                "staff_id": user[0], "username": user[1], "full_name": user[2],
                "role_level": user[3], "role_title": user[4], "branch": user[5],
                "basic_salary": user[6], "custom_bonus": user[7],
                "bank_info": user[8], "epf_no": user[9]
            }
        }), 200
    return jsonify({"status": "error", "message": "Invalid username or password"}), 401

# --- API 2: 打卡状态 + 当月 KPI 统计 + 最新门店公告 ---
@app.route('/api/status', methods=['POST'])
def get_status():
    data = request.get_json() or {}
    staff_id = data.get('staff_id', 1)
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT event_type, event_time FROM attendance_events 
            WHERE staff_id = ? ORDER BY event_id DESC LIMIT 1
        ''', (staff_id,))
        last_event = cursor.fetchone()

        # 统计当月完成班次与累计工时
        cursor.execute("SELECT COUNT(*), COALESCE(SUM(shift_hours), 0) FROM attendance_events WHERE staff_id = ? AND event_type = 'OUT'", (staff_id,))
        shifts_done, total_hours = cursor.fetchone()

        # 获取最新一条门店公告
        cursor.execute('SELECT title, content, author, created_at FROM announcements ORDER BY id DESC LIMIT 1')
        ann = cursor.fetchone()

    est_ot = round(420.00 + (shifts_done * 25.00) + (total_hours * 10.0), 2)
    notice_data = {
        "title": ann[0] if ann else "Welcome to Haidilao Portal",
        "content": ann[1] if ann else "Please punch in on time.",
        "author": ann[2] if ann else "HR Admin",
        "date": ann[3] if ann else "2026-11-01"
    }

    return jsonify({
        "is_clocked_in": bool(last_event and last_event[0] == 'IN'),
        "clock_in_time": last_event[1] if (last_event and last_event[0] == 'IN') else "",
        "kpi": {
            "shifts": shifts_done,
            "hours": round(total_hours, 2),
            "est_ot": est_ot
        },
        "announcement": notice_data
    }), 200

# --- API 3 & 4: 一进一出打卡 ---
@app.route('/api/clock-in', methods=['POST'])
def clock_in():
    data = request.get_json() or {}
    staff_id = data.get('staff_id', 1)
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT event_type FROM attendance_events WHERE staff_id = ? ORDER BY event_id DESC LIMIT 1', (staff_id,))
        last = cursor.fetchone()
        if last and last[0] == 'IN':
            return jsonify({"status": "error", "message": "Already clocked in!"}), 400

        cursor.execute('''
            INSERT INTO attendance_events (staff_id, event_type, event_time, shift_hours, location)
            VALUES (?, 'IN', ?, 0.0, 'Sutera Biometric Gate A')
        ''', (staff_id, current_time))
        cursor.execute('INSERT INTO punch_card (staff_id, clock_in_time) VALUES (?, ?)', (staff_id, current_time))
        conn.commit()
    return jsonify({"status": "success", "type": "IN", "time": current_time}), 200

@app.route('/api/clock-out', methods=['POST'])
def clock_out():
    data = request.get_json() or {}
    staff_id = data.get('staff_id', 1)
    now = datetime.now()
    current_time = now.strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT event_type, event_time FROM attendance_events 
            WHERE staff_id = ? ORDER BY event_id DESC LIMIT 1
        ''', (staff_id,))
        last = cursor.fetchone()
        if not last or last[0] != 'IN':
            return jsonify({"status": "error", "message": "No active clock-in found."}), 400

        clock_in_dt = datetime.strptime(last[1], "%Y-%m-%d %H:%M:%S")
        diff_hours = max(round((now - clock_in_dt).total_seconds() / 3600, 2), 0.01)

        cursor.execute('''
            INSERT INTO attendance_events (staff_id, event_type, event_time, shift_hours, location)
            VALUES (?, 'OUT', ?, ?, 'Sutera Biometric Gate A')
        ''', (staff_id, current_time, diff_hours))
        cursor.execute('''
            UPDATE punch_card SET clock_out_time = ?, total_hours = ?
            WHERE record_id = (SELECT record_id FROM punch_card WHERE staff_id = ? AND clock_out_time IS NULL ORDER BY record_id DESC LIMIT 1)
        ''', (current_time, diff_hours, staff_id))
        conn.commit()

    return jsonify({"status": "success", "type": "OUT", "time": current_time, "total_hours": diff_hours}), 200

# --- API 5: 进出流水记录 ---
@app.route('/api/history', methods=['POST'])
def get_history():
    data = request.get_json() or {}
    staff_id = data.get('staff_id', 1)
    view_all = data.get('view_all', False)

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        if view_all:
            cursor.execute('''
                SELECT e.event_id, u.full_name, u.role_title, e.event_type, e.event_time, e.shift_hours, e.location
                FROM attendance_events e JOIN users u ON e.staff_id = u.staff_id
                ORDER BY e.event_id DESC LIMIT 40
            ''')
        else:
            cursor.execute('''
                SELECT e.event_id, u.full_name, u.role_title, e.event_type, e.event_time, e.shift_hours, e.location
                FROM attendance_events e JOIN users u ON e.staff_id = u.staff_id
                WHERE e.staff_id = ? ORDER BY e.event_id DESC LIMIT 30
            ''', (staff_id,))
        rows = cursor.fetchall()

    events = [{
        "event_id": r[0], "staff_name": r[1], "role_title": r[2],
        "type": r[3], "time": r[4], "hours": r[5], "location": r[6]
    } for r in rows]
    return jsonify({"status": "success", "data": events}), 200

# --- API 6: 请假提交、动态假期余额计算 & 实名理由审批 ---
@app.route('/api/leave', methods=['POST'])
def apply_leave():
    data = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO leave_request (staff_id, leave_type, start_date, end_date, reason, status) 
            VALUES (?, ?, ?, ?, ?, 'Pending')
        ''', (data.get('staff_id', 1), data['leave_type'], data['start_date'], data['end_date'], data.get('reason', '')))
        conn.commit()
    return jsonify({"status": "success"}), 200

@app.route('/api/leave-list', methods=['POST'])
def get_leave_list():
    data = request.get_json() or {}
    staff_id = data.get('staff_id', 1)
    view_all = data.get('view_all', False)

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        if view_all:
            cursor.execute('''
                SELECT l.leave_id, u.full_name, l.leave_type, l.start_date, l.end_date, l.reason, l.status,
                       l.reviewer_name, l.review_remark, l.reviewed_at
                FROM leave_request l JOIN users u ON l.staff_id = u.staff_id
                ORDER BY l.leave_id DESC
            ''')
        else:
            cursor.execute('''
                SELECT l.leave_id, u.full_name, l.leave_type, l.start_date, l.end_date, l.reason, l.status,
                       l.reviewer_name, l.review_remark, l.reviewed_at
                FROM leave_request l JOIN users u ON l.staff_id = u.staff_id
                WHERE l.staff_id = ? ORDER BY l.leave_id DESC
            ''', (staff_id,))
        rows = cursor.fetchall()

        # 动态计算该员工已批准的假期消耗天数 (AL, MC, HL)
        cursor.execute('''
            SELECT leave_type, start_date, end_date FROM leave_request
            WHERE staff_id = ? AND status = 'Approved'
        ''', (staff_id,))
        approved_rows = cursor.fetchall()

    used_al, used_mc, used_hl = 0, 0, 0
    for l_type, s_str, e_str in approved_rows:
        try:
            d1 = datetime.strptime(s_str, "%Y-%m-%d")
            d2 = datetime.strptime(e_str, "%Y-%m-%d")
            days = max((d2 - d1).days + 1, 1)
        except Exception:
            days = 1
        if l_type.startswith('AL'):
            used_al += days
        elif l_type.startswith('MC'):
            used_mc += days
        elif l_type.startswith('HL'):
            used_hl += days

    leave_list = [{
        "id": r[0], "staff_name": r[1], "type": r[2], "start": r[3], "end": r[4],
        "reason": r[5] or "Personal / Medical", "status": r[6],
        "reviewer_name": r[7] or "", "review_remark": r[8] or "", "reviewed_at": r[9] or ""
    } for r in rows]

    return jsonify({
        "status": "success",
        "data": leave_list,
        "quotas": {
            "al_left": max(12 - used_al, 0), "al_used": used_al,
            "mc_left": max(14 - used_mc, 0), "mc_used": used_mc,
            "hl_left": max(60 - used_hl, 0), "hl_used": used_hl
        }
    }), 200

@app.route('/api/leave-approve', methods=['POST'])
def approve_leave():
    data = request.get_json() or {}
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M")
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE leave_request 
            SET status = ?, reviewer_name = ?, review_remark = ?, reviewed_at = ?
            WHERE leave_id = ?
        ''', (
            data.get('status'),
            data.get('reviewer_name', 'Manager'),
            data.get('review_remark', ''),
            now_str,
            data.get('leave_id')
        ))
        conn.commit()
    return jsonify({"status": "success"}), 200

# --- API 7: 费用报销申领与实名审批 (Expense Claims) ---
@app.route('/api/claim-submit', methods=['POST'])
def submit_claim():
    data = request.get_json() or {}
    today = datetime.now().strftime("%Y-%m-%d")
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO expense_claims (staff_id, category, amount, description, claim_date, status)
            VALUES (?, ?, ?, ?, ?, 'Pending')
        ''', (data.get('staff_id', 1), data['category'], float(data['amount']), data.get('description', ''), today))
        conn.commit()
    return jsonify({"status": "success"}), 200

@app.route('/api/claim-list', methods=['POST'])
def get_claim_list():
    data = request.get_json() or {}
    staff_id = data.get('staff_id', 1)
    view_all = data.get('view_all', False)
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        if view_all:
            cursor.execute('''
                SELECT c.claim_id, u.full_name, c.category, c.amount, c.description, c.claim_date, c.status, c.reviewer_name, c.review_remark
                FROM expense_claims c JOIN users u ON c.staff_id = u.staff_id ORDER BY c.claim_id DESC
            ''')
        else:
            cursor.execute('''
                SELECT c.claim_id, u.full_name, c.category, c.amount, c.description, c.claim_date, c.status, c.reviewer_name, c.review_remark
                FROM expense_claims c JOIN users u ON c.staff_id = u.staff_id WHERE c.staff_id = ? ORDER BY c.claim_id DESC
            ''', (staff_id,))
        rows = cursor.fetchall()

    claims = [{
        "id": r[0], "staff_name": r[1], "category": r[2], "amount": r[3],
        "description": r[4] or "-", "date": r[5], "status": r[6],
        "reviewer_name": r[7] or "", "review_remark": r[8] or ""
    } for r in rows]
    return jsonify({"status": "success", "data": claims}), 200

@app.route('/api/claim-approve', methods=['POST'])
def approve_claim():
    data = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE expense_claims SET status = ?, reviewer_name = ?, review_remark = ?
            WHERE claim_id = ?
        ''', (data.get('status'), data.get('reviewer_name', 'Manager'), data.get('review_remark', ''), data.get('claim_id')))
        conn.commit()
    return jsonify({"status": "success"}), 200

# --- API 8: 门店公告发布接口 ---
@app.route('/api/announcement-post', methods=['POST'])
def post_announcement():
    data = request.get_json() or {}
    today = datetime.now().strftime("%Y-%m-%d")
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO announcements (title, content, author, created_at)
            VALUES (?, ?, ?, ?)
        ''', (data.get('title'), data.get('content'), data.get('author'), today))
        conn.commit()
    return jsonify({"status": "success"}), 200

# --- API 9: 16个月薪水单 (含已批准报销金额自动入账) ---
@app.route('/api/payslips-all', methods=['POST'])
def get_all_payslips():
    data = request.get_json() or {}
    staff_id = data.get('staff_id', 1)

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT full_name, basic_salary, custom_bonus FROM users WHERE staff_id = ?', (staff_id,))
        u = cursor.fetchone()
        staff_name = u[0] if u else "Ng Zhe Wei"
        base_pay = float(u[1]) if u else 2800.00
        custom_bonus = float(u[2]) if u else 150.00

        cursor.execute("SELECT COUNT(*), COALESCE(SUM(shift_hours), 0) FROM attendance_events WHERE staff_id = ? AND event_type = 'OUT'", (staff_id,))
        out_count, total_hrs = cursor.fetchone()

        # 汇总该员工所有已批准 (Approved) 的费用报销总额，直接加进当月工资单！
        cursor.execute("SELECT COALESCE(SUM(amount), 0) FROM expense_claims WHERE staff_id = ? AND status = 'Approved'", (staff_id,))
        approved_claims_total = round(float(cursor.fetchone()[0]), 2)

    live_ot = round(420.00 + (out_count * 25.00) + (total_hrs * 10.0), 2)
    commission = 380.00

    def make_slip(month, num, date_str, basic, ot, comm, bonus, claims=0.0, status="Paid"):
        e = round(basic * 0.11, 2)
        s = 19.75
        ei = 4.50
        net = round(basic + ot + comm + bonus + claims - e - s - ei, 2)
        return {
            "staff_name": staff_name, "month": month, "month_num": num, "status": status, "pay_date": date_str,
            "basic_salary": basic, "ot_pay": ot, "commission": comm, "attendance_bonus": bonus,
            "claims_reimbursement": claims,
            "epf": e, "socso": s, "eis": ei, "net_pay": net
        }

    payslip_db = {
        "2026": [
            make_slip("October", "10", "2026-10-31", base_pay, live_ot, commission, custom_bonus, approved_claims_total, "Live Sync"),
            make_slip("September", "09", "2026-09-30", base_pay, 320.00, 410.00, 150.00),
            make_slip("August", "08", "2026-08-31", base_pay, 510.00, 520.00, 150.00),
            make_slip("July", "07", "2026-07-31", base_pay, 280.00, 390.00, 150.00),
            make_slip("June", "06", "2026-06-30", base_pay, 400.00, 460.00, 150.00),
            make_slip("May", "05", "2026-05-31", base_pay, 490.00, 480.00, 150.00),
            make_slip("April", "04", "2026-04-30", base_pay, 180.00, 340.00, 0.00),
            make_slip("March", "03", "2026-03-31", base_pay, 350.00, 420.00, 150.00),
            make_slip("February", "02", "2026-02-28", base_pay, 780.00, 750.00, 150.00),
            make_slip("January", "01", "2026-01-31", base_pay, 410.00, 440.00, 150.00),
        ],
        "2025": [
            make_slip("December", "12", "2025-12-31", base_pay - 200, 600.00, 800.00, 150.00),
            make_slip("November", "11", "2025-11-30", base_pay - 200, 250.00, 350.00, 150.00),
            make_slip("October", "10", "2025-10-31", base_pay - 200, 310.00, 390.00, 150.00),
            make_slip("September", "09", "2025-09-30", base_pay - 200, 290.00, 360.00, 150.00),
            make_slip("August", "08", "2025-08-31", base_pay - 200, 420.00, 450.00, 150.00),
            make_slip("July", "07", "2025-07-31", base_pay - 200, 200.00, 310.00, 150.00),
        ]
    }
    return jsonify({"status": "success", "data": payslip_db}), 200

# --- API 10: L3 HR 总监调薪接口 ---
@app.route('/api/users', methods=['POST'])
def get_all_users():
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT staff_id, username, full_name, role_level, role_title, branch, basic_salary, custom_bonus FROM users ORDER BY staff_id')
        rows = cursor.fetchall()
    users = [{
        "staff_id": r[0], "username": r[1], "full_name": r[2], "role_level": r[3],
        "role_title": r[4], "branch": r[5], "basic_salary": r[6], "custom_bonus": r[7]
    } for r in rows]
    return jsonify({"status": "success", "data": users}), 200

@app.route('/api/update-salary', methods=['POST'])
def update_salary():
    data = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE users SET basic_salary = ?, custom_bonus = ?, role_level = ?, role_title = ?
            WHERE staff_id = ?
        ''', (float(data['basic_salary']), float(data['custom_bonus']), int(data['role_level']), data['role_title'], int(data['staff_id'])))
        conn.commit()
    return jsonify({"status": "success"}), 200

if __name__ == '__main__':
    app.run(debug=True)