# Use the official Elixir image as a builder
FROM elixir:1.14.5-slim AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y build-essential git nodejs npm && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Prepare build directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Copy over the mix files
COPY mix.exs mix.lock ./
COPY config config

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy the app
COPY . .

# Build assets
RUN mix assets.deploy

# Compile and build release
RUN mix do compile, release

# Prepare release image
FROM elixir:1.14.5-slim

RUN apt-get update && \
    apt-get install -y openssl && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

WORKDIR /app

# Copy over the release and static assets from the builder
COPY --from=builder /app/_build/prod/rel/deploy_hello ./
COPY --from=builder /app/priv/static ./priv/static

# Set the environment variables
ENV PHX_HOST=fledgling.fly.dev
ENV PORT=8080
ENV PHX_SERVER=true
ENV RELEASE_COOKIE=secret
ENV RELEASE_NODE=deploy_hello@127.0.0.1

# Expose the port
EXPOSE 8080

# Start the Phoenix app
CMD ["bin/deploy_hello", "start"] 