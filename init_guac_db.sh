#!/bin/bash

# --- Configuration ---
# IMPORTANT: These must match the credentials in your guacamole/docker-compose.yml
DB_CONTAINER_NAME="guacamole-db"
DB_ROOT_PASSWORD="MariaDBrootpassword" # CHANGE THIS if changed in guacamole/docker-compose.yml
DB_NAME="guacamole_db"
INIT_FILE="guacamole/initdb.sql"

echo "### Starting Guacamole Database Initialization ###"
echo " "

# 1. Starting guacamole seperatly for now
echo "1. Starting guacamole"
docker compose -f guacamole/docker-compose.yml up -d

# 2. Check if the database container is running
echo "2. Checking for running database container: $DB_CONTAINER_NAME..."
if [ "$(docker ps -q -f name=$DB_CONTAINER_NAME)" ]; then
    echo "   -> Container $DB_CONTAINER_NAME is running. Proceeding..."
else
    echo "   -> ERROR: Container $DB_CONTAINER_NAME is not running. Please run 'docker compose -f guacamole/docker-compose.yml up -d' first."
    exit 1
fi
echo " "

# 3. Wait a moment for the database to be fully ready (optional, but safer)
echo "3. Waiting 10 seconds for the database service to stabilize..."
sleep 15
echo " "

# 4. Execute the SQL script on the running database container
echo "4. Executing $INIT_FILE on $DB_CONTAINER_NAME ($DB_NAME)..."
# Use 'cat' to pipe the SQL file directly into the database container's MySQL client
cat "$INIT_FILE" | docker exec -i "$DB_CONTAINER_NAME" /usr/bin/mysql -u root --password="$DB_ROOT_PASSWORD" "$DB_NAME"

if [ $? -eq 0 ]; then
    echo " "
    echo "### ✅ SUCCESS: Guacamole Database Schema Created! ###"
    echo " "
    echo "You can now access Guacamole at http://<Your-Server-IP-or-Hostname>:8080/guacamole/"
    echo "Default login: guacadmin/guacadmin"
else
    echo " "
    echo "### ❌ ERROR: Failed to execute SQL script. ###"
    echo "Check the DB_ROOT_PASSWORD and ensure the DB_CONTAINER_NAME is correct."
fi

# 5. Stop the running container 
docker stop "$DB_CONTAINER_NAME"
echo "Container stopped"
