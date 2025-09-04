#!/usr/bin/env python3

"""
Manual tests for the Simple Note App
Tests the greeting and health check endpoints using requests
"""

import requests
import json
import time
import subprocess
import signal
import os
import sys
from multiprocessing import Process


def start_app_server():
    """Start the Flask app in the background"""
    os.system("cd /home/runner/work/ansible-project/ansible-project && python3 frontend.py > /dev/null 2>&1 &")
    # Give the server time to start
    time.sleep(3)


def test_endpoint(url, endpoint_name):
    """Test a specific endpoint"""
    try:
        response = requests.get(url, timeout=5)
        print(f"✅ {endpoint_name}: HTTP {response.status_code}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"   📄 Response: {json.dumps(data, indent=2)[:200]}...")
                return True
            except json.JSONDecodeError:
                print(f"   📄 Response: {response.text[:100]}...")
                return True
        else:
            print(f"   ❌ Unexpected status code: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ {endpoint_name}: Connection failed - {e}")
        return False


def test_greeting_content(url):
    """Test specific greeting endpoint content"""
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            
            # Check required fields
            required_fields = ['message', 'greeting', 'status', 'features', 'endpoints']
            missing_fields = [field for field in required_fields if field not in data]
            
            if not missing_fields:
                print(f"   ✅ All required fields present")
                if 'Hi there!' in data.get('message', ''):
                    print(f"   ✅ Greeting message correct")
                if data.get('status') == 'success':
                    print(f"   ✅ Status is success")
                return True
            else:
                print(f"   ❌ Missing fields: {missing_fields}")
                return False
    except Exception as e:
        print(f"   ❌ Content validation failed: {e}")
        return False


def main():
    """Run all tests"""
    print("🧪 Running Simple Note App Manual Tests...")
    print("=" * 60)
    
    base_url = "http://localhost:5000"
    
    # Start the Flask app
    print("🚀 Starting Flask application...")
    start_app_server()
    
    # Test endpoints
    tests = [
        (f"{base_url}/", "Main Page"),
        (f"{base_url}/hi", "Greeting (/hi)"),
        (f"{base_url}/hello", "Greeting (/hello)"), 
        (f"{base_url}/health", "Health Check"),
        (f"{base_url}/api/notes", "Notes API"),
        (f"{base_url}/api/search?q=test", "Search API"),
    ]
    
    results = []
    for url, name in tests:
        print(f"\n🔍 Testing {name}:")
        result = test_endpoint(url, name)
        results.append((name, result))
        
        # Additional content validation for greeting endpoints
        if name.startswith("Greeting") and result:
            test_greeting_content(url)
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 Test Results Summary:")
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"   {status} {name}")
    
    print(f"\n🎯 Overall: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! The greeting endpoints are working correctly.")
        return 0
    else:
        print("❌ Some tests failed. Please check the output above.")
        return 1


if __name__ == '__main__':
    exit_code = main()
    sys.exit(exit_code)