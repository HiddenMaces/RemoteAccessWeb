FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Create links directory and file
RUN mkdir -p public && echo "[]" > links.json

# Expose port
EXPOSE 443

# Start the server
CMD ["npm", "start"]
