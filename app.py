# cSpell:disable
from flask import Flask, request, jsonify, render_template_string  # type: ignore
import sqlite3
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP

app = Flask(__name__)

@app.after_request
def add_no_cache_headers(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

def ensure_column(cursor, table, col_name, col_type):
    cursor.execute(f"PRAGMA table_info({table})")
    cols = [c[1] for c in cursor.fetchall()]
    if col_name not in cols:
        cursor.execute(f"ALTER TABLE {table} ADD COLUMN {col_name} {col_type}")

def init_db():
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()

        # 1. 员工档案表
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
                epf_no TEXT,
                ic_no TEXT DEFAULT '030618-01-8821',
                socso_no TEXT DEFAULT 'PERKESO-030618018821',
                eis_no TEXT DEFAULT 'SIP-882103',
                tax_no TEXT DEFAULT 'SG-29481029-00',
                phone TEXT DEFAULT '+60 12-789 4512',
                join_date TEXT DEFAULT '2025-06-15',
                department TEXT DEFAULT 'Frontline Service & Operations',
                emergency_contact TEXT DEFAULT 'Mdm Lim (+60 16-712 9901)',
                assigned_manager TEXT DEFAULT 'Eugene Tang (Sutera Manager)'
            )
        ''')
        ensure_column(cursor, 'users', 'ic_no', "TEXT DEFAULT '030618-01-8821'")
        ensure_column(cursor, 'users', 'socso_no', "TEXT DEFAULT 'PERKESO-030618018821'")
        ensure_column(cursor, 'users', 'eis_no', "TEXT DEFAULT 'SIP-882103'")
        ensure_column(cursor, 'users', 'tax_no', "TEXT DEFAULT 'SG-29481029-00'")
        ensure_column(cursor, 'users', 'phone', "TEXT DEFAULT '+60 12-789 4512'")
        ensure_column(cursor, 'users', 'join_date', "TEXT DEFAULT '2025-06-15'")
        ensure_column(cursor, 'users', 'department', "TEXT DEFAULT 'Frontline Service & Operations'")
        ensure_column(cursor, 'users', 'emergency_contact', "TEXT DEFAULT 'Mdm Lim (+60 16-712 9901)'")
        ensure_column(cursor, 'users', 'assigned_manager', "TEXT DEFAULT 'Eugene Tang (Sutera Manager)'")

        cursor.execute('SELECT COUNT(*) FROM users')
        if cursor.fetchone()[0] == 0:
            default_users = [
                ('staff', '1234', 'Ng Zhe Wei', 1, 'Service Crew (L1)', 'Sutera Utama Outlet', 2800.00, 150.00,
                 'Public Bank Berhad (4829108821)', 'KWSP-99482104', '030618-01-8821', 'PERKESO-03061801', 'SIP-994821', 'SG-10293847-01',
                 '+60 12-789 4512', '2025-06-01', 'Table Service & Customer Care', 'Mr. Ng (+60 19-778 2210)', 'Eugene Tang (Sutera Outlet Manager)'),
                ('manager', '1234', 'Eugene Tang', 2, 'Branch Manager (L2)', 'Sutera Utama Outlet', 4800.00, 500.00,
                 'Maybank Berhad (5123443319)', 'KWSP-88120391', '950412-01-3319', 'PERKESO-95041201', 'SIP-881203', 'SG-55482910-02',
                 '+60 17-721 9088', '2022-03-10', 'Outlet Management', 'Mrs. Tang (+60 12-334 1190)', 'See Lin (HR Director)'),
                ('admin', '1234', 'See Lin', 3, 'HR Director (L3)', 'Johor Bahru HQ', 7500.00, 1000.00,
                 'CIMB Bank Berhad (7099881029)', 'KWSP-77219002', '900921-01-1029', 'PERKESO-90092101', 'SIP-772190', 'SG-99812034-09',
                 '+60 11-2890 3312', '2020-01-15', 'Human Resources & Payroll HQ', 'Mr. See (+60 12-701 8899)', 'Board of Directors'),
                ('austin', '1234', 'Tan Mei Ling', 1, 'Senior Server (L1)', 'Mount Austin Outlet', 3000.00, 200.00,
                 'Hong Leong Bank (2910384412)', 'KWSP-66512098', '021104-01-5512', 'PERKESO-02110401', 'SIP-665120', 'SG-33910284-05',
                 '+60 16-745 9921', '2025-02-10', 'VIP Room Service', 'Mdm Tan (+60 14-990 1123)', 'Kelvin Lim (Mount Austin Manager)')
            ]
            cursor.executemany('''
                INSERT INTO users (username, password, full_name, role_level, role_title, branch, basic_salary, custom_bonus,
                bank_info, epf_no, ic_no, socso_no, eis_no, tax_no, phone, join_date, department, emergency_contact, assigned_manager)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', default_users)

        # 2. 考勤流水表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS attendance_events (
                event_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                event_type TEXT,
                event_time TEXT,
                shift_hours REAL DEFAULT 0.0,
                location TEXT DEFAULT 'Sutera Outlet Gate A',
                branch TEXT DEFAULT 'Sutera Utama Outlet',
                gps_coords TEXT DEFAULT '1.5152° N, 103.6660° E',
                distance_m INTEGER DEFAULT 14,
                selfie_tag TEXT DEFAULT 'SELFIE-CAM-VERIFIED',
                verify_status TEXT DEFAULT 'GPS & Face Verified'
            )
        ''')
        ensure_column(cursor, 'attendance_events', 'branch', "TEXT DEFAULT 'Sutera Utama Outlet'")
        ensure_column(cursor, 'attendance_events', 'gps_coords', "TEXT DEFAULT '1.5152° N, 103.6660° E'")
        ensure_column(cursor, 'attendance_events', 'distance_m', "INTEGER DEFAULT 14")
        ensure_column(cursor, 'attendance_events', 'selfie_tag', "TEXT DEFAULT 'SELFIE-CAM-VERIFIED'")
        ensure_column(cursor, 'attendance_events', 'verify_status', "TEXT DEFAULT 'GPS & Face Verified'")

        cursor.execute('SELECT COUNT(*) FROM attendance_events')
        if cursor.fetchone()[0] == 0:
            demo_events = [
                (1, 'IN', '2026-11-04 09:56:12', 0.0, 'Sutera Mall Outlet (Main Entrance)', 'Sutera Utama Outlet', '1.5152° N, 103.6660° E', 12, 'IMG_ZW_20261104_IN.jpg', 'On-Time • GPS & Face OK'),
                (1, 'OUT', '2026-11-04 19:03:45', 9.12, 'Sutera Mall Outlet (Main Entrance)', 'Sutera Utama Outlet', '1.5152° N, 103.6661° E', 15, 'IMG_ZW_20261104_OUT.jpg', 'Shift Completed • Verified'),
                (4, 'IN', '2026-11-05 10:02:18', 0.0, 'Mount Austin Outlet (VIP Lobby)', 'Mount Austin Outlet', '1.5641° N, 103.7782° E', 22, 'IMG_ML_20261105_IN.jpg', 'On-Time • GPS & Face OK'),
                (4, 'OUT', '2026-11-05 19:15:09', 9.21, 'Mount Austin Outlet (VIP Lobby)', 'Mount Austin Outlet', '1.5641° N, 103.7780° E', 19, 'IMG_ML_20261105_OUT.jpg', 'Shift Completed • Verified'),
                (1, 'IN', '2026-11-05 13:52:04', 0.0, 'Sutera Mall Outlet (Main Entrance)', 'Sutera Utama Outlet', '1.5153° N, 103.6660° E', 11, 'IMG_ZW_20261105_IN.jpg', 'On-Time • GPS & Face OK'),
                (1, 'OUT', '2026-11-05 23:10:19', 9.30, 'Sutera Mall Outlet (Main Entrance)', 'Sutera Utama Outlet', '1.5152° N, 103.6660° E', 14, 'IMG_ZW_20261105_OUT.jpg', 'Closing Shift • Verified'),
                (2, 'IN', '2026-11-06 09:45:00', 0.0, 'Sutera Mall Outlet (Manager Office)', 'Sutera Utama Outlet', '1.5152° N, 103.6660° E', 8, 'IMG_ET_20261106_IN.jpg', 'Manager Duty • Verified')
            ]
            cursor.executemany('''
                INSERT INTO attendance_events (staff_id, event_type, event_time, shift_hours, location, branch, gps_coords, distance_m, selfie_tag, verify_status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', demo_events)

        # 3. 请假审批流程表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS leave_request (
                leave_id INTEGER PRIMARY KEY AUTOINCREMENT,
                staff_id INTEGER,
                branch TEXT DEFAULT 'Sutera Utama Outlet',
                assigned_manager TEXT DEFAULT 'Eugene Tang (Sutera Manager)',
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
        ensure_column(cursor, 'leave_request', 'branch', "TEXT DEFAULT 'Sutera Utama Outlet'")
        ensure_column(cursor, 'leave_request', 'assigned_manager', "TEXT DEFAULT 'Eugene Tang (Sutera Manager)'")
        ensure_column(cursor, 'leave_request', 'reviewer_name', "TEXT DEFAULT ''")
        ensure_column(cursor, 'leave_request', 'review_remark', "TEXT DEFAULT ''")
        ensure_column(cursor, 'leave_request', 'reviewed_at', "TEXT DEFAULT ''")

        cursor.execute('SELECT COUNT(*) FROM leave_request')
        if cursor.fetchone()[0] == 0:
            demo_leaves = [
                (1, 'Sutera Utama Outlet', 'Eugene Tang (Sutera Outlet Manager)', 'AL (Annual Leave)', '2026-11-12', '2026-11-13',
                 'Family wedding dinner in Johor Bahru', 'Approved', 'Eugene Tang (Branch Manager (L2))', 'Approved. Roster covered by part-time crew.', '2026-11-02 14:20'),
                (4, 'Mount Austin Outlet', 'Kelvin Lim (Mount Austin Manager)', 'MC (Medical Leave)', '2026-11-03', '2026-11-03',
                 'Acute fever and clinic visit (Klinik Johor)', 'Approved', 'Kelvin Lim (Mount Austin Manager (L2))', 'MC certificate verified and archived.', '2026-11-03 09:15'),
                (1, 'Sutera Utama Outlet', 'Eugene Tang (Sutera Outlet Manager)', 'UP (Unpaid Leave)', '2026-11-20', '2026-11-22',
                 'Weekend personal trip', 'Rejected', 'Eugene Tang (Branch Manager (L2))', 'Rejected due to weekend peak dining reservation surge.', '2026-11-04 16:45')
            ]
            cursor.executemany('''
                INSERT INTO leave_request (staff_id, branch, assigned_manager, leave_type, start_date, end_date, reason, status, reviewer_name, review_remark, reviewed_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', demo_leaves)

        # 4. 费用报销表
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

        # 5. 门店公告表
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
            ''', ('GPS & Biometric Selfie Policy', 'All staff must capture a live selfie within 50m of the outlet GPS geofence during Clock-In and Clock-Out.', 'See Lin (HR Director)', '2026-11-01'))

        # 6. 岗位抽成/计件标准表
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS commission_rates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                role_title TEXT NOT NULL UNIQUE,
                rate_type TEXT NOT NULL,
                rate_value REAL NOT NULL
            )
        ''')
        cursor.execute('SELECT COUNT(*) FROM commission_rates')
        if cursor.fetchone()[0] == 0:
            demo_rates = [
                ('Service Crew (L1)', 'percentage', 0.02),
                ('Senior Server (L1)', 'percentage', 0.03),
                ('Kitchen (L1)', 'fixed', 0.50),
                ('Branch Manager (L2)', 'percentage', 0.05),
                ('HR Director (L3)', 'fixed', 0.00)
            ]
            cursor.executemany('''
                INSERT INTO commission_rates (role_title, rate_type, rate_value)
                VALUES (?, ?, ?)
            ''', demo_rates)

        # 7. 客人会员账号表 (支持邮箱或手机号登入)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS customers (
                customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
                contact TEXT UNIQUE NOT NULL,
                display_name TEXT NOT NULL,
                points INTEGER DEFAULT 100,
                created_at TEXT NOT NULL
            )
        ''')

        # 8. POS 商业菜单表 (含高清菜品图片 URL)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS menu_items (
                item_id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                category TEXT NOT NULL,
                price REAL NOT NULL,
                description TEXT DEFAULT '',
                image_url TEXT DEFAULT '',
                is_available INTEGER DEFAULT 1
            )
        ''')
        ensure_column(cursor, 'menu_items', 'image_url', "TEXT DEFAULT ''")

        cursor.execute('SELECT COUNT(*) FROM menu_items')
        if cursor.fetchone()[0] == 0:
            default_menu = [
                ('Signature Mala Soup Base (招牌麻辣锅底)', 'Soup Base', 38.00, 'Authentic Sichuan peppercorn & chili oil broth',
                 'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=600&q=80', 1),
                ('Classic Tomato Soup Base (浓香番茄锅底)', 'Soup Base', 34.00, 'Slow-simmered fresh vine-ripened tomato broth',
                 'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=600&q=80', 1),
                ('Wild Mushroom & Bone Soup (养生菌汤锅底)', 'Soup Base', 32.00, 'Savory herbal pork bone & wild mushroom broth',
                 'https://images.unsplash.com/photo-1603105037880-880cd4edfb0d?auto=format&fit=crop&w=600&q=80', 1),
                ('Collagen Beauty Pork Soup (胶原猪肚鸡锅)', 'Soup Base', 40.00, 'Rich white pepper & slow-boiled collagen broth',
                 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=600&q=80', 1),
                ('US Sliced Fatty Beef (顶级雪花肥牛)', 'Meat & Seafood', 42.00, 'Premium marbled beef slices (200g)',
                 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&w=600&q=80', 1),
                ('Australian Lamb Roll (澳洲精品羊肉卷)', 'Meat & Seafood', 39.00, 'Tender pasture-raised lamb slices',
                 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=600&q=80', 1),
                ('Signature Tiger Prawn Paste (手打鲜虾滑)', 'Meat & Seafood', 36.00, 'Hand-minced 95% fresh tiger prawn paste',
                 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?auto=format&fit=crop&w=600&q=80', 1),
                ('Iberico Pork Collar (西班牙黑猪肉片)', 'Meat & Seafood', 45.00, 'Juicy sliced Spanish Iberico pork',
                 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?auto=format&fit=crop&w=600&q=80', 1),
                ('Handmade Pulled Noodles (手工扯面)', 'Veggies & Noodles', 12.00, 'Fresh chewy hand-pulled noodles',
                 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80', 1),
                ('Fresh Assorted Veggie Platter (田园蔬菜拼盘)', 'Veggies & Noodles', 18.00, 'Lotus root, baby romaine, corn & tofu skin',
                 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80', 1),
                ('Golden Enoki & Mushroom Duo (菌菇双拼)', 'Veggies & Noodles', 15.00, 'Organic enoki & king oyster mushroom',
                 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=600&q=80', 1),
                ('Chilled Sour Plum Juice (冰镇酸梅汤)', 'Drinks', 9.50, 'Refreshing sweet & tangy house-brewed plum drink',
                 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80', 1),
                ('Iced Lemon Winter Melon Tea (冻柠冬瓜茶)', 'Drinks', 8.50, 'Cooling traditional winter melon brew with lemon',
                 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=600&q=80', 1)
            ]
            cursor.executemany('''
                INSERT INTO menu_items (name, category, price, description, image_url, is_available)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', default_menu)

        # 9. POS 订单主表与明细表 (关联客人账号与服务员计件)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS orders (
                order_id INTEGER PRIMARY KEY AUTOINCREMENT,
                table_no TEXT NOT NULL,
                served_by_staff_id INTEGER NOT NULL,
                customer_contact TEXT DEFAULT 'Walk-in Guest',
                subtotal REAL NOT NULL,
                service_charge REAL NOT NULL,
                sst_tax REAL NOT NULL,
                grand_total REAL NOT NULL,
                remarks TEXT DEFAULT '',
                status TEXT DEFAULT 'Pending',
                created_at TEXT NOT NULL
            )
        ''')
        ensure_column(cursor, 'orders', 'customer_contact', "TEXT DEFAULT 'Walk-in Guest'")

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS order_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                order_id INTEGER NOT NULL,
                item_id INTEGER NOT NULL,
                item_name TEXT NOT NULL,
                qty INTEGER NOT NULL,
                unit_price REAL NOT NULL,
                line_total REAL NOT NULL,
                FOREIGN KEY (order_id) REFERENCES orders(order_id)
            )
        ''')

        conn.commit()

