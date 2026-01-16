# OpenCode CLI with Ollama: Enterprise Setup Guide

## Executive Summary

OpenCode is an open-source AI coding assistant that provides a vendor-agnostic approach to AI-powered development. This guide covers comprehensive installation methods, Ollama configuration for local model deployment, AGENTS.md file creation, custom agent configuration, and best practices for enterprise environments.

---

## Table of Contents

1. [What is OpenCode?](#what-is-opencode)
2. [Installation Methods](#installation-methods)
3. [Ollama Setup](#ollama-setup)
4. [Recommended Models](#recommended-models)
5. [Critical Configuration: Context Window Adjustment](#critical-configuration-context-window-adjustment)
6. [OpenCode Configuration](#opencode-configuration)
7. [AGENTS.md Files: Project Intelligence](#agentsmd-files-project-intelligence)
8. [Custom Agents Configuration](#custom-agents-configuration)
9. [Cross-Platform Compatibility](#cross-platform-compatibility)
10. [Usage & Best Practices](#usage--best-practices)
11. [Troubleshooting](#troubleshooting)

---

## What is OpenCode?

OpenCode is an open-source AI coding agent available as a terminal-based interface (TUI), desktop app, or IDE extension. Unlike proprietary solutions, OpenCode offers:

- **Vendor Agnostic**: Support for 75+ LLM providers
- **Local Model Support**: Full compatibility with Ollama for privacy-focused development
- **Complete Privacy**: Code never leaves your machine when using local models
- **Zero API Costs**: No usage limits or subscription fees with local models
- **Tool Calling**: File operations, git integration, shell commands
- **Model Context Protocol (MCP)**: Extensible architecture for custom tools
- **AGENTS.md Support**: Industry-standard project instructions format

---

## Installation Methods

### Prerequisites

**Terminal Requirements:**
- Modern terminal emulator (WezTerm, Alacritty, Ghostty, or Kitty recommended)
- For optimal performance, use a GPU-accelerated terminal

**System Requirements:**
- Node.js 18+ (for npm installation methods)
- 8GB+ RAM minimum (16GB+ recommended for larger models)
- GPU with 8GB+ VRAM recommended for optimal performance

### Method 1: Quick Install Script (Recommended)

```bash
curl -fsSL https://opencode.ai/install | bash
```

### Method 2: Node.js Package Managers

#### npm
```bash
npm install -g opencode-ai
```

#### Bun
```bash
bun install -g opencode-ai
```

#### pnpm
```bash
pnpm install -g opencode-ai
```

#### Yarn
```bash
yarn global add opencode-ai
```

### Method 3: Homebrew (macOS & Linux)

```bash
brew install opencode
```

### Method 4: Linux Package Managers

#### Arch Linux (Paru)
```bash
paru -S opencode-bin
```

### Method 5: Windows Installation

#### Chocolatey
```bash
choco install opencode
```

#### Scoop
```bash
scoop bucket add extras
scoop install extras/opencode
```

#### Windows NPM
```bash
npm install -g opencode-ai
```

### Method 6: Mise (Cross-Platform)

```bash
mise use -g github:anomalyco/opencode
```

### Method 7: Docker

```bash
docker run -it --rm ghcr.io/anomalyco/opencode
```

### Method 8: Binary Release

Download the latest binary from [GitHub Releases](https://github.com/anomalyco/opencode/releases)

### Verify Installation

```bash
opencode --version
```

---

## Ollama Setup

### Installing Ollama

#### macOS
```bash
# Download from ollama.ai
# Or use Homebrew
brew install ollama
```

#### Linux
```bash
curl -fsSL https://ollama.ai/install.sh | sh
```

#### Windows
Download the installer from [ollama.ai](https://ollama.ai)

#### Docker (All Platforms)
```bash
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

### Starting Ollama

```bash
# Start the Ollama service
ollama serve

# Verify it's running
curl http://localhost:11434/api/tags
```

---

## Recommended Models

Based on performance benchmarks and tool-calling capabilities, here are the top models for code generation and editing with OpenCode:

### Tier 1: Best Overall Performance

#### 1. **Qwen2.5-Coder** (Highly Recommended)
```bash
# For systems with 16GB+ RAM
ollama pull qwen2.5-coder:7b

# For systems with 32GB+ RAM
ollama pull qwen2.5-coder:14b

# For high-end systems with 64GB+ RAM
ollama pull qwen2.5-coder:32b
```

**Strengths:**
- Excellent tool calling support
- Strong code generation and refactoring
- Supports 80+ programming languages
- Best balance of performance and resource usage

#### 2. **DeepSeek-Coder-V2**
```bash
# Recommended for most systems
ollama pull deepseek-coder-v2:16b

# High-end systems
ollama pull deepseek-coder-v2:236b
```

**Strengths:**
- State-of-the-art code generation
- Excellent reasoning capabilities
- Trained on 2T+ tokens
- Superior at complex refactoring

#### 3. **GPT-OSS** (OpenAI-Style Coding Model)
```bash
ollama pull gpt-oss:20b
```

**Strengths:**
- Powerful reasoning and agentic tasks
- Excellent function calling
- Good for complex algorithmic work

### Tier 2: Specialized Models

#### 4. **CodeLlama** (Meta)
```bash
# General purpose
ollama pull codellama:13b-instruct

# Python specialist
ollama pull codellama:34b-python

# Code completion
ollama pull codellama:7b-code
```

**Strengths:**
- Proven track record
- Good for production code
- Excellent documentation generation

#### 5. **Qwen3-Coder**
```bash
ollama pull qwen3-coder:30b
```

**Strengths:**
- Updated tool calling in Ollama's new engine
- Large context window support
- Good for large codebase management

### Tier 3: Lightweight Options

#### 6. **DeepSeek-Coder-V2 1.6B**
```bash
ollama pull deepseek-coder-v2:1.6b
```

**Strengths:**
- Runs on modest hardware
- Good for quick completions
- Suitable for edge devices

#### 7. **Phi-3 Mini** (Microsoft)
```bash
ollama pull phi3:mini
```

**Strengths:**
- 3.8B parameters
- Runs on laptops
- Good for simple tasks

### Model Selection Guide

| Hardware | Recommended Model | RAM Required | VRAM Required |
|----------|------------------|--------------|---------------|
| Basic Laptop | phi3:mini | 8GB | 4GB |
| Mid-Range PC | qwen2.5-coder:7b | 16GB | 8GB |
| High-End Workstation | qwen2.5-coder:14b | 32GB | 16GB |
| Server/Cluster | deepseek-coder-v2:236b | 128GB+ | 80GB+ |

---

## Critical Configuration: Context Window Adjustment

### The Problem

**Ollama defaults to a 4096-token context window**, even when models support much larger contexts (16k-128k tokens). This severely limits tool calling and coding agent capabilities.

### The Solution

You **must** manually configure the context window for each model.

### Method 1: Interactive Model Configuration (Recommended)

```bash
# Pull the model first
ollama pull qwen2.5-coder:7b

# Run the model interactively
ollama run qwen2.5-coder:7b

# Inside the Ollama prompt, set parameters
>>> /set parameter num_ctx 16384
Set parameter 'num_ctx' to '16384'

# Save as a new model variant
>>> /save qwen2.5-coder:7b-16k
Created new model 'qwen2.5-coder:7b-16k'

# Exit
>>> /bye
```

### Method 2: Modelfile Configuration

Create a `Modelfile`:

```dockerfile
FROM qwen2.5-coder:7b

PARAMETER num_ctx 16384
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER repeat_penalty 1.1
```

Build the custom model:

```bash
ollama create qwen2.5-coder:7b-16k -f Modelfile
```

### Method 3: Environment Variable (Global Setting)

```bash
# Set globally for all models
export OLLAMA_NUM_CTX=16384

# Or add to your shell profile (.bashrc, .zshrc)
echo 'export OLLAMA_NUM_CTX=16384' >> ~/.bashrc
```

### Method 4: Systemd Service Configuration

For Linux systems running Ollama as a service:

```bash
# Create override file
sudo mkdir -p /etc/systemd/system/ollama.service.d/
sudo nano /etc/systemd/system/ollama.service.d/override.conf
```

Add:

```ini
[Service]
Environment="OLLAMA_NUM_CTX=16384"
```

Reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### Recommended Context Window Sizes

| Model Size | Context Window | Use Case |
|-----------|----------------|----------|
| 1-7B | 8192-16384 | Standard coding tasks |
| 7-14B | 16384-32768 | Complex refactoring |
| 14B+ | 32768-65536 | Large codebase analysis |

### Verification

Test the context window:

```bash
ollama show qwen2.5-coder:7b-16k
```

Look for `num_ctx` in the output.

---

## OpenCode Configuration

### Configuration File Location

**Linux/macOS:**
```bash
~/.config/opencode/opencode.json
```

**Windows:**
```bash
C:\Users\<username>\.config\opencode\opencode.json
```

### Basic Ollama Configuration

Create or edit `~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen2.5-coder:7b-16k",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen2.5-coder:7b-16k": {
          "name": "Qwen 2.5 Coder 7B (16k context)",
          "tools": true,
          "reasoning": true
        }
      }
    }
  }
}
```

### Multi-Model Configuration

Configure multiple models for different tasks:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen2.5-coder:14b-16k",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen2.5-coder:14b-16k": {
          "name": "Qwen 2.5 Coder 14B (16k)",
          "tools": true,
          "reasoning": true
        },
        "deepseek-coder-v2:16b-32k": {
          "name": "DeepSeek Coder V2 16B (32k)",
          "tools": true,
          "reasoning": true
        },
        "codellama:13b-instruct-16k": {
          "name": "CodeLlama 13B Instruct (16k)",
          "tools": true
        },
        "gpt-oss:20b-16k": {
          "name": "GPT OSS 20B (16k)",
          "tools": true,
          "reasoning": true
        }
      }
    }
  }
}
```

### Remote Ollama Configuration

For distributed teams or remote servers:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (remote)",
      "options": {
        "baseURL": "http://192.168.1.100:11434/v1"
      },
      "models": {
        "qwen2.5-coder:32b-32k": {
          "name": "Qwen 2.5 Coder 32B (32k)",
          "tools": true,
          "reasoning": true
        }
      }
    }
  }
}
```

### Configuration Options Explained

| Option | Description |
|--------|-------------|
| `$schema` | JSON schema for validation |
| `model` | Default model (format: `provider_id/model_id`) |
| `npm` | AI SDK package for OpenAI-compatible APIs |
| `baseURL` | Ollama server endpoint |
| `tools` | Enable tool calling (file ops, git, shell) |
| `reasoning` | Enable chain-of-thought reasoning |

---

## AGENTS.md Files: Project Intelligence

### What is AGENTS.md?

AGENTS.md is an **industry-standard open format** for providing context and instructions to AI coding agents. Think of it as a "README for AI agents."

**Key Facts:**
- Developed collaboratively by OpenAI, Google, Factory, Sourcegraph, and Cursor
- Used by 60,000+ open-source projects
- Supported by all major AI coding tools
- Now stewarded by the Agentic AI Foundation under the Linux Foundation

### Why Use AGENTS.md?

- **Universal**: Works across OpenCode, GitHub Copilot, Cursor, VS Code, and other AI coding tools
- **Predictable**: Gives agents a consistent place to find project-specific instructions
- **Separation of Concerns**: Keeps READMEs human-focused while providing detailed agent context
- **Hierarchical**: Project-level and subdirectory-specific instructions
- **Version Controlled**: Part of your repository, shared with your team

### File Location Hierarchy

AGENTS.md files are discovered hierarchically:

```
project-root/
├── AGENTS.md                    # Project-wide instructions (highest priority for root)
├── src/
│   ├── AGENTS.md               # Overrides root for src/ and subdirectories
│   └── components/
│       └── AGENTS.md           # Overrides for components/ only
└── tests/
    └── AGENTS.md               # Test-specific instructions
```

**Discovery Order:**
1. Closest AGENTS.md to the current file wins
2. Agents read from project root down to current directory
3. Override files take precedence over regular files

### Creating AGENTS.md Files

#### Location 1: Project Root (Project-Wide)

**File:** `<project-root>/AGENTS.md`

**Purpose:** Define project structure, conventions, and standards

**Example:**

```markdown
# Project Name: Enterprise Backend API

## Project Overview
This is a TypeScript-based microservices architecture using NestJS and PostgreSQL.
We use pnpm workspaces for monorepo management.

## Architecture
- `packages/api/` - REST API endpoints
- `packages/core/` - Shared business logic
- `packages/database/` - Database models and migrations
- `infrastructure/` - Terraform IaC definitions

## Development Environment
- Node.js 20+
- PostgreSQL 15
- Redis 7 for caching
- pnpm 8+ for package management

## Code Standards

### TypeScript
- Use strict mode
- Prefer interfaces over types for object shapes
- Always use explicit return types for public functions
- Use async/await over promises

### Naming Conventions
- Files: kebab-case (e.g., `user-service.ts`)
- Classes: PascalCase (e.g., `UserService`)
- Functions: camelCase (e.g., `getUserById`)
- Constants: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)

### Import Standards
- Use absolute imports via path aliases: `@api/`, `@core/`, `@database/`
- Group imports: external → internal → relative
- Sort alphabetically within groups

## Testing Instructions
- Run all tests: `pnpm test`
- Run specific package: `pnpm test --filter @myapp/api`
- Watch mode: `pnpm test:watch`
- Coverage: `pnpm test:coverage`

### Test Standards
- Place tests adjacent to source: `user.service.ts` → `user.service.spec.ts`
- Use describe/it blocks with descriptive names
- Follow AAA pattern: Arrange, Act, Assert
- Mock external dependencies
- Aim for 80%+ coverage

## Database Conventions
- Migrations: `packages/database/migrations/`
- Naming: `YYYYMMDDHHMMSS_description.ts`
- Always include rollback logic
- Test migrations up AND down

## API Standards
- RESTful endpoints: `/api/v1/resources`
- Use proper HTTP methods (GET, POST, PUT, DELETE)
- Return consistent error format:
  ```json
  {
    "error": "ResourceNotFound",
    "message": "User with id 123 not found",
    "statusCode": 404
  }
  ```

## Git Workflow
- Branch naming: `feature/`, `bugfix/`, `hotfix/`
- Commit format: Conventional Commits
  - `feat: add user authentication`
  - `fix: resolve race condition in cache`
  - `docs: update API documentation`
- PR titles match commit format
- Squash commits on merge

## Build & Deploy
- Build: `pnpm build`
- Lint: `pnpm lint`
- Format: `pnpm format`
- Type check: `pnpm type-check`
- CI runs all checks before merge

## Environment Variables
- Never commit secrets
- Use `.env.example` as template
- Load via `@nestjs/config`
- Validate on startup

## Documentation
- Update API docs in `docs/api/` for endpoint changes
- Use JSDoc for public APIs
- Keep CHANGELOG.md updated
```

#### Location 2: Subdirectory-Specific

**File:** `<project-root>/src/components/AGENTS.md`

**Purpose:** Override or supplement parent instructions for specific directories

**Example:**

```markdown
# Frontend Components Guidelines

## Component Standards
- Use React functional components with hooks
- Place components in `src/components/<ComponentName>/`
- Structure:
  ```
  ComponentName/
  ├── ComponentName.tsx
  ├── ComponentName.test.tsx
  ├── ComponentName.styles.ts
  └── index.ts
  ```

## Styling
- Use styled-components for component styles
- Theme values: `${({ theme }) => theme.colors.primary}`
- Mobile-first responsive design
- Follow 8px grid system

## Props Interface
```typescript
interface ComponentNameProps {
  // Required props first
  id: string;
  title: string;
  
  // Optional props
  description?: string;
  onAction?: (id: string) => void;
  
  // Children
  children?: React.ReactNode;
}
```

## Testing Components
- Test user interactions, not implementation
- Use React Testing Library
- Mock external dependencies
- Test accessibility (aria-labels, keyboard navigation)

## Common Patterns
- Loading states: Use `<Skeleton>` component
- Error states: Use `<ErrorBoundary>` wrapper
- Forms: Use `react-hook-form` with zod validation
```

#### Location 3: Global User Settings

**File:** `~/.config/opencode/AGENTS.md`

**Purpose:** Personal preferences that apply across all projects

**Example:**

```markdown
# Personal Working Agreements

## General Preferences
- Always ask before adding new dependencies
- Prefer functional programming patterns
- Use early returns over nested conditionals
- Maximum function length: 50 lines

## Code Review Standards
- Check for potential memory leaks
- Verify error handling
- Ensure proper logging
- Review security implications

## Documentation Style
- Write JSDoc for all exported functions
- Include examples in complex logic
- Link to related documentation

## Testing Preferences
- Write tests for all new features
- Update tests when modifying code
- Run tests before committing
```

### Best Practices for AGENTS.md

#### 1. Be Specific and Actionable

❌ **Bad:**
```markdown
- Write good code
- Follow best practices
```

✅ **Good:**
```markdown
- Use TypeScript strict mode with explicit return types
- Implement error handling with try/catch blocks and proper logging
- Follow RESTful conventions: GET for reads, POST for creates, PUT for updates
```

#### 2. Provide Examples

```markdown
## API Error Handling

When an error occurs, return this format:

```json
{
  "error": "ValidationError",
  "message": "Email address is invalid",
  "statusCode": 400,
  "details": {
    "field": "email",
    "constraint": "isEmail"
  }
}
```
```

#### 3. Include Commands

```markdown
## Running Tests

```bash
# Run all tests
pnpm test

# Run specific test file
pnpm test user.service.spec.ts

# Run tests in watch mode
pnpm test:watch

# Generate coverage report
pnpm test:coverage
```
```

#### 4. Reference Existing Files

```markdown
## Style Guide

Follow the patterns in `@components/Button` for all new UI components.
See `@services/BaseService` for the service layer template.
```

#### 5. Keep It Current

- Update when architecture changes
- Document new conventions as they're established
- Remove deprecated patterns
- Review quarterly

### Integrating AGENTS.md with OpenCode

#### Automatic Discovery

OpenCode automatically reads AGENTS.md files when you run `/init`:

```bash
cd /path/to/project
opencode

# Initialize OpenCode - this scans for AGENTS.md
/init
```

#### Manual Instruction References

You can also reference AGENTS.md explicitly in your OpenCode config:

**File:** `~/.config/opencode/opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "AGENTS.md",
    "CONTRIBUTING.md",
    "docs/development-guide.md",
    ".github/AGENTS.md"
  ]
}
```

---

## Custom Agents Configuration

### What are Custom Agents?

Custom agents are specialized AI assistants within OpenCode with tailored configurations for specific workflows:

- **Build Agent**: Full development work with all tools
- **Plan Agent**: Analysis and planning (read-only)
- **Review Agent**: Code review with documentation focus
- **Debug Agent**: Investigation with bash and read tools

### Agent Configuration Methods

#### Method 1: Interactive Generation (Recommended)

```bash
# Inside OpenCode TUI
/agent generate

# Follow the prompts:
# 1. Where to save? (global / project-specific)
# 2. Agent name?
# 3. Description?
# 4. Tool permissions?
```

#### Method 2: Markdown Files with YAML Frontmatter

**Location Options:**

- **Project-Specific:** `<project-root>/.opencode/agent/*.md`
- **Global:** `~/.config/opencode/agent/*.md`
- **Nested:** `<project-root>/.opencode/agent/python/django.md` → Agent name: `python/django`

**File Structure:**

```markdown
---
description: 'Python FastAPI specialist with async/await expertise'
model: 'ollama/qwen2.5-coder:14b-16k'
temperature: 0.7
maxSteps: 20
color: '#3776AB'
tools:
  write: true
  read: true
  bash: true
  knowledge: false
---

You are a FastAPI specialist focused on building high-performance async Python APIs.

## Your Expertise
- FastAPI framework patterns
- Async/await best practices
- Pydantic models and validation
- SQLAlchemy with async drivers
- Authentication with JWT
- Testing with pytest-asyncio

## Code Standards
- Use type hints for all functions
- Implement proper dependency injection
- Create comprehensive docstrings
- Write async tests for async code
- Use Pydantic for data validation

## Common Patterns

### API Endpoint Structure
```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/api/v1/users", tags=["users"])

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> UserResponse:
    """Retrieve user by ID."""
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found"
        )
    return UserResponse.from_orm(user)
```

### Database Models
```python
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, DateTime
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
```

## Testing Approach
- Use pytest fixtures for test dependencies
- Mock external services
- Test both success and error paths
- Verify response schemas with Pydantic
```

**Example Agents for Different Stacks:**

```
.opencode/agent/
├── backend/
│   ├── fastapi.md           # Python FastAPI specialist
│   ├── nestjs.md            # TypeScript NestJS specialist
│   └── django.md            # Django specialist
├── frontend/
│   ├── react.md             # React specialist
│   ├── vue.md               # Vue specialist
│   └── nextjs.md            # Next.js specialist
├── devops/
│   ├── terraform.md         # Infrastructure as Code
│   ├── kubernetes.md        # K8s specialist
│   └── docker.md            # Container specialist
└── review.md                # Code review agent
```

#### Method 3: JSON Configuration

**File:** `~/.config/opencode/opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "terraform": {
      "description": "Infrastructure as Code specialist for AWS",
      "model": "ollama/deepseek-coder-v2:16b-32k",
      "temperature": 0.5,
      "prompt": "You are a Terraform expert specializing in AWS infrastructure...",
      "tools": {
        "write": true,
        "read": true,
        "bash": true
      }
    }
  }
}
```

### Agent Configuration Options

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | When to use this agent (shown in UI) |
| `model` | string | Override default model (`provider/model-id`) |
| `temperature` | number | 0.0 (deterministic) to 1.0 (creative) |
| `maxSteps` | number | Max agentic iterations before text-only response |
| `color` | string | Hex color for UI display (`#RRGGBB`) |
| `tools` | object | Tool permissions (`true`/`false` per tool) |
| `disabled` | boolean | Disable without removing config |

### Using Custom Agents

#### Switching Agents

```bash
# Inside OpenCode TUI

# Cycle through primary agents
<TAB>

# Or use keybind (default: Leader+a)
<Leader>a

# View all agents
/models
```

#### Invoking Subagents

```bash
# In your message, @ mention the agent
@python/fastapi create a user authentication endpoint with JWT tokens
```

#### Agent Invocation in Prompts

```
I need to refactor the authentication system. 

@backend/nestjs review the current implementation in @src/auth/
@devops/terraform update the AWS infrastructure to support OAuth
```

### Example Custom Agents

#### 1. Documentation Generator

**File:** `.opencode/agent/docs.md`

```markdown
---
description: 'Documentation writer for technical guides and API docs'
model: 'ollama/qwen2.5-coder:7b-16k'
temperature: 0.8
color: '#00B4D8'
tools:
  write: true
  read: true
  bash: false
  knowledge: true
---

You are a technical documentation specialist focused on creating clear, comprehensive documentation.

## Your Mission
- Write documentation that developers actually want to read
- Include practical examples
- Maintain consistency with project style
- Update docs when code changes

## Documentation Standards

### API Documentation
```markdown
## POST /api/v1/users

Creates a new user account.

### Request

**Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer <token>`

**Body:**
```json
{
  "email": "user@example.com",
  "password": "secure_password",
  "name": "John Doe"
}
```

### Response

**Success (201):**
```json
{
  "id": 123,
  "email": "user@example.com",
  "name": "John Doe",
  "createdAt": "2025-01-04T12:00:00Z"
}
```

**Errors:**
- `400 Bad Request`: Invalid email format
- `409 Conflict`: Email already exists
- `500 Internal Server Error`: Server error
```

### Code Documentation
```typescript
/**
 * Authenticates a user and returns a JWT token.
 * 
 * @param credentials - User email and password
 * @returns JWT token and user profile
 * @throws {UnauthorizedError} If credentials are invalid
 * @throws {TooManyRequestsError} If rate limit exceeded
 * 
 * @example
 * ```typescript
 * const { token, user } = await authenticate({
 *   email: 'user@example.com',
 *   password: 'password123'
 * });
 * console.log(`Logged in as ${user.name}`);
 * ```
 */
```

## Content Structure
1. **Overview**: What does this do?
2. **Prerequisites**: What's needed?
3. **Usage**: How to use it?
4. **Examples**: Practical code samples
5. **Troubleshooting**: Common issues
6. **References**: Related docs
```

#### 2. Test Generator

**File:** `.opencode/agent/test.md`

```markdown
---
description: 'Unit and integration test generator'
model: 'ollama/qwen2.5-coder:7b-16k'
temperature: 0.3
maxSteps: 15
color: '#10B981'
tools:
  write: true
  read: true
  bash: true
---

You are a test automation specialist focused on comprehensive test coverage.

## Testing Philosophy
- Test behavior, not implementation
- Cover happy paths and edge cases
- Write maintainable tests
- Use meaningful test names

## Test Standards

### TypeScript/Jest
```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user with valid data', async () => {
      // Arrange
      const userData = {
        email: 'test@example.com',
        password: 'SecurePass123!',
        name: 'Test User'
      };
      
      // Act
      const user = await userService.createUser(userData);
      
      // Assert
      expect(user.email).toBe(userData.email);
      expect(user.id).toBeDefined();
    });
    
    it('should throw error for duplicate email', async () => {
      // Arrange
      await userService.createUser({ email: 'test@example.com', password: 'pass' });
      
      // Act & Assert
      await expect(
        userService.createUser({ email: 'test@example.com', password: 'pass' })
      ).rejects.toThrow('Email already exists');
    });
  });
});
```

### Python/pytest
```python
def test_create_user_success(user_service, db_session):
    """Test successful user creation."""
    # Arrange
    user_data = {
        "email": "test@example.com",
        "password": "SecurePass123!",
        "name": "Test User"
    }
    
    # Act
    user = user_service.create_user(user_data)
    
    # Assert
    assert user.email == user_data["email"]
    assert user.id is not None
    assert user.password != user_data["password"]  # Hashed

