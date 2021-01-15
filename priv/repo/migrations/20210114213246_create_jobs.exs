defmodule FancyDiscord.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :status, :string, null: false
      add :gitlab_job_id, :integer, null: false
      add :gitlab_pipeline_id, :integer, null: false
      add :created_at, :naive_datetime, null: false
      add :finished_at, :naive_datetime

      add :app_id, references("apps", type: :binary_id, column: :id)

      timestamps()
    end

    create unique_index(:jobs, [:gitlab_job_id])
    create unique_index(:jobs, [:gitlab_pipeline_id])
  end
end