init_db()

def get_user_dict(row):
    return {
        "staff_id": row[0], "username": row[1], "full_name": row[2],
        "role_level": row[3], "role_title": row[4], "branch": row[5],
        "basic_salary": row[6], "custom_bonus": row[7], "bank_info": row[8],
        "epf_no": row[9], "ic_no": row[10], "socso_no": row[11],
        "eis_no": row[12], "tax_no": row[13], "phone": row[14],
        "join_date": row[15], "department": row[16],
        "emergency_contact": row[17], "assigned_manager": row[18]
    }

# ==========================================================
# 商业化独立客人点餐前端 (http://127.0.0.1:5000/order)
# 功能：邮箱/电话登入 + 高清菜品图片 + 先点锅底校验 + 点过一轮汤底再询问 + 实时查单
# ==========================================================
CUSTOMER_ORDER_HTML = r'''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>SmarterPot • 商业火锅自助点餐系统</title>
  <style>
    * { box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Microsoft YaHei", sans-serif; }
    body { margin: 0; background: #f4f5f8; color: #161925; }

    /* 顶部商业导航 */
    header {
      background: linear-gradient(135deg, #161925 0%, #5a1212 55%, #b71c1c 100%);
      color: #fff; padding: 14px 24px; display: flex; justify-content: space-between; align-items: center;
      position: sticky; top: 0; z-index: 50; box-shadow: 0 4px 16px rgba(0,0,0,0.18);
    }
    .brand h1 { margin: 0; font-size: 20px; font-weight: 900; letter-spacing: 0.6px; }
    .brand small { opacity: 0.85; font-size: 11px; }
    .header-actions { display: flex; align-items: center; gap: 10px; }
    .pill-btn {
      background: rgba(255,255,255,0.16); color: #fff; border: 1px solid rgba(255,255,255,0.28);
      padding: 7px 14px; border-radius: 20px; font-size: 12px; font-weight: 700; cursor: pointer;
    }
    .pill-btn:hover { background: rgba(255,255,255,0.28); }
    .user-chip { background: rgba(255, 215, 64, 0.2); border: 1px solid #ffd740; color: #ffd740; padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 700; }

    /* 主体双栏 */
    .container { display: flex; gap: 20px; max-width: 1340px; margin: 20px auto; padding: 0 16px 40px; align-items: flex-start; }
    .menu-col { flex: 2.2; }
    .cart-col {
      flex: 1; background: #fff; border-radius: 18px; padding: 18px;
      box-shadow: 0 8px 24px rgba(0,0,0,0.07); position: sticky; top: 82px;
    }

    /* 锅底引导横幅 */
    .soup-banner {
      background: linear-gradient(90deg, #fff3e0, #ffebee);
      border: 1px solid #ffcdd2; border-radius: 14px; padding: 12px 16px; margin-bottom: 14px;
      display: flex; justify-content: space-between; align-items: center; font-size: 13px; font-weight: 700; color: #b71c1c;
    }
    .soup-badge { background: #b71c1c; color: #fff; padding: 3px 10px; border-radius: 12px; font-size: 11px; }

    /* 分类栏 */
    .cats { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 16px; }
    .cat-btn {
      border: 1px solid #e0e3eb; padding: 9px 16px; border-radius: 22px; background: #fff;
      font-weight: 700; font-size: 13px; cursor: pointer; transition: 0.2s; color: #333;
    }
    .cat-btn.active { background: #b71c1c; color: #fff; border-color: #b71c1c; box-shadow: 0 4px 10px rgba(183,28,28,0.3); }

    /* 商业菜品卡片网格 */
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(235px, 1fr)); gap: 16px; }
    .card {
      background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 14px rgba(0,0,0,0.06);
      display: flex; flex-direction: column; border: 2px solid transparent; transition: transform 0.15s;
    }
    .card:hover { transform: translateY(-2px); }
    .card.in-cart { border-color: #b71c1c; }
    .card-img-wrap { position: relative; height: 150px; background: #222; overflow: hidden; }
    .card-img-wrap img { width: 100%; height: 100%; object-fit: cover; display: block; }
    .qty-ribbon {
      position: absolute; top: 10px; right: 10px; background: #b71c1c; color: #fff;
      font-weight: 900; font-size: 12px; padding: 4px 10px; border-radius: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    }
    .cat-tag {
      position: absolute; bottom: 8px; left: 10px; background: rgba(20,24,36,0.78); color: #fff;
      font-size: 10px; font-weight: 700; padding: 3px 8px; border-radius: 6px;
    }
    .card-body { padding: 12px 14px 14px; display: flex; flex-direction: column; flex: 1; justify-content: space-between; }
    .card-body h3 { margin: 0 0 4px; font-size: 14px; font-weight: 800; line-height: 1.3; }
    .card-body p { margin: 0 0 12px; font-size: 11.5px; color: #6b7280; line-height: 1.4; }
    .card-foot { display: flex; justify-content: space-between; align-items: center; }
    .price { font-weight: 900; color: #1b5e20; font-size: 16px; }
    .add-btn {
      background: #b71c1c; color: #fff; border: none; padding: 7px 14px; border-radius: 10px;
      font-weight: 800; font-size: 12px; cursor: pointer;
    }
    .add-btn:hover { background: #961616; }

    /* 购物车 */
    .field { margin-bottom: 10px; }
    .field label { display: block; font-size: 11.5px; font-weight: 700; margin-bottom: 4px; color: #4b5563; }
    .field select, .field input { width: 100%; padding: 9px 10px; border-radius: 10px; border: 1px solid #d1d5db; font-size: 13px; }
    .cart-list { max-height: 250px; overflow-y: auto; margin: 12px 0; border-top: 1px solid #eee; border-bottom: 1px solid #eee; padding: 8px 0; }
    .cart-item { display: flex; justify-content: space-between; align-items: center; padding: 7px 0; font-size: 13px; border-bottom: 1px dashed #f0f0f0; }
    .qty-ctrl button { width: 26px; height: 26px; border-radius: 50%; border: 1px solid #ccc; background: #fff; cursor: pointer; font-weight: 900; }
    .bill-row { display: flex; justify-content: space-between; font-size: 12.5px; margin: 4px 0; color: #555; }
    .bill-total { display: flex; justify-content: space-between; font-size: 18px; font-weight: 900; color: #b71c1c; margin: 10px 0 14px; }
    .submit-btn { width: 100%; padding: 13px; border: none; border-radius: 12px; background: #b71c1c; color: #fff; font-weight: 900; font-size: 14px; cursor: pointer; }
    .submit-btn:disabled { background: #cbd5e1; cursor: not-allowed; }
    .toast { display: none; background: #1b5e20; color: #fff; padding: 12px 14px; border-radius: 10px; margin-top: 12px; font-size: 12.5px; font-weight: 700; }

    /* 弹窗通用样式 */
    .modal-backdrop {
      position: fixed; inset: 0; background: rgba(15, 18, 28, 0.68); backdrop-filter: blur(4px);
      display: none; align-items: center; justify-content: center; z-index: 100; padding: 16px;
    }
    .modal-backdrop.show { display: flex; }
    .modal-box {
      background: #fff; width: 100%; max-width: 420px; border-radius: 20px; padding: 24px;
      box-shadow: 0 20px 50px rgba(0,0,0,0.3); text-align: center;
    }
    .modal-box h2 { margin: 0 0 8px; font-size: 19px; font-weight: 900; color: #161925; }
    .modal-box p { margin: 0 0 18px; font-size: 13.5px; color: #4b5563; line-height: 1.5; }
    .modal-btns { display: flex; gap: 10px; margin-top: 14px; }
    .btn-primary { flex: 1; padding: 12px; border: none; border-radius: 12px; background: #b71c1c; color: #fff; font-weight: 800; cursor: pointer; font-size: 13px; }
    .btn-secondary { flex: 1; padding: 12px; border: 1px solid #d1d5db; border-radius: 12px; background: #f8fafc; color: #334155; font-weight: 800; cursor: pointer; font-size: 13px; }
    .order-history-item { text-align: left; border: 1px solid #e5e7eb; border-radius: 12px; padding: 12px; margin-bottom: 10px; font-size: 12.5px; }

    @media (max-width: 860px) { .container { flex-direction: column; } .cart-col { width: 100%; position: static; } }
  </style>
</head>
<body>

  <!-- 1. 客人账号登录弹窗 (邮箱或手机号) -->
  <div class="modal-backdrop show" id="loginModal">
    <div class="modal-box">
      <div style="font-size:38px; margin-bottom:6px;">🍲</div>
      <h2>欢迎光临 SmarterPot 火锅</h2>
      <p>请输入您的<b>手机号或电子邮箱</b>登录会员账号，即可开始点餐并实时追踪上菜进度。</p>
      <div class="field" style="text-align:left;">
        <label>手机号或邮箱 (Phone / Email) *</label>
        <input type="text" id="loginContact" placeholder="例如: 012-7894512 或 customer@gmail.com" />
      </div>
      <div class="field" style="text-align:left;">
        <label>称呼 (可选 / Optional Name)</label>
        <input type="text" id="loginName" placeholder="例如: Alex / 陈先生" />
      </div>
      <div id="loginErr" style="color:#b71c1c; font-size:12px; font-weight:700; margin-bottom:8px; display:none;"></div>
      <div class="modal-btns">
        <button class="btn-primary" onclick="customerLogin()">立即登录并点餐</button>
      </div>
    </div>
  </div>

  <!-- 2. 未点锅底强提示弹窗 -->
  <div class="modal-backdrop" id="soupSkipModal">
    <div class="modal-box">
      <div style="font-size:38px; margin-bottom:6px;">🔥</div>
      <h2>您还没选择锅底哦！</h2>
      <p>火锅通常需要先上锅底开煮。您确定要<b>跳过锅底</b>，直接先看配菜吗？</p>
      <div class="modal-btns">
        <button class="btn-primary" onclick="stayForSoup()">回去选锅底</button>
        <button class="btn-secondary" onclick="confirmSkipSoup()">执意跳过</button>
      </div>
    </div>
  </div>

  <!-- 3. 点完一轮锅底后询问是否再点弹窗 -->
  <div class="modal-backdrop" id="soupAgainModal">
    <div class="modal-box">
      <div style="font-size:38px; margin-bottom:6px;">🥘</div>
      <h2>已为您加入一轮锅底！</h2>
      <p id="soupAgainText">是否还需要<b>再点一个锅底</b>（例如拼双拼/鸳鸯锅），还是直接去选肉类和配菜？</p>
      <div class="modal-btns">
        <button class="btn-secondary" onclick="orderMoreSoup()">再点一个锅底</button>
        <button class="btn-primary" onclick="goOrderDishes()">去点肉类配菜</button>
      </div>
    </div>
  </div>

  <!-- 4. 客人我的订单实时追踪弹窗 -->
  <div class="modal-backdrop" id="myOrdersModal">
    <div class="modal-box" style="max-width:520px;">
      <h2>我的订单与厨房实时进度</h2>
      <p style="margin-bottom:12px;">后台员工端接单后，这里会实时显示 Cooking / Served / Paid 状态。</p>
      <div id="myOrdersList" style="max-height:340px; overflow-y:auto;">加载中...</div>
      <div class="modal-btns">
        <button class="btn-secondary" onclick="loadMyOrders()">刷新状态</button>
        <button class="btn-primary" onclick="closeModal('myOrdersModal')">关闭</button>
      </div>
    </div>
  </div>

  <header>
    <div class="brand">
      <h1>SMARTERPOT • 商业自助点餐系统</h1>
      <small>先选锅底 • 高清图文菜单 • 实时直连员工 ERP 后台</small>
    </div>
    <div class="header-actions">
      <span class="user-chip" id="userBadge">未登录</span>
      <button class="pill-btn" onclick="openMyOrders()">我的订单</button>
      <button class="pill-btn" onclick="openModal('loginModal')">切换账号</button>
    </div>
  </header>

  <div class="container">
    <div class="menu-col">
      <div class="soup-banner" id="soupBanner">
        <span>🍲 第一步：请先挑选您喜欢的火锅汤底，开锅后更入味！</span>
        <span class="soup-badge" id="soupStatusBadge">尚未选锅底</span>
      </div>
      <div class="cats" id="catBar"></div>
      <div class="grid" id="menuGrid">正在加载商业菜单...</div>
    </div>

    <div class="cart-col">
      <h2 style="margin:0 0 12px; font-size:16px; font-weight:900;">🛒 当前桌台购物车</h2>
      <div class="field">
        <label>选择桌号 (Table Number)</label>
        <select id="tableNo">
          <option>Table A01</option><option>Table A02</option><option>Table A03</option>
          <option>Table B01</option><option>Table B02</option><option>VIP Room 1</option><option>VIP Room 2</option>
        </select>
      </div>
      <div class="field">
        <label>服务员归属 (自动关联员工计件/抽成)</label>
        <select id="staffId">
          <option value="1">Ng Zhe Wei (Sutera Utama Outlet)</option>
          <option value="4">Tan Mei Ling (Mount Austin Outlet)</option>
          <option value="2">Eugene Tang (Outlet Manager)</option>
        </select>
      </div>
      <div class="cart-list" id="cartList"><div style="color:#9ca3af; text-align:center; padding:18px;">请先选择锅底或菜品</div></div>
      <div class="field">
        <label>口味备注 (Kitchen Remarks)</label>
        <input type="text" id="remarks" placeholder="例如：少辣、不要香菜、先上锅底" />
      </div>
      <div class="bill-row"><span>菜品小计 (Subtotal)</span><span id="subtotal">RM 0.00</span></div>
      <div class="bill-row"><span>服务费 (Service Charge 10%)</span><span id="svc">RM 0.00</span></div>
      <div class="bill-row"><span>消费税 (SST 6%)</span><span id="sst">RM 0.00</span></div>
      <div class="bill-total"><span>应付总额</span><span id="grand">RM 0.00</span></div>
      <button class="submit-btn" id="submitBtn" disabled onclick="placeOrder()">确认下单 (直连后厨)</button>
      <div class="toast" id="toast"></div>
    </div>
  </div>

  <script>
    let menuItems = [];
    let categories = ['Soup Base', 'Meat & Seafood', 'Veggies & Noodles', 'Drinks', 'All'];
    let selectedCat = 'Soup Base'; // 火锅店默认先上汤底
    let pendingTargetCat = null;
    let skippedSoup = false;       // 客人是否执意跳过锅底
    let hasOrderedSoupBefore = false; // 本桌是否已经点过一轮汤底
    let currentCustomer = null;
    const cart = {};

    function openModal(id) { document.getElementById(id).classList.add('show'); }
    function closeModal(id) { document.getElementById(id).classList.remove('show'); }

    // 1. 客人邮箱/手机号登录
    async function customerLogin() {
      const contact = document.getElementById('loginContact').value.trim();
      const name = document.getElementById('loginName').value.trim();
      const errEl = document.getElementById('loginErr');

      if (!contact || contact.length < 5) {
        errEl.innerText = '请输入有效的手机号或电子邮箱！';
        errEl.style.display = 'block';
        return;
      }
      errEl.style.display = 'none';

      const res = await fetch('/api/customer/auth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contact, name })
      });
      const data = await res.json();
      if (res.ok) {
        currentCustomer = data.customer;
        document.getElementById('userBadge').innerText = `${currentCustomer.display_name} (${currentCustomer.contact}) • ${currentCustomer.points} 积分`;
        closeModal('loginModal');
      } else {
        errEl.innerText = data.message || '登录失败';
        errEl.style.display = 'block';
      }
    }

    // 2. 加载带图菜单
    async function loadMenu() {
      const res = await fetch('/api/pos/menu');
      const data = await res.json();
      menuItems = data.items || [];
      renderCats();
      renderMenu();
    }

    function getSoupCountInCart() {
      let count = 0;
      for (const id of Object.keys(cart)) {
        const item = menuItems.find(m => m.item_id == id);
        if (item && item.category === 'Soup Base') count += cart[id];
      }
      return count;
    }

    function updateSoupBanner() {
      const count = getSoupCountInCart();
      const badge = document.getElementById('soupStatusBadge');
      const banner = document.getElementById('soupBanner');
      if (count > 0 || hasOrderedSoupBefore) {
        badge.innerText = `已选锅底 (${count} 份)`;
        badge.style.background = '#1b5e20';
        banner.querySelector('span').innerText = '✅ 锅底已就绪！现在可以尽情挑选肉类、海鲜和配菜啦。';
      } else if (skippedSoup) {
        badge.innerText = '已跳过锅底';
        badge.style.background = '#64748b';
        banner.querySelector('span').innerText = '💡 您已选择跳过锅底，如需加锅底可随时切回 Soup Base。';
      } else {
        badge.innerText = '尚未选锅底';
        badge.style.background = '#b71c1c';
        banner.querySelector('span').innerText = '🍲 第一步：请先挑选您喜欢的火锅汤底，开锅后更入味！';
      }
    }

    // 3. 切换分类时的“先点汤”拦截逻辑
    function handleCategoryClick(cat) {
      if (cat !== 'Soup Base' && getSoupCountInCart() === 0 && !hasOrderedSoupBefore && !skippedSoup) {
        pendingTargetCat = cat;
        openModal('soupSkipModal');
        return;
      }
      selectedCat = cat;
      renderCats();
      renderMenu();
    }

    function stayForSoup() {
      pendingTargetCat = null;
      closeModal('soupSkipModal');
    }

    function confirmSkipSoup() {
      skippedSoup = true;
      closeModal('soupSkipModal');
      if (pendingTargetCat) {
        selectedCat = pendingTargetCat;
        pendingTargetCat = null;
      }
      updateSoupBanner();
      renderCats();
      renderMenu();
    }

    // 4. 点过一轮汤后询问是否再点
    function orderMoreSoup() {
      closeModal('soupAgainModal');
    }

    function goOrderDishes() {
      closeModal('soupAgainModal');
      selectedCat = 'Meat & Seafood';
      renderCats();
      renderMenu();
    }

    function renderCats() {
      document.getElementById('catBar').innerHTML = categories.map(c =>
        `<button class="cat-btn ${c === selectedCat ? 'active' : ''}" onclick="handleCategoryClick('${c}')">${c === 'Soup Base' ? '🍲 ' + c : c}</button>`
      ).join('');
    }

    function renderMenu() {
      const list = selectedCat === 'All' ? menuItems : menuItems.filter(i => i.category === selectedCat);
      document.getElementById('menuGrid').innerHTML = list.map(i => {
        const q = cart[i.item_id] || 0;
        const imgUrl = i.image_url || 'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=600&q=80';
        return `
          <div class="card ${q > 0 ? 'in-cart' : ''}">
            <div class="card-img-wrap">
              <img src="${imgUrl}" alt="${i.name}" onerror="this.style.display='none'" />
              <span class="cat-tag">${i.category}</span>
              ${q > 0 ? `<span class="qty-ribbon">已选 ${q}</span>` : ''}
            </div>
            <div class="card-body">
              <div>
                <h3>${i.name}</h3>
                <p>${i.description}</p>
              </div>
              <div class="card-foot">
                <span class="price">RM ${Number(i.price).toFixed(2)}</span>
                <button class="add-btn" onclick="updateQty(${i.item_id}, 1, true)">+ 加入</button>
              </div>
            </div>
          </div>`;
      }).join('');
    }

    function updateQty(id, delta, fromMenuCard = false) {
      const prevSoupCount = getSoupCountInCart();
      const next = (cart[id] || 0) + delta;
      if (next <= 0) delete cart[id];
      else cart[id] = next;

      const item = menuItems.find(m => m.item_id == id);
      const newSoupCount = getSoupCountInCart();

      updateSoupBanner();
      renderMenu();
      renderCart();

      // 点过一轮汤底后（刚添加锅底），询问是否再点或去点配菜
      if (fromMenuCard && delta > 0 && item && item.category === 'Soup Base') {
        document.getElementById('soupAgainText').innerHTML =
          `您已选择 <b>${newSoupCount} 份锅底</b>（刚加入：${item.name}）。是否需要<b>再点一个锅底</b>，还是直接去点肉类和配菜？`;
        openModal('soupAgainModal');
      }
    }

    function renderCart() {
      const keys = Object.keys(cart);
      const listEl = document.getElementById('cartList');
      if (keys.length === 0) {
        listEl.innerHTML = '<div style="color:#9ca3af; text-align:center; padding:18px;">请先选择锅底或菜品</div>';
        document.getElementById('subtotal').innerText = 'RM 0.00';
        document.getElementById('svc').innerText = 'RM 0.00';
        document.getElementById('sst').innerText = 'RM 0.00';
        document.getElementById('grand').innerText = 'RM 0.00';
        document.getElementById('submitBtn').disabled = true;
        return;
      }

      let sub = 0;
      listEl.innerHTML = keys.map(k => {
        const item = menuItems.find(m => m.item_id == k);
        const qty = cart[k];
        const line = item.price * qty;
        sub += line;
        return `
          <div class="cart-item">
            <div style="flex:1; padding-right:8px;"><b>${item.name}</b><br><small style="color:#1b5e20; font-weight:700;">RM ${line.toFixed(2)}</small></div>
            <div class="qty-ctrl">
              <button onclick="updateQty(${k}, -1)">-</button>
              <span style="margin:0 6px; font-weight:800;">${qty}</span>
              <button onclick="updateQty(${k}, 1)">+</button>
            </div>
          </div>`;
      }).join('');

      const svc = +(sub * 0.10).toFixed(2);
      const sst = +(sub * 0.06).toFixed(2);
      const grand = sub + svc + sst;

      document.getElementById('subtotal').innerText = 'RM ' + sub.toFixed(2);
      document.getElementById('svc').innerText = 'RM ' + svc.toFixed(2);
      document.getElementById('sst').innerText = 'RM ' + sst.toFixed(2);
      document.getElementById('grand').innerText = 'RM ' + grand.toFixed(2);
      document.getElementById('submitBtn').disabled = false;
    }

    async function placeOrder() {
      if (!currentCustomer) {
        openModal('loginModal');
        return;
      }
      const btn = document.getElementById('submitBtn');
      btn.disabled = true;
      btn.innerText = '正在传送至后厨...';

      if (getSoupCountInCart() > 0) hasOrderedSoupBefore = true;

      const items = Object.keys(cart).map(k => ({ item_id: Number(k), qty: cart[k] }));
      const payload = {
        table_no: document.getElementById('tableNo').value,
        staff_id: Number(document.getElementById('staffId').value),
        customer_contact: `${currentCustomer.display_name} (${currentCustomer.contact})`,
        remarks: document.getElementById('remarks').value,
        items: items
      };

      const res = await fetch('/api/pos/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      if (res.ok) {
        Object.keys(cart).forEach(k => delete cart[k]);
        document.getElementById('remarks').value = '';
        updateSoupBanner();
        renderMenu();
        renderCart();
        const toast = document.getElementById('toast');
        toast.style.display = 'block';
        toast.innerText = `✅ 下单成功！单号 #POS-${String(data.order_id).padStart(4, '0')} • 总计 RM ${Number(data.grand_total).toFixed(2)}（已同步至员工后台）`;
        setTimeout(() => { toast.style.display = 'none'; }, 5500);
      }
      btn.innerText = '确认下单 (直连后厨)';
    }

    function openMyOrders() {
      if (!currentCustomer) { openModal('loginModal'); return; }
      openModal('myOrdersModal');
      loadMyOrders();
    }

    async function loadMyOrders() {
      if (!currentCustomer) return;
      const contactKey = `${currentCustomer.display_name} (${currentCustomer.contact})`;
      const res = await fetch('/api/customer/orders?contact=' + encodeURIComponent(contactKey));
      const data = await res.json();
      const orders = data.data || [];
      const box = document.getElementById('myOrdersList');
      if (orders.length === 0) {
        box.innerHTML = '<div style="color:#888; padding:20px;">您还没有下单记录。</div>';
        return;
      }
      box.innerHTML = orders.map(o => `
        <div class="order-history-item">
          <div style="display:flex; justify-content:space-between; font-weight:900; margin-bottom:4px;">
            <span>#POS-${String(o.order_id).padStart(4, '0')} • ${o.table_no}</span>
            <span style="color:#b71c1c;">${o.status.toUpperCase()}</span>
          </div>
          <div style="color:#666; font-size:11px; margin-bottom:6px;">${o.created_at} • 服务员: ${o.staff_name}</div>
          ${(o.items || []).map(it => `<div>• ${it.qty}x ${it.item_name} (RM ${Number(it.line_total).toFixed(2)})</div>`).join('')}
          <div style="margin-top:6px; font-weight:900; color:#1b5e20;">总计: RM ${Number(o.grand_total).toFixed(2)}</div>
        </div>
      `).join('');
    }

    loadMenu();
  </script>
</body>
</html>
'''

