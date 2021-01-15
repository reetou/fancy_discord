defmodule FancyDiscordWeb.Plugs.GitlabSecretTokenPlug do
  @behaviour Plug
  import Plug.Conn
  require Logger
  alias FancyDiscord.Gitlab

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn, _) do
    expected_token = Gitlab.webhook_secret_token(:default)
    conn
    |> get_req_header("x-gitlab-token")
    |> case do
         [token] when token == expected_token -> conn
         _ ->
           conn
           |> put_status(401)
           |> halt()
       end
  end
end
