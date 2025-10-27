# Acquisitions API - Complete Architecture Guide

## 1. The Big Picture

### What is This Project?
This is a **RESTful API backend** for managing business acquisition deals. It's designed to facilitate a marketplace where:
- Users can create and manage business listings
- Buyers can make offers (deals) on listings
- Sellers can accept or reject offers
- Admins can oversee the entire platform

### Problem It Solves
The API provides a secure, scalable backend for a business acquisition platform—think of it as the infrastructure for a "marketplace for buying and selling businesses."

### Project Type
- **Pure Backend API** (no frontend included)
- **RESTful HTTP API** using Express.js
- **Serverless-Ready** (uses Neon's serverless Postgres)
- **Docker-Containerizable** (mentioned in README, ready for Kubernetes deployment)

---

## 2. Core Architecture

### Architecture Style: **Layered Monolith with Clean Separation**

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT (HTTP Requests)                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  MIDDLEWARE LAYER                                            │
│  ├─ Helmet (Security Headers)                                │
│  ├─ CORS (Cross-Origin)                                      │
│  ├─ Morgan + Winston (Logging)                               │
│  ├─ Cookie Parser                                            │
│  └─ Body Parser (JSON/URLEncoded)                            │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  ROUTES LAYER        /api/v1/auth                            │
│  Defines HTTP endpoints (POST /sign-up, /sign-in, etc.)      │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  CONTROLLERS LAYER                                           │
│  ├─ Receives HTTP requests                                   │
│  ├─ Validates input with Zod schemas                         │
│  ├─ Calls service layer                                      │
│  └─ Returns HTTP responses                                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  SERVICES LAYER (Business Logic)                             │
│  ├─ Password hashing (bcrypt)                                │
│  ├─ User creation logic                                      │
│  ├─ Database operations                                      │
│  └─ Business rules enforcement                               │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│  DATABASE LAYER (Drizzle ORM + Neon Postgres)                │
│  ├─ user table (auth)                                        │
│  ├─ listings table (planned)                                 │
│  └─ deals table (planned)                                    │
└───────────────────────────────────────────────────────────────┘
```

### Folder Structure Rationale

```
acquisitions/
├── src/
│   ├── index.js           # Entry point (loads env, bootstraps server)
│   ├── server.js          # HTTP server initialization
│   ├── app.js             # Express app config + middleware setup
│   │
│   ├── config/            # Infrastructure configuration
│   │   ├── database.js    # Neon DB connection
│   │   └── logger.js      # Winston logger setup
│   │
│   ├── routes/            # API endpoint definitions
│   │   └── auth.routes.js # /api/v1/auth endpoints
│   │
│   ├── controllers/       # Request handlers
│   │   └── auth.controller.js
│   │
│   ├── validations/       # Zod schemas for input validation
│   │   └── auth.validation.js
│   │
│   ├── services/          # Business logic + DB operations
│   │   └── auth.service.js
│   │
│   ├── models/            # Drizzle ORM schemas (DB tables)
│   │   └── user.model.js
│   │
│   └── utils/             # Shared utilities
│       ├── jwt.js         # Token signing/verification
│       ├── cookies.js     # Cookie management
│       └── format.js      # Error formatting
│
├── drizzle/               # Generated migration files
├── logs/                  # Winston log files (error.log, combined.log)
├── package.json           # Dependencies + npm scripts
└── drizzle.config.js      # Drizzle ORM configuration
```

---

## 3. Key Components Deep Dive

### 3.1 Entry Point Chain (`index.js` → `server.js` → `app.js`)

**`index.js`** (8 lines)
```javascript
import 'dotenv/config';  // Load .env variables
import './server.js';    // Bootstrap the server
```
- Purpose: Minimal bootstrap file
- Loads environment variables first, then delegates to server

**`server.js`** (10 lines)
```javascript
import app from './app.js';
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => { ... });
```
- Purpose: HTTP server initialization
- Starts Express server on configured port
- Separation allows for testing app without starting server

**`app.js`** (60 lines)
```javascript
const app = express();
app.use(helmet());        // Security headers
app.use(cors());          // Cross-origin
app.use(cookieParser());  // Parse cookies
app.use(express.json());  // Parse JSON bodies
app.use(morgan(...));     // HTTP logging

app.get('/', ...);        // Root endpoint
app.get('/health', ...);  // Health check
app.use('/api/v1/auth', authRoutes);  // Mount auth routes
```
- Purpose: Express app configuration
- Sets up all middleware in proper order
- Registers route modules
- Does NOT start the server (server.js does that)

### 3.2 Configuration Layer (`src/config/`)

**`database.js`**
```javascript
import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';

const sql = neon(process.env.DATABASE_URL);
const db = drizzle(sql);

export { db, sql };
```
- **Neon Serverless Postgres**: Auto-scales, no connection pooling needed
- **Exports two objects**:
  - `db`: Drizzle ORM query builder
  - `sql`: Raw SQL executor (for advanced queries)

**`logger.js`**
```javascript
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console(...));
}
```
- **Development**: Logs to console (colorized)
- **Production**: Logs only to files
- **Levels**: error, warn, info (configurable via LOG_LEVEL)

### 3.3 Data Models (`src/models/`)

**`user.model.js`**
```javascript
export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  name: varchar('name', { length: 255 }).notNull(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  password: varchar('password', { length: 255 }).notNull(),  // Hashed
  role: varchar('role', { length: 50 }).notNull().default('user'),
  created_at: timestamp('created_at').defaultNow().notNull(),
  updated_at: timestamp('updated_at').defaultNow().notNull(),
});
```
- **Drizzle ORM Schema**: Type-safe, TypeScript-first (but works with JS)
- **Role-Based Access**: 'user' or 'admin'
- **Timestamps**: Auto-managed by database

### 3.4 Validation Layer (`src/validations/`)

**`auth.validation.js`**
```javascript
export const signUpSchema = z.object({
  name: z.string().min(2).max(255).trim(),
  email: z.email().max(255).toLowerCase().trim(),
  password: z.string().min(6).max(128),
  role: z.enum(['user', 'admin']).default('user'),
});

export const signInSchema = z.object({
  email: z.email().toLowerCase().trim(),
  password: z.string().min(1),
});
```
- **Zod Schemas**: Runtime type validation (like TypeScript but at runtime)
- **Auto-transforms**: Email lowercased, strings trimmed
- **Default values**: Role defaults to 'user'

### 3.5 Service Layer (`src/services/`)

**`auth.service.js`** - Business Logic
```javascript
export const hashPassword = async password => {
  return await bcrypt.hash(password, 10);  // 10 salt rounds
};

