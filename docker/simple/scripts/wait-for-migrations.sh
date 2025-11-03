#!/bin/bash
# Database Migration Script for Flask Applications
# This script waits for PostgreSQL to be ready, then initializes and runs database migrations

# Wait for PostgreSQL to become available
echo "Waiting for postgres..."
while ! nc -z "$DB_HOST" "$DB_PORT"; do
  sleep 0.1
done
echo "PostgreSQL started..."

# Initialize Flask-Migrate if migrations folder doesn't exist
if [ ! -d "migrations" ]; then
  echo "Initializing database migrations..."
  flask db init || { echo "Failed to initialize migrations..."; exit 1; }
fi

# Create a new migration based on model changes
flask db migrate -m "Auto migration" || { echo "Failed to create migration..."; exit 1; }

# Apply migrations to the database
flask db upgrade head || { echo "Failed to run migrations..."; exit 1; }

# Exit successfully
echo "Migrations completed successfully!"
exit 0
