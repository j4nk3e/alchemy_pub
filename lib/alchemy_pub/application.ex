defmodule AlchemyPub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AlchemyPubWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:alchemy_pub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AlchemyPub.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AlchemyPub.Finch},
      # Start a worker by calling: AlchemyPub.Worker.start_link(arg)
      # {AlchemyPub.Worker, arg},
      {AlchemyPub.Engine, base_path: "priv/pages"},
      AlchemyPub.Presence,
      AlchemyPub.Repo,
      # Start to serve requests, typically the last entry
      AlchemyPubWeb.Endpoint,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlchemyPub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlchemyPubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
