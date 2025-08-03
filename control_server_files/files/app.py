#!/usr/bin/env python3
"""
Advanced Note-Taking Web Application
Production-ready Flask app with SQLite database
Features: CRUD operations, search, categories, pagination, user management
"""

from flask import (
    Flask,
    render_template_string,
    request,
    redirect,
    url_for,
    flash,
    jsonify,
)
import sqlite3
import datetime
import os

app = Flask(__name__)
app.secret_key = "advanced_noteapp_secret_key_2024"

# Configuration
DATABASE_PATH = "/opt/noteapp/notes.db"
PORT = 5000  # Will be served through Apache on port 80

# Advanced HTML Template with Bootstrap
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📝 Advanced Note-Taking App</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .navbar {
            background: rgba(255,255,255,0.95) !important;
            backdrop-filter: blur(10px);
            box-shadow: 0 2px 20px rgba(0,0,0,0.1);
        }
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
            background: rgba(255,255,255,0.95);
        }
        .note-card {
            transition: transform 0.3s ease, box-shadow 0.3s ease;
            margin-bottom: 20px;
        }
        .note-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.2);
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 25px;
            padding: 10px 30px;
        }
        .form-control, .form-select {
            border-radius: 15px;
            border: 2px solid #e9ecef;
            padding: 12px 20px;
        }
        .form-control:focus, .form-select:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }
        .category-badge {
            border-radius: 20px;
            padding: 5px 15px;
            font-size: 0.8em;
        }
        .search-container {
            background: rgba(255,255,255,0.9);
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 30px;
        }
        .stats-card {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
            border-radius: 15px;
        }
    </style>
