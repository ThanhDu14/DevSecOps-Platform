# Stage 1
FROM node:22 AS backend-builder

# setup the working dir
WORKDIR /app

# code
COPY . .

# packages install
RUN npm i

# tests
RUN npm run test

# Stage 2
FROM node:22-alpine
RUN apk upgrade --no-cache

# setup the working dir
WORKDIR /app

# copy the above stage as compressed
COPY --from=backend-builder /app .



# Port
EXPOSE 8080

# App
CMD ["npm", "start"]
