from flask import Flask, render_template, request, redirect, url_for, flash
import sqlite3
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'devops-coursework-secret-key'  # Needed for flash messages

def init_db():
    """Initialize the database and create the expenses table."""
    conn = sqlite3.connect('expenses.db')
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
    conn = sqlite3.connect('expenses.db')
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

    conn = sqlite3.connect('expenses.db')
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
    conn = sqlite3.connect('expenses.db')
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
    init_db()  # Ensure the database exists when the app starts
    app.run(debug=True, host='0.0.0.0', port=5000)