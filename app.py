from flask import Flask, request, jsonify
import sqlite3
from datetime import datetime

app = Flask(__name__)

# 初始化数据库（员工表和打卡表）
def init_db():
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS punch_card (
                record_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER NOT NULL,
                clock_in_time TEXT NOT NULL,
                clock_out_time TEXT
            )
        ''')
        conn.commit()

# 上班打卡 API 接口
@app.route('/api/clock-in', methods=['POST'])
def clock_in():
    data = request.get_json()
    staff_id = data.get('staff_id')
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO punch_card (staff_id, clock_in_time) VALUES (?, ?)", (staff_id, current_time))
        conn.commit()
        
    return jsonify({
        "status": "success", 
        "message": f"Staff {staff_id} clocked in successfully!", 
        "time": current_time
    }), 200
    
# 下班打卡 API 接口
@app.route('/api/clock-out', methods=['POST'])
def clock_out():
    data = request.get_json()
    staff_id = data.get('staff_id')
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        # 寻找该员工最新一条还没有下班时间的记录，并填入现在的下班时间
        cursor.execute('''
            UPDATE punch_card 
            SET clock_out_time = ? 
            WHERE record_id = (
                SELECT record_id FROM punch_card 
                WHERE staff_id = ? AND clock_out_time IS NULL 
                ORDER BY record_id DESC LIMIT 1
            )
        ''', (current_time, staff_id))
        conn.commit()
        
    # 为了演示，我们暂时直接返回 9 个小时，下周可以加入真实的时间差计算逻辑
    return jsonify({
        "status": "success", 
        "message": f"Staff {staff_id} clocked out successfully!", 
        "time": current_time,
        "total_hours": 9 
    }), 200

if __name__ == '__main__':
    init_db()
    print("🚀 F&B Backend API is running on port 5000...")
    app.run(debug=True, port=5000)