@pytest.mark.asyncio
async def test_authentication_failure(auth_service):
    """Test authentication with invalid credentials."""
    with pytest.raises(UnauthorizedError):
        await auth_service.authenticate("bad@email.com", "wrongpass")
```

## Coverage Requirements
- Aim for 80%+ coverage
- All public APIs must have tests
- Integration tests for critical paths
- E2E tests for user workflows
```

#### 3. Code Review Agent

**File:** `.opencode/agent/review.md`

```markdown
---
description: 'Code review specialist focused on security, performance, and best practices'
model: 'ollama/deepseek-coder-v2:16b-32k'
temperature: 0.4
color: '#F59E0B'
tools:
  write: false
  read: true
  bash: false
  knowledge: true
---

You are an expert code reviewer focused on security, performance, and maintainability.

## Review Checklist

### Security
- [ ] No hardcoded secrets or credentials
- [ ] Input validation on all user inputs
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] CSRF protection where needed
- [ ] Proper authentication/authorization
- [ ] Secure password handling (bcrypt/argon2)

### Performance
- [ ] No N+1 queries
- [ ] Appropriate use of indexes
- [ ] Efficient algorithms (O(n) vs O(n²))
- [ ] Proper caching strategy
- [ ] Resource cleanup (file handles, connections)
- [ ] Async operations where appropriate

### Code Quality
- [ ] Single Responsibility Principle
- [ ] DRY (Don't Repeat Yourself)
- [ ] Proper error handling
- [ ] Meaningful variable/function names
- [ ] Appropriate comments for complex logic
- [ ] Type safety (TypeScript, type hints)

### Testing
- [ ] Unit tests for new code
- [ ] Tests for edge cases
- [ ] Mock external dependencies
- [ ] Tests updated for code changes

## Review Format

**Severity Levels:**
- 🔴 **Critical**: Security issue, data loss risk, production blocker
- 🟠 **Major**: Performance issue, architectural concern
- 🟡 **Minor**: Code style, optimization opportunity
- 🟢 **Suggestion**: Nice-to-have improvement

**Example Review:**
```
🔴 **Critical: SQL Injection Vulnerability**
Line 45: `db.query(f"SELECT * FROM users WHERE email = '{email}'")`

This is vulnerable to SQL injection. Use parameterized queries:
```sql
db.query("SELECT * FROM users WHERE email = %s", (email,))
```

🟠 **Major: N+1 Query Problem**
Lines 67-72: Loading related data in a loop causes N+1 queries.

Use eager loading:
```python
users = User.query.options(joinedload(User.posts)).all()
```

🟡 **Minor: Magic Number**
Line 89: `if retry_count > 5:` - Extract to named constant.
```python
MAX_RETRIES = 5
if retry_count > MAX_RETRIES:
```
```
```

---

## Cross-Platform Compatibility

### Can I Reuse Agents from Other Tools?

**Short Answer:** Partially, with adaptations.

#### GitHub Copilot Instructions

**Format:** `.github/copilot-instructions.md`

**Compatibility:** 70% compatible with AGENTS.md

**Migration Steps:**

1. **Copy the file:**
   ```bash
   cp .github/copilot-instructions.md AGENTS.md
   ```

2. **Adapt the format:**
   - GitHub Copilot instructions are less structured
   - AGENTS.md supports more detailed hierarchical organization
   - Add OpenCode-specific sections

**Example Conversion:**

GitHub Copilot (`copilot-instructions.md`):
```markdown
Use TypeScript strict mode.
Follow the Airbnb style guide.
Prefer functional components with hooks.
```

