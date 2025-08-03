#!/usr/bin/env python3
"""
Simple Note-Taking Web Application
Basic Flask app with SQLite database
"""

from flask import Flask, render_template_string, request, redirect, url_for
import sqlite3
import os

app = Flask(__name__)
app.secret_key = "simple_noteapp_key"

# Configuration
DATABASE_PATH = "/opt/noteapp/notes.db"
PORT = 80

# Simple HTML Template
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📝 Simple Note App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            resize: vertical;
            min-height: 80px;
        }
        button {
            background-color: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        button:hover {
            background-color: #0056b3;
        }
        .note {
            background: #f8f9fa;
            border-left: 4px solid #007bff;
            padding: 15px;
            margin: 15px 0;
            border-radius: 0 5px 5px 0;
        }
        .note-time {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 5px;
        }
        .note-content {
            color: #333;
            line-height: 1.5;
        }
        .no-notes {
            text-align: center;
            color: #666;
            font-style: italic;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📝 Simple Note-Taking App</h1>
        
        <form method="POST" action="/">
            <div class="form-group">
                <label for="note">Write your note:</label>
                <textarea name="note" id="note" placeholder="Enter your note here..." required></textarea>
            </div>
            <button type="submit">💾 Save Note</button>
        </form>
        
        <h2>📋 Your Notes</h2>
        {% if notes %}
            {% for note in notes %}
                <div class="note">
                    <div class="note-time">🕒 {{ note.timestamp }}</div>
                    <div class="note-content">📌 {{ note.content }}</div>
                </div>
            {% endfor %}
        {% else %}
            <div class="no-notes">
                No notes yet. Start by writing your first note above! ✨
            </div>
        {% endif %}
        
        <hr style="margin-top: 30px;">
        <p style="text-align: center; color: #666;">
            Total Notes: {{ notes|length if notes else 0 }} | 
            Deployed with Ansible
        </p>
    </div>
</body>
</html>
"""


def init_database():
    """Initialize SQLite database and create table"""
    os.makedirs(os.path.dirname(DATABASE_PATH), exist_ok=True)
    conn = sqlite3.connect(DATABASE_PATH)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """
    )
    conn.commit()
    conn.close()


def get_notes():
    """Get all notes from database"""
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    notes = conn.execute("SELECT * FROM notes ORDER BY timestamp DESC").fetchall()
    conn.close()
    return notes


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        note_content = request.form["note"].strip()

        if note_content:
            # Save note to database
            conn = sqlite3.connect(DATABASE_PATH)
            conn.execute("INSERT INTO notes (content) VALUES (?)", (note_content,))
            conn.commit()
            conn.close()

            return redirect(url_for("index"))

    # Get all notes for display
    notes = get_notes()
    return render_template_string(HTML_TEMPLATE, notes=notes)


@app.route("/health")
def health():
    """Health check endpoint"""
    return {"status": "healthy"}, 200


if __name__ == "__main__":
    # Initialize database
    init_database()

    # Run the application
    print(f"Starting Note-Taking App on port {PORT}")
    app.run(host="0.0.0.0", port=PORT, debug=False)
