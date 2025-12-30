 54 # Proxy to Next.js application at /ai_workflows
 55 location /ai_workflows {
 56     rewrite ^/ai_workflows(.*)$ $1 break;
 57     proxy_pass http://localhost:3000;
 58     proxy_http_version 1.1;
 59 
 60     proxy_set_header Upgrade $http_upgrade;
 61     proxy_set_header Connection 'upgrade';
 62     proxy_set_header Host $host;
 63     proxy_cache_bypass $http_upgrade;
 64 
 65     proxy_set_header X-Real-IP $remote_addr;
 66     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
 67     proxy_set_header X-Forwarded-Proto $scheme;
 68     proxy_set_header X-Forwarded-Host $host;
 69     proxy_set_header X-Forwarded-Port $server_port;
 70 }
 71 
 72 # Redirect /ai_workflows to /ai_workflows/
 73 location = /ai_workflows {
 74     return 301 /ai_workflows/;
 75 }
 76 
 77 
 78 location /_next/static {
 79     proxy_pass http://localhost:3000;
 80     add_header Cache-Control "public, immutable";
 81 }
 82 
 83 location /_next/image {
 84     proxy_pass http://localhost:3000;
 85     proxy_set_header X-Real-IP $remote_addr;
 86     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
 87     proxy_set_header X-Forwarded-Proto $scheme;
 88 }

