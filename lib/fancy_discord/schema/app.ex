defmodule FancyDiscord.Schema.App do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias FancyDiscord.Repo
  alias FancyDiscord.Haikunator
  alias FancyDiscord.Schema.User
  alias FancyDiscord.Schema.Machine
  import FancyDiscord.Utils

  @derive {Jason.Encoder, only: [:id, :project_name, :type, :repo_url, :default_branch, :has_bot_token, :deployed, :last_deploy_at, :plan, :status]}
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
    field :last_deploy_at, :naive_datetime
    field :has_bot_token, :boolean, virtual: true
    field :deployed, :boolean, virtual: true
    field :status, :string, virtual: true
    field :plan, :integer, default: 0

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

  def update_changeset(module, attrs) do
    module
    |> cast(attrs, [:project_name, :github_oauth_token, :repo_url, :default_branch, :bot_token])
    |> foreign_key_constraint(:user_id)
    |> cast_assoc(:user)
    |> validate_required([:project_name, :dokku_app, :type, :repo_url, :default_branch, :bot_token, :user_id])
    |> unique_constraint([:dokku_app])
  end

  def internal_changeset(module, attrs) do
    module
    |> cast(attrs, [:dokku_host, :project_name, :type, :github_oauth_token, :repo_url, :default_branch, :bot_token, :last_deploy_at, :machine_id, :plan])
    |> validate_required([:project_name, :dokku_app, :type, :repo_url, :default_branch, :bot_token, :plan])
    |> validate_inclusion(:type, ["js"])
    |> foreign_key_constraint(:machine_id)
    |> unique_constraint([:dokku_app])
  end

  def reset_machine(%__MODULE__{id: id}) do
    __MODULE__
    |> Repo.get!(id)
    |> internal_changeset(%{machine_id: nil, last_deploy_at: nil})
    |> Repo.update!()
  end

  def assign_machine(%Machine{id: machine_id}, %__MODULE__{id: id}) do
    __MODULE__
    |> Repo.get!(id)
    |> internal_changeset(%{machine_id: machine_id})
    |> Repo.update!()
  end

  def deploy_update(id) do
    __MODULE__
    |> Repo.get!(id)
    |> internal_changeset(%{last_deploy_at: DateTime.utc_now()})
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

  def update(%__MODULE__{} = app, attrs) do
    app
    |> update_changeset(attrs)
    |> Repo.update()
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

  def fill_virtual_fields(%__MODULE__{bot_token: bot_token, machine_id: machine_id} = app) do
    app
    |> Map.put(:has_bot_token, bot_token != nil)
    |> deployed()
  end

  def fill_virtual_fields(%__MODULE__{} = app, %{status: status}) do
    app
    |> fill_virtual_fields()
    |> Map.put(:status, status)
    |> deployed()
  end

  def fill_virtual_fields(%__MODULE__{} = app, _), do: fill_virtual_fields(app)

  def deployed(%__MODULE__{status: status} = app) when status in [:init_failed, :init_in_progress, :destroy_in_progress, :init_required] do
    %__MODULE__{app | deployed: false}
  end

  def deployed(%__MODULE__{machine_id: nil} = app) do
    %__MODULE__{app | deployed: false}
  end

  def deployed(%__MODULE__{} = app) do
    %__MODULE__{app | deployed: true}
  end

  def last_deployed_apps do
    __MODULE__
    |> where([a], not is_nil(a.machine_id) and a.last_deploy_at < datetime_add(^NaiveDateTime.utc_now(), -4, "hour") and a.plan in [0])
    |> limit(5)
    |> Repo.all()
    |> Repo.preload(:machine)
  end
end