@app.route('/')
@app.route('/order')
def customer_order_portal():
    return render_template_string(CUSTOMER_ORDER_HTML)

# --- 客人邮箱/电话一键登录/注册 API ---
@app.route('/api/customer/auth', methods=['POST'])
def customer_auth():
    d = request.get_json() or {}
    contact = d.get('contact', '').strip().lower()
    name = d.get('name', '').strip()
    if not contact:
        return jsonify({"status": "error", "message": "Phone or Email is required"}), 400

    display_name = name if name else contact.split('@')[0]
    with sqlite3.connect('hr_system.db') as conn:
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM customers WHERE contact = ?", (contact,))
        row = cursor.fetchone()
        if not row:
            now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            cursor.execute("INSERT INTO customers (contact, display_name, points, created_at) VALUES (?, ?, 100, ?)",
                           (contact, display_name, now_str))
            conn.commit()
            cursor.execute("SELECT * FROM customers WHERE contact = ?", (contact,))
            row = cursor.fetchone()
        elif name and row['display_name'] != name:
            cursor.execute("UPDATE customers SET display_name = ? WHERE contact = ?", (name, contact))
            conn.commit()
            cursor.execute("SELECT * FROM customers WHERE contact = ?", (contact,))
            row = cursor.fetchone()

    return jsonify({"status": "success", "customer": dict(row)}), 200

