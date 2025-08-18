# 🚀 Deployment

El **deployment** es el proceso de llevar tu API desde desarrollo hasta producción. Incluye configuración de entornos, contenedores, CI/CD y monitoreo.

## 🎯 Estrategias de Deployment

### 1. **Docker Containers** - Empaquetado y portabilidad
### 2. **Cloud Platforms** - Heroku, Google Cloud, AWS
### 3. **CI/CD Pipelines** - Automatización de deployment
### 4. **Environment Configuration** - Variables y secrets
### 5. **Monitoring & Logging** - Observabilidad en producción

---

## 🐳 1. Containerización con Docker

```dockerfile
# Dockerfile
FROM dart:stable AS build

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY pubspec.yaml pubspec.lock ./

# Instalar dependencias
RUN dart pub get

# Copiar código fuente
COPY . .

# Compilar aplicación
RUN dart compile exe bin/server.dart -o bin/server

# Imagen de producción (multi-stage build)
FROM scratch

# Copiar binario compilado
COPY --from=build /app/bin/server /app/server

# Copiar archivos necesarios
COPY --from=build /app/config/ /app/config/

# Exponer puerto
EXPOSE 8080

# Variables de entorno por defecto
ENV PORT=8080
ENV HOST=0.0.0.0
ENV NODE_ENV=production

# Comando de inicio
ENTRYPOINT ["/app/server"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - HOST=0.0.0.0
      - DATABASE_URL=postgresql://user:password@db:5432/apidb
      - JWT_SECRET=your-super-secret-jwt-key
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=apidb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    command: redis-server --appendonly yes

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
      - ./nginx/html:/usr/share/nginx/html
    depends_on:
      - api
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

```nginx
# nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream api_backend {
        server api:8080;
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;

    server {
        listen 80;
        server_name api.yourdomain.com;

        # Redirect HTTP to HTTPS
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name api.yourdomain.com;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
        ssl_prefer_server_ciphers off;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=63072000";

        # API routes
        location /api/ {
            # Rate limiting
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Auth endpoints with stricter rate limiting
        location /api/auth/ {
            limit_req zone=auth burst=5 nodelay;
            
            proxy_pass http://api_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check (bypass rate limiting)
        location /api/health {
            proxy_pass http://api_backend;
            access_log off;
        }

        # Documentation
        location /docs/ {
            alias /usr/share/nginx/html/docs/;
            index index.html;
        }
    }
}
```

---

## ☁️ 2. Deployment en Cloud Platforms

### Heroku Deployment

```yaml
# heroku.yml
build:
  docker:
    web: Dockerfile
run:
  web: /app/server
```

```json
# app.json (para Heroku)
{
  "name": "api-kit-app",
  "description": "API built with api_kit framework",
  "repository": "https://github.com/yourusername/your-api",
  "logo": "https://your-logo-url.com/logo.png",
  "keywords": ["dart", "api", "rest"],
  "image": "heroku/dart",
  "stack": "heroku-22",
  "buildpacks": [
    {
      "url": "heroku/dart"
    }
  ],
  "formation": {
    "web": {
      "quantity": 1,
      "size": "hobby"
    }
  },
  "addons": [
    {
      "plan": "heroku-postgresql:hobby-dev"
    },
    {
      "plan": "heroku-redis:hobby-dev"
    }
  ],
  "env": {
    "NODE_ENV": {
      "description": "Environment mode",
      "value": "production"
    },
    "JWT_SECRET": {
      "description": "Secret key for JWT signing",
      "generator": "secret"
    },
    "API_RATE_LIMIT": {
      "description": "Requests per minute per IP",
      "value": "100"
    }
  },
  "scripts": {
    "postdeploy": "dart run bin/migrate.dart"
  }
}
```

### Google Cloud Run

```yaml
# cloudbuild.yaml
steps:
  # Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/api-kit:$COMMIT_SHA', '.']
  
  # Push to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/api-kit:$COMMIT_SHA']
  
  # Deploy to Cloud Run
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
    - 'run'
    - 'deploy'
    - 'api-kit'
    - '--image'
    - 'gcr.io/$PROJECT_ID/api-kit:$COMMIT_SHA'
    - '--region'
    - 'us-central1'
    - '--platform'
    - 'managed'
    - '--port'
    - '8080'
    - '--set-env-vars'
    - 'NODE_ENV=production'
    - '--max-instances'
    - '100'
    - '--memory'
    - '512Mi'
    - '--cpu'
    - '1'
    - '--timeout'
    - '300'
    - '--allow-unauthenticated'

options:
  logging: CLOUD_LOGGING_ONLY
```

```yaml
# service.yaml (Cloud Run)
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: api-kit
  annotations:
    run.googleapis.com/ingress: all
    run.googleapis.com/execution-environment: gen2
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/maxScale: "100"
        autoscaling.knative.dev/minScale: "1"
        run.googleapis.com/cpu-throttling: "false"
    spec:
      containerConcurrency: 1000
      timeoutSeconds: 300
      containers:
      - image: gcr.io/PROJECT_ID/api-kit:latest
        ports:
        - name: http1
          containerPort: 8080
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "8080"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: value
        resources:
          limits:
            cpu: 1000m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /api/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### AWS ECS

```json
# task-definition.json
{
  "family": "api-kit",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "api-kit",
      "image": "ACCOUNT.dkr.ecr.REGION.amazonaws.com/api-kit:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "8080"
        }
      ],
      "secrets": [
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:api-kit-jwt-secret"
        },
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:api-kit-db-url"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/api-kit",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8080/api/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

---

## 🔄 3. CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy API

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - uses: dart-lang/setup-dart@v1
      with:
        sdk: stable
    
    - name: Install dependencies
      run: dart pub get
    
    - name: Verify formatting
      run: dart format --output=none --set-exit-if-changed .
    
    - name: Analyze project source
      run: dart analyze --fatal-infos
    
    - name: Run tests
      run: dart test --coverage=coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      image: ${{ steps.image.outputs.image }}
      digest: ${{ steps.build.outputs.digest }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push Docker image
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
    
    - name: Output image
      id: image
      run: |
        echo "image=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}" >> $GITHUB_OUTPUT

  deploy-staging:
    if: github.ref == 'refs/heads/staging'
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
    - name: Deploy to staging
      run: |
        echo "Deploying ${{ needs.build.outputs.image }} to staging"
        # Add your staging deployment commands here

  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
    - name: Deploy to production
      run: |
        echo "Deploying ${{ needs.build.outputs.image }} to production"
        # Add your production deployment commands here
    
    - name: Create release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: v${{ github.run_number }}
        release_name: Release v${{ github.run_number }}
        body: |
          Automated release from commit ${{ github.sha }}
          
          Image: ${{ needs.build.outputs.image }}
          Digest: ${{ needs.build.outputs.digest }}
        draft: false
        prerelease: false
```

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - test
  - security
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

test:
  stage: test
  image: dart:stable
  script:
    - dart pub get
    - dart format --output=none --set-exit-if-changed .
    - dart analyze --fatal-infos
    - dart test --coverage=coverage
  coverage: '/lines......: \d+\.\d+%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: lcov
        path: coverage/lcov.info

security_scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy fs --exit-code 0 --no-progress --format table .
    - trivy fs --exit-code 1 --no-progress --severity HIGH,CRITICAL .

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
  only:
    - main
    - staging

deploy_staging:
  stage: deploy
  image: google/cloud-sdk:alpine
  script:
    - echo $GCP_SERVICE_KEY | base64 -d > gcp-key.json
    - gcloud auth activate-service-account --key-file gcp-key.json
    - gcloud config set project $GCP_PROJECT_ID
    - |
      gcloud run deploy api-kit-staging \
        --image $IMAGE_TAG \
        --region us-central1 \
        --platform managed \
        --set-env-vars NODE_ENV=staging
  environment:
    name: staging
    url: https://api-kit-staging-xxx.run.app
  only:
    - staging

deploy_production:
  stage: deploy
  image: google/cloud-sdk:alpine
  script:
    - echo $GCP_SERVICE_KEY | base64 -d > gcp-key.json
    - gcloud auth activate-service-account --key-file gcp-key.json
    - gcloud config set project $GCP_PROJECT_ID
    - |
      gcloud run deploy api-kit \
        --image $IMAGE_TAG \
        --region us-central1 \
        --platform managed \
        --set-env-vars NODE_ENV=production
  environment:
    name: production
    url: https://api.yourdomain.com
  when: manual
  only:
    - main
```

---

## ⚙️ 4. Configuración de Entornos

```dart
// lib/src/config/environment.dart
class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  static String get current {
    return const String.fromEnvironment('NODE_ENV', defaultValue: development);
  }
  
  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;
  
  static String get databaseUrl {
    return const String.fromEnvironment('DATABASE_URL', 
      defaultValue: 'postgresql://localhost:5432/api_kit_dev');
  }
  
  static String get jwtSecret {
    final secret = const String.fromEnvironment('JWT_SECRET');
    if (secret.isEmpty && isProduction) {
      throw StateError('JWT_SECRET environment variable is required in production');
    }
    return secret.isEmpty ? 'dev-secret-key' : secret;
  }
  
  static String get redisUrl {
    return const String.fromEnvironment('REDIS_URL', 
      defaultValue: 'redis://localhost:6379');
  }
  
  static int get port {
    return int.tryParse(const String.fromEnvironment('PORT')) ?? 8080;
  }
  
  static String get host {
    return const String.fromEnvironment('HOST', defaultValue: '0.0.0.0');
  }
  
  static int get rateLimitPerMinute {
    return int.tryParse(const String.fromEnvironment('API_RATE_LIMIT')) ?? 
      (isProduction ? 60 : 1000);
  }
  
  static Level get logLevel {
    final level = const String.fromEnvironment('LOG_LEVEL', defaultValue: 'info');
    switch (level.toLowerCase()) {
      case 'debug': return Level.DEBUG;
      case 'info': return Level.INFO;
      case 'warning': return Level.WARNING;
      case 'error': return Level.ERROR;
      default: return Level.INFO;
    }
  }
}
```

```bash
# .env.development
NODE_ENV=development
PORT=8080
HOST=localhost
DATABASE_URL=postgresql://localhost:5432/api_kit_dev
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-secret-key-not-for-production
API_RATE_LIMIT=1000
LOG_LEVEL=debug

