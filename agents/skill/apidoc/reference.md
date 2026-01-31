# API Documentation Reference

## Overview

This document provides comprehensive API documentation patterns using JSDoc format for automatic OpenAPI/Swagger generation. All examples use JavaScript and follow Next.js 16 conventions.

## API Versioning

All APIs follow the pattern: `/src/app/api/<VERSION>/<RESOURCE>/route.js`

Example: `/src/app/api/v1/items/route.js`

---

## Items API v1

### GET /api/v1/items

Get all items with pagination and filtering.

```javascript
// src/app/api/v1/items/route.js

/**
 * @api {get} /api/v1/items Get All Items
 * @apiVersion 1.0.0
 * @apiName GetItems
 * @apiGroup Items
 * @apiDescription Retrieves a paginated list of items with optional filtering.
 *
 * @apiQuery {Number} [page=1] Page number for pagination
 * @apiQuery {Number} [limit=20] Number of items per page
 * @apiQuery {String} [search] Search term to filter items by title
 * @apiQuery {String} [sortBy=createdAt] Field to sort by
 * @apiQuery {String} [sortOrder=desc] Sort order (asc or desc)
 *
 * @apiSuccess {Number} page Current page number
 * @apiSuccess {Number} limit Items per page
 * @apiSuccess {Number} total Total number of items
 * @apiSuccess {Number} totalPages Total number of pages
 * @apiSuccess {Array} items List of items
 * @apiSuccess {String} items.id Item ID
 * @apiSuccess {String} items.title Item title
 * @apiSuccess {String} items.description Item description
 * @apiSuccess {String} items.createdAt Creation timestamp
 *
 * @apiExample {curl} Example Usage:
 *    curl -X GET "http://localhost:3000/api/v1/items?page=1&limit=10&search=test"
 *
 * @apiSuccessExample {json} Success Response:
 *    HTTP/1.1 200 OK
 *    {
 *      "page": 1,
 *      "limit": 10,
 *      "total": 50,
 *      "totalPages": 5,
 *      "items": [
 *        {
 *          "id": "123",
 *          "title": "Test Item",
 *          "description": "A test item",
 *          "createdAt": "2024-01-15T10:30:00Z"
 *        }
 *      ]
 *    }
 *
 * @apiErrorExample {json} Error Response:
 *    HTTP/1.1 500 Internal Server Error
 *    {
 *      "error": "Failed to fetch items",
 *      "message": "Database connection failed"
 *    }
 */
export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '20');
  const search = searchParams.get('search') || '';
  const sortBy = searchParams.get('sortBy') || 'createdAt';
  const sortOrder = searchParams.get('sortOrder') || 'desc';

  try {
    const where = search
      ? { title: { contains: search, mode: 'insensitive' } }
      : {};

    const [items, total] = await Promise.all([
      db.item.findMany({
        where,
        orderBy: { [sortBy]: sortOrder },
        skip: (page - 1) * limit,
        take: limit,
      }),
      db.item.count({ where }),
    ]);

    return Response.json({
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      items,
    });
  } catch (error) {
    return Response.json(
      { error: 'Failed to fetch items', message: error.message },
      { status: 500 }
    );
  }
}

/**
 * @api {post} /api/v1/items Create Item
 * @apiVersion 1.0.0
 * @apiName CreateItem
 * @apiGroup Items
 * @apiDescription Creates a new item in the database.
 *
 * @apiParam {String} title Item title (required, 1-100 characters)
 * @apiParam {String} [description] Item description (optional, max 1000 characters)
 * @apiParam {String} [category] Item category
 *
 * @apiSuccess {String} id Created item ID
 * @apiSuccess {String} title Item title
 * @apiSuccess {String} description Item description
 * @apiSuccess {String} createdAt Creation timestamp
 *
 * @apiExample {curl} Example Usage:
 *    curl -X POST "http://localhost:3000/api/v1/items" \
 *      -H "Content-Type: application/json" \
 *      -d '{"title": "New Item", "description": "A new item description"}'
 *
 * @apiSuccessExample {json} Success Response:
 *    HTTP/1.1 201 Created
 *    {
 *      "id": "124",
 *      "title": "New Item",
 *      "description": "A new item description",
 *      "createdAt": "2024-01-15T11:00:00Z"
 *    }
 *
 * @apiErrorExample {json} Validation Error:
 *    HTTP/1.1 400 Bad Request
 *    {
 *      "error": "Validation failed",
 *      "details": [{ "field": "title", "message": "Title is required" }]
 *    }
 */
export async function POST(request) {
  try {
    const body = await request.json();

    if (!body.title || body.title.length < 1 || body.title.length > 100) {
      return Response.json(
        { error: 'Validation failed', details: [{ field: 'title', message: 'Title is required (1-100 chars)' }] },
        { status: 400 }
      );
    }

    const item = await db.item.create({
      data: {
        title: body.title,
        description: body.description || '',
        category: body.category,
      },
    });

    return Response.json(item, { status: 201 });
  } catch (error) {
    return Response.json(
      { error: 'Failed to create item', message: error.message },
      { status: 500 }
    );
  }
}
```

