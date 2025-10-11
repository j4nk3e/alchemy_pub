defmodule AlchemyPub.Repo.Visit do
  use Ecto.Schema

  import Ecto.Query

  alias AlchemyPub.Repo
  alias AlchemyPub.Repo.Visit

  schema "visit" do
    field(:valid, :boolean)
    field(:session, :string)
    field(:admin, :boolean)
    field(:path, :string)
    field(:source, :string)
    field(:duration, :integer)
    field(:duration_total, :integer)
    field(:date, :string)
    field(:hour, :integer)
    timestamps()
  end

  def record(valid, path, source, session_id, admin, duration, duration_total) do
    now = DateTime.utc_now()
    date = now |> DateTime.to_date() |> Date.to_string()

    %Visit{
      valid: valid,
      session: session_id,
      admin: admin,
      path: path,
      source: source,
      duration: duration,
      duration_total: duration_total,
      date: date,
      hour: now.hour
    }
    |> Repo.insert()
  end

  def fetch(date) do
    Repo.all(from(v in Visit, where: v.date == ^to_string(date) and v.valid and not v.admin))
  end
end
