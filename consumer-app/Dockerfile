FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy source code
COPY src/ ./src/

# Create logs directory
RUN mkdir -p /app/logs

# Expose metrics port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]