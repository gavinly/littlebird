import Config

# For development, we disable any cache and enable
# debugging and code reloading.
config :hello_world, HelloWorldWeb.Endpoint,
  http: [
    ip: {127, 0, 0, 1},
    port: 4000
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [],
  server: true

# Enable dev routes for dashboard and mailbox
config :hello_world, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n", level: :debug

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime 