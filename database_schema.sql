-- HR & POS Integrated System Database Schema (Planned on 12 Oct)

-- 1. Role Table (岗位与抽成设定)
CREATE TABLE IF NOT EXISTS role (
    role_id INTEGER PRIMARY KEY AUTOINCREMENT,
    role_name TEXT NOT NULL, -- e.g., Service, Kitchen, Cashier
    basic_salary_per_hour REAL NOT NULL, -- e.g., RM 8.00
    commission_rate REAL NOT NULL -- e.g., 0.03 for 3%
);

-- 2. Staff Table (员工基本信息)
CREATE TABLE IF NOT EXISTS staff (
    staff_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    phone TEXT,
    role_id INTEGER,
    status TEXT DEFAULT 'Active',
    FOREIGN KEY(role_id) REFERENCES role(role_id)
);

-- 3. Punch Card Table (考勤打卡记录)
CREATE TABLE IF NOT EXISTS punch_card (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id INTEGER NOT NULL,
    clock_in_time TEXT NOT NULL, -- Format: YYYY-MM-DD HH:MM:SS
    clock_out_time TEXT,
    total_hours REAL,
    FOREIGN KEY(staff_id) REFERENCES staff(staff_id)
);

-- 4. Payroll Table (月底薪水结算)
CREATE TABLE IF NOT EXISTS payroll (
    payroll_id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_id INTEGER NOT NULL,
    month_year TEXT NOT NULL, -- e.g., 2026-10
    total_worked_hours REAL,
    total_sales_handled REAL,
    final_commission REAL,
    total_salary REAL,
    FOREIGN KEY(staff_id) REFERENCES staff(staff_id)
);