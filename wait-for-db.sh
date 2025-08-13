#!/bin/bash

echo "Waiting for SQLite database to be ready..."

# Wait for database file to exist
while [ ! -f "/shared/notes.db" ]; do
    echo "Database not ready yet, waiting..."
    sleep 2
done

echo "Database is ready! Starting Flask app..."
python frontend.py 