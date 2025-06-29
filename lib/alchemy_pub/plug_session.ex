defmodule AlchemyPub.Plugs.Session do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    session_id = get_session(conn, :session_id) || generate_session_id()

    referrer =
      get_session(conn, :referrer) ||
        List.keyfind(conn.req_headers, "referer", 0, {nil, ""}) |> elem(1)

    conn
    |> put_session(:session_id, session_id)
    |> put_session(:referrer, referrer)
  end

  defp generate_session_id do
    Ulid.generate()
  end
end
