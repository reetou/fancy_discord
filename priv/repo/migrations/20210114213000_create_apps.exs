defmodule FancyDiscord.Repo.Migrations.CreateApps do
  use Ecto.Migration

  def change do
    create table(:apps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :project_name, :string, null: false
      add :dokku_app, :string, null: false
      add :type, :string, null: false
      add :github_oauth_token, :text
      add :repo_url, :text, null: false
      add :dokku_host, :string
      add :default_branch, :string, null: false
      add :bot_token, :text, null: false

      timestamps()
    end

    create unique_index(:apps, [:dokku_app])
  end
end
