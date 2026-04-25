# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files from react-app
COPY react-app/package.json* react-app/package-lock.json* ./

# Install dependencies
RUN npm install

# Copy source code from react-app
COPY react-app/ .

# Build the app
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Copy built app from builder stage
COPY --from=builder /app/dist ./dist

# Install serve to run the static files
RUN npm install -g serve

# Expose port
EXPOSE 5173

# Start the application
CMD ["serve", "-s", "dist", "-l", "5173"]
