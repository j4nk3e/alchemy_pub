import Config

alias Swoosh.ApiClient.Req

config :alchemy_pub, AlchemyPubWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

# Configures Swoosh API Client
config :swoosh, api_client: Req

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