# --- 客人查询自己的历史订单与实时进度 ---
@app.route('/api/customer/orders', methods=['GET'])
def get_customer_orders():
    contact = request.args.get('contact', '').strip()
    with sqlite3.connect('hr_system.db') as conn:
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute('''
            SELECT o.*, COALESCE(u.full_name, 'Staff') AS staff_name
            FROM orders o
            LEFT JOIN users u ON o.served_by_staff_id = u.staff_id
            WHERE o.customer_contact = ?
            ORDER BY o.order_id DESC LIMIT 20
        ''', (contact,))
        orders = [dict(r) for r in cursor.fetchall()]
        for o in orders:
            cursor.execute("SELECT item_name, qty, line_total FROM order_items WHERE order_id = ?", (o['order_id'],))
            o['items'] = [dict(x) for x in cursor.fetchall()]
    return jsonify({"status": "success", "data": orders}), 200

# --- API 1: 员工登录 ---
@app.route('/api/login', methods=['POST'])
def login():
    d = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT staff_id, username, full_name, role_level, role_title, branch, basic_salary, custom_bonus,
                   bank_info, epf_no, ic_no, socso_no, eis_no, tax_no, phone, join_date, department, emergency_contact, assigned_manager
            FROM users WHERE LOWER(username) = ? AND password = ?
        ''', (d.get('username', '').strip().lower(), d.get('password', '').strip()))
        row = cursor.fetchone()
    if row:
        return jsonify({"status": "success", "user": get_user_dict(row)}), 200
    return jsonify({"status": "error", "message": "Invalid username or password"}), 401

# --- API 2: 个人实时状态与门店公告 ---
@app.route('/api/status', methods=['POST'])
def get_status():
    sid = (request.get_json() or {}).get('staff_id', 1)
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT event_type, event_time, gps_coords, selfie_tag FROM attendance_events WHERE staff_id = ? ORDER BY event_id DESC LIMIT 1', (sid,))
        last = cursor.fetchone()
        cursor.execute("SELECT COUNT(*), COALESCE(SUM(shift_hours), 0) FROM attendance_events WHERE staff_id = ? AND event_type = 'OUT'", (sid,))
        s_count, t_hrs = cursor.fetchone()
        cursor.execute('SELECT title, content, author, created_at FROM announcements ORDER BY id DESC LIMIT 1')
        ann = cursor.fetchone()
    return jsonify({
        "is_clocked_in": bool(last and last[0] == 'IN'),
        "clock_in_time": last[1] if (last and last[0] == 'IN') else "",
        "last_gps": last[2] if last else "1.5152° N, 103.6660° E",
        "kpi": {"shifts": s_count, "hours": round(t_hrs, 2), "est_ot": round(420.00 + (s_count * 25.0) + (t_hrs * 10.0), 2)},
        "announcement": {"title": ann[0], "content": ann[1], "author": ann[2], "date": ann[3]} if ann else {"title": "Notice", "content": "Active"}
    }), 200

# --- API 3 & 4: 上下班打卡 ---
@app.route('/api/clock-in', methods=['POST'])
def clock_in():
    d = request.get_json() or {}
    sid = d.get('staff_id', 1)
    branch = d.get('branch', 'Sutera Utama Outlet')
    gps_coords = d.get('gps_coords', '1.5152° N, 103.6660° E')
    location_label = d.get('location', 'Sutera Mall Outlet (Geofence Gate A)')
    distance_m = int(d.get('distance_m', 14))
    selfie_tag = d.get('selfie_tag', f"SELFIE_{sid}_{datetime.now().strftime('%H%M%S')}.jpg")
    t = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO attendance_events (staff_id, event_type, event_time, shift_hours, location, branch, gps_coords, distance_m, selfie_tag, verify_status)
            VALUES (?, 'IN', ?, 0.0, ?, ?, ?, ?, ?, 'On-Time • GPS & Selfie Verified')
        ''', (sid, t, location_label, branch, gps_coords, distance_m, selfie_tag))
        conn.commit()
    return jsonify({"status": "success", "type": "IN", "time": t}), 200

