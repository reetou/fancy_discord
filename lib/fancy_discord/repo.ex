defmodule FancyDiscord.Repo do
  use Ecto.Repo,
    otp_app: :fancy_discord,
    adapter: Ecto.Adapters.Postgres
end
