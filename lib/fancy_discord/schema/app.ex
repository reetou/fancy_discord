defmodule FancyDiscord.Schema.App do
  use Ecto.Schema
  import Ecto.Changeset
  alias FancyDiscord.Repo
  alias FancyDiscord.Haikunator
  alias FancyDiscord.Schema.User
  alias FancyDiscord.Schema.Machine
  import FancyDiscord.Utils

  @derive {Jason.Encoder, only: [:id, :project_name, :type, :repo_url, :default_branch, :has_bot_token]}
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
    field :has_bot_token, :boolean, virtual: true

    belongs_to :user, User
    belongs_to :machine, Machine

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:project_name, :type, :github_oauth_token, :repo_url, :default_branch, :bot_token, :user_id])
    |> change(%{dokku_app: Haikunator.build(9999)})
    |> validate_inclusion(:type, ["js"])
    |> foreign_key_constraint(:user_id)
    |> cast_assoc(:user)
    |> validate_required([:project_name, :dokku_app, :type, :repo_url, :default_branch, :bot_token, :user_id])
    |> unique_constraint([:dokku_app])
  end

  def internal_changeset(module, attrs) do
    module
    |> cast(attrs, [:dokku_host, :project_name, :type, :github_oauth_token, :repo_url, :default_branch, :bot_token])
    |> validate_required([:project_name, :dokku_app, :type, :github_oauth_token, :repo_url, :default_branch, :bot_token])
    |> validate_inclusion(:type, ["js"])
    |> foreign_key_constraint([:machine_id])
    |> unique_constraint([:dokku_app])
  end

  def reset_machine(%__MODULE__{id: id}) do
    __MODULE__
    |> Repo.get!(id)
    |> internal_changeset(%{machine_id: nil})
    |> Repo.update!()
  end

  def assign_machine(%Machine{id: machine_id}, %__MODULE__{id: id}) do
    __MODULE__
    |> Repo.get!(id)
    |> internal_changeset(%{machine_id: machine_id})
    |> Repo.update!()
  end

  def get(id) when is_uuid(id) do
    Repo.get(__MODULE__, id)
    |> with_machine()
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

  def with_machine(%__MODULE__{} = app) do
    Repo.preload(app, :machine)
  end

  def fill_virtual_fields(apps) when is_list(apps) do
    Enum.map(apps, &fill_virtual_fields/1)
  end

  def fill_virtual_fields(%__MODULE__{bot_token: bot_token} = app) do
    app
    |> Map.put(:has_bot_token, bot_token != nil)
  end
end
