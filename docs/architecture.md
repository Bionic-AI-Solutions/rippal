# System Architecture

This document describes the overall architecture of Dev-PyNode.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Layer                            │
├─────────────────────────────────────────────────────────────────┤
│  Web Browser  │  Mobile App  │  API Client  │  CLI Tools      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Load Balancer                             │
├─────────────────────────────────────────────────────────────────┤
│                    NGINX / Traefik                             │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  Frontend (React)  │  Backend API (Node.js)  │  Python Services │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Service Layer                             │
├─────────────────────────────────────────────────────────────────┤
│  Auth Service  │  AI Service  │  File Service  │  Chat Service │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                │
├─────────────────────────────────────────────────────────────────┤
│  PostgreSQL  │  Redis Cache  │  MinIO Storage  │  AI Models    │
└─────────────────────────────────────────────────────────────────┘
```

## Component Overview

### Frontend Layer

**Technology**: React 18+ with TypeScript

**Responsibilities**:
- User interface and user experience
- Client-side routing and state management
- Real-time communication via WebSockets
- File upload and management interface

**Key Features**:
- Responsive design with Material-UI/Tailwind CSS
- Real-time chat interface
- File upload with progress tracking
- Authentication and user management
- API documentation viewer

### Backend Layer

#### Node.js API Server

**Technology**: Express.js with TypeScript

**Responsibilities**:
- RESTful API endpoints
- Authentication and authorization
- Request validation and sanitization
- Rate limiting and security
- WebSocket connections

**Key Features**:
- JWT-based authentication
- Role-based access control
- API versioning
- Comprehensive error handling
- Request/response logging

#### Python Services

**Technology**: FastAPI with Python 3.11+

**Responsibilities**:
- AI model integration
- Data processing and analysis
- Background task processing
- Machine learning operations

**Key Features**:
- Async/await support
- Automatic API documentation
- Type validation with Pydantic
- Background task queue with Celery
- AI model management

### Service Layer

#### Authentication Service

**Components**:
- JWT token management
- User registration and login
- Password hashing and validation
- Session management
- OAuth integration (optional)

**Security Features**:
- Bcrypt password hashing
- JWT token rotation
- Rate limiting on auth endpoints
- Account lockout protection

#### AI Service

**Components**:
- OpenAI API integration
- Local AI model management (Ollama)
- Model selection and routing
- Response caching
- Usage tracking and analytics

**Supported Models**:
- OpenAI: GPT-4, GPT-3.5-turbo
- Local: Llama2, CodeLlama, Mistral
- Custom fine-tuned models

#### File Service

**Components**:
- File upload and storage
- File type validation
- Image processing and resizing
- Virus scanning
- CDN integration

**Storage Options**:
- MinIO (S3-compatible)
- AWS S3
- Local filesystem (development)

#### Chat Service

**Components**:
- Real-time messaging
- Message history and persistence
- Typing indicators
- Message reactions
- File sharing in chat

### Data Layer

#### PostgreSQL Database

**Schema Design**:
```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Chat messages table
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    message TEXT NOT NULL,
    response TEXT,
    model VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Files table
CREATE TABLE files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Features**:
- Connection pooling
- Read replicas for scaling
- Automated backups
- Point-in-time recovery

#### Redis Cache

**Use Cases**:
- Session storage
- API response caching
- Rate limiting counters
- Real-time data (WebSocket state)
- Background job queues

**Configuration**:
- Memory optimization
- Persistence settings
- Cluster support (production)
- Security and authentication

#### MinIO Storage

**Features**:
- S3-compatible API
- Object versioning
- Lifecycle policies
- Cross-region replication
- Encryption at rest

**Bucket Structure**:
```
dev-pynode-storage/
├── users/
│   └── {user_id}/
│       ├── avatars/
│       ├── documents/
│       └── uploads/
├── shared/
│   ├── templates/
│   └── assets/
└── system/
    ├── logs/
    └── backups/
```

## Data Flow

### User Authentication Flow

```
1. User submits login credentials
2. Backend validates credentials against database
3. Backend generates JWT token
4. Token stored in Redis for session management
5. Token returned to client
6. Client stores token for subsequent requests
```

### AI Chat Flow

