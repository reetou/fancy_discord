defmodule FancyDiscordWeb.Plugs.CheckAppLimit do
  @behaviour Plug
  import Plug.Conn
  require Logger
  alias FancyDiscord.Schema.User

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(%{assigns: %{current_user: %User{} = user}} = conn, _) do
    with %User{app_limit: limit, apps: apps} <- User.with_apps(user),
         true <- length(apps) < limit do
      conn
    else
      false ->
        conn
        |> send_resp(403, Jason.encode!(%{errors: %{data: "App limit reached. Delete your app to create new one"}}))
        |> halt()
    end
  end
end
