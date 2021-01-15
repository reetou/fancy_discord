defmodule FancyDiscord.UserIdentities.UserIdentity do
  use Ecto.Schema
  use PowAssent.Ecto.UserIdentities.Schema, user: FancyDiscord.Schema.User

  @foreign_key_type :binary_id
  schema "user_identities" do
    pow_assent_user_identity_fields()

    timestamps()
  end
end
