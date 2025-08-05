#!/usr/bin/env python3

from flask import Flask, render_template_string, request, jsonify
import sqlite3
from datetime import datetime
import os

# Try to load environment variables from .env file
try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    print("⚠️  python-dotenv not installed. Using default environment variables.")

app = Flask(__name__)
app.secret_key = "simple_notes_secret_key_2024"

# Database configuration for SQLite
DATABASE_PATH = os.getenv("DB_PATH", "notes.db")


# Database connection helper
def get_db_connection():
    """Get database connection"""
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error as err:
        print(f"Database connection error: {err}")
        return None


# Initialize database
def init_database():
    """Initialize SQLite database with notes table"""
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS notes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL,
                    author TEXT NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """
            )
            conn.commit()
            print("✅ Database initialized successfully!")
        except sqlite3.Error as err:
            print(f"Database initialization error: {err}")
        finally:
            conn.close()
    else:
        print("❌ Failed to initialize database!")


# HTML Template with embedded CSS and JavaScript
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🗒️ Simple Note App - Interactive</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0a0a0a 0%, #1a1a1a 25%, #000000 50%, #1a1a1a 75%, #0a0a0a 100%);
            background-size: 400% 400%;
            animation: gradientShift 15s ease infinite;
            min-height: 100vh;
            color: #ffffff;
            overflow-x: hidden;
        }

        @keyframes gradientShift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }

        /* Interactive background canvas */
        #backgroundCanvas {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            pointer-events: auto;
            z-index: 0;
            cursor: crosshair;
        }

        /* Interactive background info */
        .background-info {
            position: fixed;
            bottom: 10px;
            left: 10px;
            color: rgba(255, 255, 255, 0.3);
            font-size: 12px;
            pointer-events: none;
            z-index: 200;
        }



        .btn {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 14px 28px;
            border-radius: 30px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 600;
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            box-shadow: 
                0 6px 20px rgba(102, 126, 234, 0.4),
                inset 0 1px 0 rgba(255, 255, 255, 0.2);
            text-decoration: none;
            display: inline-block;
            position: relative;
            overflow: hidden;
        }

        .btn::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
            transition: left 0.6s ease;
        }

        .btn:hover::before {
            left: 100%;
        }

        .btn:hover {
            transform: translateY(-3px) scale(1.05);
            box-shadow: 
                0 10px 35px rgba(102, 126, 234, 0.6),
                inset 0 1px 0 rgba(255, 255, 255, 0.3);
            background: linear-gradient(135deg, #764ba2, #667eea);
        }

        .btn-danger {
            background: linear-gradient(135deg, #ff6b6b, #ee5a24);
            box-shadow: 
                0 6px 20px rgba(255, 107, 107, 0.4),
                inset 0 1px 0 rgba(255, 255, 255, 0.2);
        }

        .btn-danger:hover {
            background: linear-gradient(135deg, #ee5a24, #ff6b6b);
            box-shadow: 
                0 10px 35px rgba(255, 107, 107, 0.6),
                inset 0 1px 0 rgba(255, 255, 255, 0.3);
        }

        .container {
            padding: 20px;
            max-width: 100vw;
            min-height: 100vh;
            position: relative;
        }

        .note-card {
            background: linear-gradient(145deg, 
                rgba(255, 255, 255, 0.1), 
                rgba(255, 255, 255, 0.05),
                rgba(255, 255, 255, 0.02)
            );
            border-radius: 20px;
            padding: 25px;
            margin: 15px;
            box-shadow: 
                0 8px 32px rgba(0, 0, 0, 0.6),
                inset 0 1px 1px rgba(255, 255, 255, 0.3),
                inset 0 -1px 1px rgba(0, 0, 0, 0.1),
                0 0 20px rgba(102, 126, 234, 0.3);
            backdrop-filter: blur(25px) saturate(180%);
            -webkit-backdrop-filter: blur(25px) saturate(180%);
            border: 1px solid rgba(255, 255, 255, 0.18);
            border-top: 1px solid rgba(255, 255, 255, 0.4);
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            position: absolute;
            cursor: move;
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275), 
                        z-index 0s, transform 0.2s ease;
            min-width: 300px;
            max-width: 380px;
            word-wrap: break-word;
            user-select: none;
            color: #ffffff;
            overflow: hidden;
            z-index: 100;
        }

        .note-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(135deg, 
                rgba(255, 255, 255, 0.3) 0%, 
                rgba(255, 255, 255, 0.1) 20%, 
                transparent 40%, 
                transparent 60%, 
                rgba(102, 126, 234, 0.05) 80%, 
                rgba(102, 126, 234, 0.1) 100%
            );
            opacity: 0;
            transition: opacity 0.3s ease;
            pointer-events: none;
            border-radius: 20px;
        }

        .note-card:hover {
            transform: translateY(-10px) scale(1.02);
            box-shadow: 
                0 20px 60px rgba(0, 0, 0, 0.8),
                inset 0 1px 2px rgba(255, 255, 255, 0.4),
                inset 0 -1px 2px rgba(0, 0, 0, 0.15),
                0 0 40px rgba(102, 126, 234, 0.6);
            border: 1px solid rgba(255, 255, 255, 0.3);
            border-top: 1px solid rgba(255, 255, 255, 0.6);
            border-bottom: 1px solid rgba(255, 255, 255, 0.15);
            background: linear-gradient(145deg, 
                rgba(255, 255, 255, 0.15), 
                rgba(255, 255, 255, 0.08),
                rgba(255, 255, 255, 0.04)
            );
        }

        .note-card:hover::before {
            opacity: 1;
        }

        .note-card.dragging {
            transform: rotate(8deg) scale(1.08);
            box-shadow: 
                0 25px 80px rgba(0, 0, 0, 0.9),
                inset 0 2px 4px rgba(255, 255, 255, 0.5),
                inset 0 -2px 4px rgba(0, 0, 0, 0.2),
                0 0 60px rgba(102, 126, 234, 0.8);
            z-index: 1000;
            border: 2px solid rgba(255, 255, 255, 0.4);
            border-top: 2px solid rgba(255, 255, 255, 0.7);
            border-bottom: 2px solid rgba(255, 255, 255, 0.2);
            background: linear-gradient(145deg, 
                rgba(255, 255, 255, 0.2), 
                rgba(255, 255, 255, 0.1),
                rgba(255, 255, 255, 0.05)
            );
            animation: pulse-glow 0.8s ease-in-out;
        }

        @keyframes pulse-glow {
            0%, 100% {
                box-shadow: 
                    0 25px 80px rgba(0, 0, 0, 0.9),
                    0 0 60px rgba(102, 126, 234, 0.8);
            }
            50% {
                box-shadow: 
                    0 25px 80px rgba(0, 0, 0, 0.9),
                    0 0 80px rgba(102, 126, 234, 1);
            }
        }

        .note-card:active {
            transform: scale(0.98);
            transition: transform 0.1s ease;
        }

        .note-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 20px;
            border-bottom: 2px solid rgba(102, 126, 234, 0.3);
            padding-bottom: 15px;
            position: relative;
        }

        .note-header::after {
            content: '';
            position: absolute;
            bottom: -2px;
            left: 0;
            width: 0;
            height: 2px;
            background: linear-gradient(90deg, #667eea, #764ba2);
            transition: width 0.3s ease;
        }

        .note-card:hover .note-header::after {
            width: 100%;
        }

        .note-title {
            font-size: 1.4em;
            font-weight: bold;
            background: linear-gradient(135deg, #667eea, #764ba2);
            background-clip: text;
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            color: #667eea;
            margin-bottom: 8px;
            line-height: 1.2;
            text-shadow: 0 0 10px rgba(102, 126, 234, 0.3);
        }

        .note-author {
            font-size: 0.95em;
            color: #bbbbbb;
            font-style: italic;
            opacity: 0.8;
            transition: opacity 0.3s ease;
        }

        .note-card:hover .note-author {
            opacity: 1;
            color: #dddddd;
        }

        .note-date {
            font-size: 0.85em;
            color: #999999;
            text-align: right;
            opacity: 0.7;
            transition: all 0.3s ease;
        }

        .note-card:hover .note-date {
            opacity: 1;
            color: #bbbbbb;
        }

        .note-content {
            color: #e0e0e0;
            line-height: 1.7;
            margin: 20px 0;
            white-space: pre-wrap;
            transition: color 0.3s ease;
        }

        .note-card:hover .note-content {
            color: #ffffff;
        }

        .note-actions {
            display: flex;
            gap: 12px;
            justify-content: flex-end;
            margin-top: 20px;
            border-top: 1px solid rgba(102, 126, 234, 0.2);
            padding-top: 15px;
            opacity: 0;
            transform: translateY(10px);
            transition: all 0.3s ease;
        }

        .note-card:hover .note-actions {
            opacity: 1;
            transform: translateY(0);
        }

        .btn-small {
            padding: 8px 16px;
            font-size: 12px;
            border-radius: 20px;
            background: linear-gradient(135deg, #667eea, #764ba2);
            border: none;
            color: white;
            cursor: pointer;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .btn-small::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
            transition: left 0.5s ease;
        }

        .btn-small:hover::before {
            left: 100%;
        }

        .btn-small:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }

        .modal {
            display: none;
            position: fixed;
            z-index: 3000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.8);
            backdrop-filter: blur(10px);
        }

        .modal-content {
            background: linear-gradient(145deg, 
                rgba(255, 255, 255, 0.12), 
                rgba(255, 255, 255, 0.08),
                rgba(255, 255, 255, 0.04)
            );
            margin: 5% auto;
            padding: 40px;
            border-radius: 25px;
            width: 90%;
            max-width: 550px;
            box-shadow: 
                0 25px 80px rgba(0, 0, 0, 0.8),
                inset 0 1px 2px rgba(255, 255, 255, 0.3),
                inset 0 -1px 2px rgba(0, 0, 0, 0.1),
                0 0 40px rgba(102, 126, 234, 0.4);
            backdrop-filter: blur(30px) saturate(180%);
            -webkit-backdrop-filter: blur(30px) saturate(180%);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-top: 1px solid rgba(255, 255, 255, 0.5);
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            animation: modalSlideIn 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            color: #ffffff;
        }

        @keyframes modalSlideIn {
            from { transform: translateY(-50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 10px;
            font-weight: 600;
            background: linear-gradient(135deg, #667eea, #764ba2);
            background-clip: text;
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            color: #667eea;
        }

        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 15px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-top: 1px solid rgba(255, 255, 255, 0.4);
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            font-size: 14px;
            background: linear-gradient(145deg, 
                rgba(255, 255, 255, 0.08), 
                rgba(255, 255, 255, 0.04),
                rgba(255, 255, 255, 0.02)
            );
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            color: #ffffff;
            transition: all 0.3s ease;
        }

        .form-group input::placeholder,
        .form-group textarea::placeholder {
            color: rgba(255, 255, 255, 0.5);
        }

        .form-group input:focus,
        .form-group textarea:focus {
            outline: none;
            border: 1px solid rgba(255, 255, 255, 0.4);
            border-top: 1px solid rgba(255, 255, 255, 0.6);
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 
                0 0 20px rgba(102, 126, 234, 0.4),
                inset 0 1px 2px rgba(255, 255, 255, 0.2),
                inset 0 -1px 2px rgba(0, 0, 0, 0.1);
            background: linear-gradient(145deg, 
                rgba(255, 255, 255, 0.12), 
                rgba(255, 255, 255, 0.06),
                rgba(255, 255, 255, 0.03)
            );
        }

        .form-group textarea {
            resize: vertical;
            min-height: 120px;
        }



        .no-notes {
            text-align: center;
            color: rgba(255, 255, 255, 0.7);
            font-size: 1.8em;
            margin-top: 150px;
            text-shadow: 0 0 20px rgba(102, 126, 234, 0.5);
            animation: pulse 2s ease-in-out infinite alternate;
        }

        @keyframes pulse {
            from { opacity: 0.7; }
            to { opacity: 1; }
        }

        .floating-btn {
            position: fixed;
            bottom: 30px;
            right: 30px;
            width: 70px;
            height: 70px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            font-size: 28px;
            cursor: pointer;
            box-shadow: 
                0 10px 30px rgba(0, 0, 0, 0.6),
                0 0 20px rgba(102, 126, 234, 0.4);
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            z-index: 200;
            animation: float 3s ease-in-out infinite;
        }

        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-10px); }
        }

        /* Top note card highlight */
        .note-card.top-card {
            box-shadow: 
                0 8px 32px rgba(0, 0, 0, 0.6),
                inset 0 1px 1px rgba(255, 255, 255, 0.4),
                inset 0 -1px 1px rgba(0, 0, 0, 0.1),
                0 0 30px rgba(102, 126, 234, 0.5),
                0 0 60px rgba(102, 126, 234, 0.2);
            border: 1px solid rgba(255, 255, 255, 0.25);
            border-top: 1px solid rgba(255, 255, 255, 0.5);
        }

        .floating-btn:hover {
            transform: scale(1.15) translateY(-5px);
            box-shadow: 
                0 15px 40px rgba(0, 0, 0, 0.8),
                0 0 30px rgba(102, 126, 234, 0.6);
            background: linear-gradient(135deg, #764ba2, #667eea);
        }

        .floating-btn:active {
            transform: scale(0.95);
        }

        @media (max-width: 768px) {
            .note-card {
                min-width: 250px;
                max-width: 300px;
                margin: 10px;
            }
        }
    </style>
</head>
<body>

    <!-- Interactive background canvas -->
    <canvas id="backgroundCanvas"></canvas>
  
    <div class="container" id="notesContainer">
        <!-- Notes will be loaded here -->
    </div>

    <div class="background-info">
        Click on empty space to create polygons! 🔮
    </div>

    <button class="floating-btn" onclick="showAddModal()" title="Add New Note">+</button>

    <!-- Add/Edit Note Modal -->
    <div id="noteModal" class="modal">
        <div class="modal-content">
            <h2 id="modalTitle" style="background: linear-gradient(135deg, #667eea, #764ba2); background-clip: text; -webkit-background-clip: text; -webkit-text-fill-color: transparent; color: #667eea; margin-bottom: 25px;">➕ Add New Note</h2>
            <form id="noteForm">
                <input type="hidden" id="noteId" value="">
                <div class="form-group">
                    <label for="title">📌 Title:</label>
                    <input type="text" id="title" name="title" required maxlength="255">
                </div>
                <div class="form-group">
                    <label for="author">👤 Author:</label>
                    <input type="text" id="author" name="author" required maxlength="100">
                </div>
                <div class="form-group">
                    <label for="content">📄 Content:</label>
                    <textarea id="content" name="content" required placeholder="Write your note content here..."></textarea>
                </div>
                <div style="text-align: right; margin-top: 25px;">
                    <button type="button" class="btn btn-danger" onclick="closeModal()">❌ Cancel</button>
                    <button type="submit" class="btn">💾 Save Note</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        let notes = [];
        let isDragging = false;
        let currentNote = null;
        let offset = { x: 0, y: 0 };

        // Interactive background system
        let canvas, ctx;
        let nodes = [];
        let polygons = [];
        let mouse = { x: 0, y: 0 };
        let animationId;

        // Z-index management for note cards
        let highestZIndex = 100;

        // Load notes on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadNotes();
            initInteractiveBackground();
        });

        // Initialize interactive background
        function initInteractiveBackground() {
            canvas = document.getElementById('backgroundCanvas');
            if (!canvas) {
                console.error('Canvas not found!');
                return;
            }
            
            ctx = canvas.getContext('2d');
            if (!ctx) {
                console.error('Could not get canvas context!');
                return;
            }
            
            resizeCanvas();
            createNodes();
            animate();
            
            // Event listeners
            window.addEventListener('resize', resizeCanvas);
            canvas.addEventListener('mousemove', updateMouse);
            canvas.addEventListener('click', createPolygonOnClick);
            
            // Also listen on document for backup
            document.addEventListener('mousemove', updateMouseGlobal);
            document.addEventListener('click', handleGlobalClick);
            
            console.log('Interactive background initialized!');
        }

        // Global mouse tracking as backup
        function updateMouseGlobal(e) {
            mouse.x = e.clientX;
            mouse.y = e.clientY;
        }

        // Handle clicks on the document
        function handleGlobalClick(e) {
            // Only handle if clicking on the background (not on UI elements)
            const elementUnderMouse = document.elementFromPoint(e.clientX, e.clientY);
            if (elementUnderMouse && elementUnderMouse.id === 'backgroundCanvas') {
                createPolygonOnClick(e);
            }
        }

        // Resize canvas to fill window
        function resizeCanvas() {
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;
        }

        // Update mouse position
        function updateMouse(e) {
            mouse.x = e.clientX;
            mouse.y = e.clientY;
            
            // Visual feedback - change cursor style based on nearby nodes
            const nearbyNodes = nodes.filter(node => {
                const dx = node.x - mouse.x;
                const dy = node.y - mouse.y;
                return Math.sqrt(dx * dx + dy * dy) < 150;
            });
            
            if (nearbyNodes.length >= 3) {
                canvas.style.cursor = 'pointer';
            } else {
                canvas.style.cursor = 'crosshair';
            }
        }

        // Create floating nodes
        function createNodes() {
            const nodeCount = Math.floor((window.innerWidth * window.innerHeight) / 15000);
            nodes = [];
            
            for (let i = 0; i < nodeCount; i++) {
                nodes.push({
                    x: Math.random() * canvas.width,
                    y: Math.random() * canvas.height,
                    vx: (Math.random() - 0.5) * 0.5,
                    vy: (Math.random() - 0.5) * 0.5,
                    radius: Math.random() * 2 + 1,
                    originalRadius: Math.random() * 2 + 1,
                    opacity: Math.random() * 0.5 + 0.3
                });
            }
        }

        // Create polygon on mouse click
        function createPolygonOnClick(e) {
            // Don't create polygons if clicking on a note card or modal
            const elementUnderMouse = document.elementFromPoint(e.clientX, e.clientY);
            if (elementUnderMouse && (
                elementUnderMouse.closest('.note-card') || 
                elementUnderMouse.closest('.modal') ||
                elementUnderMouse.closest('.floating-btn')
            )) {
                return;
            }

            const clickRadius = 150;
            const nearbyNodes = nodes.filter(node => {
                const dx = node.x - mouse.x;
                const dy = node.y - mouse.y;
                return Math.sqrt(dx * dx + dy * dy) < clickRadius;
            });

            if (nearbyNodes.length >= 3) {
                // Sort nodes by angle from click point to create a proper polygon
                nearbyNodes.sort((a, b) => {
                    const angleA = Math.atan2(a.y - mouse.y, a.x - mouse.x);
                    const angleB = Math.atan2(b.y - mouse.y, b.x - mouse.x);
                    return angleA - angleB;
                });

                const polygon = {
                    nodes: nearbyNodes.slice(0, Math.min(8, nearbyNodes.length)),
                    life: 120,
                    maxLife: 120,
                    pulsePhase: 0
                };
                
                polygons.push(polygon);
                
                // Create ripple effect
                createRipple(mouse.x, mouse.y);
                
                // Add screen shake effect
                document.body.style.animation = 'shake 0.3s ease-in-out';
                setTimeout(() => {
                    document.body.style.animation = '';
                }, 300);
                
                // Visual feedback
                console.log(`Polygon created with ${polygon.nodes.length} nodes!`);
                
                // Create multiple ripples for better effect
                setTimeout(() => createRipple(mouse.x, mouse.y), 200);
                setTimeout(() => createRipple(mouse.x, mouse.y), 400);
            }
        }

        // Add shake animation
        const shakeStyle = document.createElement('style');
        shakeStyle.textContent = `
            @keyframes shake {
                0%, 100% { transform: translateX(0); }
                25% { transform: translateX(-2px); }
                75% { transform: translateX(2px); }
            }
        `;
        document.head.appendChild(shakeStyle);

        // Create ripple effect
        function createRipple(x, y) {
            const ripple = {
                x: x,
                y: y,
                radius: 0,
                maxRadius: 200,
                life: 60,
                maxLife: 60
            };
            
            const animateRipple = () => {
                ripple.life--;
                ripple.radius += 4;
                
                if (ripple.life > 0) {
                    requestAnimationFrame(animateRipple);
                }
            };
            
            animateRipple();
            polygons.push(ripple);
        }

        // Animation loop
        function animate() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            
            // Update and draw nodes
            updateNodes();
            drawNodes();
            drawConnections();
            
            // Update and draw polygons
            updatePolygons();
            drawPolygons();
            
            // Draw mouse connections
            drawMouseConnections();
            
            animationId = requestAnimationFrame(animate);
        }

        // Update node positions
        function updateNodes() {
            nodes.forEach(node => {
                // Move nodes
                node.x += node.vx;
                node.y += node.vy;
                
                // Bounce off edges
                if (node.x < 0 || node.x > canvas.width) node.vx *= -1;
                if (node.y < 0 || node.y > canvas.height) node.vy *= -1;
                
                // Keep nodes in bounds
                node.x = Math.max(0, Math.min(canvas.width, node.x));
                node.y = Math.max(0, Math.min(canvas.height, node.y));
                
                // Mouse attraction effect
                const dx = mouse.x - node.x;
                const dy = mouse.y - node.y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                if (distance < 100) {
                    const force = (100 - distance) / 100;
                    node.radius = node.originalRadius * (1 + force);
                    node.opacity = Math.min(1, node.opacity + force * 0.3);
                } else {
                    node.radius = node.originalRadius;
                    node.opacity = Math.max(0.3, node.opacity - 0.02);
                }
            });
        }

        // Draw nodes
        function drawNodes() {
            nodes.forEach(node => {
                ctx.beginPath();
                ctx.arc(node.x, node.y, node.radius, 0, Math.PI * 2);
                ctx.fillStyle = `rgba(102, 126, 234, ${node.opacity})`;
                ctx.fill();
                
                // Add glow effect
                ctx.beginPath();
                ctx.arc(node.x, node.y, node.radius * 2, 0, Math.PI * 2);
                ctx.fillStyle = `rgba(102, 126, 234, ${node.opacity * 0.2})`;
                ctx.fill();
            });
        }

        // Draw connections between nearby nodes
        function drawConnections() {
            const maxDistance = 120;
            
            for (let i = 0; i < nodes.length; i++) {
                for (let j = i + 1; j < nodes.length; j++) {
                    const dx = nodes[i].x - nodes[j].x;
                    const dy = nodes[i].y - nodes[j].y;
                    const distance = Math.sqrt(dx * dx + dy * dy);
                    
                    if (distance < maxDistance) {
                        const opacity = (1 - distance / maxDistance) * 0.3;
                        
                        ctx.beginPath();
                        ctx.moveTo(nodes[i].x, nodes[i].y);
                        ctx.lineTo(nodes[j].x, nodes[j].y);
                        ctx.strokeStyle = `rgba(102, 126, 234, ${opacity})`;
                        ctx.lineWidth = 1;
                        ctx.stroke();
                    }
                }
            }
        }

        // Draw mouse connections
        function drawMouseConnections() {
            const maxDistance = 150;
            
            nodes.forEach(node => {
                const dx = mouse.x - node.x;
                const dy = mouse.y - node.y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                if (distance < maxDistance) {
                    const opacity = (1 - distance / maxDistance) * 0.5;
                    
                    ctx.beginPath();
                    ctx.moveTo(mouse.x, mouse.y);
                    ctx.lineTo(node.x, node.y);
                    ctx.strokeStyle = `rgba(118, 75, 162, ${opacity})`;
                    ctx.lineWidth = 2;
                    ctx.stroke();
                }
            });
        }

        // Update polygons
        function updatePolygons() {
            for (let i = polygons.length - 1; i >= 0; i--) {
                const polygon = polygons[i];
                polygon.life--;
                polygon.pulsePhase += 0.1;
                
                if (polygon.life <= 0) {
                    polygons.splice(i, 1);
                }
            }
        }

        // Draw polygons
        function drawPolygons() {
            polygons.forEach(polygon => {
                if (polygon.maxRadius) {
                    // Draw ripple effect
                    const progress = 1 - polygon.life / polygon.maxLife;
                    const opacity = polygon.life / polygon.maxLife;
                    
                    ctx.beginPath();
                    ctx.arc(polygon.x, polygon.y, polygon.radius, 0, Math.PI * 2);
                    ctx.strokeStyle = `rgba(102, 126, 234, ${opacity * 0.8})`;
                    ctx.lineWidth = 3;
                    ctx.stroke();
                    
                    ctx.beginPath();
                    ctx.arc(polygon.x, polygon.y, polygon.radius * 0.7, 0, Math.PI * 2);
                    ctx.strokeStyle = `rgba(118, 75, 162, ${opacity * 0.6})`;
                    ctx.lineWidth = 2;
                    ctx.stroke();
                } else if (polygon.nodes) {
                    // Draw polygon
                    const opacity = polygon.life / polygon.maxLife;
                    const pulse = Math.sin(polygon.pulsePhase) * 0.3 + 0.7;
                    
                    // Fill polygon
                    ctx.beginPath();
                    ctx.moveTo(polygon.nodes[0].x, polygon.nodes[0].y);
                    for (let i = 1; i < polygon.nodes.length; i++) {
                        ctx.lineTo(polygon.nodes[i].x, polygon.nodes[i].y);
                    }
                    ctx.closePath();
                    ctx.fillStyle = `rgba(102, 126, 234, ${opacity * 0.1 * pulse})`;
                    ctx.fill();
                    
                    // Draw polygon outline
                    ctx.strokeStyle = `rgba(102, 126, 234, ${opacity * 0.6 * pulse})`;
                    ctx.lineWidth = 2;
                    ctx.stroke();
                    
                    // Draw connecting lines to center
                    const centerX = polygon.nodes.reduce((sum, node) => sum + node.x, 0) / polygon.nodes.length;
                    const centerY = polygon.nodes.reduce((sum, node) => sum + node.y, 0) / polygon.nodes.length;
                    
                    polygon.nodes.forEach(node => {
                        ctx.beginPath();
                        ctx.moveTo(centerX, centerY);
                        ctx.lineTo(node.x, node.y);
                        ctx.strokeStyle = `rgba(118, 75, 162, ${opacity * 0.4 * pulse})`;
                        ctx.lineWidth = 1;
                        ctx.stroke();
                    });
                    
                    // Draw center point
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, 4 * pulse, 0, Math.PI * 2);
                    ctx.fillStyle = `rgba(118, 75, 162, ${opacity * pulse})`;
                    ctx.fill();
                }
            });
        }

        // Load all notes from server
        async function loadNotes() {
            try {
                const response = await fetch('/api/notes');
                notes = await response.json();
                displayNotes();
                updateStats();
            } catch (error) {
                console.error('Error loading notes:', error);
                document.getElementById('notesContainer').innerHTML = 
                    '<div class="no-notes">❌ Error loading notes. Please refresh the page.</div>';
            }
        }

        // Display notes as draggable cards
        function displayNotes(filteredNotes = null) {
            const container = document.getElementById('notesContainer');
            const notesToShow = filteredNotes || notes;
            
            if (notesToShow.length === 0) {
                container.innerHTML = '<div class="no-notes">📝 No notes found. Create your first note!</div>';
                return;
            }

            let html = '';
            notesToShow.forEach((note, index) => {
                const left = 50 + (index % 4) * 320;
                const top = 100 + Math.floor(index / 4) * 300;
                
                html += `
                    <div class="note-card" 
                         id="note-${note.id}" 
                         style="left: ${left}px; top: ${top}px; z-index: ${100 + index};"
                         onmousedown="startDrag(event, ${note.id})"
                         onclick="bringToFront(this)"
                         ondragstart="return false;">
                        <div class="note-header">
                            <div>
                                <div class="note-title">${escapeHtml(note.title)}</div>
                                <div class="note-author">by ${escapeHtml(note.author)}</div>
                            </div>
                            <div class="note-date">${formatDate(note.created_at)}</div>
                        </div>
                        <div class="note-content">${escapeHtml(note.content).substring(0, 150)}${note.content.length > 150 ? '...' : ''}</div>
                        <div class="note-actions">
                            <button class="btn btn-small" onclick="viewNote(${note.id})">👁️ View</button>
                            <button class="btn btn-small" onclick="editNote(${note.id})">✏️ Edit</button>
                            <button class="btn btn-small btn-danger" onclick="deleteNote(${note.id})">🗑️ Delete</button>
                        </div>
                    </div>
                `;
            });
            
            container.innerHTML = html;
            updateHighestZIndex(); // Update z-index tracking
            
            // Set the most recent note (first in the list) as the top card initially
            if (notesToShow.length > 0) {
                const firstCard = document.getElementById(`note-${notesToShow[0].id}`);
                if (firstCard) {
                    bringToFront(firstCard);
                }
            }
        }

        // Bring note card to front
        function bringToFront(noteElement) {
            // Remove top-card class from all cards
            document.querySelectorAll('.note-card').forEach(card => {
                card.classList.remove('top-card');
            });
            
            highestZIndex += 1;
            noteElement.style.zIndex = highestZIndex;
            
            // Mark this card as the top card
            noteElement.classList.add('top-card');
            
            // Add subtle visual feedback
            noteElement.style.transform = 'scale(1.02)';
            setTimeout(() => {
                noteElement.style.transform = '';
            }, 150);
        }

        // Update highest z-index when notes are loaded
        function updateHighestZIndex() {
            const noteCards = document.querySelectorAll('.note-card');
            noteCards.forEach(card => {
                const zIndex = parseInt(card.style.zIndex) || 100;
                if (zIndex > highestZIndex) {
                    highestZIndex = zIndex;
                }
            });
        }

        // Start dragging a note
        function startDrag(e, noteId) {
            e.preventDefault();
            isDragging = true;
            currentNote = document.getElementById(`note-${noteId}`);
            
            // Bring the card to front when starting to drag
            bringToFront(currentNote);
            
            const rect = currentNote.getBoundingClientRect();
            offset.x = e.clientX - rect.left;
            offset.y = e.clientY - rect.top;
            
            currentNote.classList.add('dragging');
            document.addEventListener('mousemove', drag);
            document.addEventListener('mouseup', stopDrag);
        }

        // Drag the note
        function drag(e) {
            if (isDragging && currentNote) {
                const x = e.clientX - offset.x;
                const y = e.clientY - offset.y;
                
                currentNote.style.left = Math.max(0, Math.min(x, window.innerWidth - currentNote.offsetWidth)) + 'px';
                currentNote.style.top = Math.max(0, Math.min(y, window.innerHeight - currentNote.offsetHeight)) + 'px';
            }
        }

        // Stop dragging
        function stopDrag() {
            if (currentNote) {
                currentNote.classList.remove('dragging');
            }
            isDragging = false;
            currentNote = null;
            document.removeEventListener('mousemove', drag);
            document.removeEventListener('mouseup', stopDrag);
        }

        // Auto arrange notes in a grid
        function arrangeNotes() {
            const noteCards = document.querySelectorAll('.note-card');
            noteCards.forEach((card, index) => {
                const left = 50 + (index % 4) * 320;
                const top = 100 + Math.floor(index / 4) * 300;
                
                card.style.transition = 'all 0.5s ease';
                card.style.left = left + 'px';
                card.style.top = top + 'px';
                
                setTimeout(() => {
                    card.style.transition = '';
                }, 500);
            });
        }

        // Search notes (disabled - no search bar)
        function searchNotes() {
            // Search functionality removed
        }

        // Clear search (disabled - no search bar)
        function clearSearch() {
            // Clear search functionality removed
        }

        // Show add note modal
        function showAddModal() {
            document.getElementById('modalTitle').textContent = '➕ Add New Note';
            document.getElementById('noteForm').reset();
            document.getElementById('noteId').value = '';
            document.getElementById('noteModal').style.display = 'block';
        }

        // View note in modal
        function viewNote(id) {
            const note = notes.find(n => n.id === id);
            if (note) {
                // Bring the note card to front when viewing
                const noteCard = document.getElementById(`note-${id}`);
                if (noteCard) bringToFront(noteCard);
                
                alert(`📄 ${note.title}\n\n👤 Author: ${note.author}\n📅 Created: ${formatDate(note.created_at)}\n\n📝 Content:\n${note.content}`);
            }
        }

        // Edit note
        function editNote(id) {
            const note = notes.find(n => n.id === id);
            if (note) {
                // Bring the note card to front when editing
                const noteCard = document.getElementById(`note-${id}`);
                if (noteCard) bringToFront(noteCard);
                
                document.getElementById('modalTitle').textContent = '✏️ Edit Note';
                document.getElementById('noteId').value = note.id;
                document.getElementById('title').value = note.title;
                document.getElementById('author').value = note.author;
                document.getElementById('content').value = note.content;
                document.getElementById('noteModal').style.display = 'block';
            }
        }

        // Delete note
        async function deleteNote(id) {
            const note = notes.find(n => n.id === id);
            if (note && confirm(`🗑️ Are you sure you want to delete "${note.title}"?`)) {
                try {
                    const response = await fetch(`/api/notes/${id}`, { method: 'DELETE' });
                    if (response.ok) {
                        loadNotes(); // Reload notes
                    } else {
                        alert('❌ Error deleting note!');
                    }
                } catch (error) {
                    alert('❌ Error deleting note!');
                }
            }
        }

        // Close modal
        function closeModal() {
            document.getElementById('noteModal').style.display = 'none';
        }

        // Refresh notes
        function refreshNotes() {
            loadNotes();
        }

        // Update statistics (disabled - no stats bar)
        function updateStats(count = null) {
            // Stats functionality removed
        }

        // Handle form submission
        document.getElementById('noteForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const formData = new FormData(e.target);
            const noteData = {
                title: formData.get('title'),
                author: formData.get('author'),
                content: formData.get('content')
            };
            
            const noteId = document.getElementById('noteId').value;
            const url = noteId ? `/api/notes/${noteId}` : '/api/notes';
            const method = noteId ? 'PUT' : 'POST';
            
            try {
                const response = await fetch(url, {
                    method: method,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(noteData)
                });
                
                if (response.ok) {
                    closeModal();
                    loadNotes(); // Reload notes
                } else {
                    alert('❌ Error saving note!');
                }
            } catch (error) {
                alert('❌ Error saving note!');
            }
        });

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('noteModal');
            if (event.target === modal) {
                closeModal();
            }
        }

        // Utility functions
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        function formatDate(dateString) {
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        }
    </script>
</body>
</html>
"""


