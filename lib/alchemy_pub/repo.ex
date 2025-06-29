defmodule AlchemyPub.Repo do
  use Ecto.Repo, otp_app: :alchemy_pub, adapter: Ecto.Adapters.SQLite3

  require Logger
end