```
1. User sends message via WebSocket or REST API
2. Message validated and stored in database
3. AI service processes message with selected model
4. Response generated and cached in Redis
5. Response sent back to user
6. Message history updated in database
```

### File Upload Flow

```
1. User selects file for upload
2. Frontend validates file type and size
3. File uploaded to MinIO storage
4. File metadata stored in database
5. File URL returned to user
6. File available for sharing in chat
```

## Security Architecture

### Authentication & Authorization

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │    │   Backend       │    │   Database      │
│                 │    │                 │    │                 │
│ 1. Login        │───▶│ 2. Validate     │───▶│ 3. Check User   │
│                 │    │    Credentials  │    │    Credentials  │
│                 │◀───│ 4. Generate JWT │◀───│ 4. Return User  │
│ 5. Store Token  │    │    Token        │    │    Data         │
│                 │    │                 │    │                 │
│ 6. API Request  │───▶│ 7. Verify JWT   │───▶│ 8. Check        │
│    + JWT        │    │    Token        │    │    Permissions  │
│                 │◀───│ 9. Process      │◀───│ 9. Return       │
│ 10. Response    │    │    Request      │    │    Data         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Network Security

**Firewall Rules**:
- Ingress: 80, 443 (HTTP/HTTPS)
- Internal: 3000 (API), 5432 (PostgreSQL), 6379 (Redis)
- Management: 22 (SSH), 9001 (MinIO Console)

**Network Segmentation**:
- Public subnet: Load balancer, ingress
- Private subnet: Application servers
- Database subnet: Database servers
- Management subnet: Monitoring, logging

### Data Protection

**Encryption**:
- TLS 1.3 for data in transit
- AES-256 for data at rest
- Encrypted database connections
- Encrypted file storage

**Access Control**:
- Role-based access control (RBAC)
- Principle of least privilege
- Regular access reviews
- Audit logging

## Scalability Architecture

### Horizontal Scaling

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │   App Server 1  │    │   App Server 2  │
│                 │    │                 │    │                 │
│  - Health Check │───▶│  - API Server   │    │  - API Server   │
│  - SSL Term.    │    │  - WebSocket    │    │  - WebSocket    │
│  - Rate Limit   │    │  - Auth Service │    │  - Auth Service │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Database      │    │   Cache Layer   │
                       │   Cluster       │    │   (Redis)       │
                       │                 │    │                 │
                       │  - Primary      │    │  - Session      │
                       │  - Read Replica │    │  - Cache        │
                       │  - Backup       │    │  - Queue        │
                       └─────────────────┘    └─────────────────┘
```

### Auto-scaling Configuration

**Kubernetes HPA**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: dev-pynode-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: dev-pynode
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Database Scaling**:
- Read replicas for read-heavy workloads
- Connection pooling
- Query optimization
- Caching strategies

## Monitoring Architecture

### Observability Stack

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │    │   Prometheus    │    │   Grafana       │
│                 │    │                 │    │                 │
│  - Metrics      │───▶│  - Collection   │───▶│  - Dashboards   │
│  - Logs         │    │  - Storage      │    │  - Alerts       │
│  - Traces       │    │  - Querying     │    │  - Visualization│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   AlertManager  │
                       │                 │
                       │  - Notifications│
                       │  - Escalation   │
                       │  - Integration  │
                       └─────────────────┘
```

### Key Metrics

**Application Metrics**:
- Request rate and latency
- Error rates and types
- User authentication metrics
- AI model usage and performance
- File upload/download metrics

**Infrastructure Metrics**:
- CPU and memory usage
- Disk I/O and network traffic
- Database connection pools
- Cache hit/miss ratios
- Storage utilization

**Business Metrics**:
- Active users
- API usage patterns
- Feature adoption rates
- User engagement metrics

## Deployment Architecture

### Development Environment

