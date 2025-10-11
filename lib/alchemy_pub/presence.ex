defmodule AlchemyPub.Presence do
  use Phoenix.Presence,
    otp_app: :alchemy_pub,
    pubsub_server: AlchemyPub.PubSub

  alias AlchemyPub.Repo.Visit

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, %{leaves: leaves}, presences, state) do
    for {_, %{metas: metas}} <- leaves,
        %{
          session: session,
          admin: admin,
          valid: valid,
          path: path,
          source: source,
          joined: joined,
          path_joined: path_joined
        } <- metas do
      now = DateTime.utc_now()
      duration = DateTime.diff(now, path_joined)
      duration_total = DateTime.diff(now, joined)

      Visit.record(
        valid,
        path,
        source,
        session,
        admin,
        duration,
        duration_total
      )
    end

    Phoenix.PubSub.local_broadcast(AlchemyPub.PubSub, topic, {:viewers, map_size(presences)})
    {:ok, state}
  end
end