# .env.staging
NODE_ENV=staging
PORT=8080
HOST=0.0.0.0
DATABASE_URL=postgresql://staging-host:5432/api_kit_staging
REDIS_URL=redis://staging-redis:6379
JWT_SECRET=staging-secret-key
API_RATE_LIMIT=200
LOG_LEVEL=info

# .env.production
NODE_ENV=production
PORT=8080
HOST=0.0.0.0
# DATABASE_URL y JWT_SECRET se configuran como secrets
API_RATE_LIMIT=60
LOG_LEVEL=warning
```

---

## 📊 5. Monitoreo y Logging

```dart
// lib/src/monitoring/metrics.dart
class Metrics {
  static final _requestCounter = Counter(
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'endpoint', 'status'],
  );
  
  static final _requestDuration = Histogram(
    name: 'http_request_duration_seconds',
    help: 'HTTP request duration in seconds',
    labelNames: ['method', 'endpoint'],
    buckets: [0.01, 0.05, 0.1, 0.5, 1.0, 5.0],
  );
  
  static final _activeConnections = Gauge(
    name: 'http_active_connections',
    help: 'Number of active HTTP connections',
  );
  
  static void recordRequest(String method, String endpoint, int statusCode, Duration duration) {
    _requestCounter.labels([method, endpoint, statusCode.toString()]).inc();
    _requestDuration.labels([method, endpoint]).observe(duration.inMilliseconds / 1000.0);
  }
  
  static void incrementActiveConnections() {
    _activeConnections.inc();
  }
  
  static void decrementActiveConnections() {
    _activeConnections.dec();
  }
}

