defmodule FancyDiscord.Repo.Migrations.CreateMachines do
  use Ecto.Migration

  def change do
    create table(:machines, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ip, :string, null: false
      add :maximum_apps, :integer, null: false
      add :deployed_apps, :integer, null: false

      timestamps()
    end

    create unique_index(:machines, [:ip])

    alter table(:apps) do
      add :machine_id, references("machines", type: :binary_id)
    end
  end
end
