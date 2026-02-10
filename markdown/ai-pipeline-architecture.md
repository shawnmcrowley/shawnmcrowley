# Secure Headless AI & RAG Pipeline Architecture

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Network Diagram](#network-diagram)
3. [Prerequisites](#prerequisites)
4. [Directory Structure](#directory-structure)
5. [Docker Compose Configuration](#docker-compose-configuration)
6. [Nginx Configuration](#nginx-configuration)
7. [SSL Certificate Setup](#ssl-certificate-setup)
8. [PostgreSQL 18 Setup](#postgresql-18-setup)
9. [n8n Configuration](#n8n-configuration)
10. [Ollama Setup](#ollama-setup)
11. [RAG Pipeline Implementation](#rag-pipeline-implementation)
12. [Webhook Security](#webhook-security)
13. [NextJS Integration](#nextjs-integration)
14. [Voice Input & Browser Speech API](#voice-input--browser-speech-api)
15. [n8n Voice Agent Workflow](#n8n-voice-agent-workflow)
16. [Deployment Commands](#deployment-commands)
17. [Summary](#summary)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    INTERNET (Public)                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Nginx Reverse Proxy (SSL/TLS)                   │
│         shawnmcrowley.publicvm.com:443                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  SSL Termination + Rate Limiting + WAF Rules        │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
┌──────────┐  ┌──────────────┐  ┌──────────┐
│  NextJS  │  │   NextJS     │  │  Other   │
│  App 1   │  │   App 2      │  │   Apps   │
│  :3001   │  │   :3002      │  │  :300X   │
└────┬─────┘  └──────┬───────┘  └────┬─────┘
     │               │               │
     └───────────────┴───────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Docker Internal Network (isolated)              │
│  ┌──────────────┐        ┌──────────────────────────┐      │
│  │     n8n      │◄──────►│     Ollama (AI/LLM)      │      │
│  │   :5678      │        │      :11434              │      │
│  └──────────────┘        └──────────────────────────┘      │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────┐  ┌──────────┐  ┌──────────────────┐     │
│  │  PostgreSQL  │  │PostgreSQL│  │    Redis         │     │
│  │  (n8n DB)    │  │   18     │  │ (Queue/Cache)    │     │
│  │   :5432      │  │  :5433   │  │    :6379         │     │
│  └──────────────┘  └──────────┘  └──────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

**Key Security Features:**
- n8n and Ollama accessible only via internal Docker network
- Webhooks exposed through Nginx with authentication
- SSL/TLS termination at Nginx
- No direct internet access to AI services

---

## Network Diagram

```mermaid
flowchart TB
    Internet((Internet))
    
    subgraph UbuntuHost[Ubuntu Host]
        Nginx[Nginx Reverse Proxy<br/>Port 443/80]
        
        subgraph DockerNetwork[Docker Internal Network<br/>172.20.0.0/24]
            n8n[n8n<br/>Port 5678]
            Ollama[Ollama<br/>Port 11434]
            Postgres[(PostgreSQL<br/>Port 5432)]
            Postgres18[(PostgreSQL 18<br/>Port 5433)]
            Redis[(Redis<br/>Port 6379)]
            Qdrant[(Qdrant<br/>Vector DB)]
        end
        
        NextJS1[NextJS App 1<br/>Port 3001]
        NextJS2[NextJS App 2<br/>Port 3002]
    end
    
    Internet -->|HTTPS| Nginx
    Nginx -->|Proxy Pass| NextJS1
    Nginx -->|Proxy Pass| NextJS2
    
    NextJS1 -.->|Internal Only| n8n
    NextJS1 -.->|Internal Only| Ollama
    NextJS1 -.->|Internal Only| Postgres18
    NextJS2 -.->|Internal Only| n8n
    NextJS2 -.->|Internal Only| Ollama
    NextJS2 -.->|Internal Only| Postgres18
    
    n8n --> Postgres
    n8n --> Redis
    n8n -.->|RAG Pipeline| Ollama
    n8n -.->|Vector Store| Qdrant
    Ollama -.->|Embeddings| Qdrant
    
    NextJS1 -->|App Data| Postgres18
    NextJS2 -->|App Data| Postgres18
    
    style DockerNetwork fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    style Nginx fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
```

---

## Prerequisites

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y \
    docker.io \
    docker-compose \
    nginx \
    certbot \
    python3-certbot-nginx \
    git \
    curl \
    ufw \
    fail2ban

# Enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw --force enable
```

---

## Directory Structure

```bash
mkdir -p ~/ai-pipeline/{n8n,ollama,nginx,apps,qdrant,shared}
mkdir -p ~/ai-pipeline/postgres18/{data,init-scripts}
cd ~/ai-pipeline

tree -L 2
# .
# ├── docker-compose.yml
# ├── nginx/
# │   ├── nginx.conf
# │   └── ssl/
# ├── n8n/
# │   └── .env
# ├── ollama/
# │   └── models/
# ├── postgres18/
# │   ├── data/
# │   └── init-scripts/
# ├── qdrant/
# │   └── storage/
# ├── shared/
# │   └── documents/
# └── apps/
#     ├── nextjs-app-1/
#     └── nextjs-app-2/
```

---

## Docker Compose Configuration

Create `~/ai-pipeline/docker-compose.yml`:

```yaml
version: '3.8'

networks:
  ai-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24

volumes:
  n8n_data:
  postgres_data:
  postgres18_data:
  redis_data:
  ollama_models:
  qdrant_storage:

services:
  # PostgreSQL for n8n
  postgres:
    image: postgres:15-alpine
    container_name: ai-postgres
    restart: unless-stopped
    networks:
      - ai-network
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 5s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 1G

  # PostgreSQL 18 - Application Database
  postgres18:
    image: postgres:18-alpine
    container_name: ai-postgres18
    restart: unless-stopped
    networks:
      - ai-network
    environment:
      - POSTGRES_USER=${POSTGRES18_USER}
      - POSTGRES_PASSWORD=${POSTGRES18_PASSWORD}
      - POSTGRES_DB=${POSTGRES18_DB}
      - PGPORT=5433
    volumes:
      - postgres18_data:/var/lib/postgresql/data
      - ./postgres18/init-scripts:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES18_USER} -p 5433"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M
    command:
      - "postgres"
      - "-c"
      - "port=5433"
      - "-c"
      - "max_connections=200"
      - "-c"
      - "shared_buffers=512MB"
      - "-c"
      - "effective_cache_size=1536MB"
      - "-c"
      - "maintenance_work_mem=128MB"
      - "-c"
      - "checkpoint_completion_target=0.9"
      - "-c"
      - "wal_buffers=16MB"
      - "-c"
      - "default_statistics_target=100"
      - "-c"
      - "random_page_cost=1.1"
      - "-c"
      - "effective_io_concurrency=200"
      - "-c"
      - "work_mem=2621kB"
      - "-c"
      - "huge_pages=off"
      - "-c"
      - "min_wal_size=1GB"
      - "-c"
      - "max_wal_size=4GB"

  # Redis for caching and queues
  redis:
    image: redis:7-alpine
    container_name: ai-redis
    restart: unless-stopped
    networks:
      - ai-network
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    deploy:
      resources:
        limits:
          memory: 512M

  # Qdrant Vector Database for RAG
  qdrant:
    image: qdrant/qdrant:latest
    container_name: ai-qdrant
    restart: unless-stopped
    networks:
      - ai-network
    environment:
      - QDRANT__SERVICE__API_KEY=${QDRANT_API_KEY}
    volumes:
      - qdrant_storage:/qdrant/storage
    deploy:
      resources:
        limits:
          memory: 2G

  # Ollama - Local LLM Server
  ollama:
    image: ollama/ollama:latest
    container_name: ai-ollama
    restart: unless-stopped
    networks:
      - ai-network
    volumes:
      - ollama_models:/root/.ollama
    environment:
      - OLLAMA_ORIGINS=*
      - OLLAMA_HOST=0.0.0.0
    # GPU support (optional - for NVIDIA)
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

  # n8n - Workflow Automation
  n8n:
    image: n8nio/n8n:latest
    container_name: ai-n8n
    restart: unless-stopped
    networks:
      - ai-network
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_WEBHOOK_URL=https://shawnmcrowley.publicvm.com/
      - N8N_WEBHOOK_TUNNEL_URL=https://shawnmcrowley.publicvm.com/
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PASSWORD=${REDIS_PASSWORD}
      - NODE_FUNCTION_ALLOW_EXTERNAL=*
      - N8N_HOST=shawnmcrowley.publicvm.com
      - N8N_PROTOCOL=https
      - N8N_PORT=5678
      - WEBHOOK_URL=https://shawnmcrowley.publicvm.com/webhook/
      - GENERIC_TIMEZONE=America/New_York
    volumes:
      - n8n_data:/home/node/.n8n
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    # NOT exposing ports - accessible only via internal network
    # ports:
    #   - "127.0.0.1:5678:5678"

  # Document Parser Service (for RAG)
  document-parser:
    image: apache/tika:latest
    container_name: ai-tika
    restart: unless-stopped
    networks:
      - ai-network
    # Internal service only
```

---

## Nginx Configuration

Create `~/ai-pipeline/nginx/nginx.conf`:

```nginx
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=webhooks:10m rate=30r/s;
limit_conn_zone $binary_remote_addr zone=addr:10m;

# Upstream definitions
upstream nextjs_app1 {
    server 127.0.0.1:3001;
    keepalive 32;
}

upstream nextjs_app2 {
    server 127.0.0.1:3002;
    keepalive 32;
}

# n8n webhook upstream (internal only - no external access)
upstream n8n_webhook {
    server 172.20.0.4:5678;  # n8n container IP
    keepalive 32;
}

# Ollama API upstream (internal only)
upstream ollama_api {
    server 172.20.0.5:11434;  # ollama container IP
    keepalive 32;
}

# PostgreSQL 18 Admin/Connection (PgAdmin or direct - optional)
upstream postgres18_admin {
    server 172.20.0.6:5433;  # postgres18 container IP
    keepalive 32;
}

server {
    listen 80;
    server_name shawnmcrowley.publicvm.com;
    
    # Redirect HTTP to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

server {
    listen 443 ssl http2;
    server_name shawnmcrowley.publicvm.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/shawnmcrowley.publicvm.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/shawnmcrowley.publicvm.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/shawnmcrowley.publicvm.com/chain.pem;
    
    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    # Client body size for file uploads
    client_max_body_size 50M;
    
    # Rate limiting
    limit_req zone=general burst=20 nodelay;
    limit_conn addr 10;
    
    # === PUBLIC APPLICATIONS ===
    
    # NextJS App 1
    location /app1 {
        proxy_pass http://nextjs_app1;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # NextJS App 2
    location /app2 {
        proxy_pass http://nextjs_app2;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # === N8N WEBHOOKS (Authenticated) ===
    
    location /webhook/ {
        # Rate limiting for webhooks
        limit_req zone=webhooks burst=50 nodelay;
        
        # Authentication (optional but recommended)
        # auth_basic "n8n Webhooks";
        # auth_basic_user_file /etc/nginx/.htpasswd;
        
        # IP Whitelist (optional - restrict to specific IPs)
        # allow 127.0.0.1;
        # allow 172.20.0.0/24;
        # deny all;
        
        proxy_pass http://n8n_webhook/webhook/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for n8n
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # === INTERNAL API ENDPOINTS (Restricted Access) ===
    
    # Ollama API - Internal only, authenticated
    location /api/ai/ {
        # Authentication required
        auth_basic "AI API Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        # IP restriction - only localhost and docker network
        allow 127.0.0.1;
        allow 172.20.0.0/24;
        allow 172.17.0.0/16;  # Default docker network
        deny all;
        
        proxy_pass http://ollama_api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Disable body size limit for large prompts
        client_max_body_size 0;
        
        # Long timeout for LLM responses
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }
    
    # n8n Internal API - Restricted
    location /api/n8n/ {
        auth_basic "n8n API Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        allow 127.0.0.1;
        allow 172.20.0.0/24;
        deny all;
        
        proxy_pass http://n8n_webhook/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # === HEALTH CHECKS ===
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # === STATIC FILES ===
    
    location /static/ {
        alias /var/www/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Default location
    location / {
        root /var/www/html;
        try_files $uri $uri/ =404;
    }
}
```

---

## SSL Certificate Setup

```bash
#!/bin/bash
# ~/ai-pipeline/setup-ssl.sh

# Create directory for Let's Encrypt
sudo mkdir -p /var/www/certbot

# Obtain SSL certificate
sudo certbot certonly \
    --nginx \
    -d shawnmcrowley.publicvm.com \
    --agree-tos \
    --non-interactive \
    --email shawnnmcrowley@gmail.com

# Set up auto-renewal
echo "0 3 * * * root certbot renew --quiet --nginx" | sudo tee -a /etc/crontab

# Create authentication file for API endpoints
sudo sh -c "echo -n 'admin:' >> /etc/nginx/.htpasswd"
sudo sh -c "openssl passwd -apr1 >> /etc/nginx/.htpasswd"
# Enter password when prompted

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

---

## PostgreSQL 18 Setup

Create `~/ai-pipeline/postgres18/init-scripts/01-init.sql`:

```sql
-- Create application databases
CREATE DATABASE IF NOT EXISTS app1_db;
CREATE DATABASE IF NOT EXISTS app2_db;
CREATE DATABASE IF NOT EXISTS shared_data;

-- Create application users
CREATE USER app1_user WITH PASSWORD 'app1_secure_password';
CREATE USER app2_user WITH PASSWORD 'app2_secure_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE app1_db TO app1_user;
GRANT ALL PRIVILEGES ON DATABASE app2_db TO app2_user;
GRANT CONNECT ON DATABASE shared_data TO app1_user;
GRANT CONNECT ON DATABASE shared_data TO app2_user;

-- Enable required extensions
\c app1_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "vector";

\c app2_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "vector";

\c shared_data
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```

Create `~/ai-pipeline/n8n/.env`:

```bash
# PostgreSQL (n8n)
POSTGRES_PASSWORD=your_secure_postgres_password_here

# PostgreSQL 18 (Application Backend)
POSTGRES18_USER=postgres_admin
POSTGRES18_PASSWORD=your_secure_postgres18_password_here
POSTGRES18_DB=app_data
POSTGRES18_APP1_PASSWORD=app1_secure_password
POSTGRES18_APP2_PASSWORD=app2_secure_password

# Redis
REDIS_PASSWORD=your_secure_redis_password_here

# n8n Authentication
N8N_USER=admin
N8N_PASSWORD=your_secure_n8n_password_here
N8N_ENCRYPTION_KEY=your_32_character_encryption_key_here

# Qdrant
QDRANT_API_KEY=your_qdrant_api_key_here
```

### n8n RAG Workflow Example

```json
{
  "name": "RAG Pipeline",
  "nodes": [
    {
      "parameters": {},
      "id": "webhook-trigger",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [250, 300],
      "webhookId": "rag-query"
    },
    {
      "parameters": {
        "model": "llama2",
        "options": {}
      },
      "id": "ollama-embeddings",
      "name": "Ollama Embeddings",
      "type": "n8n-nodes-base.ollamaEmbeddings",
      "typeVersion": 1,
      "position": [450, 300],
      "credentials": {
        "ollamaApi": {
          "id": "ollama-credentials",
          "name": "Ollama Credentials"
        }
      }
    },
    {
      "parameters": {
        "options": {}
      },
      "id": "qdrant-search",
      "name": "Qdrant Vector Search",
      "type": "n8n-nodes-base.qdrantVectorStore",
      "typeVersion": 1,
      "position": [650, 300],
      "credentials": {
        "qdrantApi": {
          "id": "qdrant-credentials",
          "name": "Qdrant Credentials"
        }
      }
    },
    {
      "parameters": {
        "model": "llama2",
        "options": {
          "temperature": 0.7
        }
      },
      "id": "ollama-llm",
      "name": "Ollama Chat Model",
      "type": "n8n-nodes-base.ollama",
      "typeVersion": 1,
      "position": [850, 300],
      "credentials": {
        "ollamaApi": {
          "id": "ollama-credentials",
          "name": "Ollama Credentials"
        }
      }
    }
  ],
  "connections": {
    "Webhook": {
      "main": [[{"node": "Ollama Embeddings", "type": "main", "index": 0}]]
    },
    "Ollama Embeddings": {
      "main": [[{"node": "Qdrant Vector Search", "type": "main", "index": 0}]]
    },
    "Qdrant Vector Search": {
      "main": [[{"node": "Ollama Chat Model", "type": "main", "index": 0}]]
    }
  },
  "settings": {
    "executionOrder": "v1"
  }
}
```

---

## Ollama Setup

```bash
#!/bin/bash
# ~/ai-pipeline/setup-ollama.sh

# Pull models after containers are running
docker exec -it ai-ollama ollama pull llama2
docker exec -it ai-ollama ollama pull codellama
docker exec -it ai-ollama ollama pull mxbai-embed-large

# List available models
docker exec -it ai-ollama ollama list

# Test Ollama API (from host)
curl -X POST http://172.20.0.5:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "prompt": "Hello, how are you?"
  }'
```

---

## RAG Pipeline Implementation

### Document Ingestion Workflow

```javascript
// n8n Function Node for Document Processing
const documents = items[0].json.documents;

// Process documents and create embeddings
for (const doc of documents) {
  // 1. Parse document using Tika
  // 2. Chunk text into segments
  // 3. Generate embeddings via Ollama
  // 4. Store in Qdrant with metadata
  
  const chunks = chunkText(doc.content, 500);
  
  for (let i = 0; i < chunks.length; i++) {
    const embedding = await $httpRequest({
      method: 'POST',
      url: 'http://ai-ollama:11434/api/embeddings',
      body: {
        model: 'mxbai-embed-large',
        prompt: chunks[i]
      }
    });
    
    // Store in Qdrant
    await $httpRequest({
      method: 'PUT',
      url: 'http://ai-qdrant:6333/collections/documents/points',
      headers: {
        'api-key': $env.QDRANT_API_KEY
      },
      body: {
        points: [{
          id: `${doc.id}-${i}`,
          vector: embedding.embedding,
          payload: {
            text: chunks[i],
            source: doc.source,
            chunk_index: i
          }
        }]
      }
    });
  }
}

return [{json: {status: "Documents processed successfully", count: documents.length}}];

function chunkText(text, maxLength) {
  const chunks = [];
  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];
  let currentChunk = "";
  
  for (const sentence of sentences) {
    if ((currentChunk + sentence).length > maxLength) {
      chunks.push(currentChunk.trim());
      currentChunk = sentence;
    } else {
      currentChunk += sentence;
    }
  }
  
  if (currentChunk) chunks.push(currentChunk.trim());
  return chunks;
}
```

---

## Webhook Security

### Webhook Authentication Middleware

```javascript
// NextJS API Route: /app1/api/webhooks/n8n/route.js
import { NextResponse } from 'next/server';
import crypto from 'crypto';

const WEBHOOK_SECRET = process.env.N8N_WEBHOOK_SECRET;

export async function POST(request) {
  // Verify webhook signature
  const signature = request.headers.get('x-n8n-signature');
  const body = await request.text();
  
  const expectedSignature = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(body)
    .digest('hex');
  
  if (signature !== expectedSignature) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
  }
  
  // Process webhook payload
  const payload = JSON.parse(body);
  
  // Call internal Ollama/n8n APIs
  const response = await fetch('http://172.20.0.4:5678/webhook/rag-query', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  
  const result = await response.json();
  return NextResponse.json(result);
}
```

### Environment Variables for Apps

Create `~/ai-pipeline/apps/.env.local`:

```bash
# Internal Service Endpoints (Docker Network)
OLLAMA_API_URL=http://172.20.0.5:11434
N8N_API_URL=http://172.20.0.4:5678
QDRANT_API_URL=http://172.20.0.3:6333
REDIS_URL=redis://:your_redis_password@172.20.0.2:6379

# PostgreSQL 18 - Application Backend
POSTGRES18_URL=postgresql://app1_user:app1_secure_password@172.20.0.6:5433/app1_db
POSTGRES18_URL_APP2=postgresql://app2_user:app2_secure_password@172.20.0.6:5433/app2_db
POSTGRES18_URL_SHARED=postgresql://postgres_admin:your_secure_postgres18_password@172.20.0.6:5433/shared_data

# Prisma (for NextJS apps)
DATABASE_URL=postgresql://app1_user:app1_secure_password@172.20.0.6:5433/app1_db

# API Keys
QDRANT_API_KEY=your_qdrant_api_key
N8N_API_KEY=your_n8n_api_key
N8N_WEBHOOK_SECRET=your_webhook_secret

# Public URLs
NEXT_PUBLIC_BASE_URL=https://shawnmcrowley.publicvm.com
```

---

## NextJS Integration

### Example: AI Chat Component

```typescript
// components/AIChat.tsx
'use client';

import { useState } from 'react';

export default function AIChat() {
  const [query, setQuery] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const res = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query })
      });
      
      const data = await res.json();
      setResponse(data.response);
    } catch (error) {
      setResponse('Error: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="ai-chat">
      <form onSubmit={handleSubmit}>
        <textarea
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Ask a question..."
        />
        <button type="submit" disabled={loading}>
          {loading ? 'Thinking...' : 'Ask'}
        </button>
      </form>
      {response && (
        <div className="response">
          <h3>Response:</h3>
          <p>{response}</p>
        </div>
      )}
    </div>
  );
}
```

### API Route

```typescript
// app/api/ai/chat/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  const { query } = await request.json();
  
  try {
    // Call n8n webhook
    const response = await fetch(
      'https://shawnmcrowley.publicvm.com/webhook/rag-query',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query })
      }
    );
    
    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to process query' },
      { status: 500 }
    );
  }
}
```

### Database Connection Example (PostgreSQL 18)

```typescript
// lib/db.ts
import { Pool } from 'pg';

const pool = new Pool({
  host: '172.20.0.6',
  port: 5433,
  user: process.env.POSTGRES18_USER,
  password: process.env.POSTGRES18_PASSWORD,
  database: process.env.POSTGRES18_DB,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

export default pool;

// app/api/data/route.ts
import { NextRequest, NextResponse } from 'next/server';
import pool from '@/lib/db';

export async function GET() {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW() as current_time');
    client.release();
    
    return NextResponse.json({ 
      status: 'Connected',
      timestamp: result.rows[0].current_time 
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Database connection failed' },
      { status: 500 }
    );
  }
}
```

### Prisma Configuration (Optional)

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

---

## Voice Input & Browser Speech API

### Speech-to-Text Component

```typescript
// components/VoiceInput.tsx
'use client';

import { useState, useRef, useCallback } from 'react';

interface VoiceInputProps {
  onTranscript: (text: string) => void;
  onSubmit: (text: string) => void;
}

export default function VoiceInput({ onTranscript, onSubmit }: VoiceInputProps) {
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [error, setError] = useState<string | null>(null);
  const recognitionRef = useRef<SpeechRecognition | null>(null);

  const startListening = useCallback(() => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      setError('Speech recognition not supported in this browser');
      return;
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    recognitionRef.current = new SpeechRecognition();
    
    recognitionRef.current.continuous = true;
    recognitionRef.current.interimResults = true;
    recognitionRef.current.lang = 'en-US';

    recognitionRef.current.onresult = (event: SpeechRecognitionEvent) => {
      let finalTranscript = '';
      let interimTranscript = '';

      for (let i = event.resultIndex; i < event.results.length; i++) {
        const transcript = event.results[i][0].transcript;
        if (event.results[i].isFinal) {
          finalTranscript += transcript;
        } else {
          interimTranscript += transcript;
        }
      }

      const fullTranscript = finalTranscript || interimTranscript;
      setTranscript(fullTranscript);
      onTranscript(fullTranscript);
    };

    recognitionRef.current.onerror = (event: SpeechRecognitionErrorEvent) => {
      console.error('Speech recognition error:', event.error);
      setError(`Error: ${event.error}`);
      setIsListening(false);
    };

    recognitionRef.current.onend = () => {
      setIsListening(false);
    };

    recognitionRef.current.start();
    setIsListening(true);
    setError(null);
  }, [onTranscript]);

  const stopListening = useCallback(() => {
    if (recognitionRef.current) {
      recognitionRef.current.stop();
    }
    setIsListening(false);
  }, []);

  const handleSubmit = () => {
    if (transcript.trim()) {
      onSubmit(transcript);
      setTranscript('');
    }
  };

  return (
    <div className="voice-input">
      <button
        onClick={isListening ? stopListening : startListening}
        className={`voice-button ${isListening ? 'listening' : ''}`}
      >
        {isListening ? '🔴 Stop Listening' : '🎤 Start Voice Input'}
      </button>
      
      {error && <div className="error">{error}</div>}
      
      {transcript && (
        <div className="transcript-container">
          <p className="transcript">{transcript}</p>
          <button onClick={handleSubmit} className="submit-button">
            Submit Query
          </button>
        </div>
      )}
      
      <style jsx>{`
        .voice-input {
          display: flex;
          flex-direction: column;
          gap: 1rem;
          padding: 1rem;
        }
        .voice-button {
          padding: 1rem 2rem;
          font-size: 1.1rem;
          background: #00ff41;
          color: #0a0e27;
          border: none;
          border-radius: 8px;
          cursor: pointer;
          font-weight: bold;
          transition: all 0.3s ease;
        }
        .voice-button:hover {
          transform: scale(1.05);
          box-shadow: 0 0 20px rgba(0, 255, 65, 0.4);
        }
        .voice-button.listening {
          background: #ff0041;
          animation: pulse 1s infinite;
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.7; }
        }
        .transcript-container {
          background: rgba(26, 26, 46, 0.8);
          border: 1px solid #00ff41;
          border-radius: 8px;
          padding: 1rem;
        }
        .transcript {
          color: #00ff41;
          font-family: 'Courier New', monospace;
          margin-bottom: 1rem;
        }
        .submit-button {
          padding: 0.75rem 1.5rem;
          background: transparent;
          border: 2px solid #00ff41;
          color: #00ff41;
          border-radius: 5px;
          cursor: pointer;
          transition: all 0.3s ease;
        }
        .submit-button:hover {
          background: #00ff41;
          color: #0a0e27;
        }
        .error {
          color: #ff0041;
          padding: 0.5rem;
          border: 1px solid #ff0041;
          border-radius: 5px;
        }
      `}</style>
    </div>
  );
}
```

### Voice Chat Integration Component

```typescript
// components/VoiceAIChat.tsx
'use client';

import { useState } from 'react';
import VoiceInput from './VoiceInput';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export default function VoiceAIChat() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [currentTranscript, setCurrentTranscript] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleTranscript = (text: string) => {
    setCurrentTranscript(text);
  };

  const handleVoiceSubmit = async (text: string) => {
    if (!text.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: text,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setIsLoading(true);
    setCurrentTranscript('');

    try {
      // Send voice query to n8n webhook
      const response = await fetch('/api/voice/query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query: text,
          sessionId: 'voice-session-' + Date.now(),
          timestamp: new Date().toISOString(),
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to get response from AI');
      }

      const data = await response.json();

      const aiMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: data.response || data.answer || 'No response received',
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, aiMessage]);
      
      // Optional: Use text-to-speech to read the response
      if ('speechSynthesis' in window) {
        const utterance = new SpeechSynthesisUtterance(aiMessage.content);
        utterance.rate = 1;
        utterance.pitch = 1;
        window.speechSynthesis.speak(utterance);
      }
    } catch (error) {
      console.error('Error:', error);
      const errorMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: 'Sorry, I encountered an error processing your request.',
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="voice-ai-chat">
      <h2>Voice AI Assistant</h2>
      
      <div className="messages-container">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`message ${message.role}`}
          >
            <div className="message-header">
              {message.role === 'user' ? 'You' : 'AI Assistant'}
            </div>
            <div className="message-content">{message.content}</div>
            <div className="message-time">
              {message.timestamp.toLocaleTimeString()}
            </div>
          </div>
        ))}
        {isLoading && (
          <div className="message assistant loading">
            <div className="typing-indicator">
              <span></span>
              <span></span>
              <span></span>
            </div>
          </div>
        )}
      </div>

      <VoiceInput
        onTranscript={handleTranscript}
        onSubmit={handleVoiceSubmit}
      />

      <style jsx>{`
        .voice-ai-chat {
          max-width: 800px;
          margin: 0 auto;
          padding: 2rem;
        }
        h2 {
          color: #00ff41;
          text-align: center;
          margin-bottom: 2rem;
        }
        .messages-container {
          background: rgba(10, 14, 39, 0.8);
          border: 2px solid #00ff41;
          border-radius: 10px;
          padding: 1.5rem;
          max-height: 500px;
          overflow-y: auto;
          margin-bottom: 2rem;
        }
        .message {
          margin-bottom: 1rem;
          padding: 1rem;
          border-radius: 8px;
        }
        .message.user {
          background: rgba(0, 255, 65, 0.1);
          border-left: 3px solid #00ff41;
        }
        .message.assistant {
          background: rgba(26, 26, 46, 0.8);
          border-left: 3px solid #00ccff;
        }
        .message-header {
          font-weight: bold;
          color: #00ff41;
          margin-bottom: 0.5rem;
        }
        .message-content {
          color: #88cc99;
          line-height: 1.6;
        }
        .message-time {
          font-size: 0.75rem;
          color: #666;
          margin-top: 0.5rem;
        }
        .typing-indicator {
          display: flex;
          gap: 0.5rem;
          padding: 1rem;
        }
        .typing-indicator span {
          width: 8px;
          height: 8px;
          background: #00ff41;
          border-radius: 50%;
          animation: bounce 1s infinite;
        }
        .typing-indicator span:nth-child(2) {
          animation-delay: 0.2s;
        }
        .typing-indicator span:nth-child(3) {
          animation-delay: 0.4s;
        }
        @keyframes bounce {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-10px); }
        }
      `}</style>
    </div>
  );
}
```

### Voice Query API Route

```typescript
// app/api/voice/query/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { query, sessionId, timestamp } = await request.json();

    if (!query || typeof query !== 'string') {
      return NextResponse.json(
        { error: 'Query is required' },
        { status: 400 }
      );
    }

    // Send to n8n webhook with voice context
    const response = await fetch(
      'https://shawnmcrowley.publicvm.com/webhook/voice-agent',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Voice-Session': sessionId || 'anonymous',
          'X-Timestamp': timestamp || new Date().toISOString(),
        },
        body: JSON.stringify({
          query: query.trim(),
          sessionId: sessionId || `session-${Date.now()}`,
          timestamp: timestamp || new Date().toISOString(),
          source: 'voice',
          metadata: {
            client: 'web',
            userAgent: request.headers.get('user-agent'),
          },
        }),
      }
    );

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
    }

    const data = await response.json();

    return NextResponse.json({
      success: true,
      response: data.response || data.answer || data.text,
      sources: data.sources || [],
      confidence: data.confidence || null,
      processingTime: data.processingTime || null,
    });
  } catch (error) {
    console.error('Voice query error:', error);
    return NextResponse.json(
      { 
        error: 'Failed to process voice query',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}
```

### TypeScript Types for Web Speech API

```typescript
// types/speech.d.ts

declare global {
  interface Window {
    SpeechRecognition: typeof SpeechRecognition;
    webkitSpeechRecognition: typeof SpeechRecognition;
  }

  interface SpeechRecognition extends EventTarget {
    continuous: boolean;
    interimResults: boolean;
    lang: string;
    maxAlternatives: number;
    onaudioend: ((this: SpeechRecognition, ev: Event) => any) | null;
    onaudiostart: ((this: SpeechRecognition, ev: Event) => any) | null;
    onend: ((this: SpeechRecognition, ev: Event) => any) | null;
    onerror: ((this: SpeechRecognition, ev: SpeechRecognitionErrorEvent) => any) | null;
    onnomatch: ((this: SpeechRecognition, ev: SpeechRecognitionEvent) => any) | null;
    onresult: ((this: SpeechRecognition, ev: SpeechRecognitionEvent) => any) | null;
    onsoundend: ((this: SpeechRecognition, ev: Event) => any) | null;
    onsoundstart: ((this: SpeechRecognition, ev: Event) => any) | null;
    onspeechend: ((this: SpeechRecognition, ev: Event) => any) | null;
    onspeechstart: ((this: SpeechRecognition, ev: Event) => any) | null;
    onstart: ((this: SpeechRecognition, ev: Event) => any) | null;
    start(): void;
    stop(): void;
    abort(): void;
  }

  interface SpeechRecognitionErrorEvent extends Event {
    error: string;
    message: string;
  }

  interface SpeechRecognitionEvent extends Event {
    resultIndex: number;
    results: SpeechRecognitionResultList;
  }

  interface SpeechRecognitionResultList {
    length: number;
    item(index: number): SpeechRecognitionResult;
    [index: number]: SpeechRecognitionResult;
  }

  interface SpeechRecognitionResult {
    isFinal: boolean;
    length: number;
    item(index: number): SpeechRecognitionAlternative;
    [index: number]: SpeechRecognitionAlternative;
  }

  interface SpeechRecognitionAlternative {
    transcript: string;
    confidence: number;
  }
}

export {};
```

---

## n8n Voice Agent Workflow

### AI Agent Configuration for Document Querying

```json
{
  "name": "Voice AI Document Agent",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "voice-agent",
        "responseMode": "responseNode"
      },
      "id": "webhook-receive",
      "name": "Voice Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "jsCode": "// Preprocess voice input\nconst query = $input.first().json.body.query;\nconst sessionId = $input.first().json.body.sessionId;\n\n// Clean up common voice-to-text artifacts\nconst cleanQuery = query\n  .replace(/^(hey |okay |so |um |uh )/i, '')\n  .replace(/(question mark|period|comma)/gi, '')\n  .trim();\n\nreturn {\n  json: {\n    originalQuery: query,\n    cleanQuery: cleanQuery,\n    sessionId: sessionId,\n    timestamp: new Date().toISOString()\n  }\n};"
      },
      "id": "preprocess",
      "name": "Preprocess Query",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [450, 300]
    },
    {
      "parameters": {
        "model": "llama2",
        "options": {}
      },
      "id": "embeddings",
      "name": "Generate Embeddings",
      "type": "n8n-nodes-base.ollamaEmbeddings",
      "typeVersion": 1,
      "position": [650, 200],
      "credentials": {
        "ollamaApi": {
          "id": "ollama-credentials",
          "name": "Ollama Credentials"
        }
      }
    },
    {
      "parameters": {
        "collection": "documents",
        "limit": 5,
        "options": {}
      },
      "id": "vector-search",
      "name": "Search Vector Store",
      "type": "n8n-nodes-base.qdrantVectorStore",
      "typeVersion": 1,
      "position": [850, 200],
      "credentials": {
        "qdrantApi": {
          "id": "qdrant-credentials",
          "name": "Qdrant Credentials"
        }
      }
    },
    {
      "parameters": {
        "operation": "executeQuery",
        "query": "SELECT content, metadata, similarity FROM pg_search WHERE query_embedding <-> $1 < 0.3 ORDER BY similarity DESC LIMIT 3",
        "additionalFields": {}
      },
      "id": "postgres-search",
      "name": "Query Postgres Vector",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2.2,
      "position": [850, 400],
      "credentials": {
        "postgres": {
          "id": "postgres18-credentials",
          "name": "Postgres 18 Credentials"
        }
      }
    },
    {
      "parameters": {
        "jsCode": "// Combine results from both vector stores\nconst qdrantResults = $input.all()[0].json;\nconst pgResults = $input.all()[1].json || [];\n\nconst combinedContext = [\n  ...qdrantResults.map(r => r.payload?.text || r.text || ''),\n  ...pgResults.map(r => r.content || '')\n].filter(text => text.length > 0);\n\n// Remove duplicates and limit context\nconst uniqueContext = [...new Set(combinedContext)].slice(0, 3);\n\nreturn {\n  json: {\n    context: uniqueContext.join('\\n\\n'),\n    sources: combinedContext.length,\n    query: $input.first().json.cleanQuery\n  }\n};"
      },
      "id": "combine-context",
      "name": "Combine Context",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [1050, 300]
    },
    {
      "parameters": {
        "model": "llama2",
        "options": {
          "temperature": 0.7,
          "systemPrompt": "You are a helpful AI assistant. Use the provided context to answer the user's question. If the context doesn't contain relevant information, say so clearly. Be concise but informative."
        },
        "messages": {
          "message": [
            {
              "role": "system",
              "content": "=Context:\n{{ $json.context }}"
            },
            {
              "role": "user",
              "content": "={{ $json.query }}"
            }
          ]
        }
      },
      "id": "llm-response",
      "name": "Generate Response",
      "type": "n8n-nodes-base.ollama",
      "typeVersion": 1,
      "position": [1250, 300],
      "credentials": {
        "ollamaApi": {
          "id": "ollama-credentials",
          "name": "Ollama Credentials"
        }
      }
    },
    {
      "parameters": {
        "options": {}
      },
      "id": "respond-webhook",
      "name": "Respond to Webhook",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1,
      "position": [1450, 300]
    },
    {
      "parameters": {
        "operation": "insert",
        "table": {
          "value": "conversation_history",
          "mode": "list"
        },
        "columns": {
          "mapping": [
            {
              "column": "session_id",
              "value": "={{ $input.first().json.sessionId }}"
            },
            {
              "column": "query",
              "value": "={{ $input.first().json.cleanQuery }}"
            },
            {
              "column": "response",
              "value": "={{ $input.all()[0].json.response || $input.all()[0].json.message?.content }}"
            },
            {
              "column": "sources",
              "value": "={{ $input.first().json.sources }}"
            },
            {
              "column": "created_at",
              "value": "={{ new Date().toISOString() }}"
            }
          ]
        }
      },
      "id": "save-history",
      "name": "Save Conversation",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2.2,
      "position": [1450, 500],
      "credentials": {
        "postgres": {
          "id": "postgres18-credentials",
          "name": "Postgres 18 Credentials"
        }
      }
    }
  ],
  "connections": {
    "Voice Webhook": {
      "main": [[{"node": "Preprocess Query", "type": "main", "index": 0}]]
    },
    "Preprocess Query": {
      "main": [
        [{"node": "Generate Embeddings", "type": "main", "index": 0}],
        [{"node": "Query Postgres Vector", "type": "main", "index": 0}]
      ]
    },
    "Generate Embeddings": {
      "main": [[{"node": "Search Vector Store", "type": "main", "index": 0}]]
    },
    "Search Vector Store": {
      "main": [[{"node": "Combine Context", "type": "main", "index": 0}]]
    },
    "Query Postgres Vector": {
      "main": [[{"node": "Combine Context", "type": "main", "index": 0}]]
    },
    "Combine Context": {
      "main": [
        [{"node": "Generate Response", "type": "main", "index": 0}],
        [{"node": "Save Conversation", "type": "main", "index": 0}]
      ]
    },
    "Generate Response": {
      "main": [[{"node": "Respond to Webhook", "type": "main", "index": 0}]]
    }
  },
  "settings": {
    "executionOrder": "v1",
    "errorWorkflow": "Error Handler"
  }
}
```

### n8n Credentials Setup

```bash
# In n8n UI, configure these credentials:

# 1. Ollama API
# Host: http://ai-ollama:11434
# No authentication required for local Ollama

# 2. Qdrant API
# Host: http://ai-qdrant:6333
# API Key: your_qdrant_api_key_here

# 3. PostgreSQL 18
# Host: ai-postgres18
# Port: 5433
# Database: shared_data
# User: postgres_admin
# Password: your_secure_password
```

### Document Ingestion Workflow for Voice Agent

```json
{
  "name": "Document Ingestion Pipeline",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "ingest-document"
      },
      "name": "Document Upload Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1
    },
    {
      "parameters": {
        "jsCode": "// Parse document content\nconst document = $input.first().json.body;\nreturn {\n  json: {\n    content: document.content,\n    metadata: {\n      title: document.title,\n      source: document.source,\n      author: document.author,\n      date: document.date,\n      docId: document.id || 'doc-' + Date.now()\n    }\n  }\n};"
      },
      "name": "Parse Document",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2
    },
    {
      "parameters": {
        "jsCode": "// Chunk document into segments\nconst content = $input.first().json.content;\nconst metadata = $input.first().json.metadata;\n\nfunction chunkText(text, maxLength = 500) {\n  const chunks = [];\n  const sentences = text.match(/[^.!?]+[.!?]+/g) || [text];\n  let currentChunk = '';\n  \n  for (const sentence of sentences) {\n    if ((currentChunk + sentence).length > maxLength) {\n      chunks.push(currentChunk.trim());\n      currentChunk = sentence;\n    } else {\n      currentChunk += sentence;\n    }\n  }\n  \n  if (currentChunk) chunks.push(currentChunk.trim());\n  return chunks;\n}\n\nconst chunks = chunkText(content);\n\nreturn chunks.map((chunk, index) => ({\n  json: {\n    chunk: chunk,\n    chunkIndex: index,\n    totalChunks: chunks.length,\n    metadata: metadata\n  }\n}));"
      },
      "name": "Chunk Document",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2
    },
    {
      "parameters": {
        "model": "mxbai-embed-large"
      },
      "name": "Generate Embeddings",
      "type": "n8n-nodes-base.ollamaEmbeddings",
      "typeVersion": 1
    },
    {
      "parameters": {
        "collection": "documents"
      },
      "name": "Store in Qdrant",
      "type": "n8n-nodes-base.qdrantVectorStore",
      "typeVersion": 1
    },
    {
      "parameters": {
        "operation": "insert",
        "table": "document_chunks",
        "columns": {
          "mapping": [
            { "column": "doc_id", "value": "={{ $json.metadata.docId }}" },
            { "column": "chunk_index", "value": "={{ $json.chunkIndex }}" },
            { "column": "content", "value": "={{ $json.chunk }}" },
            { "column": "embedding", "value": "={{ JSON.stringify($json.embedding) }}" },
            { "column": "metadata", "value": "={{ JSON.stringify($json.metadata) }}" },
            { "column": "created_at", "value": "={{ new Date().toISOString() }}" }
          ]
        }
      },
      "name": "Store in Postgres",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2.2
    }
  ],
  "connections": {
    "Document Upload Webhook": {
      "main": [[{"node": "Parse Document", "type": "main", "index": 0}]]
    },
    "Parse Document": {
      "main": [[{"node": "Chunk Document", "type": "main", "index": 0}]]
    },
    "Chunk Document": {
      "main": [[{"node": "Generate Embeddings", "type": "main", "index": 0}]]
    },
    "Generate Embeddings": {
      "main": [
        [{"node": "Store in Qdrant", "type": "main", "index": 0}],
        [{"node": "Store in Postgres", "type": "main", "index": 0}]
      ]
    }
  }
}
```

### PostgreSQL 18 Schema for Vector Storage

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Table for document chunks with embeddings
CREATE TABLE document_chunks (
    id SERIAL PRIMARY KEY,
    doc_id VARCHAR(255) NOT NULL,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1024),  -- Dimension matches mxbai-embed-large
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(doc_id, chunk_index)
);

-- Create index for vector similarity search
CREATE INDEX ON document_chunks USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Table for conversation history
CREATE TABLE conversation_history (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    query TEXT NOT NULL,
    response TEXT NOT NULL,
    sources INTEGER,
    processing_time_ms INTEGER,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for session lookups
CREATE INDEX idx_conversation_session ON conversation_history(session_id);
CREATE INDEX idx_conversation_created ON conversation_history(created_at);

-- Function for similarity search
CREATE OR REPLACE FUNCTION search_documents(
    query_embedding vector(1024),
    match_threshold float,
    match_count int
)
RETURNS TABLE(
    id integer,
    doc_id varchar,
    content text,
    metadata jsonb,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        dc.id,
        dc.doc_id,
        dc.content,
        dc.metadata,
        1 - (dc.embedding <=> query_embedding) AS similarity
    FROM document_chunks dc
    WHERE 1 - (dc.embedding <=> query_embedding) > match_threshold
    ORDER BY dc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
```

### JavaScript Hook for Real-Time Voice Processing

```javascript
// hooks/useVoiceAgent.ts
import { useState, useCallback, useRef, useEffect } from 'react';

interface VoiceAgentState {
  isListening: boolean;
  transcript: string;
  isProcessing: boolean;
  response: string | null;
  error: string | null;
}

interface UseVoiceAgentOptions {
  onResponse?: (response: string) => void;
  onError?: (error: string) => void;
  autoSubmit?: boolean;
  silenceTimeout?: number;
}

export function useVoiceAgent(options: UseVoiceAgentOptions = {}) {
  const {
    onResponse,
    onError,
    autoSubmit = true,
    silenceTimeout = 2000
  } = options;

  const [state, setState] = useState<VoiceAgentState>({
    isListening: false,
    transcript: '',
    isProcessing: false,
    response: null,
    error: null
  });

  const recognitionRef = useRef<SpeechRecognition | null>(null);
  const silenceTimerRef = useRef<NodeJS.Timeout | null>(null);
  const sessionIdRef = useRef<string>(`session-${Date.now()}`);

  const startListening = useCallback(() => {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      setState(prev => ({ ...prev, error: 'Speech recognition not supported' }));
      onError?.('Speech recognition not supported');
      return;
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    recognitionRef.current = new SpeechRecognition();
    
    recognitionRef.current.continuous = true;
    recognitionRef.current.interimResults = true;
    recognitionRef.current.lang = 'en-US';

    let finalTranscript = '';

    recognitionRef.current.onresult = (event: SpeechRecognitionEvent) => {
      let interimTranscript = '';

      for (let i = event.resultIndex; i < event.results.length; i++) {
        const transcript = event.results[i][0].transcript;
        if (event.results[i].isFinal) {
          finalTranscript += transcript + ' ';
        } else {
          interimTranscript += transcript;
        }
      }

      const fullTranscript = finalTranscript + interimTranscript;
      setState(prev => ({ ...prev, transcript: fullTranscript.trim() }));

      // Reset silence timer
      if (silenceTimerRef.current) {
        clearTimeout(silenceTimerRef.current);
      }

      if (autoSubmit && finalTranscript.trim()) {
        silenceTimerRef.current = setTimeout(() => {
          submitQuery(finalTranscript.trim());
        }, silenceTimeout);
      }
    };

    recognitionRef.current.onerror = (event: SpeechRecognitionErrorEvent) => {
      console.error('Speech recognition error:', event.error);
      setState(prev => ({ ...prev, isListening: false, error: event.error }));
      onError?.(event.error);
    };

    recognitionRef.current.onend = () => {
      setState(prev => ({ ...prev, isListening: false }));
    };

    recognitionRef.current.start();
    setState(prev => ({ ...prev, isListening: true, error: null }));
  }, [autoSubmit, silenceTimeout, onError]);

  const stopListening = useCallback(() => {
    if (silenceTimerRef.current) {
      clearTimeout(silenceTimerRef.current);
    }
    if (recognitionRef.current) {
      recognitionRef.current.stop();
    }
    setState(prev => ({ ...prev, isListening: false }));
  }, []);

  const submitQuery = useCallback(async (query: string) => {
    setState(prev => ({ ...prev, isProcessing: true, response: null }));

    try {
      const response = await fetch('/api/voice/query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query,
          sessionId: sessionIdRef.current,
          timestamp: new Date().toISOString()
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      setState(prev => ({
        ...prev,
        isProcessing: false,
        response: data.response,
        transcript: ''
      }));

      onResponse?.(data.response);

      // Text-to-speech
      if ('speechSynthesis' in window && data.response) {
        const utterance = new SpeechSynthesisUtterance(data.response);
        utterance.rate = 1;
        utterance.pitch = 1;
        window.speechSynthesis.speak(utterance);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      setState(prev => ({ ...prev, isProcessing: false, error: errorMessage }));
      onError?.(errorMessage);
    }
  }, [onResponse, onError]);

  const reset = useCallback(() => {
    setState({
      isListening: false,
      transcript: '',
      isProcessing: false,
      response: null,
      error: null
    });
    sessionIdRef.current = `session-${Date.now()}`;
  }, []);

  useEffect(() => {
    return () => {
      if (silenceTimerRef.current) {
        clearTimeout(silenceTimerRef.current);
      }
      if (recognitionRef.current) {
        recognitionRef.current.stop();
      }
    };
  }, []);

  return {
    ...state,
    startListening,
    stopListening,
    submitQuery,
    reset,
    sessionId: sessionIdRef.current
  };
}
```

---

## Deployment Commands

```bash
#!/bin/bash
# ~/ai-pipeline/deploy.sh

set -e

echo "🚀 Starting AI Pipeline Deployment..."

# 1. Start Docker containers
echo "📦 Starting Docker containers..."
cd ~/ai-pipeline
docker-compose up -d

# 2. Wait for services
echo "⏳ Waiting for services to be ready..."
sleep 30

# 3. Setup Ollama models
echo "🤖 Pulling Ollama models..."
docker exec ai-ollama ollama pull llama2 || true
docker exec ai-ollama ollama pull mxbai-embed-large || true

# 4. Setup Qdrant collection
echo "🗄️ Setting up Qdrant..."
curl -X PUT http://localhost:6333/collections/documents \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 1024,
      "distance": "Cosine"
    }
  }' || echo "Collection may already exist"

# 5. Setup PostgreSQL 18 databases
echo "🐘 Initializing PostgreSQL 18..."
sleep 10
# Wait for PostgreSQL 18 to be ready
docker exec ai-postgres18 pg_isready -U postgres_admin -p 5433
# Run initialization scripts
docker exec -i ai-postgres18 psql -U postgres_admin -p 5433 < ./postgres18/init-scripts/01-init.sql || echo "Databases may already exist"

# 6. Configure Nginx
echo "🔧 Configuring Nginx..."
sudo cp ~/ai-pipeline/nginx/nginx.conf /etc/nginx/sites-available/ai-pipeline
sudo ln -sf /etc/nginx/sites-available/ai-pipeline /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 6. Setup SSL
echo "🔒 Setting up SSL..."
if [ ! -d "/etc/letsencrypt/live/shawnmcrowley.publicvm.com" ]; then
    sudo certbot --nginx -d shawnmcrowley.publicvm.com --non-interactive --agree-tos --email shawnnmcrowley@gmail.com
fi

# 7. Start NextJS apps
echo "🌐 Starting NextJS applications..."
cd ~/ai-pipeline/apps/nextjs-app-1
npm install
npm run build
pm2 start npm --name "nextjs-app-1" -- start -- -p 3001

cd ~/ai-pipeline/apps/nextjs-app-2
npm install
npm run build
pm2 start npm --name "nextjs-app-2" -- start -- -p 3002

# 8. Save PM2 configuration
pm2 save

# 9. Setup firewall rules
echo "🛡️ Configuring firewall..."
sudo ufw allow from 172.20.0.0/24 to any port 3001,3002 proto tcp

echo "✅ Deployment complete!"
echo ""
echo "Access your applications:"
echo "  - Main: https://shawnmcrowley.publicvm.com"
echo "  - App 1: https://shawnmcrowley.publicvm.com/app1"
echo "  - App 2: https://shawnmcrowley.publicvm.com/app2"
echo ""
echo "Internal Services:"
echo "  - n8n: http://172.20.0.4:5678"
echo "  - PostgreSQL 18: 172.20.0.6:5433"
echo "    - app1_db: app1_user/app1_secure_password"
echo "    - app2_db: app2_user/app2_secure_password"
echo "    - shared_data: postgres_admin/[your_secure_password]"
echo ""
echo "Services Status:"
docker-compose ps
pm2 status
```

---

## Summary

### Architecture Highlights

1. **Security First**:
   - n8n and Ollama run in isolated Docker network (172.20.0.0/24)
   - No direct internet exposure - only accessible via internal network
   - SSL/TLS termination at Nginx with strong cipher configuration
   - Basic authentication required for internal API endpoints

2. **Webhook Strategy**:
   - Webhooks exposed through `/webhook/` path with rate limiting
   - IP whitelisting restricts access to localhost and Docker network
   - Optional HMAC signature verification for webhook security
   - Apps communicate internally via Docker network IPs

3. **RAG Pipeline**:
   - **Document Ingestion**: Files → Tika Parser → Text Chunks → Ollama Embeddings → Qdrant + PostgreSQL 18
   - **Query Flow**: User Query → Embedding → Vector Search (Hybrid: Qdrant + Postgres pgvector) → Context + LLM → Response
   - **Components**: Ollama (LLM), Qdrant (Vector DB), PostgreSQL 18 (pgvector), n8n (Orchestration)

4. **Voice Integration**:
   - **Browser Speech API**: Real-time voice input capture in NextJS
   - **Voice-to-Text**: Web Speech API for speech recognition with noise filtering
   - **AI Agent**: n8n processes voice queries, queries dual vector stores, generates responses
   - **Text-to-Speech**: Optional audio feedback of AI responses
   - **Auto-Submit**: Voice queries automatically submitted after silence detection

5. **Scalability**:
   - Redis queue for n8n execution handling
   - Separate containers for each service
   - Easy to add more NextJS apps on different ports
   - PostgreSQL 18 as dedicated application backend database
   - Hybrid vector storage (Qdrant + pgvector) for redundancy

5. **Access Points**:
   | Service | Public Access | Internal Access | Port |
   |---------|---------------|-----------------|------|
   | Nginx | ✅ Yes | ✅ Yes | 443 |
   | NextJS Apps | ✅ Via Nginx | ✅ Yes | 3001+ |
   | n8n Webhooks | ✅ Via Nginx | ✅ Yes | 5678 |
   | n8n Editor | ❌ No | ✅ Docker Only | 5678 |
   | Ollama API | ❌ No | ✅ Docker Only | 11434 |
   | Qdrant | ❌ No | ✅ Docker Only | 6333 |
   | PostgreSQL 18 | ❌ No | ✅ Docker Only | 5433 |

### Quick Start Checklist

- [ ] Install prerequisites (Docker, Nginx, Certbot)
- [ ] Clone/setup repository structure
- [ ] Configure `.env` files with secure passwords
- [ ] Run `docker-compose up -d`
- [ ] Initialize PostgreSQL 18 databases with pgvector extension
- [ ] Setup SSL with Certbot
- [ ] Configure Nginx and reload
- [ ] Pull Ollama models (llama2, mxbai-embed-large)
- [ ] Configure n8n credentials (Ollama, Qdrant, PostgreSQL)
- [ ] Import n8n workflows (Voice Agent, Document Ingestion)
- [ ] Deploy NextJS applications
- [ ] Test webhook endpoints
- [ ] Test voice input with Speech API
- [ ] Ingest documents into vector stores
- [ ] Test database connections from NextJS apps
- [ ] Test voice-to-AI query workflow

### Maintenance Commands

```bash
# View logs
docker-compose logs -f n8n
docker-compose logs -f ollama

# Update containers
docker-compose pull && docker-compose up -d

# Backup data
docker exec ai-postgres pg_dump -U n8n n8n > n8n_backup.sql
docker exec ai-postgres18 pg_dump -U postgres_admin -p 5433 app1_db > app1_backup.sql
docker exec ai-postgres18 pg_dump -U postgres_admin -p 5433 app2_db > app2_backup.sql
docker exec ai-postgres18 pg_dump -U postgres_admin -p 5433 shared_data > shared_backup.sql
tar -czf qdrant-backup.tar.gz ~/ai-pipeline/qdrant/storage
tar -czf postgres18-backup.tar.gz ~/ai-pipeline/postgres18/data

# Connect to PostgreSQL 18 CLI
docker exec -it ai-postgres18 psql -U postgres_admin -p 5433 -d shared_data

# View PostgreSQL 18 logs
docker-compose logs -f postgres18

# Monitor resources
docker stats
docker-compose top
```

This architecture ensures your AI services remain secure while allowing your web applications to leverage powerful LLM and automation capabilities through controlled webhook endpoints.
