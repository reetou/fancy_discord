defmodule FancyDiscordWeb.Plugs.ApiAuthPlug do
  use Pow.Plug.Base
  alias FancyDiscordWeb.Auth.UserToken
  alias FancyDiscord.Schema.User

  @session_key Application.fetch_env!(:fancy_discord, :session_key)
  @max_age 86400

  def fetch(conn, config) do
    conn  = Plug.Conn.fetch_session(conn)
    token = Plug.Conn.get_session(conn, @session_key)

    UserToken.verify(token, max_age: @max_age)
    |> maybe_load_user(conn)
  end

  defp maybe_load_user({:ok, user_id}, conn), do: {conn, User.get(user_id)}
  defp maybe_load_user({:error, _any}, conn), do: {conn, nil}

  def create(conn, user, config) do
    token = UserToken.sign(user.id)
    conn  =
      conn
      |> Plug.Conn.fetch_session()
      |> Plug.Conn.put_session(@session_key, token)

    {conn, user}
  end

  def delete(conn, config) do
    conn
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.delete_session(@session_key)
  end
end
