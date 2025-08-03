#!/usr/bin/python3
"""
WSGI File for Advanced Note-Taking Flask Application
This file serves as the entry point for Apache mod_wsgi
"""

import sys
import os

# Add the application directory to the Python path
sys.path.insert(0, '/opt/noteapp/')

# Import the Flask application
from app import app as application

if __name__ == "__main__":
    application.run() 