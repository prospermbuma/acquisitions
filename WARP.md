# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common Commands

### Development
```bash
npm run dev          # Start development server with hot reload (nodemon)
npm start            # Start server with Node.js --watch flag
```

### Code Quality
```bash
npm run lint         # Run ESLint to check for code issues
npm run lint:fix     # Auto-fix ESLint issues
npm run format       # Format code with Prettier
npm run format:check # Check if code is formatted correctly
```

### Database Operations
```bash
npm run db:generate  # Generate Drizzle migrations from schema
npm run db:migrate   # Run pending database migrations
npm run db:studio    # Open Drizzle Studio for database management
```

## Architecture Overview

### Import Aliases
The project uses Node.js subpath imports (not TypeScript path aliases) with the `#` prefix. All imports must follow this pattern:
- `#config/*` → `./src/config/*`
- `#controllers/*` → `./src/controllers/*`
- `#middlewares/*` → `./src/middlewares/*`
- `#models*` → `./src/models*`
- `#routes/*` → `./src/routes/*`
- `#services/*` → `./src/services/*`
- `#utils/*` → `./src/utils/*`
- `#validations/*` → `./src/validations/*`

### Layered Architecture
The codebase follows a clean, layered architecture pattern:

**Entry Point Flow**: `index.js` → `server.js` → `app.js`
- `index.js`: Loads environment variables and bootstraps the server
- `server.js`: Starts the Express server on configured port
- `app.js`: Configures middleware and routes

**Request Flow**: Route → Controller → Service → Database
- **Routes** (`src/routes/`): Define API endpoints and HTTP methods
- **Controllers** (`src/controllers/`): Handle request/response, validate input with Zod schemas
- **Services** (`src/services/`): Contain business logic and database operations
- **Models** (`src/models/`): Define Drizzle ORM database schemas

**Supporting Layers**:
- **Validations** (`src/validations/`): Zod schemas for request validation
- **Utils** (`src/utils/`): Reusable utilities (JWT, cookies, formatters)
- **Config** (`src/config/`): Application configuration (database connection, logger)

### Key Architectural Patterns

**Database Access**: All database operations use Drizzle ORM with Neon Postgres serverless. The connection is established in `src/config/database.js` and exports `db` and `sql` for query operations.

**Authentication Flow**: JWT-based authentication with httpOnly cookies. Tokens are signed with `jwttoken.sign()` and stored via `cookies.set()`. User passwords are hashed with bcrypt before storage.

**Logging**: Winston logger configured in `src/config/logger.js`. In development, logs to console; in production, logs to files (`logs/error.log`, `logs/combined.log`). Always use `logger.info/error/warn` instead of `console.log`.

**Validation**: All incoming requests must be validated using Zod schemas from `src/validations/`. Use `.safeParse()` in controllers and format errors with `formatValidationError()` from `#utils/format.js`.

**Error Handling**: Controllers use try-catch blocks. Service layer throws errors that bubble up to controllers. Use logger for all errors before responding to client.

## Environment Variables

Required in `.env`:
```
PORT=3000
NODE_ENV=development
LOG_LEVEL=info
DATABASE_URL=          # Neon Postgres connection string
ARCJET_KEY=            # Arcjet security key (when implemented)
JWT_SECRET=            # JWT signing secret (strongly recommended)
JWT_EXPIRES_IN=1d      # JWT expiration time
```

## Development Guidelines

### Adding New Features
1. Define Drizzle model in `src/models/` if database table needed
2. Run `npm run db:generate` and `npm run db:migrate` for schema changes
3. Create Zod validation schema in `src/validations/`
4. Implement service logic in `src/services/`
5. Create controller in `src/controllers/` that uses validation and service
6. Define routes in `src/routes/` and register in `src/app.js`
7. Run `npm run lint:fix` and `npm run format` before committing

### Code Style
- Use ES modules (`import/export`) throughout
- Use arrow functions for utilities and service methods
- Use async/await for asynchronous operations
- Always destructure validated data before passing to services
- Return early from controllers on validation/error cases
- Use descriptive variable names (e.g., `validationResult`, `existingUser`)

### Database Queries
- Use Drizzle ORM query builder, not raw SQL
- Import table schemas from `#models/`
- Use Drizzle operators from `drizzle-orm` (e.g., `eq`, `and`, `or`)
- Always use `.returning()` after inserts to get created records
- Check for existing records before inserts to avoid duplicates
