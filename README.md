# Product API

A RESTful API built with Ruby on Rails for managing products with JWT authentication, role-based authorization, and caching.

## Table of Contents

- [Setup Instructions](#setup-instructions)
- [Authentication Mechanism](#authentication-mechanism)
- [Authorization Approach](#authorization-approach)
- [Caching Strategy](#caching-strategy)
- [API Endpoints](#api-endpoints)
- [Sample API Requests](#sample-api-requests)

---

## Setup Instructions

### Prerequisites

- Ruby 3.2.3+
- Rails 8.1+
- SQLite3 (development) / PostgreSQL (production)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd product_api

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Set environment variables
export DEVISE_JWT_SECRET_KEY=$(rails secret)

# Start the server
rails server
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `DEVISE_JWT_SECRET_KEY` | Secret key for JWT token signing |
| `RAILS_ENV` | Environment (development/production/test) |

---

## Authentication Mechanism

### JWT (JSON Web Token) Authentication

This API uses **Devise-JWT** for stateless token-based authentication.

#### How It Works

1. User signs up or logs in with email/password
2. Server returns a JWT token in the `Authorization` header
3. Client includes this token in subsequent requests
4. Token is validated on each request
5. On logout, token is added to a denylist (revoked)

#### Token Structure

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

#### Token Expiration

- Tokens expire after **2 hours** (configurable in `config/initializers/devise.rb`)
- Expired tokens are automatically rejected

#### Token Revocation

- Uses `JwtDenylist` model to store revoked tokens
- Tokens are revoked on logout
- Denylist strategy ensures tokens can't be reused after logout

---

## Authorization Approach

### Role-Based Access Control (RBAC)

Users have one of two roles:

| Role | Permissions |
|------|-------------|
| `user` | Read-only access (GET products) |
| `admin` | Full CRUD access (create, update, delete products) |

### Implementation

Authorization is handled by the `Authorization` concern:

```ruby
# app/controllers/concerns/authorization.rb
module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!  # All endpoints require login
  end

  def authorize_admin!
    return if current_user&.admin?
    render json: { error: 'Forbidden', message: 'Admin access required' }, status: :forbidden
  end
end
---

## Caching Strategy

### Overview

The API implements **fragment caching** using Rails cache with automatic invalidation.

### Cache Store

- **Development**: `MemoryStore` (in-memory, cleared on restart)
- **Production**: `SolidCache` or `Redis` (persistent, shared across servers)

### What's Cached

| Endpoint | Cache Key Pattern | TTL |
|----------|------------------|-----|
| `GET /products` | `products/all-{count}-{updated_at}-page-{page}` | 1 hour |
| `GET /products/:id` | `products/{id}-{updated_at}` | 1 hour |

### Cache Invalidation

Cache is automatically invalidated when:

- ✅ A product is **created**
- ✅ A product is **updated**
- ✅ A product is **deleted**

```ruby
# app/models/product.rb
after_commit :invalidate_cache

def invalidate_cache
  Rails.cache.delete_matched("products/*")
end
```

### Avoiding ActiveRecord Object Caching

To prevent serialization issues, we cache **plain Ruby hashes**, not AR objects:

```ruby
# Correct: Cache as JSON hash
cache_fetch(cache_key) do
  products.to_a.map(&:as_json)  # Returns Array of Hashes
end
```

---

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/signup` | Register new user |
| POST | `/login` | Login and get JWT token |
| DELETE | `/logout` | Logout and revoke token |

### Products

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/products` | List all products (paginated) | Yes |
| GET | `/api/v1/products/:id` | Get single product | Yes |
| POST | `/api/v1/products` | Create product | Admin only |
| PUT | `/api/v1/products/:id` | Update product | Admin only |
| DELETE | `/api/v1/products/:id` | Delete product | Admin only |

### Pagination Parameters

| Parameter | Default | Max | Description |
|-----------|---------|-----|-------------|
| `page` | 1 | - | Page number |
| `per_page` | 10 | 100 | Items per page |

---

## Sample API Requests

### 1. User Registration (Signup)

```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

**Response:**
```json
{
  "status": { "code": 200, "message": "Signed up successfully." },
  "data": { "id": 1, "email": "user@example.com", "role": "user" }
}
```

### 2. User Login

```bash
curl -i -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123"
    }
  }'
```

**Response Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**Response Body:**
```json
{
  "status": { "code": 200, "message": "Logged in successfully." },
  "data": { "id": 1, "email": "user@example.com", "role": "user" }
}
```

### 3. List Products (Paginated)

```bash
curl -X GET "http://localhost:3000/api/v1/products?page=1&per_page=10" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "products": [
    {
      "id": 1,
      "name": "Product Name",
      "price": "29.99",
      "status": "active",
      "stock_quantity": 100,
      "created_at": "2026-01-08T10:00:00.000Z",
      "updated_at": "2026-01-08T10:00:00.000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 10,
    "total_count": 1,
    "total_pages": 1,
    "next_page": null,
    "prev_page": null
  }
}
```

### 4. Get Single Product

```bash
curl -X GET http://localhost:3000/api/v1/products/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "product": {
    "id": 1,
    "name": "Product Name",
    "price": "29.99",
    "status": "active",
    "stock_quantity": 100,
    "created_at": "2026-01-08T10:00:00.000Z",
    "updated_at": "2026-01-08T10:00:00.000Z"
  }
}
```

### 5. Create Product (Admin Only)

```bash
curl -X POST http://localhost:3000/api/v1/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN" \
  -d '{
    "product": {
      "name": "New Product",
      "price": 49.99,
      "status": "active",
      "stock_quantity": 50
    }
  }'
```

**Response (201 Created):**
```json
{
  "product": {
    "id": 2,
    "name": "New Product",
    "price": "49.99",
    "status": "active",
    "stock_quantity": 50
  }
}
```

### 6. Update Product (Admin Only)

```bash
curl -X PUT http://localhost:3000/api/v1/products/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN" \
  -d '{
    "product": {
      "price": 39.99,
      "stock_quantity": 75
    }
  }'
```

**Response:**
```json
{
  "product": {
    "id": 1,
    "name": "Product Name",
    "price": "39.99",
    "status": "active",
    "stock_quantity": 75
  }
}
```

### 7. Delete Product (Admin Only)

```bash
curl -X DELETE http://localhost:3000/api/v1/products/1 \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN"
```

**Response:** `204 No Content`

### 8. Logout

```bash
curl -X DELETE http://localhost:3000/logout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "status": 200,
  "message": "Logged out successfully."
}
```

---

## Error Responses

| Status Code | Description | Example |
|-------------|-------------|---------|
| 400 | Bad Request | Missing required parameters |
| 401 | Unauthorized | Invalid or missing JWT token |
| 403 | Forbidden | User role not authorized |
| 404 | Not Found | Resource doesn't exist |
| 422 | Unprocessable Entity | Validation errors |


**Example Error Response:**
```json
{
  "error": "Record not found",
  "message": "Couldn't find Product with 'id'=999"
}
```

**Validation Error Response:**
```json
{
  "errors": {
    "name": ["can't be blank", "is too short (minimum is 2 characters)"],
    "price": ["must be greater than or equal to 0"]
  }
}
```

---

## Product Model

### Attributes

| Field | Type | Validations |
|-------|------|-------------|
| `name` | string | Required, 2-255 characters |
| `price` | decimal | Required, >= 0 |
| `status` | enum | Required (`active`, `archived`) |
| `stock_quantity` | integer | Required, >= 0 |

---

## License

MIT
