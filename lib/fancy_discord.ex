defmodule FancyDiscord do
  @moduledoc """
  FancyDiscord keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias FancyDiscord.Gitlab
  require Logger

  def create_bot(%{dokku_app: dokku_app, dokku_host: dokku_host, repo_url: repo_url, default_branch: default_branch}) do
    try do
      Gitlab.Job.start_build(%{
        variables: [
          %{key: "DOKKU_APP", variable_type: "env_var", value: dokku_app},
          %{key: "DOKKU_HOST", variable_type: "env_var", value: dokku_host},
          %{key: "REPO_URL", variable_type: "env_var", value: repo_url},
          %{key: "DEFAULT_BRANCH", variable_type: "env_var", value: default_branch},
        ]
      }, Gitlab.job(:create_dokku_app))
      |> IO.inspect(label: "Result at create dokku")
    rescue
      e ->
        Logger.error("Cannot create bot #{inspect e}")
        raise e
    end
  end

  def deploy_bot(%{bot_token: token, dokku_app: dokku_app, dokku_host: dokku_host, repo_url: repo_url, default_branch: default_branch}) do
    try do
      Gitlab.Job.start_build(%{
        variables: [
          %{key: "DOKKU_APP", variable_type: "env_var", value: dokku_app},
          %{key: "BOT_TOKEN", variable_type: "env_var", value: token},
          %{key: "DOKKU_HOST", variable_type: "env_var", value: dokku_host},
          %{key: "REPO_URL", variable_type: "env_var", value: repo_url},
          %{key: "DEFAULT_BRANCH", variable_type: "env_var", value: default_branch},
        ]
      }, Gitlab.job(:deploy_dokku_app))
      |> IO.inspect(label: "Result at DEPLOY")
    rescue
      e ->
        Logger.error("Cannot deploy bot #{inspect e}")
        raise e
    end
  end
end