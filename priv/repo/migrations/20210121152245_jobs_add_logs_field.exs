defmodule FancyDiscord.Repo.Migrations.JobsAddLogsField do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :logs, :text, null: false, default: ""
    end
  end
end
