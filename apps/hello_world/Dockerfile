# Use the official Elixir image as a builder
FROM elixir:1.18.3 AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y build-essential git && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Prepare build directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Copy over the mix.exs and mix.lock files to cache dependencies
COPY mix.exs mix.lock ./
COPY config config
COPY apps/hello_world/mix.exs apps/hello_world/
COPY apps/hello_world/config apps/hello_world/config

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy over all other files
COPY apps/hello_world apps/hello_world

# Compile and build release
RUN mix do compile, release

# Prepare release image
FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y libstdc++6 openssl libncurses5 locales && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

# Copy over the release from the builder
COPY --from=builder /app/_build/prod/rel/hello_world ./

# Set the environment variables
ENV PHX_HOST=localhost
ENV PORT=4000

CMD ["bin/hello_world", "start"] 