FROM node:22-slim

# Build tools required by better-sqlite3 (native addon compiled via node-gyp).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 make g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Pre-populate the npm cache (~/.npm) with the union of all example dependencies.
# Subsequent "npm install" calls in the actual example directories hit the cache
# instead of the network.
WORKDIR /warmup
COPY package.json .
RUN npm install --prefer-offline 2>/dev/null || npm install && \
    rm -rf node_modules
