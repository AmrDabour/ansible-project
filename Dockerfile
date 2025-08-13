# Use Python 3.11 slim image
FROM python:3.11-slim

# Set working directory in container
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY frontend.py .
COPY wait-for-db.sh .

# Make wait script executable
RUN chmod +x wait-for-db.sh

# Set environment variables for connecting to SQLite container
ENV DB_TYPE=sqlite
ENV DB_PATH=/shared/notes.db
ENV FLASK_PORT=5000

# Expose port 5000
EXPOSE 5000

# Wait for database and start the Flask application
CMD ["./wait-for-db.sh"]