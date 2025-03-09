import Config

# Configures the endpoint
config :hello_world, HelloWorldWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: HelloWorldWeb.ErrorHTML, json: HelloWorldWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HelloWorld.PubSub,
  live_view: [signing_salt: "HELLO_WORLD"],
  secret_key_base: "your_strong_secret_key_base_that_is_at_least_64_bytes_long_for_production_this_should_be_in_env_vars",
  server: true

# Configure logging
config :logger,
  level: :debug,
  backends: [:console, {LoggerFileBackend, :file_log}]

# Configure file logging
config :logger, :file_log,
  path: "log/intent_demo.log",
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :intent_id]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs" 