OpenCode AGENTS.md (enhanced):
```markdown
# Frontend Development Standards

## TypeScript Configuration
- Enable strict mode in tsconfig.json
- Use explicit return types for all exported functions
- Prefer interfaces over types for object shapes

## Code Style
- Follow Airbnb style guide: https://github.com/airbnb/javascript
- Run ESLint before committing: `pnpm lint`
- Auto-format with Prettier: `pnpm format`

## React Patterns
- Use functional components with hooks (not class components)
- Custom hooks for shared logic (prefix with 'use')
- Component structure:
  ```tsx
  import { useState, useEffect } from 'react';
  
  interface Props {
    title: string;
  }
  
  export const MyComponent = ({ title }: Props) => {
    // Implementation
  };
  ```

## Testing
- Test components with React Testing Library
- Test file location: `Component.tsx` → `Component.test.tsx`
```

#### Cursor Rules

**Format:** `.cursorrules`

**Compatibility:** 60% compatible

**Migration:**
```bash
# Create AGENTS.md from Cursor rules
cat .cursorrules > AGENTS.md

# Then enhance with examples and structure
```

Cursor rules are often terse. Expand them with examples for AGENTS.md.

#### Kiro CLI Agents

**Format:** `.kiro/agents/*.json`

**Compatibility:** Not directly compatible (different architecture)

