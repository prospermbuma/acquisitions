# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install all dependencies (including dev dependencies for potential build steps)
RUN npm ci

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install dumb-init and curl for proper signal handling and health checks
RUN apk add --no-cache dumb-init curl

# Copy only production dependencies
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy application code
COPY . .

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

# Expose port
EXPOSE 3000

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "src/index.js"]
