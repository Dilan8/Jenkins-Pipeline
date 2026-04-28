# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY react-app/package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY react-app/ .

# Build app
RUN npm run build

# Stage 2: Production
FROM node:20-alpine

WORKDIR /app

# Copy built files
COPY --from=builder /app/dist ./dist

# Install serve
RUN npm install -g serve

# Expose port
EXPOSE 5173

# Run app
CMD ["serve", "-s", "dist", "-l", "5173"]