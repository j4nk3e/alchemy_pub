defmodule AlchemyPub.Repo.Migrations.InitialMigration do
  use Ecto.Migration

  def change do
    create table("visit") do
      add :valid, :boolean
      add :session, :string, size: 26
      add :path, :string
      add :source, :string
      add :duration, :integer
      add :duration_total, :integer
      add :date, :string
      add :hour, :integer

      timestamps()
    end
    create index("visit", [:valid, :date, :hour])
  end
end
