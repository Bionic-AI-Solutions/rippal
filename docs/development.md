# Development Guide

This guide covers development setup, workflows, and best practices for Dev-PyNode.

## Development Environment Setup

### Prerequisites

- Node.js 18+
- Python 3.11+
- Docker & Docker Compose
- Git
- VS Code (recommended)

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Bionic-AI-Solutions/dev-pynode.git
   cd dev-pynode
   ```

2. **Install dependencies**
   ```bash
   # Node.js dependencies
   npm install
   
   # Python dependencies
   pip3 install -r requirements.txt
   pip3 install -r requirements-dev.txt
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start development services**
   ```bash
   docker-compose up -d
   ```

## Project Structure

```
dev-pynode/
├── backend/                    # Backend services
│   ├── nodejs/                # Node.js API
│   │   ├── src/               # Source code
│   │   ├── tests/             # Tests
│   │   └── package.json       # Dependencies
│   └── python/                # Python services
│       ├── app/               # FastAPI application
│       ├── tests/             # Tests
│       └── requirements.txt   # Dependencies
├── frontend/                   # React frontend
│   ├── src/                   # Source code
│   ├── public/                # Static assets
│   └── package.json           # Dependencies
├── k8s/                       # Kubernetes manifests
├── scripts/                   # Utility scripts
├── tests/                     # Integration tests
└── docs/                      # Documentation
```

## Development Workflow

### 1. Feature Development

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-awesome-feature
   ```

2. **Create feature documentation**
   ```bash
   mkdir -p docs/feature/my-awesome-feature
   # Create implementation-plan.md, technical-architecture.md, etc.
   ```

3. **Implement the feature**
   - Write code following the coding standards
   - Add tests for new functionality
   - Update documentation

4. **Test your changes**
   ```bash
   npm test
   pytest tests/
   ```

5. **Create a pull request**
   - Ensure all CI checks pass
   - Request code review
   - Address feedback

### 2. Code Quality

#### TypeScript/JavaScript

```bash
# Lint code
npm run lint

# Fix linting issues
npm run lint:fix

# Format code
npm run format

# Type check
npm run type-check
```

#### Python

```bash
# Lint code
flake8 backend/python/
black backend/python/
isort backend/python/

# Type check
mypy backend/python/

# Security check
bandit -r backend/python/
```

### 3. Testing

#### Unit Tests

```bash
# Node.js unit tests
npm run test:unit

