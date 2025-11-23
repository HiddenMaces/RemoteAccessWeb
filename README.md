# Remote Access to your home systems

This repository contains 2 services to enable a frontend and a guacamole setup.
A root-level `docker-compose.yml` builds and runs service.
Every service has a docker-compose.yaml to start it seperatly.

## Prerequisites
- Docker installed
- Docker Compose v2 (bundled with recent Docker installations)
- Terminal access

## Project Structure
```
RemoteAccessWeb/
├── docker-compose.yaml     <-- start all the services
├── init_guac_db.sh         <-- initial setup for guacamole
├── certificates.sh         <-- setup rootca and signing user certificates
├── guacamole/
    ├── db-data/            <-- guacamole db (will be created by starting container)
    ├── docker-compose.yml  <-- to start guacamole seperatly
    └── initdb.sql          <-- initial db to add to guacamole db
├── website/
    ├── certs/              <-- to hold all the certs
    ├── config/             <-- nginx config dir
        └── default.conf    <-- nginx configuration 
    └── html/
        ├── links.txt       <-- contents for index.html
        ├── 403error.html   <-- access denied page
        ├── 404error.html   <-- not found page
        └── index.html      <-- the dashboard
```
## Quick Start

### 1. Create guacamole initial db
First time setup:
1. copy config sample to nginx.conf
```bash
chmod +x ./init_guac_db.sh
./init_guac_db.sh
```
The guacamole db is created and de tables are added

2. create the nessecary certificates.
Following the README_certificates.md for creating the self-signed certificates

### 2. Start Services
Build and start both services, in the root of the project
```bash
docker compose up -d
```
after succesfull creation and startup you can check the services individual.

**website: https://fqdn**

**guacamole: https://fqdn:8080**

### 3. Stop Services
```bash
docker compose down
```
