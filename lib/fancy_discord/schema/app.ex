defmodule FancyDiscord.Schema.App do
  use Ecto.Schema
  import Ecto.Changeset
  alias FancyDiscord.Repo
  alias FancyDiscord.Haikunator
  alias FancyDiscord.Schema.User
  import FancyDiscord.Utils

  @derive {Jason.Encoder, only: [:id, :project_name, :type]}
  @primary_key {:id, :binary_id, [autogenerate: true]}
  @foreign_key_type :binary_id
  schema "apps" do
    field :project_name, :string
    field :dokku_app, :string
    field :type, :string
    field :github_oauth_token, :string
    field :repo_url, :string
    field :dokku_host, :string
    field :default_branch, :string, default: "main"
    field :bot_token, :string

    belongs_to :user, User

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:project_name, :type, :github_oauth_token, :repo_url, :default_branch, :bot_token])
    |> change(%{dokku_app: Haikunator.build(9999)})
    |> validate_required([:project_name, :dokku_app, :type, :repo_url, :default_branch, :bot_token])
    |> validate_inclusion(:type, ["js"])
    |> foreign_key_constraint([:user_id])
    |> unique_constraint([:dokku_app])
  end

  def internal_changeset(module, attrs) do
    module
    |> cast(attrs, [:dokku_host, :project_name, :type, :github_oauth_token, :repo_url, :default_branch, :bot_token])
    |> validate_required([:project_name, :dokku_app, :type, :github_oauth_token, :repo_url, :default_branch, :bot_token])
    |> validate_inclusion(:type, ["js"])
    |> unique_constraint([:dokku_app])
  end

  def reset_dokku_host(id) do
    __MODULE__
    |> Repo.get!(id)
    |> internal_changeset(%{dokku_host: nil})
    |> Repo.update!()
  end

  def get(id) when is_uuid(id) do
    Repo.get(__MODULE__, id)
  end

  def get(_) do
    nil
  end

  def get_in_user(user, id) do
    user
    |> User.with_apps()
    |> Map.fetch!(:apps)
    |> Enum.find(fn a -> a.id == id end)
  end

  def create(attrs, user_id) do
    attrs =
      attrs
      |> Map.drop([:user_id, "user_id"])
      |> Map.put("user_id", user_id)
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def delete(id) do
    __MODULE__
    |> Repo.get!(id)
    |> Repo.delete!()
  end
end
