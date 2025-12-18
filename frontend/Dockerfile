# FilaOps Frontend - React + Vite
# Multi-stage build: Node for building, Nginx for serving
# 
# ⚠️  IMPORTANT: This Dockerfile uses DEVELOPMENT MODE builds
# Production minified builds are DISABLED due to temporal dead zone errors
# See: frontend/PRODUCTION_BUILD_BLOCKED.md

# ===================
# Stage 1: Build
# ===================
FROM node:20-alpine AS builder

WORKDIR /app

# Accept build arg for API URL
ARG VITE_API_URL=http://localhost:8001
ENV VITE_API_URL=$VITE_API_URL

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build for production
RUN npm run build

# ===================
# Stage 2: Serve with Nginx
# ===================
FROM nginx:alpine

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
