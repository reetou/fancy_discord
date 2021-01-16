defmodule FancyDiscordWeb.Pow.Routes do
  use Pow.Phoenix.Routes
  alias FancyDiscordWeb.Router.Helpers, as: Routes

  @impl true
  def session_path(conn, verb, query_params \\ []), do: Routes.auth_path(conn, :success)
end
