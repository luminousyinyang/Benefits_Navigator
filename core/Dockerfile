# Use the official Python image
FROM python:3.11-slim

# Set the working directory to /app
# Everything inside 'core' on your Mac will now be in /app in the container
WORKDIR /app

# Copy and install dependencies first (for faster builds)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy everything else
COPY . .

# Change working directory to the app folder so sibling imports (e.g. 'import models') work
WORKDIR /app/app

# Ensure the container sees the root folder as a package source if needed, 
# although WORKDIR /app/app usually suffices for sibling imports.
ENV PYTHONPATH=/app/app

# Run uvicorn from the app directory
# Use 0.0.0.0 for the host so it is accessible to Cloud Run
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port $PORT"]