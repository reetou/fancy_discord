defmodule FancyDiscord.Repo.Migrations.AppsUserIdFk do
  use Ecto.Migration

  def change do
    alter table(:apps) do
      add :user_id, references("users", type: :binary_id)
    end
  end
end