# Routes
@app.route("/")
def index():
    """Main page with interactive note cards"""
    return render_template_string(HTML_TEMPLATE)


@app.route("/api/notes", methods=["GET"])
def get_notes():
    """API endpoint to get all notes"""
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500

    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM notes ORDER BY created_at DESC")
        notes_data = cursor.fetchall()

        # Convert to list of dictionaries for JSON serialization
        notes_list = []
        for note in notes_data:
            note_dict = {
                "id": note[0],
                "title": note[1],
                "content": note[2],
                "author": note[3],
                "created_at": note[4],
                "updated_at": note[5],
            }
            notes_list.append(note_dict)

        return jsonify(notes_list)
    except sqlite3.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/api/notes", methods=["POST"])
def create_note():
    """API endpoint to create a new note"""
    data = request.get_json()

    if not data or not all(key in data for key in ["title", "author", "content"]):
        return jsonify({"error": "Missing required fields"}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500

    try:
        cursor = conn.cursor()
        query = """
        INSERT INTO notes (title, content, author, created_at) 
        VALUES (?, ?, ?, ?)
        """
        cursor.execute(
            query, (data["title"], data["content"], data["author"], datetime.now())
        )
        conn.commit()

        note_id = cursor.lastrowid
        return jsonify({"id": note_id, "message": "Note created successfully"}), 201
    except sqlite3.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/api/notes/<int:note_id>", methods=["PUT"])
def update_note(note_id):
    """API endpoint to update a note"""
    data = request.get_json()

    if not data or not all(key in data for key in ["title", "author", "content"]):
        return jsonify({"error": "Missing required fields"}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500

    try:
        cursor = conn.cursor()
        query = """
        UPDATE notes 
        SET title = ?, content = ?, author = ?, updated_at = ?
        WHERE id = ?
        """
        cursor.execute(
            query,
            (data["title"], data["content"], data["author"], datetime.now(), note_id),
        )
        conn.commit()

        if cursor.rowcount == 0:
            return jsonify({"error": "Note not found"}), 404

        return jsonify({"message": "Note updated successfully"})
    except sqlite3.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/api/notes/<int:note_id>", methods=["DELETE"])
def delete_note(note_id):
    """API endpoint to delete a note"""
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500

    try:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM notes WHERE id = ?", (note_id,))
        conn.commit()

        if cursor.rowcount == 0:
            return jsonify({"error": "Note not found"}), 404

        return jsonify({"message": "Note deleted successfully"})
    except sqlite3.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


@app.route("/api/search")
def search_notes():
    """API endpoint to search notes"""
    query = request.args.get("q", "").strip()

    if not query:
        return jsonify([])

    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500

    try:
        cursor = conn.cursor()
        search_query = """
        SELECT * FROM notes 
        WHERE title LIKE ? OR content LIKE ? OR author LIKE ?
        ORDER BY created_at DESC
        """
        search_pattern = f"%{query}%"
        cursor.execute(search_query, (search_pattern, search_pattern, search_pattern))
        notes_data = cursor.fetchall()

        # Convert to list of dictionaries for JSON serialization
        notes_list = []
        for note in notes_data:
            note_dict = {
                "id": note[0],
                "title": note[1],
                "content": note[2],
                "author": note[3],
                "created_at": note[4],
                "updated_at": note[5],
            }
            notes_list.append(note_dict)

        return jsonify(notes_list)
    except sqlite3.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        cursor.close()
        conn.close()


if __name__ == "__main__":
    # Initialize database
    init_database()

    # Get port from environment or default to 5000
    port = int(os.getenv("FLASK_PORT", 5000))

    # Test database connection on startup
    conn = get_db_connection()
    if conn:
        print("✅ Database connection successful!")
        conn.close()
        print("🚀 Starting Flask web server...")
        print(f"🌐 Open your browser and go to: http://localhost:{port}")
        print("🎯 Features:")
        print("   - Interactive floating note cards")
        print("   - Drag and drop notes anywhere")
        print("   - Real-time search")
        print("   - Add/Edit/Delete with beautiful modals")
        print("   - Responsive design")
        print("   - SQLite database for note storage")

        if port == 80:
            print("⚠️  Note: Running on port 80 requires administrator privileges")
            print("   - On Linux/Mac: sudo python3 frontend.py")
            print("   - On Windows: Run as Administrator")
            print("   - Alternative: Set FLASK_PORT=5000 for non-privileged port")

        try:
            app.run(debug=True, host="0.0.0.0", port=port)
        except PermissionError:
            print("❌ Permission denied to bind to port 80!")
            print("💡 Solutions:")
            print("   1. Run with sudo: sudo python3 frontend.py")
            print("   2. Use different port: FLASK_PORT=5000 python3 frontend.py")
            print("   3. Deploy with Ansible for production (Apache handles port 80)")
        except OSError as e:
            if "Address already in use" in str(e):
                print(f"❌ Port {port} is already in use!")
                print("💡 Try a different port: FLASK_PORT=5000 python3 frontend.py")
            else:
                print(f"❌ Error starting server: {e}")
    else:
        print("❌ Database connection failed!")
        print("Please make sure:")
        print("1. SQLite3 is installed and accessible")
        print("2. Write permissions exist in the current directory")
        print("3. Python sqlite3 module is available (built-in)")