# Python unit tests
pytest tests/unit/ -v
```

#### Integration Tests

```bash
# Integration tests
npm run test:integration
pytest tests/integratione2e/ -v
```

#### Test Coverage

```bash
# Generate coverage report
npm run test:coverage
pytest --cov=backend tests/ --cov-report=html
```

## Backend Development

### Node.js API

#### Project Structure

```
backend/nodejs/
├── src/
│   ├── controllers/           # Request handlers
│   ├── middleware/            # Express middleware
│   ├── models/               # Data models
│   ├── routes/               # API routes
│   ├── services/             # Business logic
│   ├── utils/                # Utility functions
│   ├── config/               # Configuration
│   └── index.ts              # Application entry point
├── tests/
└── package.json
```

#### Adding a New Endpoint

1. **Create the route**
   ```typescript
   // src/routes/users.ts
   import { Router } from 'express';
   import { getUsers, createUser } from '../controllers/users';
   
   const router = Router();
   
   router.get('/', getUsers);
   router.post('/', createUser);
   
   export default router;
   ```

2. **Create the controller**
   ```typescript
   // src/controllers/users.ts
   import { Request, Response } from 'express';
   import { UserService } from '../services/user';
   
   export const getUsers = async (req: Request, res: Response) => {
     try {
       const users = await UserService.getAll();
       res.json(users);
     } catch (error) {
       res.status(500).json({ error: 'Internal server error' });
     }
   };
   ```

3. **Add tests**
   ```typescript
   // tests/controllers/users.test.ts
   import request from 'supertest';
   import app from '../../src/app';
   
   describe('Users API', () => {
     it('should get all users', async () => {
       const response = await request(app)
         .get('/api/users')
         .expect(200);
       
       expect(response.body).toBeInstanceOf(Array);
     });
   });
   ```

### Python Services

#### Project Structure

```
backend/python/
├── app/
│   ├── api/                  # API routes
│   ├── core/                 # Core functionality
│   ├── models/               # Database models
│   ├── schemas/              # Pydantic schemas
│   ├── services/             # Business logic
│   └── main.py               # Application entry point
├── tests/
└── requirements.txt
```

#### Adding a New Service

1. **Create the service**
   ```python
   # app/services/ai_service.py
   from typing import Dict, Any
   import openai
   
   class AIService:
       def __init__(self):
           self.client = openai.OpenAI()
       
       async def chat(self, message: str, model: str = "gpt-4") -> Dict[str, Any]:
           response = await self.client.chat.completions.create(
               model=model,
               messages=[{"role": "user", "content": message}]
           )
           return {
               "message": response.choices[0].message.content,
               "model": model
           }
   ```

2. **Create the API endpoint**
   ```python
   # app/api/chat.py
   from fastapi import APIRouter, Depends
   from app.services.ai_service import AIService
   from app.schemas.chat import ChatRequest, ChatResponse
   
   router = APIRouter()
   
   @router.post("/chat", response_model=ChatResponse)
   async def chat(
       request: ChatRequest,
       ai_service: AIService = Depends()
   ):
       response = await ai_service.chat(request.message, request.model)
       return ChatResponse(**response)
   ```

3. **Add tests**
   ```python
   # tests/test_ai_service.py
   import pytest
   from app.services.ai_service import AIService
   
   @pytest.mark.asyncio
   async def test_chat():
       service = AIService()
       response = await service.chat("Hello, AI!")
       
       assert "message" in response
       assert "model" in response
   ```

## Frontend Development

### React Application

#### Project Structure

```
frontend/
├── src/
│   ├── components/           # Reusable components
│   ├── pages/               # Page components
│   ├── hooks/               # Custom hooks
│   ├── services/            # API services
│   ├── utils/               # Utility functions
│   ├── types/               # TypeScript types
│   └── App.tsx              # Main application
├── public/
└── package.json
```

#### Adding a New Component

1. **Create the component**
   ```typescript
   // src/components/ChatMessage.tsx
   import React from 'react';
   
   interface ChatMessageProps {
     message: string;
     isUser: boolean;
     timestamp: Date;
   }
   
   export const ChatMessage: React.FC<ChatMessageProps> = ({
     message,
     isUser,
     timestamp
   }) => {
     return (
       <div className={`message ${isUser ? 'user' : 'ai'}`}>
         <div className="content">{message}</div>
         <div className="timestamp">
           {timestamp.toLocaleTimeString()}
         </div>
       </div>
     );
   };
   ```

2. **Add tests**
   ```typescript
   // src/components/__tests__/ChatMessage.test.tsx
   import React from 'react';
   import { render, screen } from '@testing-library/react';
   import { ChatMessage } from '../ChatMessage';
   
   describe('ChatMessage', () => {
     it('renders user message', () => {
       render(
         <ChatMessage
           message="Hello, AI!"
           isUser={true}
           timestamp={new Date()}
         />
       );
       
       expect(screen.getByText('Hello, AI!')).toBeInTheDocument();
     });
   });
   ```

## Database Development

### Migrations

#### Node.js (using Knex)

```bash
# Create a migration
npx knex migrate:make create_users_table

# Run migrations
npx knex migrate:latest

# Rollback migrations
npx knex migrate:rollback
```

#### Python (using Alembic)

```bash
# Create a migration
alembic revision --autogenerate -m "Create users table"

# Run migrations
alembic upgrade head

# Rollback migrations
alembic downgrade -1
```

### Seeding Data

```bash
# Seed development data
npm run db:seed

# Seed test data
ENV=test npm run db:seed
```

## AI Integration

### Adding New AI Models

1. **Update the AI service**
   ```typescript
   // src/services/ai.ts
   export class AIService {
     async chat(message: string, model: string = 'gpt-4') {
       // Implementation
     }
     
     async generateImage(prompt: string, model: string = 'dall-e-3') {
       // Implementation
     }
   }
   ```

2. **Add model configuration**
   ```typescript
   // src/config/ai.ts
   export const AI_MODELS = {
     chat: ['gpt-4', 'gpt-3.5-turbo', 'claude-3'],
     image: ['dall-e-3', 'midjourney'],
     local: ['llama2', 'codellama']
   };
   ```

## Testing

### Unit Testing

#### Node.js (Jest)

```typescript
// tests/services/user.test.ts
import { UserService } from '../../src/services/user';

describe('UserService', () => {
  it('should create a user', async () => {
    const userData = {
      email: 'test@example.com',
      name: 'Test User'
    };
    
    const user = await UserService.create(userData);
    
    expect(user.email).toBe(userData.email);
    expect(user.name).toBe(userData.name);
  });
});
```

#### Python (pytest)

```python
# tests/test_user_service.py
import pytest
from app.services.user import UserService

