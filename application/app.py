from flask import Flask, render_template, request, redirect, url_for, flash
import sqlite3
import os

app = Flask(__name__)
app.secret_key = 'devops-coursework-secret-key'  # Needed for flash messages

# Get the absolute path for the database within the 'application' folder
DB_PATH = os.path.join(os.path.dirname(__file__), 'expenses.db')

def init_db():
    """Initialize the database and create the expenses table."""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            amount REAL NOT NULL
        )
    ''')
    conn.commit()
    conn.close()

@app.route('/')
def home():
    """Homepage displaying all expenses and the add form."""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('SELECT * FROM expenses ORDER BY date DESC')
    expenses = c.fetchall()
    conn.close()

    # Calculate total
    total = sum(expense[4] for expense in expenses) if expenses else 0

    return render_template('index.html', expenses=expenses, total=total)

@app.route('/add', methods=['POST'])
def add_expense():
    """Handle adding a new expense."""
    date = request.form['date']
    category = request.form['category']
    description = request.form['description']
    amount = request.form['amount']

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('INSERT INTO expenses (date, category, description, amount) VALUES (?, ?, ?, ?)',
              (date, category, description, amount))
    conn.commit()
    conn.close()

    flash('Expense added successfully!', 'success')
    return redirect(url_for('home'))

@app.route('/delete/<int:expense_id>')
def delete_expense(expense_id):
    """Handle deleting an expense."""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('DELETE FROM expenses WHERE id = ?', (expense_id,))
    conn.commit()
    conn.close()

    flash('Expense deleted!', 'info')
    return redirect(url_for('home'))

@app.route('/health')
def health():
    """Health check endpoint for DevOps pipeline."""
    return 'OK', 200

if __name__ == '__main__':
    # Initialize the database when the app startss
    init_db()
    port = int(os.environ.get('PORT', 5000))
    #Get debug mode from environment variable, default to False for production
    #This allows us to set FLASK_DEBUG=True locally for development
    debug_enabled = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(debug=debug_enabled, host='0.0.0.0', port=port)