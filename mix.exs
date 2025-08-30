defmodule AlchemyPub.MixProject do
  use Mix.Project

  def project do
    [
      app: :alchemy_pub,
      version: "0.3.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AlchemyPub.Application, []},
      extra_applications: [
        :logger,
        :ecto_sqlite3,
        :runtime_tools,
        :os_mon,
        :yaml_front_matter,
        :ulid,
      ],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8", override: true},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.1", override: true},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:tailwind, "~> 0.3"},
      {:heroicons,
       github: "tailwindlabs/heroicons", tag: "v2.1.1", app: false, compile: false, depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1"},
      {:bandit, "~> 1.5"},
      {:qr_code, "~> 3.2"},
      {:yaml_front_matter, "~> 1.0"},
      {:file_system, "~> 1.0"},
      {:earmark, "~> 1.4"},
      {:ecto_sqlite3, "~> 0.17"},
      {:ulid, github: "j4nk3e/ulid"},
      {:contex, "~> 0.5"},
      {:calendar, "~> 1.0"},
      {:credo, "~> 1.7", only: :dev},
      {:quokka, "~> 2.7", only: :dev},
      {:freedom_formatter, "~> 2.1", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev},
      {:floki, ">= 0.30.0", only: :test},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["test"],
      "assets.setup": [
        "cmd npm install --prefix assets",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
      ],
      "assets.build": ["tailwind alchemy_pub", "esbuild alchemy_pub"],
      "assets.deploy": [
        "tailwind alchemy_pub --minify",
        "esbuild alchemy_pub --minify",
        "phx.digest",
      ],
    ]
  end
end
