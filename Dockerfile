# Sets node:alpine as the builder.
FROM node:alpine as builder

# Updates and installs required Linux dependencies.
RUN set -eux; \
    apk update; \
    apk upgrade; \
    apk add --no-cache \
        python3 \
    ; \
    ln -sf python3 /usr/bin/python; \
    rm -rf /var/cache/apk/*

# Installs required Node dependencies.
COPY package*.json /saleor/
WORKDIR /saleor
RUN npm install

# Defines new group and user for security reasons.
RUN addgroup -S saleor && adduser -S -G saleor saleor

# Copies the source code from the host into the container.
COPY --chown=saleor:saleor . /saleor
WORKDIR /saleor

ARG API_URI
ARG SENTRY_DSN
ARG SENTRY_APM
ARG DEMO_MODE
ARG GTM_ID
ENV API_URI ${API_URI:-http://django:8000/graphql/}

# Executes npm build script.
RUN API_URI=${API_URI} npm run build:export

# Sets nginx:alpine as the final image.
FROM nginx:alpine

# Copies the build from the main builder.
COPY --from=builder /saleor/dist/ /saleor/

# Copies Nginx default configuration file.
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# Sets the main working directory.
WORKDIR /saleor

# Expose the deafult port for Salor Storefront.
EXPOSE 3000

# Change to the new user for security reasons.
USER saleor