```
┌─────────────────────────────────────────────────────────────────┐
│                    Development Setup                           │
├─────────────────────────────────────────────────────────────────┤
│  Docker Compose                                                 │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │   Backend   │ │  Frontend   │ │  Database   │              │
│  │   (Node.js) │ │   (React)   │ │ (PostgreSQL)│              │
│  └─────────────┘ └─────────────┘ └─────────────┘              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐              │
│  │    Redis    │ │   MinIO     │ │   Ollama    │              │
│  │   (Cache)   │ │ (Storage)   │ │   (AI)      │              │
│  └─────────────┘ └─────────────┘ └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### Production Environment

```
┌─────────────────────────────────────────────────────────────────┐
│                    Production Setup                            │
├─────────────────────────────────────────────────────────────────┤
│  Kubernetes Cluster                                             │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Ingress Controller (NGINX/Traefik)                        ││
│  └─────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Application Pods (Auto-scaled)                            ││
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          ││
│  │  │   Backend   │ │  Frontend   │ │  Python     │          ││
│  │  │   (3 pods)  │ │   (2 pods)  │ │ Services    │          ││
│  │  └─────────────┘ └─────────────┘ └─────────────┘          ││
│  └─────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  Data Layer                                                ││
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          ││
│  │  │ PostgreSQL  │ │    Redis    │ │   MinIO     │          ││
│  │  │ (StatefulSet)│ │ (Cluster)   │ │ (StatefulSet)│          ││
│  │  └─────────────┘ └─────────────┘ └─────────────┘          ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Frontend
- **React 18+**: UI framework
- **TypeScript**: Type safety
- **Material-UI/Tailwind**: Styling
- **React Query**: State management
- **Socket.io**: Real-time communication

### Backend
- **Node.js 18+**: Runtime
- **Express.js**: Web framework
- **TypeScript**: Type safety
- **FastAPI**: Python web framework
- **Python 3.11+**: Runtime

### Database
- **PostgreSQL 15**: Primary database
- **Redis 7**: Caching and sessions
- **MinIO**: Object storage

### AI/ML
- **OpenAI API**: GPT models
- **Ollama**: Local AI models
- **Transformers**: Model management

### Infrastructure
- **Docker**: Containerization
- **Kubernetes**: Orchestration
- **NGINX**: Load balancing
- **Prometheus**: Monitoring
- **Grafana**: Visualization

### DevOps
- **GitHub Actions**: CI/CD
- **ArgoCD**: GitOps
- **Helm**: Package management
- **Kustomize**: Configuration management

## Performance Considerations

### Caching Strategy

**Multi-level Caching**:
1. **Browser Cache**: Static assets, API responses
2. **CDN Cache**: Global content delivery
3. **Application Cache**: Redis for session data
4. **Database Cache**: Query result caching

### Database Optimization

**Indexing Strategy**:
```sql
-- User lookup by email
CREATE INDEX idx_users_email ON users(email);

-- Chat messages by user and date
CREATE INDEX idx_chat_messages_user_date ON chat_messages(user_id, created_at);

-- Files by user
CREATE INDEX idx_files_user ON files(user_id);
```

**Query Optimization**:
- Connection pooling
- Prepared statements
- Query result caching
- Read replicas for scaling

### API Performance

**Optimization Techniques**:
- Response compression
- Pagination for large datasets
- Field selection (GraphQL-style)
- Request/response caching
- Rate limiting

## Disaster Recovery

### Backup Strategy

**Database Backups**:
- Daily automated backups
- Point-in-time recovery
- Cross-region replication
- Backup verification

**File Storage Backups**:
- Object versioning
- Cross-region replication
- Lifecycle policies
- Backup validation

### Recovery Procedures

**RTO (Recovery Time Objective)**: 4 hours
**RPO (Recovery Point Objective)**: 1 hour

**Recovery Steps**:
1. Assess damage and scope
2. Restore database from backup
3. Restore file storage
4. Deploy application
5. Verify functionality
6. Notify users

## Future Architecture Considerations

### Microservices Migration

**Potential Services**:
- User Management Service
- AI Processing Service
- File Management Service
- Notification Service
- Analytics Service

### Event-Driven Architecture

**Event Streaming**:
- Apache Kafka for event streaming
- Event sourcing for audit trails
- CQRS for read/write separation
- Saga pattern for distributed transactions

### Multi-Cloud Strategy

**Cloud Providers**:
- Primary: AWS/GCP/Azure
- Secondary: Different provider for DR
- CDN: Global content delivery
- Edge computing for AI inference

## Next Steps

- [Configuration Guide](configuration.md) - System configuration
- [Development Guide](development.md) - Development setup
- [Deployment Guide](deployment.md) - Production deployment
- [Monitoring Guide](monitoring.md) - System monitoring