### GET /api/v1/items/:id

Get a single item by ID.

```javascript
// src/app/api/v1/items/[id]/route.js

/**
 * @api {get} /api/v1/items/:id Get Item by ID
 * @apiVersion 1.0.0
 * @apiName GetItemById
 * @apiGroup Items
 * @apiDescription Retrieves a single item by its unique identifier.
 *
 * @apiParam {String} id Item unique identifier (UUID or string)
 *
 * @apiSuccess {String} id Item ID
 * @apiSuccess {String} title Item title
 * @apiSuccess {String} description Item description
 * @apiSuccess {String} category Item category
 * @apiSuccess {String} createdAt Creation timestamp
 * @apiSuccess {String} updatedAt Last update timestamp
 *
 * @apiExample {curl} Example Usage:
 *    curl -X GET "http://localhost:3000/api/v1/items/123"
 *
 * @apiSuccessExample {json} Success Response:
 *    HTTP/1.1 200 OK
 *    {
 *      "id": "123",
 *      "title": "Test Item",
 *      "description": "A test item",
 *      "category": "electronics",
 *      "createdAt": "2024-01-15T10:30:00Z",
 *      "updatedAt": "2024-01-15T10:30:00Z"
 *    }
 *
 * @apiErrorExample {json} Not Found:
 *    HTTP/1.1 404 Not Found
 *    {
 *      "error": "Item not found",
 *      "message": "No item found with id: 123"
 *    }
 */
export async function GET(request, { params }) {
  const id = (await params).id;

  try {
    const item = await db.item.findUnique({ where: { id } });

    if (!item) {
      return Response.json(
        { error: 'Item not found', message: `No item found with id: ${id}` },
        { status: 404 }
      );
    }

    return Response.json(item);
  } catch (error) {
    return Response.json(
      { error: 'Failed to fetch item', message: error.message },
      { status: 500 }
    );
  }
}

/**
 * @api {put} /api/v1/items/:id Update Item
 * @apiVersion 1.0.0
 * @apiName UpdateItem
 * @apiGroup Items
 * @apiDescription Updates an existing item by its ID.
 *
 * @apiParam {String} id Item unique identifier
 * @apiParam {String} [title] New title (1-100 characters)
 * @apiParam {String} [description] New description
 * @apiParam {String} [category] New category
 *
 * @apiSuccess {String} id Item ID
 * @apiSuccess {String} title Updated title
 * @apiSuccess {String} description Updated description
 * @apiSuccess {String} updatedAt Update timestamp
 *
 * @apiExample {curl} Example Usage:
 *    curl -X PUT "http://localhost:3000/api/v1/items/123" \
 *      -H "Content-Type: application/json" \
 *      -d '{"title": "Updated Title"}'
 *
 * @apiSuccessExample {json} Success Response:
 *    HTTP/1.1 200 OK
 *    {
 *      "id": "123",
 *      "title": "Updated Title",
 *      "description": "A test item",
 *      "updatedAt": "2024-01-15T12:00:00Z"
 *    }
 */
export async function PUT(request, { params }) {
  const id = (await params).id;

  try {
    const body = await request.json();

    if (body.title && (body.title.length < 1 || body.title.length > 100)) {
      return Response.json(
        { error: 'Validation failed', details: [{ field: 'title', message: 'Title must be 1-100 characters' }] },
        { status: 400 }
      );
    }

    const item = await db.item.update({
      where: { id },
      data: {
        title: body.title,
        description: body.description,
        category: body.category,
      },
    });

    return Response.json(item);
  } catch (error) {
    if (error.code === 'P2025') {
      return Response.json(
        { error: 'Item not found', message: `No item found with id: ${id}` },
        { status: 404 }
      );
    }
    return Response.json(
      { error: 'Failed to update item', message: error.message },
      { status: 500 }
    );
  }
}

/**
 * @api {delete} /api/v1/items/:id Delete Item
 * @apiVersion 1.0.0
 * @apiName DeleteItem
 * @apiGroup Items
 * @apiDescription Deletes an item by its ID.
 *
 * @apiParam {String} id Item unique identifier
 *
 * @apiSuccess {String} message Success message
 * @apiSuccess {String} id Deleted item ID
 *
 * @apiExample {curl} Example Usage:
 *    curl -X DELETE "http://localhost:3000/api/v1/items/123"
 *
 * @apiSuccessExample {json} Success Response:
 *    HTTP/1.1 200 OK
 *    {
 *      "message": "Item deleted successfully",
 *      "id": "123"
 *    }
 *
 * @apiErrorExample {json} Not Found:
 *    HTTP/1.1 404 Not Found
 *    {
 *      "error": "Item not found",
 *      "message": "No item found with id: 123"
 *    }
 */
export async function DELETE(request, { params }) {
  const id = (await params).id;

  try {
    await db.item.delete({ where: { id } });

    return Response.json({
      message: 'Item deleted successfully',
      id,
    });
  } catch (error) {
    if (error.code === 'P2025') {
      return Response.json(
        { error: 'Item not found', message: `No item found with id: ${id}` },
        { status: 404 }
      );
    }
    return Response.json(
      { error: 'Failed to delete item', message: error.message },
      { status: 500 }
    );
  }
}
```

