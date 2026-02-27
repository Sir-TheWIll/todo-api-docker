FROM node:18-alpine

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies
# Use --omit=dev for npm 7+ (replaces deprecated --only=production)
RUN npm ci --omit=dev || npm install --omit=dev

# Copy source code
COPY src/ ./src/

# Expose port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production

# Start the server
CMD ["node", "src/server.js"]
