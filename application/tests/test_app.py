import sys
import os
import tempfile
import pytest  #importing pytest allows for any function with test_ to be automatically discovered and run so we don't have to list out tests manually. Also is industry standard

#Add the parent directory to Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import app, init_db

init_db()

#Test to see if the home page loads
def test_home_page():
    """Does the home page load?"""
    with app.test_client() as client:
        response = client.get('/')
        assert response.status_code == 200
        assert b'Expense Tracker' in response.data
        print("Home page test passed my dawg!")

#Now to test if the health endpoint works..? This doesn't rely on the database so we don't need to make one for this test.
def test_health_endpoint():
    """Does the health endpoint work?"""
    with app.test_client() as client:
        response = client.get('/health')
        assert response.status_code == 200
        assert b'OK' in response.data
        print("Health endpoint test passed too dude!")

if __name__ == "__main__":
    #This can also be run for debugging purposes
    test_home_page()
    test_health_endpoint()
    print("All tests passed my dawg")

#Using pytest we can also get the stats on these tests which is useful