defmodule FancyDiscordWeb.Plugs.CheckAvailableMachine do
  @behaviour Plug
  import Plug.Conn
  require Logger
  alias FancyDiscord.Schema.User
  alias FancyDiscord.MachineManager

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(%{assigns: %{current_user: %User{}}} = conn, _) do
    case MachineManager.has_available?() do
      true -> conn
      false ->
        conn
        |> send_resp(400, Jason.encode!(%{errors: %{data: "No available machine, try again later"}}))
        |> halt()
    end
  end
end
