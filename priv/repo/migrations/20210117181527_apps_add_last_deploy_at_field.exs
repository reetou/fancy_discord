defmodule FancyDiscord.Repo.Migrations.AppsAddLastDeployAtField do
  use Ecto.Migration

  def change do
    alter table(:apps) do
      add :last_deploy_at, :naive_datetime
    end
  end
end
