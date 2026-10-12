import sqlite3

def test_database_connection():
    try:
        # Connect to the local SQLite database (creates the file automatically if it doesn't exist)
        conn = sqlite3.connect('hr_system.db')
        cursor = conn.cursor()
        print("✅ Successfully connected to the local database!")

        # Create a simple Staff table for testing purposes
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS staff (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                role TEXT NOT NULL,
                basic_salary REAL NOT NULL
            )
        ''')
        print("✅ Successfully created the staff table!")

        # Insert a test record into the table
        cursor.execute('''
            INSERT INTO staff (name, role, basic_salary) 
            VALUES ('Zhe Wei', 'IT Intern', 1500.00)
        ''')
        conn.commit()
        print("✅ Successfully inserted test data!")

    except sqlite3.Error as e:
        print(f"❌ Database connection or operation error: {e}")
    
    finally:
        # Close the database connection
        if 'conn' in locals() and conn:
            conn.close()
            print("🔒 Database connection closed.")

if __name__ == '__main__':
    test_database_connection()