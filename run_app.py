#!/usr/bin/env python3
"""
Simple Note-Taking App Runner
Runs the Flask application on port 80 with proper error handling
"""

import os
import sys
import subprocess


def main():
    print("🚀 Note-Taking App Launcher")
    print("=" * 30)

    # Check if running as administrator/root
    try:
        is_admin = os.getuid() == 0
    except AttributeError:
        # Windows
        import ctypes

        is_admin = ctypes.windll.shell32.IsUserAnAdmin() != 0

    if not is_admin:
        print("⚠️  This app needs to run on port 80 (requires admin privileges)")
        print()

        if sys.platform.startswith("win"):
            print("🖥️  Windows detected:")
            print("   1. Right-click Command Prompt → 'Run as Administrator'")
            print("   2. Navigate to this folder")
            print("   3. Run: python run_app.py")
        else:
            print("🐧 Linux/Mac detected:")
            print("   Running with sudo...")
            try:
                subprocess.run(["sudo", "python3", "frontend.py"], check=True)
                return
            except subprocess.CalledProcessError:
                print("❌ Failed to run with sudo")
            except FileNotFoundError:
                print("❌ sudo not found")

        print()
        print("💡 Alternative: Run on different port")
        print("   FLASK_PORT=8080 python3 frontend.py")
        return

    # Run the application
    print("✅ Running with administrator privileges")
    os.environ["FLASK_PORT"] = "80"

    try:
        import frontend
    except ImportError:
        print("❌ frontend.py not found in current directory")
        return


if __name__ == "__main__":
    main()