@app.route('/api/clock-out', methods=['POST'])
def clock_out():
    d = request.get_json() or {}
    sid = d.get('staff_id', 1)
    branch = d.get('branch', 'Sutera Utama Outlet')
    gps_coords = d.get('gps_coords', '1.5152° N, 103.6660° E')
    location_label = d.get('location', 'Sutera Mall Outlet (Geofence Gate A)')
    distance_m = int(d.get('distance_m', 16))
    selfie_tag = d.get('selfie_tag', f"SELFIE_OUT_{sid}_{datetime.now().strftime('%H%M%S')}.jpg")
    now = datetime.now()
    t = now.strftime("%Y-%m-%d %H:%M:%S")

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT event_time FROM attendance_events WHERE staff_id = ? AND event_type = 'IN' ORDER BY event_id DESC LIMIT 1", (sid,))
        last = cursor.fetchone()
        if last:
            diff = max(round((now - datetime.strptime(last[0], "%Y-%m-%d %H:%M:%S")).total_seconds() / 3600, 2), 0.02)
        else:
            diff = 8.0
        cursor.execute('''
            INSERT INTO attendance_events (staff_id, event_type, event_time, shift_hours, location, branch, gps_coords, distance_m, selfie_tag, verify_status)
            VALUES (?, 'OUT', ?, ?, ?, ?, ?, ?, ?, 'Shift Completed • GPS & Selfie OK')
        ''', (sid, t, diff, location_label, branch, gps_coords, distance_m, selfie_tag))
        conn.commit()
    return jsonify({"status": "success", "type": "OUT", "time": t, "total_hours": diff}), 200