export const createUser = async ({ name, email, password, role = 'user' }) => {
  // 1. Check if user exists
  const existingUser = db.select().from(users)
    .where(eq(users.email, email)).limit(1);
  
  if (existingUser.length > 0) 
    throw new Error('User with this email already exists');

  // 2. Hash password
  const passwordHash = await hashPassword(password);

  // 3. Insert into database
  const [newUser] = await db.insert(users)
    .values({ name, email, password: passwordHash, role })
    .returning({ id, name, email, role, createdAt });

  return newUser;
};
```
- **Pure business logic**: No HTTP concerns
- **Reusable**: Can be called from controllers, background jobs, tests
- **Database operations**: All Drizzle ORM queries happen here

### 3.6 Controller Layer (`src/controllers/`)

**`auth.controller.js`**
```javascript
export const signUp = async (req, res, next) => {
  try {
    // 1. Validate request body
    const validationResult = signUpSchema.safeParse(req.body);
    if (!validationResult.success) {
      return res.status(400).json({
        errors: 'Validation failed',
        details: formatValidationError(validationResult.error),
      });
    }

    // 2. Call service layer
    const { name, email, password, role } = validationResult.data;
    const user = await createUser({ name, email, password, role });

    // 3. Sign JWT token
    const token = jwttoken.sign({ id: user.id, email: user.email, role: user.role });

    // 4. Set httpOnly cookie
    cookies.set(res, 'token', token);

    // 5. Log success
    logger.info(`User registered successfully: ${email}`);

    // 6. Send response
    return res.status(201).json({
      message: 'User registered',
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (e) {
    logger.error('Signup Error', e);
    if (e.message === 'User with this email already exists') {
      return res.status(409).json({ error: 'Email already exists' });
    }
    next(e);  // Pass to error handler middleware
  }
};
```
- **HTTP-aware**: Knows about req, res, status codes
- **Orchestration**: Validates → Calls Service → Logs → Responds
- **Never contains business logic**: That's in services

### 3.7 Routes Layer (`src/routes/`)

**`auth.routes.js`**
```javascript
import express from 'express';
import { signUp } from '#controllers/auth.controller.js';

const authRoutes = express.Router();

authRoutes.post('/sign-up', signUp);
authRoutes.post('/sign-in', (req, res) => { ... });  // Stub
authRoutes.post('/sign-out', (req, res) => { ... });  // Stub

export default authRoutes;
```
- **Mounted at**: `/api/v1/auth` in `app.js`
- **Full paths**: 
  - `POST /api/v1/auth/sign-up`
  - `POST /api/v1/auth/sign-in`
  - `POST /api/v1/auth/sign-out`

### 3.8 Utilities (`src/utils/`)

**`jwt.js`** - Token Management
```javascript
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_Please_Change-on-deployment';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1d';

export const jwttoken = {
  sign: payload => jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN }),
  verify: token => jwt.verify(token, JWT_SECRET),
};
```

**`cookies.js`** - Cookie Management
```javascript
export const cookies = {
  getOptions: () => ({
    httpOnly: true,           // Not accessible via JavaScript (XSS protection)
    secure: process.env.NODE_ENV === 'production',  // HTTPS only in prod
    sameSite: 'strict',       // CSRF protection
    maxAge: 15 * 60 * 1000,   // 15 minutes
  }),
  set: (res, name, value, options = {}) => {
    res.cookie(name, value, { ...cookies.getOptions(), ...options });
  },
  clear: (res, name, options = {}) => { ... },
  get: (req, name) => req.cookies[name],
};
```
- **Security-first**: httpOnly prevents XSS, sameSite prevents CSRF

**`format.js`** - Error Formatting
```javascript
export const formatValidationError = errors => {
  if (!errors || !errors.issues) return 'Validation failed';
  if (Array.isArray(errors.issues))
    return errors.issues.map(issue => issue.message).join(', ');
  return JSON.stringify(errors);
};
```

---

## 4. Data Flow & Communication

### 4.1 Complete Request Flow (User Sign-Up Example)

```
1. CLIENT
   POST /api/v1/auth/sign-up
   Content-Type: application/json
   {
     "name": "John Doe",
     "email": "john@example.com",
     "password": "secret123",
     "role": "user"
   }

2. EXPRESS MIDDLEWARE STACK (app.js)
   ├─ helmet()          → Adds security headers
   ├─ cors()            → Handles CORS preflight
   ├─ cookieParser()    → Parses existing cookies
   ├─ express.json()    → Parses JSON body into req.body
   └─ morgan()          → Logs: "POST /api/v1/auth/sign-up 201"

3. ROUTES (auth.routes.js)
   authRoutes.post('/sign-up', signUp)
   └─ Matches route, calls signUp controller

4. CONTROLLER (auth.controller.js)
   signUp(req, res, next)
   ├─ Validates with Zod: signUpSchema.safeParse(req.body)
   │  └─ Transforms: email → lowercase, strings → trimmed
   │  └─ If invalid → return 400 with formatted errors
   │
   ├─ Calls service: createUser({ name, email, password, role })
   │
   ├─ Service returns: { id: 1, name: "John Doe", email: "john@example.com", role: "user" }
   │
   ├─ Signs JWT: jwttoken.sign({ id: 1, email: "john@example.com", role: "user" })
   │  └─ Returns: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
   │
   ├─ Sets cookie: cookies.set(res, 'token', token)
   │  └─ Adds Set-Cookie header (httpOnly, secure in prod, sameSite: strict)
   │
   ├─ Logs: logger.info("User registered successfully: john@example.com")
   │
   └─ Responds: res.status(201).json({ message, user })

5. SERVICE (auth.service.js)
   createUser({ name, email, password, role })
   ├─ Query DB: Check if email exists
   │  db.select().from(users).where(eq(users.email, email))
   │  └─ If exists → throw Error("User with this email already exists")
   │
   ├─ Hash password: bcrypt.hash(password, 10)
   │  └─ Returns: "$2b$10$X..." (bcrypt hash)
   │
   ├─ Insert into DB:
   │  db.insert(users).values({
   │    name: "John Doe",
   │    email: "john@example.com",
   │    password: "$2b$10$X...",
   │    role: "user"
   │  }).returning({ id, name, email, role, createdAt })
   │
   └─ Returns user object

6. DATABASE (Neon Postgres)
   INSERT INTO users (name, email, password, role, created_at, updated_at)
   VALUES ('John Doe', 'john@example.com', '$2b$10$X...', 'user', NOW(), NOW())
   RETURNING id, name, email, role, created_at;

7. RESPONSE TO CLIENT
   HTTP/1.1 201 Created
   Set-Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...; HttpOnly; Secure; SameSite=Strict; Max-Age=900
   Content-Type: application/json

   {
     "message": "User registered",
     "user": {
       "id": 1,
       "name": "John Doe",
       "email": "john@example.com",
       "role": "user"
     }
   }
```

### 4.2 Authentication Flow (After Sign-Up)

```
┌─────────────┐
│   Client    │
│  (Browser)  │
└──────┬──────┘
       │
       │ 1. POST /api/v1/auth/sign-in
       │    { email, password }
       │
       ▼
┌──────────────────────────────────────┐
│  Controller: auth.controller.js      │
│  ├─ Validate with signInSchema       │
│  ├─ Call: authenticateUser()         │
│  └─ Sign JWT + Set Cookie            │
└──────┬───────────────────────────────┘
       │
       │ 2. authenticateUser(email, password)
       │
       ▼
┌──────────────────────────────────────┐
│  Service: auth.service.js            │
│  ├─ Find user by email               │
│  ├─ Compare: bcrypt.compare()        │
│  └─ Return user if valid             │
└──────┬───────────────────────────────┘
       │
       │ 3. SELECT * FROM users WHERE email = ?
       │
       ▼
┌──────────────────────────────────────┐
│  Database (Neon Postgres)            │
│  └─ Returns user record              │
└──────┬───────────────────────────────┘
       │
       │ 4. User object returned
       │
       ▼
┌──────────────────────────────────────┐
│  JWT Token Generated                 │
│  { id: 1, email: "...", role: "..." }│
│  Signed with JWT_SECRET              │
└──────┬───────────────────────────────┘
       │
       │ 5. Set-Cookie: token=...
       │
       ▼
┌──────────────────────────────────────┐
│  Client stores cookie                │
│  (httpOnly - not accessible to JS)   │
└──────────────────────────────────────┘
       │
       │ 6. Future requests:
       │    GET /api/v1/listings
       │    Cookie: token=...
       │
       ▼
┌──────────────────────────────────────┐
│  Middleware: auth.middleware.js      │
│  ├─ Extract token from cookie        │
│  ├─ Verify with jwttoken.verify()    │
│  ├─ Attach user to req.user          │
│  └─ next() or 401 Unauthorized       │
└──────────────────────────────────────┘
```

---

## 5. Tech Stack & Dependencies

### Core Framework & Runtime
| Technology | Purpose | Why It Matters |
|-----------|---------|----------------|
| **Node.js** (v18+) | JavaScript runtime | Event-driven, non-blocking I/O for handling concurrent requests efficiently |
| **Express.js 5.1** | Web framework | Minimalist, flexible, industry-standard for Node.js APIs |

### Database Stack
| Technology | Purpose | Why It Matters |
|-----------|---------|----------------|
| **Neon Postgres** | Serverless database | Auto-scales, no connection pooling needed, branch-based dev workflows |
| **Drizzle ORM 0.44** | Type-safe ORM | TypeScript-first, minimal overhead, direct SQL compilation |
| **@neondatabase/serverless** | Neon driver | Optimized for serverless environments (edge-compatible) |

### Security & Authentication
| Technology | Purpose | Why It Matters |
|-----------|---------|----------------|
| **jsonwebtoken** | JWT creation/verification | Stateless authentication, works across microservices |
| **bcrypt 6.0** | Password hashing | Industry-standard, resistant to brute-force (10 rounds) |
| **Helmet.js** | Security headers | Sets HTTP headers to prevent XSS, clickjacking, etc. |
| **CORS** | Cross-origin control | Allows frontend (different domain) to access API |
| **cookie-parser** | Cookie handling | Parses cookies for JWT retrieval |

### Validation & Data Integrity
| Technology | Purpose | Why It Matters |
|-----------|---------|----------------|
| **Zod 4.1** | Schema validation | Runtime type checking, auto-transforms (trim, lowercase), great error messages |

### Logging & Monitoring
| Technology | Purpose | Why It Matters |
|-----------|---------|----------------|
| **Winston 3.18** | Structured logging | Production-ready, multiple transports (console, file), log levels |
| **Morgan** | HTTP request logging | Logs all incoming requests (combined with Winston) |

### Development Tools
| Technology | Purpose | Why It Matters |
|-----------|---------|----------------|
| **Nodemon** | Auto-restart server | Watches file changes, restarts server automatically |
| **ESLint** | Code linting | Enforces code style, catches bugs |
| **Prettier** | Code formatting | Consistent code style across team |
| **Drizzle Kit** | Database migrations | Generates SQL migrations from schema changes |

### Why This Stack?
1. **Serverless-First**: Neon + Node.js = scales to zero, pay per usage
2. **Type Safety**: Drizzle + Zod = runtime and compile-time safety
3. **Security by Default**: JWT httpOnly cookies + Helmet + bcrypt
4. **Developer Experience**: Hot reload, structured logging, auto-formatting
5. **Production-Ready**: Winston logging, error handling, health checks

---

## 6. Execution Flow (Typical Workflows)

### Workflow A: New User Registration

```
┌─────────┐
│ START   │
└────┬────┘
     │
     ▼
┌────────────────────────────────────┐
│ User fills sign-up form            │
│ ├─ Name: "Alice"                   │
│ ├─ Email: "alice@example.com"      │
│ ├─ Password: "SecurePass123"       │
│ └─ Role: "user" (default)          │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Frontend sends POST request        │
│ POST /api/v1/auth/sign-up          │
│ Body: { name, email, password }    │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Express Middleware Pipeline        │
│ ├─ Parse JSON body                 │
│ ├─ Parse cookies                   │
│ └─ Log request                     │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Route Match: /sign-up → signUp()   │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Controller: Validate Input         │
│ signUpSchema.safeParse(req.body)   │
│ ├─ Email → lowercase               │
│ ├─ Strings → trimmed               │
│ └─ Password min 6 chars            │
└────┬───────────────────────────────┘
     │
     ├─ Invalid? ────┐
     │               ▼
     │         ┌─────────────────┐
     │         │ Return 400      │
     │         │ Bad Request     │
     │         └─────────────────┘
     │
     ▼ Valid
┌────────────────────────────────────┐
│ Service: createUser()              │
│ ├─ Check if email exists           │
│ │  ├─ Exists? → throw Error        │
│ │  └─ Not exists → continue        │
│ ├─ Hash password (bcrypt)          │
│ └─ Insert into users table         │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Database: INSERT INTO users        │
│ RETURNING id, name, email, role    │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Service returns user object        │
│ { id: 42, name: "Alice", ... }     │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Controller: Sign JWT               │
│ jwttoken.sign({ id, email, role }) │
│ → "eyJhbGciOiJI..."                │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Set httpOnly Cookie                │
│ cookies.set(res, 'token', token)   │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Log Success                        │
│ logger.info("User registered: ...") │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Return 201 Created                 │
│ {                                  │
│   message: "User registered",      │
│   user: { id, name, email, role }  │
│ }                                  │
└────┬───────────────────────────────┘
     │
     ▼
┌────────────────────────────────────┐
│ Frontend receives response         │
│ ├─ Stores cookie (browser auto)    │
│ └─ Redirects to dashboard          │
└────┬───────────────────────────────┘
     │
     ▼
┌─────────┐
│  END    │
└─────────┘
```

### Workflow B: Protected Route Access (Future Implementation)

```
User wants to create a business listing (requires authentication)

1. Browser sends request with cookie:
   GET /api/v1/listings
   Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

2. Middleware chain:
   ├─ cookieParser() → Parses cookies into req.cookies
   ├─ authMiddleware() → 
   │  ├─ Extract token from req.cookies.token
   │  ├─ Verify: jwttoken.verify(token)
   │  ├─ If valid → Attach user to req.user = { id, email, role }
   │  └─ If invalid → Return 401 Unauthorized
   └─ If authenticated → next()

3. Controller receives request with req.user populated:
   {
     id: 42,
     email: "alice@example.com",
     role: "user"
   }

4. Controller can now:
   ├─ Check role: if (req.user.role !== 'admin') return 403 Forbidden
   ├─ Use user ID: listings.where(eq(listings.owner_id, req.user.id))
   └─ Log actions: logger.info(`User ${req.user.id} created listing`)
```

---

## 7. Strengths & Tradeoffs

### ✅ Strengths

#### 1. **Clean Architecture**
- **Separation of concerns**: Routes don't know about databases, services don't know about HTTP
- **Testability**: Can test services without HTTP, controllers without database
- **Maintainability**: Each layer has single responsibility

#### 2. **Type Safety (Runtime)**
- **Zod validation**: Catches invalid data before it reaches business logic
- **Drizzle ORM**: Type-safe database queries (TypeScript-like in JavaScript)

#### 3. **Security-First Design**
- **httpOnly cookies**: Prevents XSS attacks on tokens
- **bcrypt hashing**: Password never stored in plaintext
- **Helmet.js**: Automatic security headers
- **Input validation**: All user input validated with Zod

#### 4. **Scalability**
- **Neon serverless**: Auto-scales database, no connection management
- **Stateless auth**: JWT allows horizontal scaling (no session store needed)
- **Docker-ready**: Containerization for Kubernetes deployment

#### 5. **Developer Experience**
- **Absolute imports**: `#config/logger` instead of `../../../config/logger`
- **Hot reload**: Nodemon restarts on file changes
- **Structured logging**: Winston for production-grade logging
- **Migration system**: Drizzle Kit manages schema changes

#### 6. **Production-Ready**
- **Health check endpoint**: `/health` for monitoring
- **Environment-based config**: Different settings for dev/prod
- **Error handling**: Try-catch blocks with proper HTTP status codes
- **Logging**: All actions logged for debugging

### ⚠️ Tradeoffs & Limitations

#### 1. **Incomplete Implementation**
- **Sign-in/sign-out**: Controllers are stubs, not implemented
- **No auth middleware**: Protected routes can't verify tokens yet
- **Missing features**: Listings, deals, admin panel not implemented

#### 2. **No Tests**
- **Testing framework**: Jest mentioned in README, but no test files
- **Risk**: Refactoring without tests is dangerous
- **Recommendation**: Add integration tests for auth flow

#### 3. **Limited Error Handling**
- **Global error handler**: No centralized error handler middleware
- **Database errors**: Not all DB errors handled gracefully
- **Recommendation**: Add `app.use((err, req, res, next) => {...})` at end of middleware stack

#### 4. **Cookie Security**
- **MaxAge**: Cookies expire in 15 minutes (seems short for user sessions)
- **No refresh tokens**: User has to re-login every 15 minutes
- **Recommendation**: Implement refresh token strategy

#### 5. **No Rate Limiting**
- **Arcjet mentioned**: In README/env, but not implemented
- **Risk**: Brute-force attacks on /sign-in
- **Recommendation**: Add rate limiting middleware

#### 6. **Database Migrations**
- **Migration files**: Generated but not version controlled properly
- **Risk**: Teammates may have schema drift
- **Recommendation**: Commit migration files to git

#### 7. **Monolithic Structure**
- **Single codebase**: All features in one repo
- **Tradeoff**: Easier to start, harder to scale teams
- **When to split**: If team grows >10 engineers, consider microservices

#### 8. **No API Documentation**
- **No Swagger/OpenAPI**: Endpoints not documented
- **Risk**: Frontend devs have to read code
- **Recommendation**: Add Swagger UI with JSDoc annotations

### 🔍 Code Quality Issues

#### Issue 1: Bug in `auth.service.js` Line 18
```javascript
const existingUser = db.select().from(users)
  .where(eq(users.email, email)).limit(1);

if (existingUser.length > 0) throw new Error(...);
```
**Problem**: Missing `await` - query is never executed!
**Fix**: `const existingUser = await db.select()...`

#### Issue 2: Inconsistent Error Handling
- Some errors return JSON: `res.status(400).json({ error: "..." })`
- Others use `next(e)` to pass to error handler
- **Recommendation**: Pick one pattern (prefer error handler middleware)

#### Issue 3: Magic Numbers
```javascript
maxAge: 15 * 60 * 1000,  // What is 15 * 60 * 1000?
```
**Recommendation**: `const COOKIE_MAX_AGE_MS = 15 * 60 * 1000; // 15 minutes`

---

## 8. Final Summary

### 🎯 Elevator Pitch (30 seconds)

**This is a Node.js + Express REST API for managing business acquisitions.** It uses a layered architecture where routes handle HTTP, controllers validate inputs with Zod, services contain business logic, and Drizzle ORM talks to Neon Postgres. Authentication is JWT-based with httpOnly cookies, passwords are bcrypt-hashed, and everything is logged with Winston. The codebase follows clean architecture principles with absolute imports, making it maintainable and testable.

### 📊 Technical Summary (2 minutes)

**Architecture**: Layered monolith with clear separation - Routes → Controllers → Services → Database

**Entry flow**: `index.js` bootstraps → `server.js` starts HTTP server → `app.js` configures Express

**Request lifecycle**: HTTP request → Middleware (helmet, CORS, body parser) → Route matcher → Controller validates with Zod → Service executes business logic → Drizzle ORM queries Neon Postgres → Response with JWT cookie

**Security**: bcrypt password hashing (10 rounds), JWT tokens in httpOnly cookies (prevents XSS), Helmet.js security headers, input validation with Zod, CORS enabled

**Database**: Neon serverless Postgres (auto-scaling, no connection pooling) with Drizzle ORM for type-safe queries and migration management

**Key patterns**: 
- Absolute imports with `#` prefix (e.g., `#config/logger`)
- Environment-based configuration (dev logs to console, prod to files)
- Validation happens in controllers, business logic in services
- All database operations return clean objects (no passwords in responses)

**Production-ready features**: Winston structured logging, health check endpoint, error handling with try-catch, Docker support, ESLint + Prettier for code quality

**Current state**: Auth signup fully implemented, signin/signout are stubs, core listings/deals features planned but not built yet

---

## 9. Next Steps for Development

If you were to continue building this, here's the recommended order:

1. **Fix the bug in `auth.service.js`** (add `await` on line 18)
2. **Implement sign-in controller** (verify password with bcrypt.compare)
3. **Create auth middleware** (`verifyToken()` to protect routes)
4. **Add listings feature** (model, routes, controller, service)
5. **Add deals feature** (offers on listings)
6. **Implement role-based access control** (admin vs user permissions)
7. **Add rate limiting** (Arcjet integration)
8. **Write tests** (Jest + SuperTest for API tests)
9. **Add API documentation** (Swagger/OpenAPI)
10. **Set up CI/CD** (GitHub Actions for tests + Docker builds)

---

**Questions?** Feel free to dive into any specific component, and I can explain it in more detail!
