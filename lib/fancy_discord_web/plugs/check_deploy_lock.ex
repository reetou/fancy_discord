defmodule FancyDiscordWeb.Plugs.CheckDeployLock do
  @behaviour Plug
  import Plug.Conn
  require Logger
  alias FancyDiscord.DeployLocker
  alias FancyDiscord.Schema.User

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(%{path_params: %{"app_id" => id}, assigns: %{current_user: %User{} = user}} = conn, _) do
    case DeployLocker.check(id) do
      {:error, :in_progress} ->
        conn
        |> send_resp(400, Jason.encode!(%{errors: %{data: "Job already in progress"}}))
        |> halt()
      :ok -> conn
    end
  end
end