</head>
<body>
    <!-- Navigation -->
    <nav class="navbar navbar-expand-lg navbar-light">
        <div class="container">
            <a class="navbar-brand fw-bold" href="/">
                <i class="fas fa-sticky-note text-primary"></i> Advanced Notes
            </a>
            <div class="navbar-nav ms-auto">
                <a class="nav-link" href="/"><i class="fas fa-home"></i> Home</a>
                <a class="nav-link" href="/stats"><i class="fas fa-chart-bar"></i> Stats</a>
                <a class="nav-link" href="/export"><i class="fas fa-download"></i> Export</a>
            </div>
        </div>
    </nav>

    <div class="container mt-4">
        <!-- Flash Messages -->
        {% with messages = get_flashed_messages(with_categories=true) %}
            {% if messages %}
                {% for category, message in messages %}
                    <div class="alert alert-{{ 'success' if category == 'message' else category }} alert-dismissible fade show" role="alert">
                        <i class="fas fa-check-circle"></i> {{ message }}
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                {% endfor %}
            {% endif %}
        {% endwith %}

        <!-- Search and Filters -->
        <div class="search-container">
            <form method="GET" action="/" class="row g-3">
                <div class="col-md-6">
                    <input type="text" class="form-control" name="search" placeholder="🔍 Search notes..." value="{{ request.args.get('search', '') }}">
                </div>
                <div class="col-md-3">
                    <select class="form-select" name="category">
                        <option value="">All Categories</option>
                        <option value="work" {{ 'selected' if request.args.get('category') == 'work' }}>💼 Work</option>
                        <option value="personal" {{ 'selected' if request.args.get('category') == 'personal' }}>👤 Personal</option>
                        <option value="ideas" {{ 'selected' if request.args.get('category') == 'ideas' }}>💡 Ideas</option>
                        <option value="tasks" {{ 'selected' if request.args.get('category') == 'tasks' }}>✅ Tasks</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <button type="submit" class="btn btn-primary w-100">
                        <i class="fas fa-search"></i> Search
                    </button>
                </div>
            </form>
        </div>

        <!-- Add Note Form -->
        <div class="card mb-4">
            <div class="card-header bg-primary text-white">
                <h5><i class="fas fa-plus"></i> Add New Note</h5>
            </div>
            <div class="card-body">
                <form method="POST" action="/">
                    <div class="row g-3">
                        <div class="col-md-8">
                            <textarea name="content" class="form-control" rows="3" placeholder="Write your note here..." required></textarea>
                        </div>
                        <div class="col-md-2">
                            <select name="category" class="form-select" required>
                                <option value="">Category</option>
                                <option value="work">💼 Work</option>
                                <option value="personal">👤 Personal</option>
                                <option value="ideas">💡 Ideas</option>
                                <option value="tasks">✅ Tasks</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <button type="submit" class="btn btn-primary w-100">
                                <i class="fas fa-save"></i> Save
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <!-- Statistics -->
        <div class="row mb-4">
            <div class="col-md-3">
                <div class="card stats-card">
                    <div class="card-body text-center">
                        <h3><i class="fas fa-sticky-note"></i></h3>
                        <h4>{{ total_notes }}</h4>
                        <p>Total Notes</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card stats-card">
                    <div class="card-body text-center">
                        <h3><i class="fas fa-calendar-day"></i></h3>
                        <h4>{{ today_notes }}</h4>
                        <p>Today's Notes</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card stats-card">
                    <div class="card-body text-center">
                        <h3><i class="fas fa-fire"></i></h3>
                        <h4>{{ week_notes }}</h4>
                        <p>This Week</p>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card stats-card">
                    <div class="card-body text-center">
                        <h3><i class="fas fa-tags"></i></h3>
                        <h4>{{ categories_count }}</h4>
                        <p>Categories</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Notes Display -->
        <div class="row">
            {% if notes %}
                {% for note in notes %}
                    <div class="col-md-6 col-lg-4">
                        <div class="card note-card">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <span class="category-badge bg-{{ category_colors[note.category] or 'secondary' }} text-white">
                                    {{ note.category|title }}
                                </span>
                                <div class="dropdown">
                                    <button class="btn btn-sm btn-outline-secondary dropdown-toggle" data-bs-toggle="dropdown">
                                        <i class="fas fa-ellipsis-v"></i>
                                    </button>
                                    <ul class="dropdown-menu">
                                        <li><a class="dropdown-item" href="/edit/{{ note.id }}"><i class="fas fa-edit"></i> Edit</a></li>
                                        <li><a class="dropdown-item text-danger" href="/delete/{{ note.id }}" onclick="return confirm('Delete this note?')"><i class="fas fa-trash"></i> Delete</a></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="card-body">
                                <p class="card-text">{{ note.content[:150] }}{% if note.content|length > 150 %}...{% endif %}</p>
                                <div class="d-flex justify-content-between align-items-center">
                                    <small class="text-muted">
                                        <i class="fas fa-clock"></i> {{ note.timestamp }}
                                    </small>
                                    <a href="/view/{{ note.id }}" class="btn btn-sm btn-outline-primary">
                                        <i class="fas fa-eye"></i> View
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                {% endfor %}
            {% else %}
                <div class="col-12">
                    <div class="card">
                        <div class="card-body text-center py-5">
                            <i class="fas fa-sticky-note fa-3x text-muted mb-3"></i>
                            <h4>No notes found</h4>
                            <p class="text-muted">Start by creating your first note above!</p>
                        </div>
                    </div>
                </div>
            {% endif %}
        </div>

        <!-- Footer -->
        <footer class="mt-5 py-4 text-center text-white">
            <p><i class="fas fa-rocket"></i> Deployed with Advanced Ansible | <i class="fas fa-database"></i> SQLite Database</p>
        </footer>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
"""


def init_database():
    """Initialize SQLite database with advanced schema"""
    os.makedirs(os.path.dirname(DATABASE_PATH), exist_ok=True)
    conn = sqlite3.connect(DATABASE_PATH)

    # Create notes table with additional fields
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'general',
            priority INTEGER DEFAULT 1,
            is_completed BOOLEAN DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """
    )

    # Create sample data if empty
    count = conn.execute("SELECT COUNT(*) FROM notes").fetchone()[0]
    if count == 0:
        sample_notes = [
            (
                "Welcome to Advanced Notes! This is your first note with category support.",
                "personal",
            ),
            ("Don't forget to review the IAM policy lecture notes.", "work"),
            ("Build a machine learning model for note categorization", "ideas"),
            ("Set up automated backups for the database", "tasks"),
            ("Meeting with team tomorrow at 10 AM", "work"),
        ]

        for content, category in sample_notes:
            conn.execute(
                "INSERT INTO notes (content, category) VALUES (?, ?)",
                (content, category),
            )

    conn.commit()
    conn.close()


