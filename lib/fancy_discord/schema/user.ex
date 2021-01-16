defmodule FancyDiscord.Schema.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  use PowAssent.Ecto.Schema
  alias FancyDiscord.Repo
  alias FancyDiscord.Schema.App

  @primary_key {:id, :binary_id, [autogenerate: true]}
  @foreign_key_type :binary_id
  schema "users" do
    pow_user_fields()

    field :app_limit, :integer, default: 1

    has_many :apps, App
    timestamps()
  end

  def user_identity_changeset(user_or_changeset, user_identity, attrs, user_id_attrs) do
    user_or_changeset
    |> Ecto.Changeset.cast(attrs, [:app_limit])
    |> pow_assent_user_identity_changeset(user_identity, attrs, user_id_attrs)
  end

  def get(id) do
    Repo.get(__MODULE__, id)
  end

  def with_apps(user) do
    Repo.preload(user, :apps)
  end
end
