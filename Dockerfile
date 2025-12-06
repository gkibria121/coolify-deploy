
FROM node:24-alpine AS alpine

# Install dependencies only when needed
FROM alpine AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
ENV NODE_ENV=development
# Install dependencies based on the preferred package manager
COPY package*.json  .
RUN npm install

# Rebuild the source code only when needed
FROM alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED=1

COPY .env.example .env

RUN  npm run build

# Production image, copy all the files and run next
FROM builder AS production
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Set the correct permission for prerender cache


EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["sh", "-c", "npm run start & tail -f /dev/null"]

FROM   deps AS development

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . . 
ENV NODE_ENV=development
CMD [ "npm","run","dev" ]