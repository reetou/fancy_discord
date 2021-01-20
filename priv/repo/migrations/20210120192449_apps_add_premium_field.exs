defmodule FancyDiscord.Repo.Migrations.AppsAddPremiumField do
  use Ecto.Migration

  def change do
    alter table(:apps) do
      add :plan, :integer, null: false, default: 0
    end
  end
end
