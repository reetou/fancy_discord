defmodule FancyDiscordWeb.PublicController do
  use FancyDiscordWeb, :controller
  alias FancyDiscord.MachineManager

  def stats(conn, _params) do
    json(conn, %{
      available_machines: MachineManager.available_machines()
    })
  end
end
