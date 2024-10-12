defmodule Mix.Tasks.CreateDb do
  @moduledoc "The create_db mix task: `mix create_db`"
  use Mix.Task

  @shortdoc "Create database for PhoenixAnalytics."
  def run(_) do
    PhoenixAnalytics.Migration.up()
  end
end
