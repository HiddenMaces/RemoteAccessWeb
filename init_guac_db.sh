#!/bin/bash
set -e

ENV_FILE="guacamole/.env"
COMPOSE_FILE="guacamole/docker-compose.yaml"
DB_CONTAINER_NAME="guacamole-db"
INIT_FILE="guacamole/initdb.sql"

echo "### Starting Guacamole Database Initialization ###"
echo ""

# Load credentials from guacamole/.env
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found."
    echo "Copy guacamole/.env.example to guacamole/.env and set your passwords first."
    exit 1
fi

set -a
# shellcheck source=guacamole/.env
source "$ENV_FILE"
set +a

echo "1. Starting database container..."
docker compose -f "$COMPOSE_FILE" up -d guacdb
echo ""

echo "2. Checking for running database container: $DB_CONTAINER_NAME..."
if [ "$(docker ps -q -f name=^/${DB_CONTAINER_NAME}$)" ]; then
    echo "   -> Container $DB_CONTAINER_NAME is running. Proceeding..."
else
    echo "   -> ERROR: Container $DB_CONTAINER_NAME did not start."
    exit 1
fi
echo ""

echo "3. Waiting for the database to be ready..."
until docker exec "$DB_CONTAINER_NAME" healthcheck.sh --connect --innodb_initialized 2>/dev/null; do
    echo "   -> Not ready yet, retrying in 3s..."
    sleep 3
done
echo "   -> Database is ready."
echo ""

echo "4. Executing schema: $INIT_FILE..."
docker exec -i "$DB_CONTAINER_NAME" \
    /usr/bin/mysql -u root --password="$DB_ROOT_PASSWORD" "$DB_NAME" \
    < "$INIT_FILE"

echo ""
echo "### SUCCESS: Guacamole database schema created. ###"
echo ""
echo "Default login: guacadmin / guacadmin"
echo "!! Change the guacadmin password immediately after first login !!"
echo ""

echo "5. Stopping database container (run 'docker compose up -d' to start the full stack)..."
docker compose -f "$COMPOSE_FILE" stop guacdb
echo "Done."