**Conceptual Mapping:**

Kiro CLI uses JSON configuration for agent behavior:
```json
{
  "name": "aws-expert",
  "description": "AWS infrastructure specialist",
  "tools": ["read", "write", "shell", "aws"],
  "prompt": "You are an AWS expert..."
}
```

OpenCode equivalent uses Markdown with YAML frontmatter:
```markdown
---
description: 'AWS infrastructure specialist'
tools:
  read: true
  write: true
  bash: true
---

You are an AWS expert specializing in infrastructure as code...
```

**Migration Strategy:**

1. Extract the `prompt` field → Markdown body
2. Extract `tools` → YAML frontmatter tools section
3. Add OpenCode-specific examples and patterns

#### VS Code Copilot Custom Instructions

**Format:** VS Code Settings JSON

**Compatibility:** 50% compatible

VS Code stores instructions in settings:
```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "text": "Use TypeScript strict mode"
    }
  ]
}
```

**Migration:** Extract instructions and format as AGENTS.md sections.

### Universal Agent Pattern

To maximize compatibility across tools, use this structure:

**File:** `AGENTS.md`

```markdown
# Project Instructions

<!-- Section 1: Universal Context -->
## Project Overview
[Description that works for all AI tools]

<!-- Section 2: Language/Framework Specifics -->
## Technology Stack
[Specific technologies and versions]

<!-- Section 3: Code Standards -->
## Coding Standards
[Language-agnostic principles, then specifics]

<!-- Section 4: Testing -->
## Testing Requirements
[Universal testing principles]

<!-- Section 5: Tool-Specific (Optional) -->
## Tool-Specific Notes

### OpenCode
[OpenCode-specific patterns]

### GitHub Copilot
[Copilot-specific patterns]

### Cursor
[Cursor-specific patterns]
```

This ensures maximum reusability across tools while allowing tool-specific customization.

---

## Usage & Best Practices

### Initial Setup

```bash
# Navigate to your project
cd /path/to/project

# Start OpenCode
opencode

# Initialize OpenCode for the project
/init
```

This creates an `AGENTS.md` file that helps OpenCode understand your project structure.

### Switching Models

```bash
# Inside OpenCode TUI
/models

# Select from your configured models
# Or search by name
```

### Key Commands

| Command | Description |
|---------|-------------|
| `/init` | Initialize project analysis |
| `/models` | Switch between configured models |
| `/connect` | Add new provider credentials |
| `/undo` | Revert last changes |
| `/redo` | Reapply reverted changes |
| `/share` | Share conversation (creates link) |
| `/agent generate` | Create custom agent interactively |
| `<TAB>` | Toggle Plan/Build mode |
| `@filename` | Reference specific file |
| `@agentname` | Invoke custom agent |

### Workflow Example

```bash
# Start OpenCode
opencode

# Ask for analysis
How is authentication handled in @src/auth.ts?

# Switch to Plan mode
<TAB>

# Request a feature
Add rate limiting to the API endpoints. Use Redis as the backend.

# Review the plan, then switch to Build mode
<TAB>

# Confirm implementation
Looks good! Go ahead and implement it.
```

