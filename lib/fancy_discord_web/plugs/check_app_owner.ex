defmodule FancyDiscordWeb.Plugs.CheckAppOwner do
  @behaviour Plug
  import Plug.Conn
  require Logger
  alias FancyDiscord.Schema.User
  alias FancyDiscord.Schema.App

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(%{path_params: %{"app_id" => id}, assigns: %{current_user: %User{} = user}} = conn, _) do
    %User{} = user = User.with_apps(user)
    case App.get_in_user(user, id) do
      %App{} -> conn
      nil ->
        conn
        |> put_status(404)
        |> halt()
    end
  end

  @impl Plug
  def call(%{assigns: %{current_user: %User{} = user}} = conn, _) do
    conn
    |> put_status(400)
    |> halt()
  end
end