---

## Authentication API v1

### POST /api/v1/auth/register

Register a new user account.

```javascript
// src/app/api/v1/auth/register/route.js

/**
 * @api {post} /api/v1/auth/register Register User
 * @apiVersion 1.0.0
 * @apiName RegisterUser
 * @apiGroup Authentication
 * @apiDescription Registers a new user account.
 *
 * @apiParam {String} email User email (valid email format, unique)
 * @apiParam {String} password User password (min 8 characters)
 * @apiParam {String} name User display name (1-100 characters)
 *
 * @apiSuccess {String} id User ID
 * @apiSuccess {String} email User email
 * @apiSuccess {String} name User name
 * @apiSuccess {String} createdAt Account creation timestamp
 *
 * @apiExample {curl} Example Usage:
 *    curl -X POST "http://localhost:3000/api/v1/auth/register" \
 *      -H "Content-Type: application/json" \
 *      -d '{"email": "user@example.com", "password": "securepass", "name": "John Doe"}'
 *
 * @apiSuccessExample {json} Success Response:
 *    HTTP/1.1 201 Created
 *    {
 *      "id": "user-123",
 *      "email": "user@example.com",
 *      "name": "John Doe",
 *      "createdAt": "2024-01-15T10:00:00Z"
 *    }
 *
 * @apiErrorExample {json} Validation Error:
 *    HTTP/1.1 400 Bad Request
 *    {
 *      "error": "Validation failed",
 *      "details": [
 *        { "field": "email", "message": "Invalid email format" },
 *        { "field": "password", "message": "Password must be at least 8 characters" }
 *      ]
 *    }
 *
 * @apiErrorExample {json} Conflict Error:
 *    HTTP/1.1 409 Conflict
 *    {
 *      "error": "Email already registered",
 *      "message": "A user with this email already exists"
 *    }
 */
export async function POST(request) {
  try {
    const body = await request.json();
    const { email, password, name } = body;

    // Validation
    const errors = [];
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
      errors.push({ field: 'email', message: 'Invalid email format' });
    }
    if (!password || password.length < 8) {
      errors.push({ field: 'password', message: 'Password must be at least 8 characters' });
    }
    if (!name || name.length < 1 || name.length > 100) {
      errors.push({ field: 'name', message: 'Name must be 1-100 characters' });
    }

    if (errors.length > 0) {
      return Response.json({ error: 'Validation failed', details: errors }, { status: 400 });
    }

    // Check if user exists
    const existingUser = await db.user.findUnique({ where: { email } });
    if (existingUser) {
      return Response.json(
        { error: 'Email already registered', message: 'A user with this email already exists' },
        { status: 409 }
      );
    }

    // Create user
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await db.user.create({
      data: { email, password: hashedPassword, name },
    });

    return Response.json({
      id: user.id,
      email: user.email,
      name: user.name,
      createdAt: user.createdAt,
    }, { status: 201 });
  } catch (error) {
    return Response.json(
      { error: 'Registration failed', message: error.message },
      { status: 500 }
    );
  }
}
```

