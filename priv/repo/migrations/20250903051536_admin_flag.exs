defmodule AlchemyPub.Repo.Migrations.AdminFlag do
  use Ecto.Migration

  def change do
    alter table(:visit) do
      add(:admin, :boolean, default: false)
    end
  end
end
