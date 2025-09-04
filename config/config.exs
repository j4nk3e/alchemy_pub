# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
alias Swoosh.Adapters.Local

config :alchemy_pub, AlchemyPub.Mailer, adapter: Local
config :alchemy_pub, AlchemyPub.Repo, database: "tracker.db"

# Configures the endpoint
config :alchemy_pub, AlchemyPubWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AlchemyPubWeb.ErrorHTML, json: AlchemyPubWeb.ErrorJSON],
    layout: false,
  ],
  pubsub_server: AlchemyPub.PubSub,
  live_view: [signing_salt: "pWWRs/C1"]

config :alchemy_pub, :copyright,
  name: "AlchemyPub",
  url: "https://creativecommons.org/licenses/by/4.0/",
  license: "CC BY 4.0"

config :alchemy_pub,
  admin_secret: System.get_env("ADMIN_SECRET")

config :alchemy_pub,
  ecto_repos: [AlchemyPub.Repo]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.24.2",
  alchemy_pub: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)},
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mime, :types, %{
  "image/svg+xml" => ["svg"],
}

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.10",
  alchemy_pub: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    # Import environment specific config. This must remain at the bottom
    # of this file so it overrides the configuration defined above.
    cd: Path.expand("..", __DIR__),
  ]

import_config "#{config_env()}.exs"