# --- API 5: 考勤查询与审计 ---
@app.route('/api/history', methods=['POST'])
def get_history():
    d = request.get_json() or {}
    sid = d.get('staff_id', 1)
    view_all = d.get('view_all', False)
    branch_filter = d.get('branch_filter', 'All Branches')
    staff_filter = d.get('staff_filter', 'All Staff')

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        query = '''
            SELECT e.event_id, u.staff_id, u.full_name, u.role_title, u.ic_no,
                   e.event_type, e.event_time, e.shift_hours, e.location,
                   COALESCE(e.branch, u.branch),
                   COALESCE(e.gps_coords, '1.5152° N, 103.6660° E'),
                   COALESCE(e.distance_m, 15),
                   COALESCE(e.selfie_tag, 'SELFIE_VERIFIED.jpg'),
                   COALESCE(e.verify_status, 'GPS & Selfie Verified')
            FROM attendance_events e
            JOIN users u ON e.staff_id = u.staff_id
            WHERE 1=1
        '''
        params = []
        if not view_all:
            query += ' AND e.staff_id = ?'
            params.append(sid)
        else:
            if branch_filter and branch_filter != 'All Branches':
                query += ' AND COALESCE(e.branch, u.branch) = ?'
                params.append(branch_filter)
            if staff_filter and staff_filter != 'All Staff':
                query += ' AND u.full_name = ?'
                params.append(staff_filter)

        query += ' ORDER BY e.event_id DESC LIMIT 60'
        cursor.execute(query, params)
        rows = cursor.fetchall()

    events = [{
        "event_id": r[0], "staff_id": r[1], "staff_name": r[2], "role_title": r[3], "ic_no": r[4],
        "type": r[5], "time": r[6], "hours": r[7], "location": r[8], "branch": r[9],
        "gps_coords": r[10], "distance_m": r[11], "selfie_tag": r[12], "verify_status": r[13]
    } for r in rows]
    return jsonify({"status": "success", "data": events}), 200

# --- API 6: 请假审批流 ---
@app.route('/api/leave', methods=['POST'])
def apply_leave():
    d = request.get_json() or {}
    sid = d.get('staff_id', 1)
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT branch, assigned_manager FROM users WHERE staff_id = ?', (sid,))
        u_row = cursor.fetchone()
        branch = u_row[0] if u_row else 'Sutera Utama Outlet'
        assigned_mgr = u_row[1] if u_row else 'Eugene Tang (Sutera Outlet Manager)'
        cursor.execute('''
            INSERT INTO leave_request (staff_id, branch, assigned_manager, leave_type, start_date, end_date, reason, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'Pending')
        ''', (sid, branch, assigned_mgr, d['leave_type'], d['start_date'], d['end_date'], d.get('reason', '')))
        conn.commit()
    return jsonify({"status": "success"}), 200

