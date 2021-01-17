defmodule FancyDiscord.Schema.Machine do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias FancyDiscord.Repo
  alias FancyDiscord.Schema.App

  @default_total_apps 3

  @primary_key {:id, :binary_id, [autogenerate: true]}
  @foreign_key_type :binary_id
  schema "machines" do
    field :ip, :string
    field :maximum_apps, :integer, default: @default_total_apps
    field :deployed_apps, :integer, default: 0

    has_many :apps, App

    timestamps()
  end

  def by_ip(ip) do
    __MODULE__
    |> Repo.get_by(ip: ip)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:ip, :maximum_apps, :deployed_apps])
    |> validate_required([:ip, :maximum_apps, :deployed_apps])
    |> validate_number(:deployed_apps, greater_than_or_equal_to: 0)
    |> validate_number(:maximum_apps, greater_than: 0)
  end

  def create(ip) do
    %__MODULE__{}
    |> changeset(%{ip: ip})
    |> Repo.insert()
  end

  def inc_deployed(%{ip: ip}, val) do
    inc_deployed(ip, val)
  end

  def inc_deployed(ip, val) do
    from(u in __MODULE__, where: u.ip == ^ip)
    |> Repo.update_all([inc: [deployed_apps: val], set: [updated_at: DateTime.utc_now()]])
  end

  def first_available do
    __MODULE__
    |> where([m], m.maximum_apps > m.deployed_apps)
    |> first(desc: :updated_at)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end
end