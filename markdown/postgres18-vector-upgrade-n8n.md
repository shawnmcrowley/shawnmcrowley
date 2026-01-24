# PostgreSQL 18 Upgrade Guide for n8n with pgvector Support

This guide provides a step-by-step procedure for upgrading from PostgreSQL 17 to PostgreSQL 18 with pgvector support, specifically for n8n deployments.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Backup Existing Data](#step-1-backup-existing-data)
4. [Step 2: Stop and Remove Containers](#step-2-stop-and-remove-containers)
5. [Step 3: Update Docker Compose Configuration](#step-3-update-docker-compose-configuration)
6. [Step 4: Create Database and Schema](#step-4-create-database-and-schema)
7. [Step 5: Start PostgreSQL 18 Container](#step-5-start-postgresql-18-container)
8. [Step 6: Import Data and Enable Extensions](#step-6-import-data-and-enable-extensions)
9. [Step 7: Configure n8n Environment](#step-7-configure-n8n-environment)
10. [Step 8: Start n8n Container](#step-8-start-n8n-container)
11. [Step 9: Verification and Testing](#step-9-verification-and-testing)
12. [Troubleshooting](#troubleshooting)

## Overview

This upgrade involves:
- Migrating from PostgreSQL 17 to PostgreSQL 18
- Using the `pgvector/pgvector:pg18-trixie` Docker image
- Updating data directory paths due to PostgreSQL 18 changes
- Creating proper database schema for n8n
- Enabling pgvector extension

## Prerequisites

- Docker and Docker Compose installed
- Existing PostgreSQL 17 container with pgvector
- Access to n8n configuration files
- Sufficient disk space for backup

## Step 1: Backup Existing Data

Create a complete backup of your PostgreSQL data before proceeding:

```bash
# Export all data from the existing container
docker exec <postgres_container_name> pg_dump -U <postgres_user> -d <database_name> > backup.sql

# Alternative: Export all databases
docker exec <postgres_container_name> pg_dumpall -U <postgres_user> > full_backup.sql
```

## Step 2: Stop and Remove Containers

Stop and remove the existing PostgreSQL container and associated volumes:

```bash
# Stop the container
docker stop <postgres_container_name>

# Remove the container
docker rm <postgres_container_name>

# Remove associated volumes (WARNING: This deletes data)
docker volume rm <postgres_volume_name>
```

## Step 3: Update Docker Compose Configuration

Update your `docker-compose.yml` file with the new PostgreSQL 18 image and corrected volume path:

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg18-trixie
    container_name: postgres18
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n_user
      POSTGRES_PASSWORD: your_secure_password
    volumes:
      # IMPORTANT: Updated path for PostgreSQL 18
      - ./postgres_data:/var/lib/postgresql
    ports:
      - "5432:5432"
    restart: unless-stopped
```

**Key Changes:**
- Image updated to `pgvector/pgvector:pg18-trixie`
- Volume path changed from `/var/lib/postgresql/data` to `/var/lib/postgresql`

## Step 4: Create Database and Schema

Once the PostgreSQL 18 container is running, connect to it and create the necessary database and schema:

```sql
-- Connect to PostgreSQL
docker exec -it postgres18 psql -U postgres

-- Create database
CREATE DATABASE n8n;

-- Connect to the new database
\c n8n;

-- Create schema for n8n
CREATE SCHEMA n8n_schema;

-- Create n8n user with password
CREATE USER n8n_user WITH PASSWORD 'your_secure_password';

-- Grant database privileges
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;

-- Grant schema privileges
GRANT ALL ON SCHEMA n8n_schema TO n8n_user;

-- Grant default privileges for table creation
ALTER DEFAULT PRIVILEGES IN SCHEMA n8n_schema GRANT ALL ON TABLES TO n8n_user;

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;
```

## Step 5: Start PostgreSQL 18 Container

Start the new PostgreSQL 18 container:

```bash
docker-compose up -d postgres
```

## Step 6: Import Data and Enable Extensions

If you have existing data to migrate:

```bash
# Import data into the new container
docker exec -i postgres18 psql -U n8n_user -d n8n < backup.sql

# Connect to verify import and enable extensions
docker exec -it postgres18 psql -U n8n_user -d n8n

-- Verify pgvector extension is enabled
SELECT * FROM pg_extension WHERE extname = 'vector';

-- Check PostgreSQL version
SELECT version();
```

## Step 7: Configure n8n Environment

Update your n8n Docker Compose configuration with the correct database settings:

```yaml
services:
  n8n:
    image: n8nio/n8n
    environment:
      # Database configuration
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n_user
      DB_POSTGRESDB_PASSWORD: your_secure_password
      DB_POSTGRESDB_SCHEMA: n8n_schema
    depends_on:
      - postgres
    restart: unless-stopped
```

## Step 8: Start n8n Container

Start the n8n container:

```bash
docker-compose up -d n8n
```

n8n will automatically create the necessary tables within the `n8n_schema` on first startup.

## Step 9: Verification and Testing

Verify that everything is working correctly:

```bash
# Check container status
docker-compose ps

# Check n8n logs
docker-compose logs n8n

# Test database connection
docker exec -it postgres18 psql -U n8n_user -d n8n -c "\dt n8n_schema.*"
```

## Troubleshooting

### Container Boot Loop

**Issue**: Container restarts in a loop due to incorrect volume path.

**Solution**: Ensure you're using `/var/lib/postgresql` instead of `/var/lib/postgresql/data`:

```yaml
volumes:
  - ./postgres_data:/var/lib/postgresql  # Correct
  # - ./postgres_data:/var/lib/postgresql/data  # Incorrect - causes boot loop
```

### Permission Issues

**Issue**: n8n cannot create tables in the schema.

**Solution**: Ensure proper permissions are granted:

```sql
-- Connect as postgres user and run
ALTER DEFAULT PRIVILEGES IN SCHEMA n8n_schema GRANT ALL ON TABLES TO n8n_user;
GRANT ALL ON SCHEMA n8n_schema TO n8n_user;
```

### pgvector Extension Not Available

**Issue**: Vector extension not found.

**Solution**: Ensure you're using the correct image and enable the extension:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### Performance Optimization

After migration, consider rebuilding vector indexes for optimal performance:

```sql
-- Rebuild vector indexes if they exist
REINDEX INDEX CONCURRENTLY your_vector_index_name;
```

## Key Considerations

- **Data Directory**: PostgreSQL 18 changed the default data directory to `/var/lib/postgresql/18/docker`
- **Permissions**: The n8n user must have CREATE privileges on the n8n_schema
- **Automatic Setup**: n8n automatically creates required tables on first launch
- **Version Compatibility**: n8n supports PostgreSQL 18 via standard connection protocols
- **Vector Support**: The pgvector extension provides vector data type and distance functions (L2, Inner Product, Cosine, L1)

## Post-Upgrade Checklist

- [ ] Verify PostgreSQL 18 is running
- [ ] Confirm pgvector extension is enabled
- [ ] Test n8n database connectivity
- [ ] Verify n8n tables were created in n8n_schema
- [ ] Test n8n web interface functionality
- [ ] Check application logs for errors
- [ ] Perform a test workflow execution
- [ ] Remove old PostgreSQL 17 backup files (after confirming success)