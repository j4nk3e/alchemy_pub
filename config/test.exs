import Config

# Configure your database

alias Swoosh.Adapters.Test

# In test we don't send emails
config :alchemy_pub, AlchemyPub.Mailer, adapter: Test

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :alchemy_pub, AlchemyPubWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Nx4Q5cpIkveKgPdVpUF71fHMLfZXZjIXYeRqDyOOyreKI9YDToG8MOK5l8ovzWAp",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