### Best Practices

1. **Use Plan Mode First**: Switch to Plan mode (`<TAB>`) for complex features to review the approach before implementation

2. **Provide Context**: Use `@` to reference files and give detailed requirements

3. **Commit AGENTS.md**: Always commit the generated `AGENTS.md` to version control

4. **Model Selection**:
   - **Quick tasks**: 7B models
   - **Refactoring**: 14B models
   - **Complex architecture**: 32B+ models

5. **Context Management**: Start fresh conversations for unrelated tasks to avoid context confusion

6. **File References**: Always use `@filename` to ensure OpenCode reads the correct files

7. **Custom Agents**: Create specialized agents for repeated workflows (docs, testing, review)

8. **Hierarchical AGENTS.md**: Use directory-specific AGENTS.md files for different parts of large codebases

---

## Troubleshooting

### Issue: Tools Not Working

**Symptoms:** Model doesn't execute file operations, git commands, or shell commands

**Solution:**
1. Verify context window is set to 16k+:
   ```bash
   ollama show qwen2.5-coder:7b-16k
   ```

2. Ensure `"tools": true` in config:
   ```json
   "models": {
     "qwen2.5-coder:7b-16k": {
       "tools": true
     }
   }
   ```

3. Try increasing context further:
   ```bash
   ollama run qwen2.5-coder:7b
   >>> /set parameter num_ctx 32768
   >>> /save qwen2.5-coder:7b-32k
   ```

### Issue: Model Not Appearing

**Solution:**
1. Verify model name matches exactly:
   ```bash
   ollama list
   ```

2. Check the model name in config matches `ollama list` output exactly

3. Restart OpenCode:
   ```bash
   exit
   opencode
   ```

### Issue: AGENTS.md Not Being Read

**Solution:**
1. Verify file location:
   ```bash
   ls -la AGENTS.md
   ls -la .opencode/agent/
   ```

2. Re-initialize project:
   ```bash
   /init
   ```

3. Check file permissions:
   ```bash
   chmod 644 AGENTS.md
   ```

### Issue: Custom Agent Not Showing

**Solution:**
1. Verify agent file structure:
   ```bash
   cat .opencode/agent/your-agent.md
   ```

2. Check YAML frontmatter is valid:
   ```markdown
   ---
   description: 'Agent description'
   tools:
     read: true
   ---
   ```

3. Restart OpenCode to reload agents

### Issue: Connection Refused

**Solution:**
1. Verify Ollama is running:
   ```bash
   curl http://localhost:11434/api/tags
   ```

2. Start Ollama if needed:
   ```bash
   ollama serve
   ```

3. Check firewall settings if using remote Ollama

### Issue: Out of Memory

**Solution:**
1. Use a smaller model:
   ```bash
   ollama pull qwen2.5-coder:1.5b
   ```

2. Reduce context window:
   ```bash
   >>> /set parameter num_ctx 8192
   ```

3. Close other applications to free RAM

### Issue: Slow Performance

**Solution:**
1. Ensure model is using GPU:
   ```bash
   # Check GPU usage
   nvidia-smi  # NVIDIA
   amdgpu-top  # AMD
   ```

2. Use quantized models:
   ```bash
   ollama pull qwen2.5-coder:7b-q4_K_M
   ```

3. Set `OLLAMA_KEEP_ALIVE` to keep model in memory:
   ```bash
   export OLLAMA_KEEP_ALIVE=30m
   ```

