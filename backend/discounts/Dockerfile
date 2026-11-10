
# Use Node.js Alpine image
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install production dependencies
RUN npm ci --omit=dev

# Copy application files
COPY --chown=node:node . .

# Set production environment
ENV NODE_ENV=production

# Run as non-root user
USER node

# Discounts service port
EXPOSE 3002

# Start application
CMD ["node", "server.js"]
