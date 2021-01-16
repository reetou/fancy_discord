# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :fancy_discord,
  ecto_repos: [FancyDiscord.Repo]

# Configures the endpoint
config :fancy_discord, FancyDiscordWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "YgVtMOEybOnY7p9o70opudX1FXuIO8/JAl0WPxY+Z2T/BBuwc0LZxFNIQj0TKOom",
  render_errors: [view: FancyDiscordWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: FancyDiscord.PubSub,
  live_view: [signing_salt: "QdZ/BsVe"]

config :fancy_discord, :gitlab,
  project_id: System.get_env("GITLAB_PROJECT_ID"),
  project_access_token: System.get_env("GITLAB_PROJECT_ACCESS_TOKEN"),
  trigger_token: System.get_env("GITLAB_TRIGGER_TOKEN"),
  jobs: [
    deploy_dokku_app: "deploy_dokku_app",
    create_dokku_app: "create_dokku_app",
    destroy_dokku_app: "destroy_dokku_app"
  ],
  webhook_secret_tokens: [
    default: System.get_env("GITLAB_WEBHOOK_TOKEN")
  ]
config :fancy_discord, :pow,
       user: FancyDiscord.Schema.User,
       repo: FancyDiscord.Repo

config :fancy_discord, :pow_assent,
  providers: [
    discord: [
      client_id: System.get_env("DISCORD_CLIENT_ID"),
      client_secret: System.get_env("DISCORD_CLIENT_SECRET"),
      strategy: Assent.Strategy.Discord
    ]
  ]
# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :fancy_discord, :adjectives, ~w(
  autumn hidden bitter misty silent empty dry dark summer
  icy delicate quiet white cool spring winter patient
  twilight dawn crimson wispy weathered blue billowing
  broken cold damp falling frosty green long late lingering
  bold little morning muddy old red rough still small
  sparkling throbbing shy wandering withered wild black
  young holy solitary fragrant aged snowy proud floral
  restless divine polished ancient purple lively nameless
)

config :fancy_discord, :nouns, ~w(
   waterfall river breeze moon rain wind sea morning
   snow lake sunset pine shadow leaf dawn glitter forest
   hill cloud meadow sun glade bird brook butterfly
   bush dew dust field fire flower firefly feather grass
   haze mountain night pond darkness snowflake silence
   sound sky shape surf thunder violet water wildflower
   wave water resonance sun wood dream cherry tree fog
   frost voice paper frog smoke star
)


config :fancy_discord, FancyDiscord.Scheduler,
  jobs: [
    {"*/3 * * * *", {FancyDiscord.Deploy, :refresh_active_jobs, []}},
    {"*/2 * * * *", {FancyDiscord.Deploy, :kill_old_deploys, []}},
  ]
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