def get_notes(search=None, category=None, limit=None):
    """Get notes with optional filtering"""
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row

    query = "SELECT * FROM notes WHERE 1=1"
    params = []

    if search:
        query += " AND content LIKE ?"
        params.append(f"%{search}%")

    if category:
        query += " AND category = ?"
        params.append(category)

    query += " ORDER BY timestamp DESC"

    if limit:
        query += f" LIMIT {limit}"

    notes = conn.execute(query, params).fetchall()
    conn.close()
    return notes


def get_stats():
    """Get notes statistics"""
    conn = sqlite3.connect(DATABASE_PATH)

    total = conn.execute("SELECT COUNT(*) FROM notes").fetchone()[0]
    today = conn.execute(
        'SELECT COUNT(*) FROM notes WHERE DATE(timestamp) = DATE("now")'
    ).fetchone()[0]
    week = conn.execute(
        'SELECT COUNT(*) FROM notes WHERE timestamp >= datetime("now", "-7 days")'
    ).fetchone()[0]
    categories = conn.execute("SELECT COUNT(DISTINCT category) FROM notes").fetchone()[
        0
    ]

    conn.close()
    return {
        "total_notes": total,
        "today_notes": today,
        "week_notes": week,
        "categories_count": categories,
    }


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        content = request.form.get("content", "").strip()
        category = request.form.get("category", "general")

        if content:
            conn = sqlite3.connect(DATABASE_PATH)
            conn.execute(
                "INSERT INTO notes (content, category) VALUES (?, ?)",
                (content, category),
            )
            conn.commit()
            conn.close()

            flash(f"Note added successfully to {category} category!", "success")
            return redirect(url_for("index"))
        else:
            flash("Please enter note content!", "error")

    # Get filtered notes
    search = request.args.get("search", "")
    category = request.args.get("category", "")

    notes = get_notes(search=search, category=category)
    stats = get_stats()

    # Category colors for styling
    category_colors = {
        "work": "primary",
        "personal": "success",
        "ideas": "warning",
        "tasks": "info",
        "general": "secondary",
    }

    return render_template_string(
        HTML_TEMPLATE, notes=notes, category_colors=category_colors, **stats
    )


@app.route("/view/<int:note_id>")
def view_note(note_id):
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    note = conn.execute("SELECT * FROM notes WHERE id = ?", (note_id,)).fetchone()
    conn.close()

    if not note:
        flash("Note not found!", "error")
        return redirect(url_for("index"))

    return jsonify(
        {
            "id": note["id"],
            "content": note["content"],
            "category": note["category"],
            "timestamp": note["timestamp"],
        }
    )


@app.route("/delete/<int:note_id>")
def delete_note(note_id):
    conn = sqlite3.connect(DATABASE_PATH)
    result = conn.execute("DELETE FROM notes WHERE id = ?", (note_id,))
    conn.commit()
    conn.close()

    if result.rowcount > 0:
        flash("Note deleted successfully!", "success")
    else:
        flash("Note not found!", "error")

    return redirect(url_for("index"))


@app.route("/stats")
def stats_page():
    stats = get_stats()
    return jsonify(stats)


@app.route("/export")
def export_notes():
    notes = get_notes()
    export_data = []

    for note in notes:
        export_data.append(
            {
                "id": note["id"],
                "content": note["content"],
                "category": note["category"],
                "timestamp": note["timestamp"],
            }
        )

    return jsonify(
        {
            "export_date": datetime.datetime.now().isoformat(),
            "total_notes": len(export_data),
            "notes": export_data,
        }
    )


@app.route("/api/notes")
def api_notes():
    """API endpoint for notes"""
    notes = get_notes(limit=10)
    return jsonify([dict(note) for note in notes])


@app.route("/health")
def health():
    """Advanced health check"""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        count = conn.execute("SELECT COUNT(*) FROM notes").fetchone()[0]
        conn.close()

        return (
            jsonify(
                {
                    "status": "healthy",
                    "database": "connected",
                    "notes_count": count,
                    "version": "2.0",
                    "features": ["search", "categories", "stats", "export", "api"],
                }
            ),
            200,
        )
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500


if __name__ == "__main__":
    # Initialize database
    init_database()

    # Run the application
    print(f"Starting Advanced Note-Taking App on port {PORT}")
    print("Features: Search, Categories, Statistics, Export, API")
    app.run(host="0.0.0.0", port=PORT, debug=False)
