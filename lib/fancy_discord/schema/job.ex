defmodule FancyDiscord.Schema.Job do
  use Ecto.Schema
  alias FancyDiscord.Repo
  alias FancyDiscord.Schema.App
  alias FancyDiscord.Gitlab
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, [autogenerate: true]}
  @derive {Jason.Encoder, only: [:id, :status, :created_at, :finished_at]}
  schema "jobs" do
    field :name, :string
    field :status, :string
    field :gitlab_job_id, :integer
    field :gitlab_pipeline_id, :integer
    field :created_at, :naive_datetime
    field :finished_at, :naive_datetime

    belongs_to :app, App, type: :binary_id

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:name, :status, :gitlab_job_id, :finished_at, :created_at, :gitlab_pipeline_id, :app_id])
    |> validate_required([:name, :status, :gitlab_job_id, :created_at, :gitlab_pipeline_id, :app_id])
    |> validate_inclusion(:status, ["pending", "success", "failed", "running", "canceled"])
    |> foreign_key_constraint(:app_id)
    |> unique_constraint([:gitlab_job_id])
  end

  def get_by(attrs) do
    Repo.get_by(__MODULE__, attrs)
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def update(id, attrs) do
    __MODULE__
    |> Repo.get!(id)
    |> changeset(attrs)
    |> Repo.update!()
  end

  def delete(id) do
    __MODULE__
    |> Repo.get!(id)
    |> Repo.delete!()
  end

  def last_created(app_id) do
    __MODULE__
    |> where([j], j.app_id == ^app_id)
    |> first([desc: :inserted_at])
    |> Repo.one()
  end

  def last_deploy(app_id) do
    job_name = Gitlab.job(:deploy_dokku_app)
    __MODULE__
    |> where([j], j.app_id == ^app_id and j.name == ^job_name)
    |> first([desc: :inserted_at])
    |> Repo.one()
  end

  def active_jobs do
    __MODULE__
    |> lock("FOR UPDATE")
    |> where([j], j.status in ["running", "pending"])
    |> order_by([asc: :inserted_at])
    |> limit(5)
    |> Repo.all()
  end
end
