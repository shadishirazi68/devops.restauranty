
# Use the Node.js runtime
FROM node:22-alpine

# Set the working directory
WORKDIR /app

# Copy dependency manifests
COPY package.json package-lock.json ./

# Install production dependencies
RUN npm ci --omit=dev

# Copy application source code
COPY --chown=node:node . .

# Configure production environment
ENV NODE_ENV=production

# Use a non-root user
USER node

# Document the application port
EXPOSE 3001

# Start the authentication service
CMD ["node", "server.js"]