### Issue: Model Gives Incorrect Output

**Solution:**
1. Try adjusting temperature:
   ```bash
   >>> /set parameter temperature 0.5
   ```

2. Provide more context in your prompt

3. Try a different model variant

---

## Performance Optimization

### GPU Acceleration

Ensure Ollama is using your GPU:

```bash
# Check GPU support
ollama list

# Should show GPU in model info
# NVIDIA: Look for CUDA
# AMD: Look for ROCm
# Apple: Look for Metal
```

### Memory Management

```bash
# Keep models loaded longer
export OLLAMA_KEEP_ALIVE=1h

# Limit concurrent models
export OLLAMA_MAX_LOADED_MODELS=1
```

### Parallel Inference

For multiple projects:

```bash
# Terminal 1
cd ~/project1
opencode

# Terminal 2
cd ~/project2
opencode
```

Both can hit the same Ollama server, running different tasks in parallel.

---

## Enterprise Considerations

### Security

1. **Network Isolation**: Run Ollama on isolated network segments for sensitive code
2. **Access Control**: Use firewall rules to restrict Ollama API access
3. **Audit Logging**: Monitor Ollama logs for usage patterns
4. **Code Review**: Always review AI-generated code before merging

### Compliance

- **Data Residency**: All processing happens locally—no data leaves your infrastructure
- **GDPR/CCPA**: No data transmission to third parties
- **IP Protection**: Code remains on your servers
- **Audit Trail**: All conversations can be logged locally

### Scalability

1. **Distributed Setup**: Run Ollama on dedicated GPU servers, point multiple OpenCode instances to it
2. **Load Balancing**: Use nginx/HAProxy to load balance across multiple Ollama instances
3. **Model Management**: Maintain a model registry for team standardization

### Cost Analysis

| Solution | Cost/Month | Notes |
|----------|------------|-------|
| OpenCode + Ollama | $0 + electricity | One-time hardware investment |
| Claude Code | $20-100+ | Per user subscription + API usage |
| GitHub Copilot | $10-39 | Per user subscription |
| **Total Savings** | **~$30-140/user/month** | After hardware ROI |

For a 10-person team:
- **Annual savings**: $3,600 - $16,800
- **Hardware investment**: $2,000 - $5,000 (GPU server)
- **ROI timeline**: 2-4 months

---

## Quick Reference Guide

### File Locations

```
# OpenCode Configuration
~/.config/opencode/opencode.json          # Main config
~/.config/opencode/AGENTS.md              # Global instructions

# Project-Level
<project-root>/AGENTS.md                  # Project instructions
<project-root>/.opencode/agent/*.md       # Custom agents
<project-root>/.github/copilot-instructions.md  # Copilot (convertible)

# Subdirectory-Specific
<project-root>/src/AGENTS.md              # Override for src/
<project-root>/tests/AGENTS.md            # Override for tests/
```

### Common Commands

```bash
# Installation
curl -fsSL https://opencode.ai/install | bash

# Ollama Setup
ollama pull qwen2.5-coder:7b
ollama run qwen2.5-coder:7b
>>> /set parameter num_ctx 16384
>>> /save qwen2.5-coder:7b-16k

# OpenCode Usage
cd /path/to/project
opencode
/init                    # Initialize project
/models                  # Switch models
/agent generate          # Create custom agent
<TAB>                    # Toggle Plan/Build mode
@filename                # Reference file
@agentname prompt        # Use custom agent
```

### Model Recommendations by Use Case

| Use Case | Model | Context | Tools |
|----------|-------|---------|-------|
| General Coding | qwen2.5-coder:7b-16k | 16k | ✓ |
| Large Refactoring | deepseek-coder-v2:16b-32k | 32k | ✓ |
| Code Review | deepseek-coder-v2:16b-32k | 32k | Read only |
| Documentation | qwen2.5-coder:7b-16k | 16k | Write, Read |
| Testing | qwen2.5-coder:7b-16k | 16k | All |
| Quick Tasks | phi3:mini | 8k | ✓ |

---

## Additional Resources

- **Official Documentation**: https://opencode.ai/docs/
- **GitHub Repository**: https://github.com/anomalyco/opencode
- **Discord Community**: https://opencode.ai/discord
- **Ollama Library**: https://ollama.com/library
- **AGENTS.md Spec**: https://github.com/agenticai/.well-known
- **Model Performance**: https://collabnix.com/best-ollama-models-for-developers-complete-2025-guide-with-code-examples/

---

## Conclusion

OpenCode with Ollama provides a powerful, privacy-focused alternative to cloud-based AI coding assistants. By following this guide, enterprise teams can:

1. Deploy AI coding assistance without data leaving infrastructure
2. Eliminate recurring API costs
3. Maintain full control over model selection and configuration
4. Scale horizontally across teams and projects
5. Comply with strict data residency requirements
6. Use industry-standard AGENTS.md files for consistent AI behavior
7. Create custom agents for specialized workflows
8. Leverage existing instructions from other AI coding tools

The key to success is:
- Proper context window configuration (16k+ tokens)
- Model selection based on hardware and use case
- Well-structured AGENTS.md files with concrete examples
- Custom agents for repeated workflows
- Regular updates to project instructions

---

**Document Version**: 2.0  
**Last Updated**: January 2026  
**Author**: Enterprise Architecture Team  
**License**: CC BY-SA 4.0