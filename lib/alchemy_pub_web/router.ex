defmodule AlchemyPubWeb.Router do
  use AlchemyPubWeb, :router

  import Phoenix.LiveDashboard.Router

  alias AlchemyPub.Plugs.Session
  alias Plug.Swoosh.MailboxPreview

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(Session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {AlchemyPubWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :rss do
    plug(:accepts, ["xml"])
  end

  pipeline :svg do
    plug(:accepts, ["svg"])
  end

  # Other scopes may use custom stacks.
  # scope "/api", AlchemyPubWeb do
  #   pipe_through :api
  # end

  def require_basic_auth(conn, _opts) do
    username = System.get_env("AUTH_USERNAME")
    password = System.get_env("AUTH_PASSWORD")
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end

  def set_admin_cookie(conn, _opts) do
    admin_secret = Application.get_env(:alchemy_pub, :admin_secret)
    Plug.Conn.put_resp_cookie(conn, "admin_secret", admin_secret, http_only: true)
  end

  @auth_pipeline (case(Mix.env()) do
                    :prod -> [:browser, :require_basic_auth, :set_admin_cookie]
                    env when env in [:dev, :test] -> [:browser, :set_admin_cookie]
                  end)

  scope "/dev" do
    pipe_through(@auth_pipeline)

    live_dashboard("/dashboard",
      metrics: AlchemyPubWeb.Telemetry,
      additional_pages: [
        analytics: AlchemyPubWeb.DevAnalytics
      ]
    )

    forward("/mailbox", MailboxPreview)
  end

  scope "/", AlchemyPubWeb do
    pipe_through(:rss)

    get "/feed.rss", FeedController, :index
  end

  scope "/qr", AlchemyPubWeb do
    pipe_through(:svg)
    get("/", QrController, :index)
  end

  scope "/", AlchemyPubWeb do
    pipe_through(:browser)

    live_session :default do
      live("/*path", PageLive)
    end
  end
end
