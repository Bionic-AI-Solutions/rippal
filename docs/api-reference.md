# API Reference

Complete API documentation for Dev-PyNode.

## Base URL

```
Development: http://localhost:3000
Production: https://api.dev-pynode.bionic-ai-solutions.com
```

## Authentication

Dev-PyNode uses JWT (JSON Web Tokens) for authentication.

### Getting a Token

```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

### Using the Token

Include the token in the Authorization header:

```bash
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## API Endpoints

### Health & Status

#### GET /health

Check application health.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "uptime": 3600
}
```

#### GET /ready

Check if the application is ready to serve requests.

**Response:**
```json
{
  "status": "ready",
  "services": {
    "database": "connected",
    "redis": "connected",
    "storage": "connected"
  }
}
```

#### GET /metrics

Prometheus metrics endpoint.

**Response:** Prometheus format metrics

### Authentication

#### POST /api/auth/register

Register a new user.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

**Response:**
```json
{
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "name": "John Doe",
    "created_at": "2024-01-15T10:30:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### POST /api/auth/login

Authenticate a user.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### POST /api/auth/refresh

Refresh an access token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600
}
```

#### POST /api/auth/logout

Logout a user.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Successfully logged out"
}
```

### User Management

#### GET /api/users/me

Get current user profile.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "email": "user@example.com",
  "name": "John Doe",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

#### PUT /api/users/me

Update current user profile.

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "John Smith",
  "email": "john.smith@example.com"
}
```

**Response:**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "email": "john.smith@example.com",
  "name": "John Smith",
  "updated_at": "2024-01-15T11:00:00Z"
}
```

### AI Chat

#### POST /api/chat

Send a message to the AI.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "message": "Hello, how can you help me?",
  "model": "gpt-4",
  "temperature": 0.7,
  "max_tokens": 1000
}
```

**Response:**
```json
{
  "id": "chat-123",
  "message": "Hello! I'm an AI assistant that can help you with various tasks...",
  "model": "gpt-4",
  "usage": {
    "prompt_tokens": 15,
    "completion_tokens": 50,
    "total_tokens": 65
  },
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### GET /api/chat/history

Get chat history for the current user.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of messages to return (default: 50)
- `offset` (optional): Number of messages to skip (default: 0)

**Response:**
```json
{
  "messages": [
    {
      "id": "chat-123",
      "message": "Hello, how can you help me?",
      "response": "Hello! I'm an AI assistant...",
      "model": "gpt-4",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

### File Management

#### POST /api/files/upload

Upload a file.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request:**
```
file: <file>
```

**Response:**
```json
{
  "id": "file-123",
  "filename": "document.pdf",
  "size": 1024000,
  "mime_type": "application/pdf",
  "url": "https://storage.example.com/files/file-123",
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### GET /api/files

List user's files.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of files to return (default: 50)
- `offset` (optional): Number of files to skip (default: 0)

**Response:**
```json
{
  "files": [
    {
      "id": "file-123",
      "filename": "document.pdf",
      "size": 1024000,
      "mime_type": "application/pdf",
      "url": "https://storage.example.com/files/file-123",
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

#### GET /api/files/{id}

Get file details.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": "file-123",
  "filename": "document.pdf",
  "size": 1024000,
  "mime_type": "application/pdf",
  "url": "https://storage.example.com/files/file-123",
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### DELETE /api/files/{id}

Delete a file.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "File deleted successfully"
}
```

### WebSocket API

#### WebSocket Connection

Connect to the WebSocket endpoint:

```javascript
const ws = new WebSocket('ws://localhost:3001/ws');

ws.onopen = function() {
  console.log('Connected to WebSocket');
};

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};
```

#### Chat Messages

Send a chat message via WebSocket:

```json
{
  "type": "chat",
  "data": {
    "message": "Hello, AI!",
    "model": "gpt-4"
  }
}
```

Receive response:

```json
{
  "type": "chat_response",
  "data": {
    "id": "chat-123",
    "message": "Hello! How can I help you?",
    "model": "gpt-4"
  }
}
```

## Error Responses

All API endpoints return consistent error responses:

### 400 Bad Request

```json
{
  "error": "Bad Request",
  "message": "Invalid request parameters",
  "code": "INVALID_PARAMETERS",
  "details": {
    "field": "email",
    "reason": "Invalid email format"
  }
}
```

### 401 Unauthorized

```json
{
  "error": "Unauthorized",
  "message": "Authentication required",
  "code": "AUTHENTICATION_REQUIRED"
}
```

### 403 Forbidden

```json
{
  "error": "Forbidden",
  "message": "Insufficient permissions",
  "code": "INSUFFICIENT_PERMISSIONS"
}
```

### 404 Not Found

```json
{
  "error": "Not Found",
  "message": "Resource not found",
  "code": "RESOURCE_NOT_FOUND"
}
```

### 429 Too Many Requests

```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 60
}
```

### 500 Internal Server Error

```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred",
  "code": "INTERNAL_ERROR"
}
```

## Rate Limiting

API requests are rate limited:

- **Authenticated users**: 100 requests per 15 minutes
- **Unauthenticated users**: 10 requests per 15 minutes

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248000
```

## SDKs and Examples

### JavaScript/Node.js

```javascript
const axios = require('axios');

const api = axios.create({
  baseURL: 'http://localhost:3000',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

// Send a chat message
const response = await api.post('/api/chat', {
  message: 'Hello, AI!',
  model: 'gpt-4'
});

console.log(response.data);
```

### Python

```python
import requests

headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}

# Send a chat message
response = requests.post(
    'http://localhost:3000/api/chat',
    json={
        'message': 'Hello, AI!',
        'model': 'gpt-4'
    },
    headers=headers
)

print(response.json())
```

### cURL

```bash
# Send a chat message
curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, AI!",
    "model": "gpt-4"
  }'
```

## Interactive Documentation

Visit the interactive API documentation at:

- **Development**: http://localhost:3000/docs
- **Production**: https://api.dev-pynode.bionic-ai-solutions.com/docs

The interactive documentation allows you to:

- Explore all available endpoints
- Test API calls directly in the browser
- View request/response schemas
- Download OpenAPI specification

## OpenAPI Specification

Download the complete OpenAPI specification:

- **JSON**: http://localhost:3000/openapi.json
- **YAML**: http://localhost:3000/openapi.yaml

## Next Steps

- [Configuration Guide](configuration.md) - Configure the API
- [Development Guide](development.md) - Set up development environment
- [Deployment Guide](deployment.md) - Deploy to production
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
