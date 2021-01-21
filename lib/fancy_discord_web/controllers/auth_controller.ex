defmodule FancyDiscordWeb.AuthController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.Schema.User

  def check(%{assigns: %{current_user: %User{}}} = conn, _params) do
    json(conn, %{})
  end

  def success(%{assigns: %{current_user: %User{}}} = conn, _) do
    domain = Application.fetch_env!(:fancy_discord, :cookie_domain)
    conn
    |> Plug.Conn.put_resp_cookie("domain", domain)
    |> redirect(external: Application.fetch_env!(:fancy_discord, :redirect_after_login_url))
  end

  def success(conn, _) do
    conn
    |> put_status(400)
    |> json(%{})
  end
end
