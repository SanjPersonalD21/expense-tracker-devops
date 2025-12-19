from flask import Flask
import os  # Import os module to read environment variables

app = Flask(__name__)

@app.route('/')
def home():
    return '<h1>Expense Tracker</h1><p>Version 1.0. Flask server is active.</p>'

@app.route('/health')
def health():
    return 'OK', 200  # A simple endpoint for health checks (vital for DevOps)

if __name__ == '__main__':
    # Get port from environment variable (important for cloud hosting),
    # default to 5000 for local development.
    port = int(os.environ.get('PORT', 5000))
    
    # Run app. debug=True is for local dev only. 
    # host='0.0.0.0' makes it accessible to all network interfaces.
    app.run(debug=True, host='0.0.0.0', port=port)