### POST /api/v1/auth/login

Authenticate a user and return a JWT token.

```javascript
// src/app/api/v1/auth/login/route.js

/**
 * @api {post} /api/v1/auth/login User Login
 * @apiVersion 1.0.0
 * @apiName UserLogin
 * @apiGroup Authentication
 * @apiDescription Authenticates a user and returns a JWT token.
 *
 * @apiParam {String} email User email
 * @apiParam {String} password User password
 *
 * @apiSuccess {String} token JWT authentication token
 * @apiSuccess {String} user.id User ID
 * @apiSuccess {String} user.email User email
 * @apiSuccess {String} user.name User name
 * @apiSuccess {Number} expiresIn Token expiration time in seconds
 *
 * @apiExample {curl} Example Usage:
 *    curl -X POST "http://localhost:3000/api/v1/auth/login" \
 *      -H "Content-Type: application/json" \
 *      -d '{"email": "user@example.com", "password": "securepass"}'
 *
 * @apiSuccessExample {json} Success Response:
 *    HTTP/1.1 200 OK
 *    {
 *      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
 *      "user": {
 *        "id": "user-123",
 *        "email": "user@example.com",
 *        "name": "John Doe"
 *      },
 *      "expiresIn": 86400
 *    }
 *
 * @apiErrorExample {json} Invalid Credentials:
 *    HTTP/1.1 401 Unauthorized
 *    {
 *      "error": "Invalid credentials",
 *      "message": "Email or password is incorrect"
 *    }
 */
export async function POST(request) {
  try {
    const body = await request.json();
    const { email, password } = body;

    const user = await db.user.findUnique({ where: { email } });
    if (!user) {
      return Response.json(
        { error: 'Invalid credentials', message: 'Email or password is incorrect' },
        { status: 401 }
      );
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return Response.json(
        { error: 'Invalid credentials', message: 'Email or password is incorrect' },
        { status: 401 }
      );
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.NEXTAUTH_SECRET,
      { expiresIn: '1d' }
    );

    return Response.json({
      token,
      user: { id: user.id, email: user.email, name: user.name },
      expiresIn: 86400,
    });
  } catch (error) {
    return Response.json(
      { error: 'Login failed', message: error.message },
      { status: 500 }
    );
  }
}
```

