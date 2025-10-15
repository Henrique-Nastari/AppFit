FROM node:20-slim

WORKDIR /app

# Dependências necessárias para Prisma (Debian/Ubuntu base)
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --legacy-peer-deps

COPY . .

RUN npm run build && npx prisma generate

EXPOSE 3000
CMD ["sh", "-c", "npx prisma db push && node dist/main"]