@app.route('/api/leave-list', methods=['POST'])
def get_leave_list():
    d = request.get_json() or {}
    sid = d.get('staff_id', 1)
    view_all = d.get('view_all', False)
    branch_filter = d.get('branch_filter', 'All Branches')

    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        query = '''
            SELECT l.leave_id, u.full_name, u.role_title, COALESCE(l.branch, u.branch),
                   COALESCE(l.assigned_manager, u.assigned_manager),
                   l.leave_type, l.start_date, l.end_date, l.reason, l.status,
                   l.reviewer_name, l.review_remark, l.reviewed_at
            FROM leave_request l
            JOIN users u ON l.staff_id = u.staff_id
            WHERE 1=1
        '''
        params = []
        if not view_all:
            query += ' AND l.staff_id = ?'
            params.append(sid)
        elif branch_filter and branch_filter != 'All Branches':
            query += ' AND COALESCE(l.branch, u.branch) = ?'
            params.append(branch_filter)

        query += ' ORDER BY l.leave_id DESC'
        cursor.execute(query, params)
        rows = cursor.fetchall()

        cursor.execute("SELECT leave_type, start_date, end_date FROM leave_request WHERE staff_id = ? AND status = 'Approved'", (sid,))
        app_rows = cursor.fetchall()

    used_al, used_mc, used_hl = 0, 0, 0
    for lt, s_str, e_str in app_rows:
        try:
            days = max((datetime.strptime(e_str, "%Y-%m-%d") - datetime.strptime(s_str, "%Y-%m-%d")).days + 1, 1)
        except Exception:
            days = 1
        if lt.startswith('AL'): used_al += days
        elif lt.startswith('MC'): used_mc += days
        elif lt.startswith('HL'): used_hl += days

    data = [{
        "id": r[0], "staff_name": r[1], "role_title": r[2], "branch": r[3],
        "assigned_manager": r[4], "type": r[5], "start": r[6], "end": r[7],
        "reason": r[8] or "Personal", "status": r[9],
        "reviewer_name": r[10] or "", "review_remark": r[11] or "", "reviewed_at": r[12] or ""
    } for r in rows]

    return jsonify({
        "status": "success",
        "data": data,
        "quotas": {
            "al_left": max(12 - used_al, 0), "al_used": used_al,
            "mc_left": max(14 - used_mc, 0), "mc_used": used_mc,
            "hl_left": max(60 - used_hl, 0), "hl_used": used_hl
        }
    }), 200

@app.route('/api/leave-approve', methods=['POST'])
def approve_leave():
    d = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        conn.execute('''
            UPDATE leave_request
            SET status = ?, reviewer_name = ?, review_remark = ?, reviewed_at = ?
            WHERE leave_id = ?
        ''', (d.get('status'), d.get('reviewer_name'), d.get('review_remark'), datetime.now().strftime("%Y-%m-%d %H:%M"), d.get('leave_id')))
        conn.commit()
    return jsonify({"status": "success"}), 200

# --- API 7: 费用报销 ---
@app.route('/api/claim-submit', methods=['POST'])
def submit_claim():
    d = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        conn.execute("INSERT INTO expense_claims (staff_id, category, amount, description, claim_date) VALUES (?, ?, ?, ?, ?)",
                     (d.get('staff_id', 1), d['category'], float(d['amount']), d.get('description', ''), datetime.now().strftime("%Y-%m-%d")))
        conn.commit()
    return jsonify({"status": "success"}), 200

@app.route('/api/claim-list', methods=['POST'])
def get_claim_list():
    d = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        if d.get('view_all', False):
            cursor.execute('SELECT c.claim_id, u.full_name, c.category, c.amount, c.description, c.claim_date, c.status, c.reviewer_name, c.review_remark FROM expense_claims c JOIN users u ON c.staff_id = u.staff_id ORDER BY c.claim_id DESC')
        else:
            cursor.execute('SELECT c.claim_id, u.full_name, c.category, c.amount, c.description, c.claim_date, c.status, c.reviewer_name, c.review_remark FROM expense_claims c JOIN users u ON c.staff_id = u.staff_id WHERE c.staff_id = ? ORDER BY c.claim_id DESC', (d.get('staff_id', 1),))
        rows = cursor.fetchall()
    return jsonify({"status": "success", "data": [{
        "id": x[0], "staff_name": x[1], "category": x[2], "amount": x[3], "description": x[4],
        "date": x[5], "status": x[6], "reviewer_name": x[7] or "", "review_remark": x[8] or ""
    } for x in rows]}), 200

@app.route('/api/claim-approve', methods=['POST'])
def approve_claim():
    d = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        conn.execute('UPDATE expense_claims SET status = ?, reviewer_name = ?, review_remark = ? WHERE claim_id = ?',
                     (d.get('status'), d.get('reviewer_name'), d.get('review_remark'), d.get('claim_id')))
        conn.commit()
    return jsonify({"status": "success"}), 200