---

## OpenAPI/Swagger Integration

### Generating OpenAPI Spec

The JSDoc comments follow apidoc format. To generate OpenAPI/Swagger documentation:

```bash
# Install apidoc
npm install -g apidoc

# Generate documentation
apidoc -i src/app/api/ -o docs/api/
```

### OpenAPI Spec Generation

```javascript
// src/lib/openapi.js
export function generateOpenAPISpec() {
  return {
    openapi: '3.0.0',
    info: {
      title: 'My Next.js API',
      version: '1.0.0',
      description: 'Production-ready API with self-documenting endpoints',
    },
    servers: [
      { url: 'http://localhost:3000', description: 'Development server' },
      { url: 'https://api.myapp.com', description: 'Production server' },
    ],
    paths: {
      '/api/v1/items': {
        get: {
          summary: 'Get all items',
          parameters: [
            { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
            { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } },
            { name: 'search', in: 'query', schema: { type: 'string' } },
          ],
          responses: {
            '200': { description: 'Successful response' },
            '500': { description: 'Server error' },
          },
        },
        post: {
          summary: 'Create item',
          requestBody: {
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    title: { type: 'string', required: true },
                    description: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: {
            '201': { description: 'Item created' },
            '400': { description: 'Validation error' },
          },
        },
      },
      '/api/v1/items/{id}': {
        get: {
          summary: 'Get item by ID',
          parameters: [
            { name: 'id', in: 'path', required: true, schema: { type: 'string' } },
          ],
          responses: {
            '200': { description: 'Successful response' },
            '404': { description: 'Item not found' },
          },
        },
        put: {
          summary: 'Update item',
          parameters: [
            { name: 'id', in: 'path', required: true, schema: { type: 'string' } },
          ],
          responses: {
            '200': { description: 'Item updated' },
            '404': { description: 'Item not found' },
          },
        },
        delete: {
          summary: 'Delete item',
          parameters: [
            { name: 'id', in: 'path', required: true, schema: { type: 'string' } },
          ],
          responses: {
            '200': { description: 'Item deleted' },
            '404': { description: 'Item not found' },
          },
        },
      },
    },
  };
}
```

### Swagger UI Integration

Add Swagger UI to your Next.js app:

```javascript
// src/app/api-docs/page.js
export default function ApiDocsPage() {
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">API Documentation</h1>
      <iframe
        src="/swagger-ui.html"
        className="w-full h-screen border-0"
        title="API Documentation"
      />
    </div>
  );
}
```

---

## Best Practices for API Documentation

1. **Use JSDoc Comments**: Document every endpoint with @api tags
2. **Version APIs**: Use `/api/v1/`, `/api/v2/` for different versions
3. **Document All Methods**: GET, POST, PUT, PATCH, DELETE
4. **Include Examples**: Provide curl examples for easy testing
5. **Document Responses**: Show success and error response formats
6. **Use Standard Tags**: @apiVersion, @apiName, @apiGroup, @apiParam, @apiSuccess
7. **Keep Updated**: Update docs when changing API behavior
8. **Generate OpenAPI**: Create machine-readable specs for tooling

---

## JSDoc Tag Reference

| Tag | Description |
|-----|-------------|
| `@api {METHOD}` | HTTP method (get, post, put, delete, patch) |
| `@apiVersion` | API version number |
| `@apiName` | Unique endpoint name |
| `@apiGroup` | Resource group category |
| `@apiDescription` | Endpoint description |
| `@apiParam` | Request parameter (path, query, body) |
| `@apiSuccess` | Success response field |
| `@apiExample` | Example curl request |
| `@apiSuccessExample` | Example success response |
| `@apiErrorExample` | Example error response |