def test_create_user():
    user_data = {
        "email": "test@example.com",
        "name": "Test User"
    }
    
    user = UserService.create(user_data)
    
    assert user.email == user_data["email"]
    assert user.name == user_data["name"]
```

### Integration Testing

```typescript
// tests/integration/api.test.ts
import request from 'supertest';
import app from '../../src/app';

describe('API Integration Tests', () => {
  it('should handle complete user flow', async () => {
    // Register user
    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User'
      });
    
    expect(registerResponse.status).toBe(201);
    
    // Login user
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'password123'
      });
    
    expect(loginResponse.status).toBe(200);
    expect(loginResponse.body.access_token).toBeDefined();
  });
});
```

## Debugging

### Backend Debugging

#### Node.js

```bash
# Start with debugger
npm run dev:debug

# Attach debugger in VS Code
# Add breakpoints and use F5 to start debugging
```

#### Python

```bash
# Start with debugger
python -m debugpy --listen 5678 --wait-for-client app/main.py

# Attach debugger in VS Code
# Add breakpoints and use F5 to start debugging
```

### Frontend Debugging

```bash
# Start development server
npm run dev

# Open browser dev tools
# Use React Developer Tools extension
```

## Performance Optimization

### Backend

1. **Database optimization**
   - Add indexes for frequently queried fields
   - Use connection pooling
   - Implement caching with Redis

2. **API optimization**
   - Implement pagination
   - Use compression middleware
   - Add rate limiting

### Frontend

1. **Bundle optimization**
   - Code splitting
   - Lazy loading
   - Tree shaking

2. **Performance monitoring**
   - Use React DevTools Profiler
   - Monitor bundle size
   - Implement performance budgets

## Security

### Backend Security

1. **Input validation**
   - Use Joi for Node.js
   - Use Pydantic for Python

2. **Authentication**
   - JWT tokens
   - Refresh token rotation
   - Rate limiting

3. **Data protection**
   - Encrypt sensitive data
   - Use HTTPS
   - Implement CORS

### Frontend Security

1. **XSS prevention**
   - Sanitize user input
   - Use Content Security Policy
   - Avoid dangerouslySetInnerHTML

2. **CSRF protection**
   - Use CSRF tokens
   - Implement SameSite cookies

## Deployment

### Local Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Staging Deployment

```bash
# Deploy to staging
kubectl apply -k k8s/overlays/staging

# Check deployment
kubectl get pods -n dev-pynode
```

### Production Deployment

```bash
# Deploy to production
kubectl apply -k k8s/overlays/production

# Monitor deployment
kubectl rollout status deployment/dev-pynode -n dev-pynode
```

## Best Practices

### Code Quality

1. **Follow coding standards**
   - Use ESLint and Prettier for JavaScript/TypeScript
   - Use Black and isort for Python
   - Write meaningful commit messages

2. **Testing**
   - Write tests for all new features
   - Maintain high test coverage
   - Use TDD when possible

3. **Documentation**
   - Document all public APIs
   - Keep README files updated
   - Write clear commit messages

### Git Workflow

1. **Branch naming**
   - `feature/feature-name`
   - `bugfix/bug-description`
   - `hotfix/urgent-fix`

2. **Commit messages**
   ```
   feat: add user authentication
   fix: resolve database connection issue
   docs: update API documentation
   test: add unit tests for user service
   ```

3. **Pull requests**
   - Write descriptive PR descriptions
   - Link related issues
   - Request code reviews

## Troubleshooting

### Common Issues

1. **Port conflicts**
   ```bash
   # Check port usage
   netstat -tulpn | grep :3000
   
   # Kill process using port
   sudo kill -9 $(lsof -t -i:3000)
   ```

2. **Database connection issues**
   ```bash
   # Check PostgreSQL status
   docker-compose exec postgres pg_isready -U postgres
   
   # Reset database
   docker-compose down -v
   docker-compose up -d
   ```

3. **Dependency issues**
   ```bash
   # Clear npm cache
   npm cache clean --force
   
   # Reinstall dependencies
   rm -rf node_modules package-lock.json
   npm install
   ```

## Next Steps

- [API Reference](api-reference.md) - Learn about the API
- [Deployment Guide](deployment.md) - Deploy to production
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
- [Architecture Documentation](architecture.md) - Understand the system design