# --- API 8: 马来西亚法定标准薪水单 ---
@app.route('/api/payslips-all', methods=['POST'])
def get_all_payslips():
    sid = (request.get_json() or {}).get('staff_id', 1)
    with sqlite3.connect('hr_system.db') as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT staff_id, username, full_name, role_level, role_title, branch, basic_salary, custom_bonus,
                   bank_info, epf_no, ic_no, socso_no, eis_no, tax_no, phone, join_date, department, emergency_contact, assigned_manager
            FROM users WHERE staff_id = ?
        ''', (sid,))
        u_row = cursor.fetchone()
        u = get_user_dict(u_row) if u_row else {
            "staff_id": 1, "full_name": "Ng Zhe Wei", "role_title": "Service Crew (L1)", "branch": "Sutera Utama Outlet",
            "basic_salary": 2800.0, "custom_bonus": 150.0, "bank_info": "Public Bank Berhad (4829108821)",
            "epf_no": "KWSP-99482104", "ic_no": "030618-01-8821", "socso_no": "PERKESO-03061801",
            "eis_no": "SIP-994821", "tax_no": "SG-10293847-01", "department": "Table Service"
        }

        cursor.execute("SELECT COUNT(*), COALESCE(SUM(shift_hours), 0) FROM attendance_events WHERE staff_id = ? AND event_type = 'OUT'", (sid,))
        o_count, t_hrs = cursor.fetchone()
        cursor.execute("SELECT COALESCE(SUM(amount), 0) FROM expense_claims WHERE staff_id = ? AND status = 'Approved'", (sid,))
        claims = round(float(cursor.fetchone()[0]), 2)

    b_pay = float(u['basic_salary'])
    c_bonus = float(u['custom_bonus'])
    live_ot = round(420.00 + (o_count * 25.0) + (t_hrs * 10.0), 2)

    def make_my_slip(month, num, period_str, date_str, basic, ot, comm, bonus, claim_amt=0.0, status="Paid"):
        gross = round(basic + ot + comm + bonus + claim_amt, 2)
        emp_epf = round(basic * 0.11, 2)
        emp_socso = 19.75 if basic <= 4000 else 29.75
        emp_eis = round(min(basic, 5000) * 0.002, 2)
        pcb_tax = 0.00 if gross < 3400 else round((gross - 3400) * 0.03, 2)
        total_deduction = round(emp_epf + emp_socso + emp_eis + pcb_tax, 2)
        net_pay = round(gross - total_deduction, 2)

        empr_epf_rate = 0.13 if basic <= 5000 else 0.12
        empr_epf = round(basic * empr_epf_rate, 2)
        empr_socso = round(min(basic, 5000) * 0.0175, 2)
        empr_eis = emp_eis
        hrdf_levy = round(gross * 0.01, 2)

        return {
            "company_name": "SMARTER POS F&B SDN. BHD.",
            "company_reg": "201801012345 (1274361-T)",
            "staff_id": f"EMP-{u['staff_id']:03d}",
            "staff_name": u['full_name'],
            "ic_no": u['ic_no'],
            "role_title": u['role_title'],
            "department": u['department'],
            "branch": u['branch'],
            "bank_info": u['bank_info'],
            "epf_no": u['epf_no'],
            "socso_no": u['socso_no'],
            "eis_no": u['eis_no'],
            "tax_no": u['tax_no'],
            "month": month, "month_num": num, "pay_period": period_str, "pay_date": date_str, "status": status,
            "basic_salary": basic, "ot_pay": ot, "commission": comm, "attendance_bonus": bonus, "claims_reimbursement": claim_amt,
            "gross_pay": gross,
            "epf": emp_epf, "socso": emp_socso, "eis": emp_eis, "pcb": pcb_tax,
            "total_deduction": total_deduction,
            "employer_epf": empr_epf, "employer_socso": empr_socso, "employer_eis": empr_eis, "employer_hrdf": hrdf_levy,
            "net_pay": net_pay
        }

    payslip_db = {
        "2026": [
            make_my_slip("October", "10", "01/10/2026 - 31/10/2026", "2026-10-31", b_pay, live_ot, 380.00, c_bonus, claims, "Live Sync"),
            make_my_slip("September", "09", "01/09/2026 - 30/09/2026", "2026-09-30", b_pay, 320.00, 410.00, 150.00),
            make_my_slip("August", "08", "01/08/2026 - 31/08/2026", "2026-08-31", b_pay, 510.00, 520.00, 150.00),
            make_my_slip("July", "07", "01/07/2026 - 31/07/2026", "2026-07-31", b_pay, 280.00, 390.00, 150.00),
            make_my_slip("June", "06", "01/06/2026 - 30/06/2026", "2026-06-30", b_pay, 400.00, 460.00, 150.00),
            make_my_slip("May", "05", "01/05/2026 - 31/05/2026", "2026-05-31", b_pay, 490.00, 480.00, 150.00),
            make_my_slip("April", "04", "01/04/2026 - 30/04/2026", "2026-04-30", b_pay, 180.00, 340.00, 0.00),
            make_my_slip("March", "03", "01/03/2026 - 31/03/2026", "2026-03-31", b_pay, 350.00, 420.00, 150.00),
            make_my_slip("February", "02", "01/02/2026 - 28/02/2026", "2026-02-28", b_pay, 780.00, 750.00, 150.00),
            make_my_slip("January", "01", "01/01/2026 - 31/01/2026", "2026-01-31", b_pay, 410.00, 440.00, 150.00)
        ],
        "2025": [
            make_my_slip("December", "12", "01/12/2025 - 31/12/2025", "2025-12-31", b_pay - 200, 600.00, 800.00, 150.00),
            make_my_slip("November", "11", "01/11/2025 - 30/11/2025", "2025-11-30", b_pay - 200, 250.00, 350.00, 150.00),
            make_my_slip("October", "10", "01/10/2025 - 31/10/2025", "2025-10-31", b_pay - 200, 310.00, 390.00, 150.00),
            make_my_slip("September", "09", "01/09/2025 - 30/09/2025", "2025-09-30", b_pay - 200, 290.00, 360.00, 150.00),
            make_my_slip("August", "08", "01/08/2025 - 31/08/2025", "2025-08-31", b_pay - 200, 420.00, 450.00, 150.00),
            make_my_slip("July", "07", "01/07/2025 - 31/07/2025", "2025-07-31", b_pay - 200, 200.00, 310.00, 150.00)
        ]
    }
    return jsonify({"status": "success", "data": payslip_db}), 200

@app.route('/api/users', methods=['POST'])
def get_all_users():
    with sqlite3.connect('hr_system.db') as conn:
        rows = conn.cursor().execute('''
            SELECT staff_id, username, full_name, role_level, role_title, branch, basic_salary, custom_bonus,
                   bank_info, epf_no, ic_no, socso_no, eis_no, tax_no, phone, join_date, department, emergency_contact, assigned_manager
            FROM users ORDER BY staff_id
        ''').fetchall()
    return jsonify({"status": "success", "data": [get_user_dict(x) for x in rows]}), 200

@app.route('/api/update-salary', methods=['POST'])
def update_salary():
    d = request.get_json() or {}
    with sqlite3.connect('hr_system.db') as conn:
        conn.execute('UPDATE users SET basic_salary = ?, custom_bonus = ? WHERE staff_id = ?',
                     (float(d['basic_salary']), float(d['custom_bonus']), int(d['staff_id'])))
        conn.commit()
    return jsonify({"status": "success"}), 200

# --- API 9: 实时抽成/计件引擎 ---
@app.route('/api/commission/<int:staff_id>', methods=['GET'])
def get_staff_commission(staff_id):
    try:
        with sqlite3.connect('hr_system.db') as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()

            cursor.execute("SELECT full_name, role_title FROM users WHERE staff_id = ?", (staff_id,))
            user = cursor.fetchone()
            if not user:
                return jsonify({"status": "error", "message": "User not found"}), 404

            cursor.execute("SELECT rate_type, rate_value FROM commission_rates WHERE role_title = ?", (user['role_title'],))
            rate_info = cursor.fetchone()
            if not rate_info:
                return jsonify({"status": "error", "message": f"Commission rate not set for {user['role_title']}"}), 400

            rate_type = rate_info['rate_type']
            rate_value = Decimal(str(rate_info['rate_value']))
            mock_total_sales_or_items = Decimal('2450.50') if rate_type == 'percentage' else Decimal('300')
            calculated_commission = mock_total_sales_or_items * rate_value
            final_commission = calculated_commission.quantize(Decimal('0.00'), rounding=ROUND_HALF_UP)

            target_commission = Decimal('50.00')
            progress = min(float(final_commission / target_commission), 1.0) if target_commission > 0 else 0

        return jsonify({
            "status": "success",
            "staff_id": staff_id,
            "staff_name": user['full_name'],
            "role": user['role_title'],
            "weekly_commission_rm": str(final_commission),
            "kpi_progress": progress,
            "target_achieved": bool(final_commission >= target_commission)
        }), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# --- API 10: 获取 POS 商业菜单 ---
@app.route('/api/pos/menu', methods=['GET'])
def get_pos_menu():
    with sqlite3.connect('hr_system.db') as conn:
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM menu_items WHERE is_available = 1 ORDER BY item_id")
        rows = [dict(r) for r in cursor.fetchall()]
    categories = ['Soup Base', 'Meat & Seafood', 'Veggies & Noodles', 'Drinks', 'All']
    return jsonify({"status": "success", "categories": categories, "items": rows}), 200

# --- API 11: 客人提交 POS 订单 ---
@app.route('/api/pos/orders', methods=['POST'])
def create_pos_order():
    d = request.get_json() or {}
    table_no = d.get('table_no', 'Table A01')
    staff_id = int(d.get('staff_id', 1))
    customer_contact = d.get('customer_contact', 'Walk-in Guest')
    remarks = d.get('remarks', '').strip()
    cart_items = d.get('items', [])

    if not cart_items:
        return jsonify({"status": "error", "message": "Cart cannot be empty"}), 400

    try:
        with sqlite3.connect('hr_system.db') as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("BEGIN TRANSACTION")

            subtotal = Decimal('0.00')
            validated_items = []

            for item in cart_items:
                item_id = int(item['item_id'])
                qty = int(item['qty'])
                if qty <= 0:
                    continue
                cursor.execute("SELECT name, price FROM menu_items WHERE item_id = ?", (item_id,))
                m = cursor.fetchone()
                if not m:
                    continue
                unit_price = Decimal(str(m['price']))
                line_total = (unit_price * qty).quantize(Decimal('0.00'), rounding=ROUND_HALF_UP)
                subtotal += line_total
                validated_items.append((item_id, m['name'], qty, float(unit_price), float(line_total)))

            if not validated_items:
                conn.rollback()
                return jsonify({"status": "error", "message": "No valid menu items found"}), 400

            service_charge = (subtotal * Decimal('0.10')).quantize(Decimal('0.00'), rounding=ROUND_HALF_UP)
            sst_tax = (subtotal * Decimal('0.06')).quantize(Decimal('0.00'), rounding=ROUND_HALF_UP)
            grand_total = (subtotal + service_charge + sst_tax).quantize(Decimal('0.00'), rounding=ROUND_HALF_UP)
            created_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            cursor.execute('''
                INSERT INTO orders (table_no, served_by_staff_id, customer_contact, subtotal, service_charge, sst_tax, grand_total, remarks, status, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Pending', ?)
            ''', (table_no, staff_id, customer_contact, float(subtotal), float(service_charge), float(sst_tax), float(grand_total), remarks, created_at))
            order_id = cursor.lastrowid

            for v in validated_items:
                cursor.execute('''
                    INSERT INTO order_items (order_id, item_id, item_name, qty, unit_price, line_total)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (order_id, v[0], v[1], v[2], v[3], v[4]))

            conn.commit()

        return jsonify({
            "status": "success",
            "order_id": order_id,
            "table_no": table_no,
            "subtotal": float(subtotal),
            "service_charge": float(service_charge),
            "sst_tax": float(sst_tax),
            "grand_total": float(grand_total),
            "created_at": created_at
        }), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# --- API 12: 员工 App 后台实时拉取客人订单 ---
@app.route('/api/pos/orders/live', methods=['GET'])
def get_live_pos_orders():
    with sqlite3.connect('hr_system.db') as conn:
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute('''
            SELECT o.*, COALESCE(u.full_name, 'Unassigned') AS staff_name
            FROM orders o
            LEFT JOIN users u ON o.served_by_staff_id = u.staff_id
            ORDER BY o.order_id DESC LIMIT 40
        ''')
        orders = [dict(r) for r in cursor.fetchall()]

        for o in orders:
            cursor.execute("SELECT item_name, qty, line_total FROM order_items WHERE order_id = ?", (o['order_id'],))
            o['items'] = [dict(x) for x in cursor.fetchall()]

    return jsonify({"status": "success", "data": orders}), 200

# --- API 13: 员工 App 更新订单状态 ---
@app.route('/api/pos/orders/<int:order_id>/status', methods=['POST'])
def update_order_status(order_id):
    d = request.get_json() or {}
    new_status = d.get('status', 'Cooking')
    with sqlite3.connect('hr_system.db') as conn:
        conn.execute("UPDATE orders SET status = ? WHERE order_id = ?", (new_status, order_id))
        conn.commit()
    return jsonify({"status": "success", "order_id": order_id, "new_status": new_status}), 200

if __name__ == '__main__':
    app.run(debug=True)