// Middleware de métricas
class MetricsMiddleware {
  static Middleware metricsCollector() {
    return (Handler innerHandler) {
      return (Request request) async {
        final stopwatch = Stopwatch()..start();
        Metrics.incrementActiveConnections();
        
        try {
          final response = await innerHandler(request);
          
          stopwatch.stop();
          Metrics.recordRequest(
            request.method,
            _normalizeEndpoint(request.requestedUri.path),
            response.statusCode,
            stopwatch.elapsed,
          );
          
          return response;
          
        } catch (e) {
          stopwatch.stop();
          Metrics.recordRequest(
            request.method,
            _normalizeEndpoint(request.requestedUri.path),
            500,
            stopwatch.elapsed,
          );
          rethrow;
        } finally {
          Metrics.decrementActiveConnections();
        }
      };
    };
  }
  
  static String _normalizeEndpoint(String path) {
    return path.replaceAllMapped(RegExp(r'/\d+'), (match) => '/{id}');
  }
}
```

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'api-kit'
    static_configs:
      - targets: ['api:8080']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./monitoring/grafana/datasources:/etc/grafana/provisioning/datasources

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./monitoring/loki.yml:/etc/loki/local-config.yaml
    command: -config.file=/etc/loki/local-config.yaml

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./logs:/var/log/app
      - ./monitoring/promtail.yml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml

volumes:
  prometheus_data:
  grafana_data:
```

---

## 🏆 Mejores Prácticas para Deployment

### ✅ **DO's**
- ✅ Usar contenedores para consistencia entre entornos
- ✅ Implementar health checks y readiness probes
- ✅ Configurar CI/CD con tests automáticos
- ✅ Usar secrets para datos sensibles
- ✅ Implementar monitoreo y alertas
- ✅ Configurar logging estructurado

### ❌ **DON'Ts**
- ❌ Hardcodear configuración en el código
- ❌ Desplegar sin tests o health checks
- ❌ Exponer secrets en logs o variables de entorno
- ❌ Ignorar security scanning
- ❌ Deployar sin rollback plan
- ❌ Usar configuraciones de desarrollo en producción

### 🔄 Estrategias de Deployment
```
Blue-Green: Dos entornos idénticos, switch instantáneo
Rolling: Actualización gradual de instancias
Canary: Deployment a subset de usuarios
A/B Testing: Comparación de versiones
```

### 📋 Checklist de Production
```
✅ SSL/TLS configurado
✅ Rate limiting implementado
✅ Monitoreo y alertas activos
✅ Backups automáticos
✅ Security headers configurados
✅ CORS policy restrictiva
✅ Secrets management
✅ Load balancing
✅ Auto-scaling configurado
✅ Disaster recovery plan
```

---

**👉 [Siguiente: Examples y Uso Avanzado →](14-examples.md)**